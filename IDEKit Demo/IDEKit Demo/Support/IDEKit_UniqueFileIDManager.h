//
//  IDEKit_UniqueFileIDManager.h
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

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CFUUID.h>

// Handle the mapping between files and a unique id (valid in all IDEKit apps) which allows
// us to store information in a file somewhere other than the resource fork.
//
// Note that a file ID is ultimately implemented using CFUUID
//
// There are still open issues - namely renaming vs copy in the finder.
// In the intial version, we keep track of things via names paths only - rename or move the file, data goes
// away.  Copy the file and only the original file has the data.
//
// In the second version, there will be tracking information stored in the resource fork (obviously, this
// can go away, but at that point you've got essentially no different than the first case).  With that tracking
// info, we can handle moved/renamed files.  Copied files need to look at the orginal file (and assumign that it
// is still there) we copy the persistent data but give it a new id.  If it isn't there, we use the old id (or
// do we?)
//
// Is is up to the caller to use persistentDataForFileID: (or persistentDataCopyForFileID:) and writeForFile:
// when saving.

@class IDEKit_PersistentFileData;

@interface IDEKit_UniqueID : NSObject<NSCopying,NSCoding> { // this is an immutable object
    CFUUIDRef myCFUUID;
}
+ (IDEKit_UniqueID *) uniqueIDFromString: (NSString *)string;
+ (IDEKit_UniqueID *) uniqueID;
- (id) init; // creates a new uuid
- (id) initWithString: (NSString *)string; // converts the uuid from the string
- (NSString *)stringValue;
- (BOOL) isEqualToID: (IDEKit_UniqueID *)other;

// associated with a unique file can be a single object, which can be found later
// Note that this does not maintain a reference to the object, so when the object is deallocated
// it must remove the representation (also note that this will persist even after the unique id is
// released and later recreated - it all just works).  Keys can even be hierarchical - separate them
// by "." (and don't use ";")
//- (void) setRepresentedObject: (id) obj;
//- (id) representedObject;
- (void) setRepresentedObject: (id) obj forKey: (NSString *)key;
- (id) representedObjectForKey: (NSString *)key;
// returns a dictionary mapping the unique object to the value represented
+ (NSDictionary *) allObjectsForKey: (NSString *)key;
+ (NSDictionary *) allObjectsForParentKey: (NSString *)key; // you can pass in a parent heirarchy and it will return the children only
@end


@interface IDEKit_UniqueFileIDManager : NSObject {

}
+ (IDEKit_UniqueFileIDManager *) sharedFileIDManager;
- (IDEKit_UniqueID *) newUniqueFileID;
- (IDEKit_UniqueID *) uniqueFileIDForFile: (NSString *)path;
- (NSString *) pathForFileID: (IDEKit_UniqueID *)fileID;
- (void) removeFileIDForPath: (NSString *)path;
- (void) saveFileID: (IDEKit_UniqueID *) fileID forPath: (NSString *)path;
- (IDEKit_PersistentFileData *) persistentDataForFile: (NSString *)path;
- (IDEKit_PersistentFileData *) persistentDataForFileID: (IDEKit_UniqueID *) fileID;
- (IDEKit_PersistentFileData *) persistentDataCopyForFileID: (IDEKit_UniqueID *) fileID;
@end


// Once you've got a unique file ID, you can get the persistent data for it
//
// It is much like the defaults system, but for only one specific file.  We try to
// store the information both in the resource fork (which is considered to be the authoritative
// information if available) or in our own IDEKit specific storage.  Like defaults, one should
// only put plist data here (though in reality we may relax this)
//
// This persistent file data is broken into several groups of data:
//	Internal (private) data - used to keep various bookkeeping things
//	File global information - things like the window position, current cursor location, markers etc...
//				    These things are available to all IDEKit based apps
//	App specific information - available to a specific application only
//	App/Project specific information - data associated with a specific project for a specific application
//
//  For example, breakpoint information could be stored with either app specific (for simple scripts) or
// with app/project specific (for project based applications).
// Note that a Null project ID in "app/project specific" is the same as just "app specific", and
// Null for app is "file global"
@interface IDEKit_PersistentFileData : NSObject {
    NSMutableDictionary *myData;
    BOOL myNeedsWrite;
}
- (IDEKit_UniqueID *) uniqueFileID;
- (NSString *) filePath; // may be null
- (NSData *) archivedData;
// setting application data in the file is normally a bad thing, except if this is to be shared in
// multiple applications (for example, if the editor and debugger were two different apps).  Application
// data associated with a file should be stored by the applications
- (id) fileDataForApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID target: (NSString *)target key: (NSString *)key;
- (void) setFileData: (id) value forApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID target: (NSString *)target key: (NSString *)key;

- (id) fileDataForApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID key: (NSString *)key;
- (void) setFileData: (id) value forApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID key: (NSString *)key;

- (id) fileDataForApplication: (NSString *)appBundleID key: (NSString *)key;
- (void) setFileData: (id) value forApplication: (NSString *)appBundleID key: (NSString *)key;

- (id) globalFileDataForKey: (NSString *)key;
- (void) setGlobalFileData: (id) value forKey: (NSString *)key;
- (void) writeForFile: (NSString *)path; // this will note if the file was moved as well
@end
