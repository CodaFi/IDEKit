//
//  IDEKit_BreakpointManager.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/17/04.
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

#import "IDEKit_BreakpointManager.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_SourceFingerprint.h"
#import "IDEKit_FileManager.h"
#import "IDEKit_Breakpoint.h"
#import "IDEKit_SnapshotFile.h"

static IDEKit_BreakpointManager *gSharedBreakpointManager = NULL;
@implementation IDEKit_BreakpointManager
+ (IDEKit_BreakpointManager *) sharedBreakpointManager
{
    if (!gSharedBreakpointManager)
	gSharedBreakpointManager = [[self alloc] init];
    return gSharedBreakpointManager;
}

- (id) init
{
    if (gSharedBreakpointManager) {
	return gSharedBreakpointManager;
    }
    self = [super init];
    if (self) {
	mySingleFiles = [NSMutableDictionary dictionary];
	myProjects = [NSMutableDictionary dictionary];
#ifdef nomore
	myShadowMapping =  [[NSMutableDictionary dictionary] retain];
#endif
	gSharedBreakpointManager = self;
    }
    return self;
}

- (void) refreshDataFromViewForFile: (IDEKit_UniqueID *)file
{
    NSDictionary *bps = NULL;
    IDEKit_SnapshotFile *snapshot = [IDEKit_SnapshotFile snapshotFileAssociatedWith:file];
    if (snapshot) {
	bps = [snapshot breakpoints];
    }
    if (!bps) {
	// grab the breakpoints from the view
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:file];
	if (view) {
	    bps = [view breakpoints];
	}
    }
    if (!bps) {
	bps = [self loadSavedDataForFile: file project: NULL target: NULL];
    }
    [self setBreakPoints: bps forFile: file];
}
- (NSDictionary *) loadSavedDataForFile: (IDEKit_UniqueID *)file project: (IDEKit_UniqueID *)project target: (NSString *)target // need to know what the breakpoints for this file are and it isn't loaded (so we can't ask the view)
{
    switch ([IDEKit breakpointStoragePolicy]) {
	case IDEKit_kStoreBreakpointsInApp: // only makes sense if there is no project
	    if (project == IDEKit_AppBreakpointProject) {
		return [IDEKit loadApplicationBreakpointsForFile: file];
	    }
	    // otherwise fall through to "inProject"
	case IDEKit_kStoreBreakpointsInProject:
	    // must be a valid project
	    NSAssert(project != IDEKit_AppBreakpointProject, @"Project == IDEKit_AppBreakpointProject");
	    // tbd
	    return NULL;
	case IDEKit_kStoreBreakpointsInFile: {
	    // annoying, but...
	    IDEKit_PersistentFileData *data = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataForFileID: file];
	    return [data fileDataForApplication:[[NSBundle mainBundle] bundleIdentifier] project: project target: target key: @"IDEKit_Breakpoints"];
	}
	default:
	    return NULL;
	    
    }
}

-(void) savePersistentData: (IDEKit_PersistentFileData *)data forFile: (IDEKit_UniqueID *)file
{
    [self refreshDataFromViewForFile: file];
    NSDictionary *bpsForFile = mySingleFiles[[file stringValue]];
    [data setFileData: bpsForFile forApplication: [[NSBundle mainBundle] bundleIdentifier] key: @"IDEKit_Breakpoints"];
}

-(void) loadPersistentData: (IDEKit_PersistentFileData *)data forFile: (IDEKit_UniqueID *)file
{
    NSDictionary  *bpsForFile = [data fileDataForApplication: [[NSBundle mainBundle] bundleIdentifier] key: @"IDEKit_Breakpoints"];
    if (!bpsForFile) {
	mySingleFiles[[file stringValue]] = [NSMutableDictionary dictionary];
    } else {
	// go deep to make mutable
	NSMutableDictionary *bps = [bpsForFile mutableCopy];
	NSEnumerator *e = [bps keyEnumerator];
	id key;
	while ((key = [e nextObject]) != NULL) {
	    id obj = bps[key];
	    bps[key] = [obj mutableCopy];
	}
	mySingleFiles[[file stringValue]] = bps;
    }
}

- (NSDictionary *) getBreakPointsForFile: (IDEKit_UniqueID *)file; // for no project
{
    [self refreshDataFromViewForFile: file];
    return mySingleFiles[[file stringValue]];
}

- (NSDictionary *) getBreakPointsForFile: (IDEKit_UniqueID *)file project: (IDEKit_UniqueID *)project target: (NSString *)target;
{
    return NULL;
}

- (void) setBreakPoints: (NSDictionary *)bps forFile: (IDEKit_UniqueID *)file; // for no project
{
    //NSLog(@"Setting breakpoints for %@",file);
    if (bps) {
	mySingleFiles[[file stringValue]] = [bps mutableCopy];
    } else {
	mySingleFiles[[file stringValue]] = [NSMutableDictionary dictionary];
    }
}

