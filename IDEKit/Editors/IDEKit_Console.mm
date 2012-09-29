//
//  IDEKit_Console.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon Jan 19 2004.
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
//

#import "IDEKit_Console.h"
#import "IDEKit_TextViewExtensions.h"

@implementation IDEKit_Console
- (void) dealloc
{
    [myHistory release];
    [myStreamAttributes release];
    [myTypingAttributes release];
    [myStreamNames release];
    [myLastStreamOutput release];
    [myInputSoFar release];
}

- (void) awakeFromNib
{
    myHistory = [[NSMutableArray array] retain];
    myStreamAttributes = [[NSMutableDictionary dictionary] retain];
    myStreamNames = [[NSMutableArray array] retain];
    myLastStreamOutput = [[NSMutableDictionary dictionary] retain];
    myGotCommand = NO;
    myOutputStart = myInputStart = mySelStart = 0;
    [myEditText setDelegate: NULL];
    [myEditText insertText: [self commandPrompt]];
    mySelStart = [[myEditText string] length]; // and sel starts after prompt
    [myEditText setDelegate: self];
    myTypingAttributes = [[myEditText typingAttributes] copy];
    //NSLog(@"Typing attributes %@",myTypingAttributes);
    myCurHistoryIndex = 0;
    myInputSoFar = [[NSMutableString string] retain];
}

- (NSDictionary *)inputAttributes // attributes of text input
{
    return myTypingAttributes;
}

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"IDEKit_Console";
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    // Implement to provide a persistent data representation of your document OR remove this and implement the file-wrapper or file path based save methods.
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    // Implement to load a persistent data representation of your document OR remove this and implement the file-wrapper or file path based load methods.
    return YES;
}

