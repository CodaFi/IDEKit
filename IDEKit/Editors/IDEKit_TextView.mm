//
//  IDEKit_TextView.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon Oct 20 2003.
//  Copyright (c) 2003, 2004 by Glenn Andreas
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Library General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Library General Public License for more details.
//
//  You should have received a copy of the GNU Library General Public
//  License along with this library; if not, write to the Free
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import "IDEKit_TextView.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_SrcEditViewExtensions.h"
#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_SrcEditViewFolding.h"

NSString *IDEKit_ConvertFilesPBoardType = @"IDEKit_ConvertFilesPBoardType";

@implementation IDEKit_TextView

- (void)interpretKeyEvents:(NSArray *)eventArray
{
    //NSLog(@"got interpretKeyEvents! (%@)",[eventArray description]);
    if ([[self delegate] respondsToSelector: @selector(textView:shouldInterpretKeyEvents:)] && [[self delegate]textView: self shouldInterpretKeyEvents: eventArray] == NO)
		return;
    [super interpretKeyEvents: eventArray];
}

- (NSMenu *) menu
{
    NSMenu *realMenu = [[super menu] copy];
//    NSMenu *menu = [[self delegate] menu];
    NSMenu *retval = [[NSMenu alloc] init];
//    for (int i=0;i<[menu numberOfItems];i++) {
//		[retval addItem: [[menu itemAtIndex: i] copy]];
//    }
    for (int i=0;i<[realMenu numberOfItems];i++) {
		[retval addItem: [[realMenu itemAtIndex: i] copy]];
    }
    return retval;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 1) {
		[super mouseDown: theEvent];
    } else if ([theEvent clickCount] == 2) {
		NSRange sel = [self selectedRange];
		if (sel.length == 0) {
			unichar balance = [[self string] characterAtIndex: sel.location];
			//NSLog(@"Trying to balance %C from %d", balance,sel.location);
			NSRange balanced = {0,0};
			id currentLanguage = [(IDEKit_SrcEditView*)[self delegate] currentLanguage];
			if (currentLanguage) {
				balanced = [currentLanguage selectionForMultiClick: theEvent fromSelection: sel inView: self];
			}
			if (balanced.length == 0) {
				// for free we handle balancing (), [], {}
				if (balance == '(' || balance == '[' || balance == '{') {
					balanced = [self balanceFrom: sel.location+1]; // start from inside balance
				} else if (balance == ')' || balance == ']' || balance == '}') {
					balanced = [self balanceFrom: sel.location];
				}
			}
			if (balanced.length != 0) {
				[self setSelectedRange: balanced];
			} else {
				[super mouseDown: theEvent];
			}
		}
    } else {
		NSRange sel = [self selectedRange];
		id currentLanguage = [(IDEKit_SrcEditView*)[self delegate] currentLanguage];
		NSRange balanced = {0,0};
		if (currentLanguage) {
			balanced = [currentLanguage selectionForMultiClick: theEvent fromSelection: sel inView: self];
		}
		if (balanced.length != 0) {
			[self setSelectedRange: balanced];
		} else {
			[super mouseDown: theEvent];
		}
    }
}
#pragma mark Folding Support
- (NSInteger) foldableIndentOfRange: (NSRange) range hasFold: (BOOL *)fold  atOffset: (NSUInteger *)offset;
{
    int indent = 0;
    if (fold) *fold = NO;
    NSString *s = [[self textStorage] string];
    for (NSInteger ci = range.location; ci < range.location + range.length;ci++) {
		unichar c = [s characterAtIndex:ci];
		if (c == '\t') {
			indent++;
		} else {
			if (c == NSAttachmentCharacter) {
				if (fold) *fold = YES;
				if (offset) *offset = ci;
			}
			break; // done
		}
    }
    return indent;
}
- (NSInteger) foldabilityAtOffset: (NSUInteger) offset foldedAtOffset: (NSUInteger *)foldOffset
{
#ifdef foldonnext
    NSString *s = [[self textStorage] string];
    NSRange lineRange = [s lineRangeForRange: NSMakeRange(offset,0)];
    // and the previous line
    BOOL isFolded = NO;
    int thisIndent = [self foldableIndentOfRange: lineRange hasFold: &isFolded atOffset: foldOffset];
    if (isFolded)
		return 1;
    if (lineRange.location == 0) {
		// at the start of the file
		return 0;
    }
    NSRange prevRange = [s lineRangeForRange: NSMakeRange(lineRange.location-1,0)];
    if (prevRange.length <= 1) // previous line is blank, so don't fold
		return 0;
    if (thisIndent > [self foldableIndentOfRange: prevRange hasFold: NULL atOffset: NULL]) { // not folded so don't need to update offset
		return -1;
    }
    return 0;
#else
    NSString *s = [[self textStorage] string];
    NSRange lineRange = [s lineRangeForRange: NSMakeRange(offset,0)];
    // and the previous line
    NSInteger thisIndent = [self foldableIndentOfRange: lineRange hasFold:NULL atOffset: NULL];
    if (lineRange.location + lineRange.length + 1 >= [s length]) {
		// at the end of the file
		return 0;
    }
    BOOL isFolded = NO;
    NSRange nextRange = [s lineRangeForRange: NSMakeRange(lineRange.location + lineRange.length + 1,0)];
    NSInteger nextIndent = [self foldableIndentOfRange: nextRange hasFold: &isFolded atOffset: foldOffset];
    if (isFolded) // actually, next line is folded
		return 1;
    if (lineRange.length <= 1) // this line is blank, so don't fold
		return 0;
    if (nextIndent > thisIndent) { // we can fold
		return -1;
    }
    return 0;
#endif
}

