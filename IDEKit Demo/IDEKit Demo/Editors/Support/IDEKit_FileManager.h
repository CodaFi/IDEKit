//
//  IDEKit_FileManager.h
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

// This manages all the open files, not opened files, buffers for untitled files
// and snapshots associated with them

#import <Cocoa/Cocoa.h>

@class IDEKit_UniqueID;
@class IDEKit_SnapshotFile;

@interface IDEKit_FileManager : NSObject {
    NSMutableDictionary *myShadows; // maps from files->set of shadows
}
+ (IDEKit_FileManager *) sharedFileManager;
- (IDEKit_SnapshotFile *) snapshotFileForFile: (IDEKit_UniqueID *)fileID;
- (NSData *) fingerprintForFile: (IDEKit_UniqueID *)fileID;
// this can not retain the snapshot file (so we use the unique ID) or else we'll never release it
- (void) registerSnapshot: (IDEKit_SnapshotFile *) snapshot forFile: (IDEKit_UniqueID *)fileID;
- (void) unregisterSnapshot: (IDEKit_SnapshotFile *) snapshot;
- (NSSet *)associatedFiles: (IDEKit_UniqueID *)fileID; // return both shadows and real (but not the fileID)
@end
