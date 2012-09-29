//
//  IDEKit_SrcEditViewBreakpoints.mm
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

#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_SrcEditViewFolding.h"
#import "IDEKit_SrcScroller.h"
#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_LineCache.h"
#import "IDEKit_BreakpointManager.h"
#import "IDEKit_SourceFingerprint.h"
#import "IDEKit_BreakpointInspector.h"
#import "IDEKit_UniqueFileIDManager.h"

#define kBREAKPOINTATTRIBUTENAME	@"IDEKit_SrcBreakpoint"
#define kBREAKPOINTATTRIBUTEONVALUE	@"IDEKit_SrcBreakpointOn"
#define kBREAKPOINTATTRIBUTEOFFVALUE	@"IDEKit_SrcBreakpointOff"


//NSString *IDEKit_SourceBreakpointAddedNotification = @"IDEKit_SourceBreakpointAddedNotification"; // a breakpoint added
//NSString *IDEKit_SourceBreakpointRemovedNotification = @"IDEKit_SourceBreakpointRemovedNotification"; // a breakpoint removed
//NSString *IDEKit_SourceBreakpointsChangedNotification = @"IDEKit_SourceBreakpointsChangedNotification"; // update all source breakpoints - project closed, removed, target changed, etc...



@implementation IDEKit_SrcEditView(Breakpoints)

- (void) forceBreakpointRedraw: (BOOL) updateClient
{
    BOOL showBP = [myCurrentLanguage wantsBreakpoints];
    NSArray *scrollViews = [self allScrollViews];
    for (NSUInteger i=0;i<[scrollViews count];i++) {
		[scrollViews[i] setHasHorizontalRuler: NO];
		[scrollViews[i] setHasVerticalRuler: showBP];
		if (showBP)
			[[scrollViews[i] verticalRulerView] setNeedsDisplay: YES];
    }
    if (updateClient && myContext) {
		[myContext srcEditView: self setBreakPoints: [self breakpoints]];
    }
}
- (void) forceBreakpointRedraw
{
    [self forceBreakpointRedraw: YES];
}

- (NSDictionary *) breakpoints
{
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		IDEKit_Breakpoint *bp = myLineCache->UnfoldedLineData(line, false)[@"IDEKit_Breakpoint"];
		if (bp) {
			retval[[NSString stringWithFormat: @"%ld", line]] = [bp asPlist];
			//[retval setObject: bp forKey: [NSString stringWithFormat: @"%d", line]];
		}
    }
    return retval;
}
- (void) setBreakpoints: (NSDictionary *)d
{
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		NSDictionary *dp = d[[NSString stringWithFormat: @"%ld", line]];
		if (dp) {
			// this will work even if it already exists
			myLineCache->UnfoldedLineData(line, true)[@"IDEKit_Breakpoint"] = [IDEKit_Breakpoint breakpointFromPlist: dp];
		} else {
			[myLineCache->UnfoldedLineData(line, false) removeObjectForKey: @"IDEKit_Breakpoint"];
		}
    }
    [self forceBreakpointRedraw: NO];
}

- (void) updateProjectWithBreakpoints
{
    NSDictionary *bps = [self breakpoints];
    [[IDEKit_BreakpointManager sharedBreakpointManager] setBreakPoints: bps forFile: myUniqueID];
    if (myContext) {
		[myContext srcEditView: self setBreakPoints: bps];
    }
}
- (void) updateBreakpointsFromProject
{
    NSDictionary *d;
    // asking for the breakpoints will end up asking our view for them (which is what we don't have)
    // so remove us from our unique object for a moment
    [myUniqueID setRepresentedObject: NULL forKey: @"IDEKit_SrcEditView"];
    d = [[IDEKit_BreakpointManager sharedBreakpointManager] getBreakPointsForFile: myUniqueID];
    [myUniqueID setRepresentedObject: self forKey: @"IDEKit_SrcEditView"];
    [self setBreakpoints: d];
}
- (IDEKit_Breakpoint *)getBreakpointForDisplay: (NSInteger)line // includes "program counter" (or other similar things)
{
    if (!myLineCache->ValidLineNum(line))
		return NULL;
    NSMutableDictionary *d = myLineCache->UnfoldedLineData(line, false);
    if (!d) return NULL;
    if (d[@"IDEKit_ProgramCounter"]) {
		return [[IDEKit_Breakpoint alloc] initWithKind: IDEKit_kBreakpointProgramCounter file: myUniqueID  line: line];
    } else {
		return [self getBreakpoint: line];
    }
}