- (void) redisplayLastOutput
{
    [myEditText setDelegate: NULL]; // we don't need to be asked about what we are doing
    NSTextStorage *storage = [myEditText textStorage];
    NSMutableAttributedString *newOutput = [[[NSMutableAttributedString alloc] init] autorelease];
    NSEnumerator *e = [myStreamNames objectEnumerator];
    NSString *streamName = [e nextObject];
    while (streamName) {
		NSString *output = [myLastStreamOutput objectForKey: streamName];
		if (output && [output length]) {
			NSDictionary *attributes = [myStreamAttributes objectForKey: streamName];
			NSAttributedString *attribOutput;
			if ([output characterAtIndex:[output length] - 1] != '\n') {
				// need to append newline at end
				attribOutput = [[[ NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n",output] attributes: attributes] autorelease];
			} else {
				attribOutput = [[[ NSAttributedString alloc] initWithString: output attributes: attributes] autorelease];
			}
			// toss that attributed string onto the end of our output
			[newOutput appendAttributedString: attribOutput];
		}
		streamName = [e nextObject];
    }
    NSAssert2(myOutputStart <= myInputStart,@"Output %d needs to be before input %d",myOutputStart,myInputStart);
    NSAssert2(myInputStart <= [storage length],@"Input %d needs to be before end of text %d",myInputStart,[storage length]);
    // newOutput is now attributed text like we want with all the outputs in order
    //NSLog(@"Replacing %d..%d/%d with new string (%d bytes)",myOutputStart,myInputStart,[storage length],[newOutput length]);
    [storage replaceCharactersInRange: NSMakeRange(myOutputStart,myInputStart-myOutputStart) withAttributedString: newOutput];
    // adjust our boundary pointers
    int outputDeltaLen =[newOutput length]  -(myInputStart-myOutputStart); // how much did the output change length?
    myInputStart += outputDeltaLen; // our input now starts here
    mySelStart += outputDeltaLen;
    //NSLog(@"My input %d, my sel %d, new len %d",myInputStart,mySelStart,[storage length]);
    [myEditText setDelegate: self];
}

- (void) restartOutput
{
    // our output is onscreen, start next batch of output
    NSEnumerator *e = [myStreamNames objectEnumerator];
    NSString *streamName = [e nextObject];
    while (streamName) {
		// clear this stream
		[myLastStreamOutput setObject: [NSMutableString string] forKey: streamName];
		streamName = [e nextObject];
    }
}

- (void) addStream: (NSString *) streamName withAttributes: (NSDictionary *)attributes
{
    [myStreamAttributes setObject: attributes forKey: streamName];
    [myStreamNames addObject: streamName];
    [myLastStreamOutput setObject: [NSMutableString string] forKey: streamName];
}

- (void) writeText: (NSString *) output toStream: (NSString *)streamName
{
    if ([myStreamNames containsObject: streamName]) {
		// put it in the correct stream
		[[myLastStreamOutput objectForKey: streamName] appendString: output];
		[self redisplayLastOutput];
    }
}

- (void) setCurrentCommand: (NSString *) command
{
    // split apart into lines, rejoin with appropriate prompts
    NSMutableArray *components = [[[command componentsSeparatedByString: @"\n"] mutableCopy] autorelease];
    [components removeObject: @""]; // remove the empty lines
    NSString *prompted = [NSString stringWithFormat: @"%@%@", [self commandPrompt],[components componentsJoinedByString: [NSString stringWithFormat: @"\n%@",[self multiLinePrompt]]]];
    NSAttributedString *newPrompt = [[[ NSAttributedString alloc] initWithString: prompted attributes: myTypingAttributes] autorelease]; // make sure typing attributes are correct
    // replace old input with this
    [myEditText setDelegate: NULL];
    NSTextStorage *storage = [myEditText textStorage];
    [storage replaceCharactersInRange: NSMakeRange(myInputStart,[storage length] - myInputStart) withAttributedString: newPrompt];
    [myEditText setSelectedRange:NSMakeRange([storage length],0)]; // move to end
    // now the tricky part is fixing mySelStart
    [myInputSoFar setString: command];
    if ([components count]) {
		int lastLength = [(NSString *)[components objectAtIndex: [components count]-1] length];
		mySelStart = [storage length] - lastLength; // and we can edit the last line worth
		[myInputSoFar deleteCharactersInRange: NSMakeRange([myInputSoFar length] - lastLength, lastLength)]; // remove the last line here
    } else {
		// empty line
		mySelStart = [storage length];
    }
    [myEditText setDelegate: self];
}

- (void) promptChanged // dynamic prompt changed
{
    [self setCurrentCommand: [[[self currentCommand] copy] autorelease]]; // just redisplay
}

- (void) nextHistory: (id) sender
{
    myCurHistoryIndex++;
    if (myCurHistoryIndex >= [myHistory count]) {
		[self setCurrentCommand: @""];
		myCurHistoryIndex = [myHistory count];
    } else {
		[self setCurrentCommand: [myHistory objectAtIndex: myCurHistoryIndex]];
    }
}

- (void) prevHistory: (id) sender
{
    if (myCurHistoryIndex > 0)
		myCurHistoryIndex--;
    if (myCurHistoryIndex >= [myHistory count]) {
		[self setCurrentCommand: @""];
		myCurHistoryIndex = [myHistory count];
    } else {
		[self setCurrentCommand: [myHistory objectAtIndex: myCurHistoryIndex]];
    }
}

-(void) updatePseudoTooltipForView: (NSTextView *)view
{
    // make sure the tool tip refer to the current line only
    [view removeAllToolTips];
    // get the bounds of the current line
    NSRange range = [[view string] lineRangeForRange: [view selectedRange]];
    NSRange glyphRange = [[view layoutManager] glyphRangeForCharacterRange: range actualCharacterRange: NULL];
    NSRect boundingRect = [[view layoutManager] boundingRectForGlyphRange: glyphRange inTextContainer: [view textContainer]];
    boundingRect.size.width = 9999.0;
    [view addToolTipRect: boundingRect owner: self userData: NULL];
}
- (NSString *) view: (NSView *)view stringForToolTip: (NSToolTipTag) tag point: (NSPoint) point userData: (void *)userData
{
    NSString *tip = [self toolTipForCommand: [self currentCommand]];
    return tip;
}

- (void) completeCompletionWith: (NSString *) value
{
    //NSLog(@"Complete completion with %@",value);
    // since we didn't have the concept of "completion subrange" we just
    // remove the overlap between string and the selection
    NSUInteger start = [myEditText selectedRange].location;
    NSUInteger overlap = [value length]; // start with full overlap
    if (overlap > start) overlap = start;
    while (overlap > 0) {
		//NSLog(@"%d:does %@ overlap with %@",overlap,[[myEditText string] substringWithRange:NSMakeRange(start - overlap, overlap)], [value substringToIndex:overlap]);
		if ([[[myEditText string] substringWithRange:NSMakeRange(start - overlap, overlap)] isEqualToString:[value substringToIndex:overlap]])
			break; // found it!
		overlap--;
    }
    [myEditText setDelegate: NULL];
    [myEditText insertText: [value substringFromIndex:overlap]];
    //[myEditText setSelectedRange:NSMakeRange(start-overlap,[value length])]; // select all of what we entered
    [myEditText setSelectedRange:NSMakeRange(start-overlap + [value length],0)]; // select at end
    [myEditText setDelegate: self];
}
- (IBAction) doCompletion: (id) sender
{
    [self completeCompletionWith: [sender representedObject]];
}
- (IBAction) complete: (id) sender
{
    // try auto-completion
    //NSLog(@"complete console");
    NSArray *autoComplete = [self autoCompleteCommand: [self currentCommand]];
    if (autoComplete) {
		// for now, just use the first item
		if ([autoComplete count] == 1) {
			[self completeCompletionWith: [autoComplete objectAtIndex: 0]];
		} else {
			id completion = [myEditText popupCompletionAtInsertion: autoComplete];
			if (completion) {
				[self completeCompletionWith: completion];
			}
		}
    }
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index
{
    // let Panther handle it
    NSArray *autoComplete = [self autoCompleteCommand: [self currentCommand]];
    return autoComplete;
}
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    //NSLog(@"textView:doCommandBySelector");
    if (aSelector == @selector(moveUp:)) {
		[self prevHistory: self];
		return YES;
    }
    if (aSelector == @selector(moveDown:)) {
		[self nextHistory: self];
		return YES;
    }
    if (aSelector == @selector(moveToBeginningOfLine:)) {
		// move to after prompt
		[myEditText setSelectedRange:NSMakeRange(mySelStart,0)];
		return YES;
    }
    if (aSelector == @selector(complete:)) {
		//NSLog(@"textView:doCommandBySelector:complete console");
		[self complete: self];
		return YES;
    }
    if (aSelector == @selector(insertNewline:)) {
		myGotCommand = YES;
		[myEditText setSelectedRange:NSMakeRange([[myEditText textStorage] length],0)];
		return NO; // perform it like normal now that we are in the right place
    }
    return NO;
}
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    //NSLog(@"Should, change %d-%d?",affectedCharRange.location,affectedCharRange.length);
    if (affectedCharRange.location < mySelStart)
		return NO; // don't edit anything before my selection
    if ([replacementString rangeOfString: @"\n"].location != NSNotFound) {
		myGotCommand = YES; // about to have a command
    }
    return YES;
}

- (NSString *)currentCommand
{
    NSString *lastLine = [[myEditText string] substringWithRange: NSMakeRange(mySelStart,[[myEditText string] length] - mySelStart)]; // this would include EOL, if any
    return [myInputSoFar stringByAppendingString:lastLine];
}

- (void)textDidChange:(NSNotification *)notification
{
    if (myGotCommand) {
		myGotCommand = NO;
		// now get the text
		//NSLog(@"Attempting to exectute from %d-%d",mySelStart,[[myEditText string] length]);
		NSString *command = [myInputSoFar stringByAppendingString:
							 [[myEditText string] substringWithRange: NSMakeRange(mySelStart,[[myEditText string] length] - mySelStart-1)]]; // don't include eol
		if ([[myEditText string] length] - mySelStart-1 > 0 && [self isMultiLineCommand: command]) { // empty line - force complete
			// add this to our input so far
			[myInputSoFar release];
			myInputSoFar = [command mutableCopy];
			[myInputSoFar appendString: @"\n"]; // add back trailing newline
			// put out our secondary prompt
			mySelStart = [[myEditText string] length]; // we start after the secondary prompt
			[myEditText setDelegate: NULL];
			[myEditText setSelectedRange:NSMakeRange(mySelStart,0)];
			[myEditText setTypingAttributes: myTypingAttributes];
			[myEditText insertText: [self multiLinePrompt]]; // put out next prompt
			[myEditText setDelegate: self];
			mySelStart = [[myEditText string] length]; // we start after the secondary prompt
			// then keep going
		} else {
			[myEditText setDelegate: NULL];
			// we are now at the end of the text
			myOutputStart = [[myEditText string] length];
			myInputStart = myOutputStart; // for now
			[self restartOutput]; // commit what we've got
			if ([command length] && ![myHistory containsObject: command]) {
				[myHistory addObject: command]; // don't add if we already are there
				myCurHistoryIndex = [myHistory count];
			}
			myCurHistoryIndex = [myHistory count]; // skip history to end
			[myInputSoFar release];
			myInputSoFar = [[NSMutableString string] retain];
			[self performCommand: command];
			// if there is any output, it will be handled above, and inputStart will be adjusted accordingly
			// go to end
			[myEditText setSelectedRange:NSMakeRange(myInputStart,0)];
			[myEditText setTypingAttributes: myTypingAttributes];
			[myEditText insertText: [self commandPrompt]]; // put out next prompt
			[myEditText setDelegate: self];
			mySelStart = [[myEditText string] length]; // we start after the prompt
		}
    }
    [self updatePseudoTooltipForView: [notification object]];
}

- (IBAction)clearConsoleOutput:(id)sender
{
    [myEditText setDelegate: NULL];
    [myEditText selectAll: sender];
    [myEditText delete: sender];
    myOutputStart = 0;
    myInputStart = 0;
    [self setCurrentCommand: @""];
    [myEditText setDelegate: self];
}


// Should be implemented by subclass
- (NSString *) commandPrompt // for single line entry
{
    return @">>> ";
}

- (NSString *) multiLinePrompt // for subsequent lines in multi line prompts
{
    return @"... ";
}

- (BOOL) isMultiLineCommand: (NSString *) command // does the command so far require more (is it a multi-line prompt)?
{
    return NO;
}

- (void) performCommand: (NSString *)command // execute the actual command
{
    // for now, ignore it
    NSLog(@"Console needs to implement performCommand for command %@",command);
}

- (NSArray *) autoCompleteCommand: (NSString *) command
{
    return NULL;
}
- (NSString *) toolTipForCommand: (NSString *)command
{
    return NULL;
}

@end
