//
//  IDEKit_FileManager.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/20/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "IDEKit_FileManager.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_Sourcefingerprint.h"
#import "IDEKit_SnapshotFile.h"

static IDEKit_FileManager *gFileManager = NULL;
@implementation IDEKit_FileManager
+ (IDEKit_FileManager *) sharedFileManager
{
    if (!gFileManager) gFileManager = [[self alloc] init];
    return gFileManager;
}

- (id) init
{
    if (gFileManager) {
	[self release];
	return gFileManager;
    }
    self = [super init];
    if (self) {
	myShadows = [[NSMutableDictionary dictionary] retain];
	gFileManager = [self retain];
    }
    return self;
}
- (IDEKit_SnapshotFile *) snapshotFileForFile: (IDEKit_UniqueID *)fileID;
{
    IDEKit_SnapshotFile *retval = [fileID representedObjectForKey: @"IDEKit_SnapshotFile"];
    if (!retval) {
	if ([fileID representedObjectForKey: @"IDEKit_SrcEditView"]) { // we've got the file in memory
	    retval = [IDEKit_SnapshotFile snapshotFileWithBufferID: fileID];
	} else {
	    retval = [IDEKit_SnapshotFile snapshotFileWithExternalFile: [[IDEKit_UniqueFileIDManager sharedFileIDManager] pathForFileID: fileID]];
	}
    }
    return retval;
}

- (NSData *) fingerprintForFile: (IDEKit_UniqueID *)fileID
{
    IDEKit_SrcEditView *view = [fileID representedObjectForKey: @"IDEKit_SrcEditView"];
    if (view)
	return [view fingerprint];
    return NULL;
}

- (void) registerSnapshot: (IDEKit_SnapshotFile *) snapshot forFile: (IDEKit_UniqueID *)fileID
{
    // just to be safe
    [self unregisterSnapshot:snapshot];
    NSMutableSet *shadows = [myShadows objectForKey: fileID];
    if (!shadows) {
	shadows = [NSMutableSet set];
	[myShadows setObject: shadows forKey: fileID];
    }
    [shadows addObject: [snapshot uniqueID]]; // keep the unique id, not the snapshot
}
- (void) unregisterSnapshot: (IDEKit_SnapshotFile *) snapshot
{
    IDEKit_UniqueID *masterFile = [snapshot masterID];
    NSMutableSet *shadows = [myShadows objectForKey: masterFile];
    [shadows removeObject: [snapshot uniqueID]];
    if ([shadows count] == 0) {
	[myShadows removeObjectForKey: masterFile]; // remove the set as well, it's empty
    }
}
- (NSSet *)associatedFiles: (IDEKit_UniqueID *)fileID // return both shadows and real (but not the fileID)
{
    IDEKit_SnapshotFile *snapshot = [IDEKit_SnapshotFile snapshotFileAssociatedWith: fileID];
    if (snapshot) {
	NSMutableSet *retval = [[myShadows objectForKey: [snapshot masterID]] mutableCopy]; // start with it's master's shadows
	[retval removeObject: fileID]; // remove this one
	[retval addObject: [snapshot masterID]]; // add the master
	return retval;
    } else {
	return [myShadows objectForKey: fileID]; // return whatever we've got
    }
}

@end