- (IDEKit_Breakpoint *)getBreakpoint: (NSInteger)line
{
    // only show breakpoints for things that want them
    if (!myCurrentLanguage)
		return NULL;
    if ([myCurrentLanguage wantsBreakpoints] == NO)
		return NULL;
    
    if (!myLineCache->ValidLineNum(line))
		return NULL;
    NSMutableDictionary *d = myLineCache->UnfoldedLineData(line, false);
    if (!d) return NULL;
    return d[@"IDEKit_Breakpoint"];
}
- (NSInteger) getBreakpointCapability: (NSInteger) line // return if there could be a breakpoint here, etc...
{
    if (!myCurrentLanguage)
		return IDEKit_kBeyondBreakPoint;
    if ([myCurrentLanguage wantsBreakpoints] == NO)
		return IDEKit_kBeyondBreakPoint;
    
    if (!myLineCache->ValidLineNum(line))
		return IDEKit_kBeyondBreakPoint;
    // should check the language parse for this line
    NSRange range = myLineCache->UnfoldedNthLineRange(line);
    // is it empty?
    if ([[[self string] substringWithRange: range] trimmedFingerprint] == 0)
		return IDEKit_kBreakPointNotPossible; // blank line
    return IDEKit_kNoBreakPoint;
}
- (void) removeBreakpoint: (NSInteger) line // user clicked here - turn on/off as default
{
    IDEKit_Breakpoint *bp = myLineCache->UnfoldedLineData(line, false)[@"IDEKit_Breakpoint"];
    if (bp) {
		[[IDEKit_BreakpointManager sharedBreakpointManager] removeBreakpoint: bp fromFiles: myUniqueID];
    }
}

- (void) addBreakpoint: (NSInteger) line // user clicked here - turn on/off as default
{
    // create a blank, default breakpoint
    IDEKit_Breakpoint *bp = [[IDEKit_BreakpointManager sharedBreakpointManager] createBreakpointToFiles: myUniqueID atLine: line];
    [[IDEKit_BreakpointInspector sharedBreakpointInspector] setBreakpoint: bp];
}

#ifdef nomore
- (NSInteger) getBreakPoint: (NSInteger) line
{
    // only show breakpoints for things that want them
    if (!myCurrentLanguage)
		return IDEKit_kBeyondBreakPoint;
    if ([myCurrentLanguage wantsBreakpoints] == NO)
		return IDEKit_kBeyondBreakPoint;
    
#ifndef qIDEKIT_UseCache
    NSDocument *project = [myContext owningProjectForSrcEditView: self];
    if (!project) {
		return IDEKit_kBeyondBreakPoint;
    }
    
    NSRange lineRange = [self nthLineRange: line];
    if (lineRange.location >= [[myTextView textStorage] length])
		return IDEKit_kBeyondBreakPoint; // line is beyond the file
    NSUInteger startIndex = lineRange.location;
    // we've finally got the characters for line # (assuming uniform line height, of corse)
    NSString *value = kBREAKPOINTATTRIBUTEONVALUE;
    NSString *oldValue = [[myTextView textStorage] attribute: kBREAKPOINTATTRIBUTENAME atIndex: startIndex effectiveRange: NULL];
    if (oldValue && [oldValue isEqualToString: kBREAKPOINTATTRIBUTEONVALUE])
		return IDEKit_kBreakPoint;
    return IDEKit_kNoBreakPoint;
#else
    if (!myLineCache->ValidLineNum(line))
		return IDEKit_kBeyondBreakPoint;
    NSMutableDictionary *d = myLineCache->UnfoldedLineData(line, false);
    if (!d) return IDEKit_kNoBreakPoint;
    return [[d objectForKey: IDEKit_BreakpointKind] intValue];
#endif
}
- (NSDictionary *) getBreakPointData: (NSInteger) line
{
#ifndef qIDEKIT_UseCache
    return NULL;
#else
    NSMutableDictionary *d = myLineCache->UnfoldedLineData(line, false);
    return [d objectForKey: IDEKit_BreakpointData];
#endif
}
- (void) setBreakPoint: (NSInteger) line kind: (NSInteger) kind data: (NSDictionary *)data;
{
    if (!myCurrentLanguage) return;
    if ([myCurrentLanguage wantsBreakpoints] == NO)
		return;
    if (kind == IDEKit_kBeyondBreakPoint)
		return;
    
#ifndef qIDEKIT_UseCache
    NSDocument *project = [myContext owningProjectForSrcEditView: self];
    if (!project)
		return;
    
    NSRange lineRange = [self nthLineRange: line];
    
    NSString *value;
    switch (kind) {
		case IDEKit_kBreakPoint:
			value = kBREAKPOINTATTRIBUTEONVALUE;
			break;
		case IDEKit_kNoBreakPoint:
			value = kBREAKPOINTATTRIBUTEOFFVALUE;
			break;
    }
    // set the value to something else
    [[myTextView textStorage] addAttribute: kBREAKPOINTATTRIBUTENAME value: value range: lineRange];
#else
    NSMutableDictionary *d = myLineCache->UnfoldedLineData(line, true);
    if (kind == IDEKit_kNoBreakPoint || kind == IDEKit_kBeyondBreakPoint) {
		[d removeObjectForKey:IDEKit_BreakpointKind];
		[d removeObjectForKey:IDEKit_BreakpointData];
    } else {
		if (data) {
			[d setObject: data forKey: IDEKit_BreakpointData];
		} else {
			[d removeObjectForKey:IDEKit_BreakpointData];
		}
		[d setObject: [NSNumber numberWithInt:kind] forKey: IDEKit_BreakpointKind];
    }
    //[self updateProjectWithBreakpoints];
#endif
}