// This is so copy & paste, while they loose the collapsed state, don't loose the collapsed text
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    //NSLog(@"Copy type %@",type);
    if ([[self textStorage] containsAttachments]) {
		// if we've got collapsed text, so we only grab NSStringPboardType (or the paste doesn't do NSStringPboardType)
		NSAttributedString *selection = [[self textStorage] attributedSubstringFromRange: [self selectedRange]];
		if ([selection containsAttachments]) {
			if ([type isEqualToString: NSStringPboardType]) {
				NSString *expandedString = [selection uncollapsedString];
				[pboard setString: expandedString forType: type];
				return YES;
			}
			return NO;
		}
    }
    // do what our super does
    return [super writeSelectionToPasteboard: pboard type: type];
}

// make sure to paste as plain text
- (IBAction) paste: (id) sender
{
    [self pasteAsPlainText: sender];
}
- (IBAction) pasteAsRich: (id) sender
{
    [self pasteAsPlainText: sender];
}
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if ([type isEqualToString: NSStringPboardType]) {
		//return [super readSelectionFromPasteboard: pboard type: type];
		// fix autoindent
		NSString *text = [pboard stringForType: type];
		text = [(IDEKit_SrcEditView*)[self delegate] massageInsertableText: text];
		NSRange range = [self rangeForUserTextChange];
		if ([self shouldChangeTextInRange:range replacementString:text]) {
			[self replaceCharactersInRange:range withString:text];
			[self didChangeText];
		}
		return YES;
    }
    return NO;
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info
{
    // start of drag - convert a file to a string so we can accept and track it
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: NSFilenamesPboardType] && ![[pboard types] containsObject: NSStringPboardType]) {
		// this is a bit ugly - changing the drag info to be something that we've got that has a string
		id files = [pboard propertyListForType:NSFilenamesPboardType]; // since it could go away
		[pboard declareTypes: [NSArray arrayWithObjects:NSStringPboardType, IDEKit_ConvertFilesPBoardType, NULL] owner: self];
		//[pboard addTypes: [NSArray arrayWithObject:NSStringPboardType] owner: self];
		[pboard setString: @"<IDEKit soon to be files>" forType: NSStringPboardType];
		[pboard setPropertyList: files forType: IDEKit_ConvertFilesPBoardType]; // use our own type here
		[files release]; // new pboard has them
		//NSLog(@"Changed pboard %@(%@)",[pboard description], [[pboard types] description]);
    }
    NSDragOperation retval = [super draggingEntered: info];
    //NSLog(@"draggin entered returns %d",retval);
    return retval;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) info
{
    // we want to have drag & drop work with folded text eventually, but for now
    // good place to hook in droppping files & directories
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: IDEKit_ConvertFilesPBoardType]) {
		NSString *representation = [IDEKit representationOfDropFiles: [pboard propertyListForType:IDEKit_ConvertFilesPBoardType] forOperation: sourceDragMask];
		if (representation) {
			[pboard setString: representation forType: NSStringPboardType];
		}
    }
    return [super performDragOperation: info];
}

#pragma mark Tooltips
#ifdef notyet
- (void) helpRequested: (id) sender
{
    NSLog(@"Showing contextual help");
    NSHelpManager *helpManager = [NSHelpManager sharedHelpManager];
    [helpManager setContextHelp: [[[NSAttributedString alloc] initWithString: @"Argle Bargle"] autorelease] forObject: self];
    [helpManager showContextHelpForObject: self locationHint: [NSEvent mouseLocation]];
}
#endif

#pragma mark Completion
- (void) complete: (id) sender
{
    // need to see if we already do completion (i.e., 10.3 and later) by default
    // or if we need to manually do the completion
#ifdef nomore
    if ([self respondsToSelector: @selector(completionsForPartialWordRange:indexOfSelectedItem:)]) {
		[super complete: sender];
    } else {
		// bubble up to the delegate (SrcEditView)
		[[self delegate] complete: sender];
    }
#else
    // Actually, just do it ourselves for consistency and the ability to get new UI and more flexible selections
    [(IDEKit_SrcEditView*)[self delegate] complete: sender];
#endif
}
- (NSRange) rangeForUserCompletion
{
    NSCharacterSet *cset = [[(IDEKit_SrcEditView*)[self delegate] currentLanguage] characterSetForAutoCompletion];
    if (!cset) cset = [NSCharacterSet alphanumericCharacterSet];
    NSRange range = [self selectedRange];
    NSString *str = [self string];
    // expand backwards so long as we are in the characterset
    while (range.location > 0 && [cset characterIsMember: [str characterAtIndex: range.location-1]]) {
		range.location--;
		range.length++; // keep end same
    }
    return range;
}
@end
