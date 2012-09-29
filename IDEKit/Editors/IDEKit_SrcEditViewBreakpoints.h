//
//  IDEKit_SrcEditViewBreakpoints.h
//  IDEKit
//
//  Created by Glenn Andreas on 9/15/04.
//  Copyright 2004 by Glenn Andreas.
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

/*
 So, how do breakpoints work?  Where are they stored?  How do we toggle them?
 
 The srcEditView is responsible for answering the questions (asked by the scroller) about
 the state of the breakpoints, as well as actually changing them.  As such, it is also responsible
 for maintaining the information.
 
 Breakpoints are extra problematic because they move (as the file is edited) and are also shared - so
 if you edit a file, and have that same file in the debugger, setting the breakpoint in one should set it
 in the other.
 
 Of course, if you edit the file while also having the file in a debugger, how should the breakpoints
 behave?  For us, the correct answer is, once the file is modified from what a debugger is using, it should
 no longer be linked to its breakpoints (i.e., it may not even show them).  Furthermore, we require that
 the editor view in the debugger be read-only (we really don't support having multiple views of source).
 
 The breakpoint use to be stored as an attribute to the text, but we now store it in our line cache
 in the general line data (which survives folding, etc...).
 
 */

#import <AppKit/AppKit.h>
#import "IDEKit_SrcEditView.h"
#import "IDEKit_Breakpoint.h"

@interface IDEKit_SrcEditView(Breakpoints)
// get the current breakpoint, if any...
- (IDEKit_Breakpoint *)getBreakpoint: (NSInteger)line; // only real breakpoints
- (IDEKit_Breakpoint *)getBreakpointForDisplay: (NSInteger)line; // includes "program counter" (or other similar things)
- (NSInteger) getBreakpointCapability: (NSInteger) line; // return if there could be a breakpoint here, etc...
- (void) removeBreakpoint: (NSInteger) line; // user clicked here - turn on/off as default
- (void) addBreakpoint: (NSInteger) line; // user clicked here - turn on/off as default

#ifdef nomore
    // want to remove these
- (NSInteger) getBreakPoint: (NSInteger) line;
- (void) setBreakPoint: (NSInteger) line kind: (NSInteger) kind;
    // a breakpoint can contain more information
- (NSDictionary *) getBreakPointData: (NSInteger) line;
- (void) setBreakPoint: (NSInteger) line kind: (NSInteger) kind data: (NSDictionary *)data;
- (void) toggleBreakPoint: (NSInteger) line; // depricated
- (void) updateProjectWithBreakpoints;
- (NSMenu *)toggleBreakPointMenuForLine: (NSInteger) line;
#endif
- (void) updateBreakpointsFromProject;

- (void) forceBreakpointRedraw;
// not used
- (NSMenu *) breakpointMenuForLine: (NSInteger) line;
- (IBAction) showBreakpointInspector: (id) sender;
- (IBAction) clearAllBreakpoints: (id) sender;
- (IBAction) clearBreakpoint: (id) sender;
- (IBAction) setBreakpoint: (id)sender;
// the whole lot of them
- (NSDictionary *) breakpoints;
- (void) setBreakpoints: (NSDictionary *)d;
// used to sync or otherwise manipulate (at a low level) breakpoints
// Normally these routines are only called by the breakpoint manager
- (NSInteger) findBreakpoint: (IDEKit_Breakpoint *)breakpoint; // returns  0 if not found
- (void) insertBreakpoint: (IDEKit_Breakpoint *)breakpoint atLine: (NSInteger) line;
- (void) deleteBreakpoint: (IDEKit_Breakpoint *)breakpoint; // doesn't matter what line it is...
// this isn't so much for breakpoints, but rather for debuggers
- (void) setProgramCounterLine: (NSInteger) line;
@end


//extern NSString *IDEKit_SourceBreakpointAddedNotification; // a breakpoint added
//extern NSString *IDEKit_SourceBreakpointRemovedNotification; // a breakpoint removed
//extern NSString *IDEKit_SourceBreakpointsChangedNotification; // update all source breakpoints - project closed, removed, target changed, etc...