#ifdef nomore
/* Ugh - this has to go */
- (void) file: (IDEKit_UniqueID *)virtualView shadowsFile: (IDEKit_UniqueID *)realSource;
{
    [mySingleFiles removeObjectForKey: [virtualView stringValue]]; // in case it use to shadow something else
    // first, remove from where it was, if anywhere
    NSString *oldReal = [myVirtualToRealMapping objectForKey: [virtualView stringValue]];
    if (oldReal) {
	NSMutableSet *virtuals = [myShadowMapping objectForKey: oldReal];
	NSEnumerator *e = [virtuals objectEnumerator];
	NSDictionary *virtualEntry;
	while ((virtualEntry = [e nextObject]) != NULL) {
	    if ([[virtualEntry objectForKey: @"fileid"] isEqualToString: [virtualView stringValue]]) {
		[virtuals removeObject:virtualEntry];
		break;
	    }
	}
	if ([virtuals count] == 0) {
	    // no more - remove it entirely
	    [myShadowMapping removeObjectForKey: oldReal];
	}
	[myVirtualToRealMapping removeObjectForKey: [virtualView stringValue]];
    } else if (realSource == NULL) {
	NSLog(@"Removing virtual view %@ but it doesn't shadow anything",[virtualView stringValue]);
    }
    // add where it goes
    if (realSource) {
	NSMutableSet *virtuals = [myShadowMapping objectForKey: [realSource stringValue]];
	if (!virtuals) {
	    virtuals = [NSMutableSet set];
	    [myShadowMapping setObject: virtuals forKey: [realSource stringValue]];
	}
	[virtuals addObject: 
	    [NSDictionary dictionaryWithObjectsAndKeys:
		[virtualView stringValue],@"fileid",
		// since virtualView will shadow the current value of realSource, use that fingerprint
		[(IDEKit_SrcEditView *)[realSource representedObjectForKey: @"IDEKit_SrcEditView"] fingerprint], @"fingerprint",
		NULL
	    ]
	];
	[myVirtualToRealMapping setObject: [realSource stringValue] forKey: [virtualView stringValue]];
    }
}

- (void) update: (NSString *) fileidname withChangedBreakPoints: (NSDictionary *)bps fromFile: (IDEKit_UniqueID *)file atLine: (NSInteger) line
{
    // something releated to this has changed
}
// the user has explicitly changed the breakpoints
- (void) notifyChangedBreakPointsForFile: (IDEKit_UniqueID *)file atLine: (NSInteger) line
{
    // is "file" a real file?  Or a shadow?  If it is a shadow, update the real file and all things it shadows (except for the starting file).
    // If it is a real file, update all the shadows
    NSString *realFile = [myVirtualToRealMapping objectForKey: [file stringValue]];
    if (realFile) {
	// found the real file, notify it
	[self updateChangedBreakPoints: realFile];
    } else {
	realFile = [file stringValue]; // file is a real file
    }
    
    NSSet *virtuals = [myShadowMapping objectForKey: realFile];
    NSEnumerator *e = [virtuals objectEnumerator];
    NSDictionary *virtualEntry;
    while ((virtualEntry = [e nextObject]) != NULL) {
	if (![[e objectForKey: @"fileid"] isEqualToString: [file stringValue]]) { // for everything other than the starting file
	    [self updateChangedBreakPoints: [e objectForKey: @"fileid"]];
	}
    }
}
#endif

- (void) addBreakpoint: (IDEKit_Breakpoint *)breakpoint toFiles: (IDEKit_UniqueID *) file atLine: (NSInteger) line
{
    IDEKit_FileManager *fm = [IDEKit_FileManager sharedFileManager];
    NSSet *associatedFiles = [fm associatedFiles: file];
    NSData *fingerprint = NULL; // do this lazy if we've got no other files
    NSEnumerator *e = [associatedFiles objectEnumerator];
    IDEKit_UniqueID *other;
    while ((other = [e nextObject]) != NULL) {
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:other];
	if (view) {
	    if (!fingerprint)
		fingerprint = [fm fingerprintForFile: file];
	    IDEKit_SourceMapping *mapping = [[IDEKit_SourceMapping alloc] initMappingFrom: fingerprint to: [view fingerprint]];
	    [view insertBreakpoint: breakpoint atLine: [mapping mapForward: line]];
	}
    }
    // finally, put in main thing
    [[IDEKit_SrcEditView srcEditViewAssociatedWith:file] insertBreakpoint: breakpoint atLine: line];
}

- (IDEKit_Breakpoint *) createBreakpointToFiles: (IDEKit_UniqueID *) file atLine: (NSInteger) line
{
    IDEKit_Breakpoint *	bp = [[IDEKit_Breakpoint alloc] initWithKind: IDEKit_kBreakPoint file: file line: line];
    [self addBreakpoint:bp toFiles:file atLine:line];
    return bp;
}

- (void) removeBreakpoint: (IDEKit_Breakpoint *)breakpoint fromFiles: (IDEKit_UniqueID *) file
{
    IDEKit_FileManager *fm = [IDEKit_FileManager sharedFileManager];
    NSSet *associatedFiles = [fm associatedFiles: file];
    NSEnumerator *e = [associatedFiles objectEnumerator];
    IDEKit_UniqueID *other;
    while ((other = [e nextObject]) != NULL) {
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:other];
	if (view) {
	    [view deleteBreakpoint: breakpoint ];
	}
    }
    // finally, put in main thing
    [[IDEKit_SrcEditView srcEditViewAssociatedWith:file] deleteBreakpoint: breakpoint];
}
- (void) redrawBreakpoint: (IDEKit_Breakpoint *)breakpoint
{
    IDEKit_FileManager *fm = [IDEKit_FileManager sharedFileManager];
    NSSet *associatedFiles = [fm associatedFiles: [breakpoint fileID]];
    NSEnumerator *e = [associatedFiles objectEnumerator];
    IDEKit_UniqueID *other;
    while ((other = [e nextObject]) != NULL) {
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:other];
	if (view) {
	    [view forceBreakpointRedraw ];
	}
    }
    // finally, put in main thing
    [[IDEKit_SrcEditView srcEditViewAssociatedWith:[breakpoint fileID]] forceBreakpointRedraw];    
}
@end
