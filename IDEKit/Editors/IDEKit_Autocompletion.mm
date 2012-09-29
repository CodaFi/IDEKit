//
//  IDEKit_Autocompletion.mm
//  IDEKit
//
//  Created by Glenn Andreas on Sat Mar 20 2004.
//  Copyright (c) 2004 by Glenn Andreas
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

#import "IDEKit_Autocompletion.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_TextViewExtensions.h"

@interface IDEKit_FloatingKeyWindow : NSWindow
@end
@implementation IDEKit_FloatingKeyWindow
- (BOOL)canBecomeKeyWindow
{
    return YES; // otherwise no title, not key
}
@end
@interface IDEKit_AutoCompleteList : NSTableView
@end
@implementation IDEKit_AutoCompleteList
- (void)keyDown:(NSEvent *)theEvent
{
    // skip up to our controller
    NSString *s = [theEvent characters];
    for (NSUInteger i=0;i<[s length];i++) {
	unichar c = [s characterAtIndex:i];
	//NSLog(@"Key down: %x, %C",c,c);
	switch (c) {
	    case 27: // escape
		[[[self window] windowController] cancelOperation: self];
		break;
	    case NSEnterCharacter:
	    case NSNewlineCharacter:
	    case NSCarriageReturnCharacter:
		[[[self window] windowController] insertNewline: self];
		break;
	    case NSBackspaceCharacter:
	    case NSDeleteCharacter:
		[[[self window] windowController] deleteBackward: self];
		break;
	    case NSUpArrowFunctionKey:
	    case NSDownArrowFunctionKey:
		[super keyDown: theEvent]; // not quite perfect, if there are multiple characters here
		break;
	    default:
		if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember: c] || [[NSCharacterSet punctuationCharacterSet] characterIsMember: c]) {
		    [[[self window] windowController] insertText: [NSString stringWithFormat: @"%C",c]];
		} else {
		    NSBeep();
		}
	}
    }
}
@end

@implementation IDEKit_Autocompletion

- (id) initWithCompletions: (NSArray *)completions
{
    self = [super initWithWindow: nil];
    if (self) {
	myCompletions = [completions sortedUniqueArray]; // make sure we are sorted & unique
	if ([completions count]) {
	    myCommonPrefix = [completions[0] mutableCopy];
	    for (NSUInteger i=1;i<[completions count];i++) {
		//NSLog(@"Common prefix %@",myCommonPrefix);
		NSString *next = completions[i];
		if ([next hasPrefix:myCommonPrefix]) {
		    // good to keep going
		    continue;
		}
		[myCommonPrefix setString:[myCommonPrefix commonPrefixWithString: next options: 0]];
		// we may have trimmed it to nought
		if ([myCommonPrefix length] == 0)
		    break; // don't bother looking further
	    }
	    myCurrentTypeAhead = [myCommonPrefix mutableCopy];
	} else {
	    myCommonPrefix = NULL;
	    myCurrentTypeAhead = NULL;
	}
	
	[NSBundle loadOverridenNibNamed: @"IDEKit_Autocompletions" owner: self]; // use default, or overridden version
	//NSLog(@"Inited, view %@",myView);
    }
    return self;
}

- (void) dealloc
{
    [myList setDataSource: NULL];
    [myList setDelegate: NULL];
     // release the top level named object in the NIB since we loaded it
//    [myTextView release];
//    [myScrollView release];
//    [myList release];
}
- (void)awakeFromNib
{
    //NSLog(@"IDEKit_Autocompletion awakeFromNib, view %@",myView);
    if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
    }
    [myList setTarget: self];
    [myList setDoubleAction:@selector(endSessionWithCompletedString:)];
    [myTextView setStringValue: myCommonPrefix];
    [self updateTypeSelection];
}

- (void) updateTypeSelection
{
    // find the first thing that matches our current type selection, if anything
    if ([myCurrentTypeAhead length] == 0) {
	if ([myList selectedRow] != -1) [myList deselectRow: [myList selectedRow]];
	return;
    }
    for (NSUInteger i=0;i<[myCompletions count];i++) {
	if ([myCompletions[i] hasPrefix:myCurrentTypeAhead]) {
	    [myList selectRow:i byExtendingSelection:false];
	    [myList scrollRowToVisible: i];
	    return;
	}
    }
    if ([myList selectedRow] != -1) [myList deselectRow: [myList selectedRow]];
}

- (void) endSessionWithCompletedString: (id) sender
{
    [NSApp stopModalWithCode: NSRunStoppedResponse];
}
- (void)insertNewline:(id)sender
{
    [NSApp stopModalWithCode: NSRunStoppedResponse];
}
- (void)cancelOperation:(id)sender
{
    [NSApp stopModalWithCode: NSRunAbortedResponse];
}
- (void)insertText:(NSString *)aString
{
    [myCurrentTypeAhead appendString:aString];
    [myTextView setStringValue: myCurrentTypeAhead];
    [self updateTypeSelection];
}
- (void)deleteBackward:(id)sender
{
    if ([myCurrentTypeAhead length] > [myCommonPrefix length]) {
	[myCurrentTypeAhead deleteCharactersInRange: NSMakeRange([myCurrentTypeAhead length]-1,1)]; // trim off last character
	[myTextView setStringValue: myCurrentTypeAhead];
	[self updateTypeSelection];
    } else {
	[NSApp stopModalWithCode: NSRunAbortedResponse];
    }
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [myCompletions count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    return myCompletions[row];
}

- (id)popupAssistantAt: (NSPoint)where forView: (NSTextView *)view
{
    if ([myCompletions count] == 0) {
	[view popupHelpTagAtInsertion: [[NSAttributedString alloc] initWithString: @"No completions"]];
	return NULL; // nothing possible
    }
    if ([myCompletions count] == 1) {
	return myCompletions[0]; // only one choice
    }
    //NSLog(@"Creating window at %g,%g",where.x,where.y);
    NSRect bounds = [myView frame];
    bounds.origin = where;
    bounds.origin.y -= bounds.size.height;
    NSWindow *w = [[IDEKit_FloatingKeyWindow alloc] initWithContentRect: bounds styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    
    [self setWindow:w];
    [w setContentView: myView];
    [w setHasShadow: YES];
    [w setLevel: NSPopUpMenuWindowLevel];
    [w makeKeyAndOrderFront:self];
    //[w setInitialFirstResponder:myList];
    [[view window] addChildWindow: w ordered: NSWindowAbove];
    [w makeKeyWindow];
    //NSLog(@"My window %@, my view %@",w,myView);

    NSInteger result = [NSApp runModalForWindow:w];
    id retval;
    if (result == NSRunStoppedResponse) {
	if ([myList selectedRow] == -1) {
	    retval = myCurrentTypeAhead; // use whatever we typed
	} else {
	    retval = myCompletions[[myList selectedRow]];
	}
    } else {
	retval = NULL;
    }
    [[view window] removeChildWindow: w];
    [[view window] makeKeyWindow]; // restore key window
    //[w orderOut: self];
    //[w close];
    //[w release];
    [self close];
    return retval;
}

@end

@implementation NSArray(IDEKit_Autocompletion)
- (NSArray *) sortedUniqueArray
{
    NSSet *set = [NSSet setWithArray: self]; // make unique
    NSArray *unique = [set allObjects];
    return [unique sortedArrayUsingSelector: @selector(caseSensitiveCompare:)];
}
@end