- (void) setBreakPoint: (NSInteger) line kind: (NSInteger) kind
{
    [self setBreakPoint: line kind: kind data: NULL];
}

- (NSMenu *)toggleBreakPointMenuForLine: (NSInteger) line
{
    // should prepare a breakpoint menu for this line - we don't auto-update it since it's tough to maintain
    // that across the delegate
    return myBreakpointMenu;
    //return [myContext srcEditView: self breakpointMenuForLine: line];
}

- (void) toggleBreakPoint: (NSInteger) line
{
    if (!myCurrentLanguage) return;
    if ([myCurrentLanguage wantsBreakpoints] == NO)
		return;
    NSDocument *project = [myContext owningProjectForSrcEditView: self];
    if (!project) {
		NSLog(@"No document for %@",self);
		return;
    }
#ifndef qIDEKIT_UseCache
    NSRange lineRange = [self nthLineRange: line];
    
    NSString *value = kBREAKPOINTATTRIBUTEONVALUE;
    NSString *oldValue = [[myTextView textStorage] attribute: kBREAKPOINTATTRIBUTENAME atIndex: lineRange.location effectiveRange: NULL];
    if (oldValue && [oldValue isEqualToString: kBREAKPOINTATTRIBUTEONVALUE])
		value = kBREAKPOINTATTRIBUTEOFFVALUE;
    // set the value to something else
    [[myTextView textStorage] addAttribute: kBREAKPOINTATTRIBUTENAME value: value range: lineRange];
    [self updateProjectWithBreakpoints];
    // now notify the world
    NSDictionary *sbp = [NSDictionary dictionaryWithObjectsAndKeys:
						 [myContext fileNameForSrcEditView: self],IDEKit_BreakpointFile,
						 [NSNumber numberWithInt: line],IDEKit_BreakpointLineNum,
						 NULL];
    if (value == kBREAKPOINTATTRIBUTEONVALUE) {
		[[NSNotificationCenter defaultCenter] postNotificationName: IDEKit_SourceBreakpointAddedNotification object: self userInfo: sbp];
    } else if (value == kBREAKPOINTATTRIBUTEOFFVALUE) {
		[[NSNotificationCenter defaultCenter] postNotificationName: IDEKit_SourceBreakpointRemovedNotification object: self userInfo: sbp];
    }
#else
    int kind = [self getBreakPoint: line];
    if (kind == IDEKit_kNoBreakPoint)
		kind = IDEKit_kBreakPoint;
    else if (kind != IDEKit_kBeyondBreakPoint)
		kind = IDEKit_kNoBreakPoint; // remove custom bp
    if (kind != IDEKit_kBeyondBreakPoint) {
		[self setBreakPoint: line kind: kind]; // Surprisingly, this will leave non-bp line info untouched
		NSDictionary *sbp = [NSDictionary dictionaryWithObjectsAndKeys:
							 [myContext fileNameForSrcEditView: self],IDEKit_BreakpointFile,
							 [NSNumber numberWithInt: line],IDEKit_BreakpointLineNum,
							 [NSNumber numberWithInt: kind], IDEKit_BreakpointKind,
							 [self getBreakPointData: line], IDEKit_BreakpointData, // may be NULL, so terminates this list quicker
							 NULL];
		if (kind == IDEKit_kBreakPoint) {
			[[NSNotificationCenter defaultCenter] postNotificationName: IDEKit_SourceBreakpointAddedNotification object: self userInfo: sbp];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName: IDEKit_SourceBreakpointRemovedNotification object: self userInfo: sbp];
		}
    }
