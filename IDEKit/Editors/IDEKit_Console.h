//
//  IDEKit_Console.h
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

#import <AppKit/AppKit.h>

// IDEKit_Console is to support console windows (for example, for interactive
// interpreters).  It assumes that the user will type a line (possibly more)
// of some sort of text which is then sent to the interpreter, with the output
// coming back here.
//
// There is no default nib for this currently, but you should subclass this
// to provide a UI - all that is required is a text view
//
// The model is that the user types, and when they hit return, the text they've typed
// is sent to be performed.  This document will keep track of handling things like prompts,
// including multi-line input (it will append the commands together, separated by newlines)
//
// There is also the idea of multiple "output" streams that can be emitted.  We will automagically
// group all the stream output together between commands (even while waiting for more text, if
// the output is somehow running async).
//
// The text view has three "areas"
//      Ancient history - this never changes
//      Current output - this is where writeText:toStream: shows up
//      Current input - where all editing by the user happens
//	    Current input past multi-lines (if any)
//	    Current input last multi-line
//
// The user can not edit anywhere except current input (they can select & copy, however)
//
// Current output is updated whenever something happens, which can update current input area
// The current command is edited line by line, with the current input area actually broken down
// into previous lines (which don't change) and current line (which does)
//

@class IDEKit_SrcEditView;

@interface IDEKit_Console : NSDocument {
    IBOutlet IDEKit_SrcEditView *myEditText;
    NSMutableArray *myHistory;
    NSMutableDictionary *myStreamAttributes; // contains typing attributes
    NSMutableArray *myStreamNames;
    NSMutableDictionary *myLastStreamOutput;// contains mutable strings
	NSDictionary *myTypingAttributes; // for input
    NSUInteger myOutputStart; // start of current output
    NSUInteger myInputStart; // start of current + past lines (includes prompts)
    NSUInteger mySelStart;// only the current line (does not include prompts)
    BOOL myGotCommand;
    NSUInteger myCurHistoryIndex;
    NSMutableString *myInputSoFar;
}
- (void) addStream: (NSString *) streamName withAttributes: (NSDictionary *)attributes;
- (void) writeText: (NSString *) output toStream: (NSString *)streamName;
- (IBAction)clearConsoleOutput:(id)sender;
    // in case we don't like the default pageup/down bindings
- (void) nextHistory: (id) sender;
- (void) prevHistory: (id) sender;
- (void) setCurrentCommand: (NSString *)command; // will include prompts, even multi-line ones
- (void) promptChanged; // dynamic prompt changed
- (NSString *)currentCommand;
- (NSDictionary *)inputAttributes; // attributes of text input

// These are to be implemented by the subclass that actually interfaces with the
// interpeter.
- (NSString *) commandPrompt; // for single line entry
- (NSString *) multiLinePrompt; // for subsequent lines in multi line prompts
- (BOOL) isMultiLineCommand: (NSString *) command; // does the command so far require more (is it a multi-line prompt)?
- (void) performCommand: (NSString *)command; // execute the actual command
// since the console isn't a language/project, autoComplete may not be the same as the project
// Return what could be _added_ to the command, or NULL for no completion
- (NSArray *) autoCompleteCommand: (NSString *) command; 
- (NSString *) toolTipForCommand: (NSString *)command;
@end
