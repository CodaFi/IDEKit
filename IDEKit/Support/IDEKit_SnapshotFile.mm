//
//  IDEKit_SnapshotFile.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/20/04.
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

#import "IDEKit_SnapshotFile.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_FileManager.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_SourceFingerprint.h"
#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_BreakpointManager.h"

static NSMutableDictionary *gPathToSnapshot = NULL;
@implementation IDEKit_SnapshotFile
- (id) init // both other versions of init call this
{
    self = [super init];
    if (self) {
	myUniqueID = [IDEKit_UniqueID uniqueID]; 
	[myUniqueID setRepresentedObject: self forKey: @"IDEKit_SnapshotFile"];
    }
    return self;
}
- (id) initWithExternalFile: (NSString *)path
{
    self = [self init];
    if (self) {
	myPath = path;
	if (!gPathToSnapshot)
	    gPathToSnapshot = [NSMutableDictionary dictionary];
	gPathToSnapshot[myPath] = [self uniqueID];
	myMasterID = [[IDEKit_UniqueFileIDManager sharedFileIDManager] uniqueFileIDForFile: path];
	mySource = [NSString stringWithContentsOfFile:path];
	[[IDEKit_FileManager sharedFileManager] registerSnapshot: self forFile: myMasterID];
    }
    return self;
}
- (id) initWithBufferID: (IDEKit_UniqueID *)bufferID
{
    self = [self init];
    if (self) {
	myMasterID = bufferID;
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:bufferID];
	if (view) {
	    mySource = [[[bufferID representedObjectForKey: @"IDEKit_SrcEditView"] string] copy]; // keep our own copy
	    myFingerprint = [[view fingerprint] copy]; // and also copy the existing fingerprint
	    myBreakpoints = [[view breakpoints] copy];
	} else {
	    mySource = @"";
	    unsigned short blanks[2] = {0,0};
	    myFingerprint = [NSData dataWithBytes:&blanks length:sizeof(blanks)];
	    myBreakpoints = @{};
	}
	[[IDEKit_FileManager sharedFileManager] registerSnapshot: self forFile: myMasterID];
    }
    return self;
}
- (id) initWithExternalTemporaryFile: (NSString *)path copyOfBufferID: (IDEKit_UniqueID *)bufferID
{
    self = [self init];
    if (self) {
	myPath = path;
	if (!gPathToSnapshot)
	    gPathToSnapshot = [NSMutableDictionary dictionary];
	gPathToSnapshot[myPath] = [self uniqueID];
	myMasterID = bufferID; // retain the bufferID as our master, like initWithBufferID
	mySource = [NSString stringWithContentsOfFile:path]; // but source from the path
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:bufferID];
	if (view) {
	    myBreakpoints = [[view breakpoints] copy]; // get the breakpoints from the buffer(?)
	} else {
	}
	[[IDEKit_FileManager sharedFileManager] registerSnapshot: self forFile: myMasterID];
    }
    return self;
}
- (void) dealloc
{
    [[IDEKit_FileManager sharedFileManager] unregisterSnapshot:self];
    if (myPath) [gPathToSnapshot removeObjectForKey: myPath];
    [myUniqueID setRepresentedObject: NULL forKey: @"IDEKit_SnapshotFile"];
}
- (IDEKit_UniqueID *) uniqueID
{
    return myUniqueID;
}
- (IDEKit_UniqueID *) masterID
{
    return myMasterID;
}
- (NSData *)fingerprint
{
    return myFingerprint;
}
- (id) persistentData
{
    if (!myPersistentData) {
	
    }
    return myPersistentData;
}
- (NSString *)source
{
    return mySource;
}
- (NSDictionary *)breakpoints
{
    // so try to get the breakpoints from somewhere
    return myBreakpoints;
}

+ (IDEKit_SnapshotFile *) snapshotFileWithExternalFile: (NSString *)path
{
    IDEKit_UniqueID *existingID = gPathToSnapshot[path];
    if (existingID) {
	return [self snapshotFileAssociatedWith: existingID];
    }
    return [[self alloc] initWithExternalFile: path];
}
+ (IDEKit_SnapshotFile *) snapshotFileWithBufferID: (IDEKit_UniqueID *)bufferID
{
    return [[self alloc] initWithBufferID: bufferID];
}
+ (IDEKit_SnapshotFile *) snapshotFileWithExternalTemporaryFile: (NSString *)path copyOfBufferID: (IDEKit_UniqueID *)bufferID // take an external file
{
    IDEKit_UniqueID *existingID = gPathToSnapshot[path];
    if (existingID) {
	return [self snapshotFileAssociatedWith: existingID];
    }
    return [[self alloc] initWithExternalTemporaryFile: path copyOfBufferID: bufferID];
}
+ (IDEKit_SnapshotFile *) snapshotFileAssociatedWith:(IDEKit_UniqueID *)snapshotID
{
    return [snapshotID representedObjectForKey:@"IDEKit_SnapshotFile"];
}

@end

