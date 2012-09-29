//
//  IDEKit_BreakpointInspector.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "IDEKit_BreakpointInspector.h"
#import "IDEKit_BreakpointManager.h"
#import "IDEKit_Breakpoint.h"
#import "IDEKit_PathUtils.h"

static IDEKit_BreakpointInspector *gInspector = NULL;

@implementation IDEKit_BreakpointInspector
+ (IDEKit_BreakpointInspector *) sharedBreakpointInspector
{
    if (!gInspector) {
	gInspector = [self alloc];
	// try to override nib loading by looking in main bundle first (and then our bundle for class
	NSString *path = [[NSBundle mainBundle] pathForResource:@"IDEKit_BreakpointEditor" ofType:@"nib"];
	if ([path length]) {
	    gInspector = [gInspector initWithWindowNibPath: path owner: gInspector];
	} else {
	    gInspector = [gInspector initWithWindowNibName: @"IDEKit_BreakpointEditor" owner: gInspector];
	}
    }
    return gInspector;
}

- (IBAction) changeKind: (id) sender
{
    int newKind = [[sender selectedItem] tag];
    if (newKind == IDEKit_kNoBreakPoint) {
	if (myCurrentBreakpoint) {
	    [[IDEKit_BreakpointManager sharedBreakpointManager] removeBreakpoint:myCurrentBreakpoint fromFiles:[myCurrentBreakpoint fileID]];
	    [self setBreakpoint:NULL];
	}
    } else {
	[myCurrentBreakpoint setKind: newKind];
	[self saveValuesToBreakpoint: myCurrentBreakpoint];
    }
    [myKindData selectTabViewItemWithIdentifier: [[sender selectedItem] title]];
}

- (IBAction) toggleEnabled: (id) sender
{
    [myCurrentBreakpoint setDisabled:[sender state] == NSOffState];
}

- (IBAction) changeTraceLog: (id) sender
{
    [myCurrentBreakpoint setData:[sender stringValue]];
}

- (IBAction) changePauseDelay: (id) sender
{
    [myCurrentBreakpoint setData: [NSString stringWithFormat: @"%d",[[sender selectedItem] tag]]];
}

- (IBAction) changeCondition: (id) sender
{
    [myCurrentBreakpoint setData:[sender stringValue]];
}

- (IBAction) changeSound: (id) sender
{
    NSString *path = [[sender selectedItem] representedObject];
    [myCurrentBreakpoint setData: path];
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
    [sound play];
    [sound release];
}

- (void) setBreakpoint: (IDEKit_Breakpoint *)bp // or NULL for none here (but could be)
{
    [self window]; // make sure our nib is loaded so we can mess with the controls now
    [myCurrentBreakpoint release];
    myCurrentBreakpoint = [bp retain];
    if (bp == NULL) {
	[myEnabled setEnabled: NO];
	[myEnabled setState: NSOffState];
	[myKind setEnabled: NO];
	[myKind selectItem:[[myKind menu] itemWithTag:IDEKit_kNoBreakPoint]];
	//[myKindData setEnabled: YES];
	[myKindData selectTabViewItemWithIdentifier: [[[myKind menu] itemWithTag:IDEKit_kNoBreakPoint] title]];
    } else {
	[myEnabled setEnabled: YES];
	[myEnabled setState: [bp disabled] ? NSOffState : NSOnState];
	[myKind setEnabled: YES];
	[myKind selectItem:[[myKind menu] itemWithTag:[bp kind]]];
	[self resetDefaultValues];
	[self setValuesFromBreakpoint:bp];
	//[myKindData setEnabled: YES];
	[self changeKind: myKind];
    }
}
- (void) setNoBreakpointPossible // disables it
{
    [myCurrentBreakpoint release];
    myCurrentBreakpoint = NULL;
    [myEnabled setEnabled:NO];
    [myKind setEnabled: NO];
    //[myKindData setEnabled: NO];
}

- (void) rebuildSounds
{
    [mySound removeAllItems];
    NSArray *types = [NSSound soundUnfilteredFileTypes];
    for (int domain = kSystemDomain; domain<= kUserDomain; domain++) {
	NSString *folder = [NSString findFolder: kSystemSoundsFolderType forDomain: domain];
	NSEnumerator *fileEnum = [[NSFileManager defaultManager] enumeratorAtPath: folder];
	NSString *file;
	while ((file = [fileEnum nextObject]) != NULL) {
	    if ([types containsObject:[file pathExtension]]) {
		NSString *path = [folder stringByAppendingPathComponent:file];
		NSString *name = [[NSFileManager defaultManager] displayNameAtPath:path];
		// this allows combining multiple identical named things
		[mySound addItemWithTitle: name];
		NSMenuItem *item = [mySound itemWithTitle: name];
		[item setRepresentedObject:path];
	    }
	}
	
	
    }
}

- (void) resetDefaultValues
{
    [self rebuildSounds];
    [myTraceLog setStringValue: @""];
    [myCondition setStringValue: @""];
    [myPauseDelay selectItemAtIndex: 1];
    [mySound selectItemAtIndex: 1];
}
- (void) setValuesFromBreakpoint: (IDEKit_Breakpoint *)bp
{
    if ([(NSString *)[bp data] length]) {
	switch ([[myKind selectedItem] tag]) {
	    case IDEKit_kBreakPointPause: {
		int index = [myPauseDelay indexOfItemWithTag: [[bp data] intValue]];
		if (index != NSNotFound)
		    [myPauseDelay selectItemAtIndex: index];
		else
		    [myPauseDelay selectItemAtIndex: 1];
		break;
	    }
	    case IDEKit_kBreakPointConditional:
		[myCondition setStringValue: [bp data]];
		break;
	    case IDEKit_kBreakPointTracePoint:
		[myTraceLog setStringValue: [bp data]];
		break;
	    case IDEKit_kBreakPointSoundPoint:
		[mySound selectItemAtIndex: [mySound indexOfItemWithRepresentedObject: [bp data] ]];
		break;
	}
    }
}
- (void) saveValuesToBreakpoint: (IDEKit_Breakpoint *)bp
{
    switch ([[myKind selectedItem] tag]) {
	case IDEKit_kBreakPointPause:
	    [myCurrentBreakpoint setData: [NSString stringWithFormat: @"%d",[[myPauseDelay selectedItem] tag]]];
	    break;
	case IDEKit_kBreakPointConditional:
	    [myCurrentBreakpoint setData:[myCondition stringValue]];
	    break;
	case IDEKit_kBreakPointTracePoint:
	    [myCurrentBreakpoint setData:[myTraceLog stringValue]];
	    break;
	case IDEKit_kBreakPointSoundPoint:
	    [myCurrentBreakpoint setData: [[mySound selectedItem] representedObject]];
	    break;
	default:
	    [bp setData: NULL];
    }
}
- (void) showWindow: (id) sender
{
    [super showWindow: sender];
    [self rebuildSounds];
}
@end