#endif
    [self updateProjectWithBreakpoints]; // since we changed at the user behest, update project info accordingly
}
- (void) addBreakPointNotification: (NSNotification *)notification
{
    //NSLog(@"Src got add bp notification %@",notification );
    if ([notification object] != self && [[[notification userInfo] objectForKey: IDEKit_BreakpointFile] isEqualToString: [myContext fileNameForSrcEditView: self]]) {
		[self setBreakPoint: [[[notification userInfo] objectForKey: IDEKit_BreakpointLineNum] intValue] kind: IDEKit_kBreakPoint];
    }
    [self forceBreakpointRedraw];
}
- (void) removeBreakPointNotification: (NSNotification *)notification
{
    //NSLog(@"Src got rem bp notification %@",notification );
    if ([notification object] != self && [[[notification userInfo] objectForKey: IDEKit_BreakpointFile] isEqualToString: [myContext fileNameForSrcEditView: self]]) {
		[self setBreakPoint: [[[notification userInfo] objectForKey: IDEKit_BreakpointLineNum] intValue] kind: IDEKit_kNoBreakPoint];
    }
    [self forceBreakpointRedraw];
}
- (void) updateBreakPointNotification: (NSNotification *)notification
{
    //NSLog(@"Src got updt notification %@",notification );
    if ([notification object] != self) {
		[self updateBreakpointsFromProject];
    }
    [self forceBreakpointRedraw];
}
#endif


- (NSMenu *)breakpointMenuForLine: (NSInteger) line
{
    // should prepare a breakpoint menu for this line - we don't auto-update it since it's tough to maintain
    // that across the delegate
    return myBreakpointMenu;
    //return [myContext srcEditView: self breakpointMenuForLine: line];
}

- (IBAction) showBreakpointInspector: (id) sender
{
    [[IDEKit_BreakpointInspector sharedBreakpointInspector] showWindow: sender];
}

- (IBAction) clearAllBreakpoints: (id) sender
{
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		IDEKit_Breakpoint *bp = myLineCache->UnfoldedLineData(line, false)[@"IDEKit_Breakpoint"];
		[[IDEKit_BreakpointManager sharedBreakpointManager] removeBreakpoint: bp fromFiles: myUniqueID];
    }
}

- (IBAction) clearBreakpoint: (id) sender
{
}
- (IBAction) setBreakpoint: (id)sender
{
}

// Normally these routines are only called by the breakpoint manager (or the breakpoints themselves)
- (NSInteger) findBreakpoint: (IDEKit_Breakpoint *)breakpoint; // returns  0 if not found
{
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		IDEKit_Breakpoint *bp = myLineCache->UnfoldedLineData(line, false)[@"IDEKit_Breakpoint"];
		if (bp == breakpoint) {
			return line;
		}
    }
    return IDEKit_kBreapointNotFound;
}
- (void) insertBreakpoint: (IDEKit_Breakpoint *)breakpoint atLine: (NSInteger) line
{
    myLineCache->UnfoldedLineData(line, true)[@"IDEKit_Breakpoint"] = breakpoint;
    [self forceBreakpointRedraw: YES];
    [[IDEKit_BreakpointInspector sharedBreakpointInspector] setBreakpoint: breakpoint];
}

- (void) deleteBreakpoint: (IDEKit_Breakpoint *)breakpoint // doesn't matter what line it is...
{
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		IDEKit_Breakpoint *bp = myLineCache->UnfoldedLineData(line, false)[@"IDEKit_Breakpoint"];
		if (bp == breakpoint) {
			[myLineCache->UnfoldedLineData(line, false) removeObjectForKey: @"IDEKit_Breakpoint"];
		}
    }
    [self forceBreakpointRedraw: YES];
    [[IDEKit_BreakpointInspector sharedBreakpointInspector] setBreakpoint: NULL];
}

- (void) setProgramCounterLine: (NSInteger) pcline
{
    NSInteger numLines = myLineCache->UnfoldedLineCount();
    for (NSInteger line=1;line <= numLines; line++) {
		if (line == pcline) {
			myLineCache->UnfoldedLineData(line, true)[@"IDEKit_ProgramCounter"] = @YES;
		} else {
			[myLineCache->UnfoldedLineData(line, false) removeObjectForKey: @"IDEKit_ProgramCounter"];
		}
    }
    [self forceBreakpointRedraw: NO];
}

@end
