//
//  IDEKit_SnapshotFile.h
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

#import <Cocoa/Cocoa.h>

@class IDEKit_UniqueID;

// Snapshot files are read-only versions of a "snapshot" of an existing file.  These are used, for example,
// to provide a debugger view (which may not show the current file, but rather some potentially older version)
// Note that Snapshot files are never intended to have their persistent file information changed
@interface IDEKit_SnapshotFile : NSObject {
    IDEKit_UniqueID *myUniqueID; // this has a unique id
    IDEKit_UniqueID *myMasterID; // and this is the file/buffer that we are a snapshot of
    NSData *myFingerprint; // since we are read-only, this never changes
    id myPersistentData;
    NSString *mySource;
    NSString *myPath;
    NSDictionary *myBreakpoints;
}
// we provide the (up to the application to) copy, as well as the fileID of the original
+ (IDEKit_SnapshotFile *) snapshotFileWithExternalFile: (NSString *)path; // implicitly take an external file
+ (IDEKit_SnapshotFile *) snapshotFileWithExternalTemporaryFile: (NSString *)path copyOfBufferID: (IDEKit_UniqueID *)bufferID; // explicitly take an external file that is a saved copy of a buffer
+ (IDEKit_SnapshotFile *) snapshotFileWithBufferID: (IDEKit_UniqueID *)bufferID; // explicity copy from the actual bufferID

+ (IDEKit_SnapshotFile *) snapshotFileAssociatedWith:(IDEKit_UniqueID *)fileID; // if any
- (id) initWithExternalFile: (NSString *)path;
- (id) initWithBufferID: (IDEKit_UniqueID *)bufferID;
- (IDEKit_UniqueID *) uniqueID;
- (IDEKit_UniqueID *) masterID;
- (NSData *) fingerprint;
- (id) persistentData;
- (NSString *)source;
- (NSDictionary *)breakpoints;
@end

