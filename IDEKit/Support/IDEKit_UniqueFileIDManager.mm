//
//  IDEKit_UniqueFileIDManager.mm
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

#import "IDEKit_UniqueFileIDManager.h"
#import <CoreFoundation/CFUUID.h>
#import "IDEKit_PathUtils.h"

#define IDEKit_UniqueFileIDManagerDomain @"com.gandreas.idekit.uniquefileid"

@interface IDEKit_PersistentFileData(Private)
- (id) initWithFileID: (IDEKit_UniqueID *)fileID;
- (id) initCopyWithFileID: (IDEKit_UniqueID *)fileID; // the file id of this is something new then
- (id) initWithFileID: (IDEKit_UniqueID *)fileID forFile: (NSString *)path;
- (id) privateFileDataForKey: (NSString *)key;
- (void) setPrivateFileData: (id) value forKey: (NSString *)key;
- (void) save;
@end


static NSMutableDictionary *gUniqueObjects;
@implementation IDEKit_UniqueID
+ (IDEKit_UniqueID *) uniqueIDFromString: (NSString *)string
{
    if (!string) return NULL;
    // should we keep a cache of all of them?
    return [[self alloc] initWithString: string];
}
+ (IDEKit_UniqueID *) uniqueID
{
    return [[self alloc] init];
}

- (id) init
{
    self = [super init];
    if (self) {
		myCFUUID = CFUUIDCreate(kCFAllocatorDefault);
    }
    return self;
}
- (id) initWithString: (NSString *)string
{
    self = [super init];
    if (self) {
		myCFUUID = CFUUIDCreateFromString(kCFAllocatorDefault,(CFStringRef)string);
    }
    return self;
}
- (void) dealloc
{
    if (myCFUUID) CFRelease(myCFUUID);
}
- (NSString *)stringValue
{
    NSString *str = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault,myCFUUID);
    return str;
}
- (id)copyWithZone:(NSZone *)zone;
{
    // we're immutable, just retain ourselves again
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: [self stringValue]]; // encode the string value
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
		myCFUUID = CFUUIDCreateFromString(kCFAllocatorDefault,(CFStringRef)[aDecoder decodeObject]);
	}
    return self;
}
- (NSString *)stringWithKey:(NSString*)key
{
    return [NSString stringWithFormat: @"%@;%@",[self stringValue],key];
}
- (void)setRepresentedObject:(id)obj forKey:(NSString *)key
{
    if (!gUniqueObjects) {
		gUniqueObjects = [NSMutableDictionary dictionary];
    }
    if (obj == NULL)
		[gUniqueObjects removeObjectForKey:[self stringWithKey: key]];
    else
		gUniqueObjects[[self stringWithKey: key]] = [NSValue valueWithNonretainedObject:obj]; // use a pointer to avoid retaining (or else it will never be released)
}
- (id) representedObjectForKey: (NSString *)key
{
    if (!gUniqueObjects)
		return NULL;
    return (id)[gUniqueObjects[[self stringWithKey: key]] pointerValue];
}
- (void) setRepresentedObject: (id) obj
{
    [self setRepresentedObject: obj forKey: @""];
}
- (id) representedObject
{
    return [self representedObjectForKey: @""];
}
+ (NSDictionary *) allObjectsStartingWith: (NSString *)prefix
{
    if (!gUniqueObjects)
		return NULL;
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnum = [gUniqueObjects keyEnumerator];
    NSString *key;
    while ((key = [keyEnum nextObject]) != NULL) {
		if ([key hasPrefix:prefix]) {
			IDEKit_UniqueID *unique = [self uniqueIDFromString: [key substringFromIndex:[key length] - 36]]; // last 36 chars are UUID
			retval[unique] = (id)[gUniqueObjects[key] pointerValue];
		}
    }
    return retval;
}

+ (NSDictionary *) allObjectsForKey: (NSString *)key
{
    return [self allObjectsStartingWith: [key stringByAppendingString:@";"]]; // terminate key
}
+ (NSDictionary *) allObjectsForParentKey: (NSString *)key // you can pass in a parent heirarchy and it will work
{
    return [self allObjectsStartingWith: [key stringByAppendingString:@"."]]; // terminate key path entry
}

- (NSUInteger) hash
{
    return [[self stringValue] hash]; // use the hash of the string, that way "if two objects are
    // equal (as determined by the isEqual: method) they must have the same hash value"
}
- (BOOL) isEqual: (id) other
{
    return [[self stringValue] isEqualToString: [other stringValue]];
}

- (BOOL) isEqualToID: (IDEKit_UniqueID *)other
{
    if (self == other) return YES;
    return CFEqual(myCFUUID, other->myCFUUID);
}
- (NSString *) description
{
    return [self stringValue];
}
@end


@implementation IDEKit_UniqueFileIDManager
+ (IDEKit_UniqueFileIDManager *) sharedFileIDManager
{
    static IDEKit_UniqueFileIDManager *gUniqueFileIDManager = NULL;
    if (!gUniqueFileIDManager)
		gUniqueFileIDManager = [[self alloc] init];
    return gUniqueFileIDManager;
}
- (IDEKit_UniqueID *) newUniqueFileID
{
    return [IDEKit_UniqueID uniqueID];
}
- (IDEKit_UniqueID *) uniqueFileIDForFile: (NSString *)path
{
    NSString *str = [[NSUserDefaults standardUserDefaults] persistentDomainForName: IDEKit_UniqueFileIDManagerDomain][path];
    if (str) {
		return [[IDEKit_UniqueID alloc] initWithString: str];
    } else {
		// we've got a path, add an id (for future reference)
		IDEKit_UniqueID *retval = [self newUniqueFileID];
		[self saveFileID: retval forPath: path];
		return retval;
    }
}
- (NSString *) pathForFileID: (IDEKit_UniqueID *)fileID
{
    return [[self persistentDataForFileID: fileID] filePath];
}

- (void) removeFileIDForPath: (NSString *)path
{
    if (!path) return; // already not there
    NSMutableDictionary *domain = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: IDEKit_UniqueFileIDManagerDomain] mutableCopy];
    if (!domain) return;
    [domain removeObjectForKey: path];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:domain forName:IDEKit_UniqueFileIDManagerDomain];
}


- (void) saveFileID: (IDEKit_UniqueID *) fileID forPath: (NSString *)path
{
    NSMutableDictionary *domain = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: IDEKit_UniqueFileIDManagerDomain] mutableCopy];
    if (!domain) domain = [NSMutableDictionary dictionary];
    domain[path] = [fileID stringValue];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:domain forName:IDEKit_UniqueFileIDManagerDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IDEKit_PersistentFileData *) persistentDataForFile: (NSString *)path
{
    return [[IDEKit_PersistentFileData alloc] initWithFileID: [self uniqueFileIDForFile: path] forFile: path];
}
- (IDEKit_PersistentFileData *) persistentDataForFileID: (IDEKit_UniqueID *) fileID
{
    return [[IDEKit_PersistentFileData alloc] initWithFileID: fileID];
}
- (IDEKit_PersistentFileData *) persistentDataCopyForFileID: (IDEKit_UniqueID *) fileID
{
    return [[IDEKit_PersistentFileData alloc] initCopyWithFileID: fileID];
}

@end


#define IDEKit_PrivatePersistentFileData    @"gandreas.com.idekit"

#define IDEKit_PrivatePersistentFileDataUUID    @"$uuid"
#define IDEKit_PrivatePersistentFileDataPath    @"$path"

@implementation IDEKit_PersistentFileData
- (NSString *) keyFromAppliation: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID target: (NSString *)target key: (NSString *)key
{
    if (appBundleID) {
		if (projID) {
			if (target) {
				return [NSString stringWithFormat: @"%@/%@/%@/%@",appBundleID,[projID stringValue],target,key];
			} else {
				return [NSString stringWithFormat: @"%@/%@/%@",appBundleID,[projID stringValue],key];
			}
		} else {
			return [NSString stringWithFormat: @"%@/%@",appBundleID,key];
		}
    } else
		return key;
}

- (id) fileDataForApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID target: (NSString *)target key: (NSString *)key
{
    return myData[[self keyFromAppliation:appBundleID project:projID target: target key:key]];
}
- (void) setFileData: (id) value forApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID target: (NSString *)target key: (NSString *)key
{
    myData[[self keyFromAppliation:appBundleID project:projID target: target key:key]] = value;
    myNeedsWrite = YES;
}


- (id) fileDataForApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID key: (NSString *)key
{
    return myData[[self keyFromAppliation:appBundleID project:projID target: NULL key:key]];
}

- (void) setFileData: (id) value forApplication: (NSString *)appBundleID project: (IDEKit_UniqueID *)projID key: (NSString *)key
{
    myData[[self keyFromAppliation:appBundleID project:projID target: NULL key:key]] = value;
    myNeedsWrite = YES;
}


- (id) fileDataForApplication: (NSString *)appBundleID key: (NSString *)key
{
    return [self fileDataForApplication: appBundleID project: NULL target: NULL key: key];
}
- (void) setFileData: (id) value forApplication: (NSString *)appBundleID key: (NSString *)key
{
    [self setFileData: value forApplication: appBundleID project: NULL target: NULL key: key];
}

- (id) globalFileDataForKey: (NSString *)key
{
    return [self fileDataForApplication: NULL project: NULL key: key];
}

- (void) setGlobalFileData: (id) value forKey: (NSString *)key
{
    [self setFileData: value forApplication: NULL project: NULL key: key];
}

- (NSData *) archivedData
{
    return [NSArchiver archivedDataWithRootObject: myData];
}
- (IDEKit_UniqueID *) uniqueFileID
{
    return [[IDEKit_UniqueID alloc] initWithString:myData[IDEKit_PrivatePersistentFileDataUUID]];
}
- (NSString *) filePath
{
    return myData[IDEKit_PrivatePersistentFileDataPath];
}
- (void) writeForFile: (NSString *)path
{
    path = [path stringByExpandingTildeInPath];
    if (![path isEqualToString: myData[IDEKit_PrivatePersistentFileDataPath]]) {
		// new location, or otherwise moved
		[[IDEKit_UniqueFileIDManager sharedFileIDManager] removeFileIDForPath: myData[IDEKit_PrivatePersistentFileDataPath]]; // no longer there
		myData[IDEKit_PrivatePersistentFileDataPath] = path;
		[[IDEKit_UniqueFileIDManager sharedFileIDManager] saveFileID: [self uniqueFileID] forPath: path];
    }
    [self save];
}
@end


@implementation IDEKit_PersistentFileData(Private)
+ (NSString *) persistentFileCacheBase: (BOOL) forWriting
{
    NSString *path = [NSString userPrefFolderPath];
    path = [path stringByAppendingPathComponent: @"IDEKit"];
    if (forWriting) {
		[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:NULL error:nil];
    }
    path = [path stringByAppendingPathComponent: @"PersistentFileInfo"];
    if (forWriting) {
		[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:NULL error:nil];
    }
    return path;
}
+ (NSString *) persistentFileCachePath: (IDEKit_UniqueID *)fileID
{
    return [[self persistentFileCacheBase: NO] stringByAppendingPathComponent:[fileID stringValue]];
}
- (NSString *) persistentFileCachePath
{
    [IDEKit_PersistentFileData persistentFileCacheBase: YES]; // make sure it exists
    return [IDEKit_PersistentFileData persistentFileCachePath: [self uniqueFileID]];
}

- (id) initWithFileID: (IDEKit_UniqueID *)fileID
{
    self = [super init];
    if (self) {
		NSString *cachePath = [IDEKit_PersistentFileData persistentFileCachePath:fileID];
		myData = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
		if (!myData) {
			myData = [NSMutableDictionary dictionary]; // doesn't exist, or error
		}
		// and to be on the safe side
		myData[IDEKit_PrivatePersistentFileDataUUID] = [fileID stringValue];
    }
    return self;
}
- (id) initCopyWithFileID: (IDEKit_UniqueID *)fileID
{
    self = [super init];
    if (self) {
		NSString *cachePath = [IDEKit_PersistentFileData persistentFileCachePath:fileID];
		myData = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
		if (!myData) {
			myData = [NSMutableDictionary dictionary]; // doesn't exist, or error
		}
		// make a new fileID
		myData[IDEKit_PrivatePersistentFileDataUUID] = [[[IDEKit_UniqueID alloc] init] stringValue];
    }
    return self;
}

- (id) initWithFileID: (IDEKit_UniqueID *)fileID forFile: (NSString *)path
{
    self = [super init];
    if (self) {
		// first, see if there is a resource fork for the file
		// if not, use the cache path
		NSString *cachePath = [IDEKit_PersistentFileData persistentFileCachePath:fileID];
		myData = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
		if (!myData) {
			myData = [NSMutableDictionary dictionary]; // doesn't exist, or error
		}
		// and to be on the safe side
		myData[IDEKit_PrivatePersistentFileDataUUID] = [fileID stringValue];
		myData[IDEKit_PrivatePersistentFileDataPath] = path;
    }
    return self;
}

- (void) dealloc
{
    if (myNeedsWrite)
		[self save];
}

- (id) privateFileDataForKey: (NSString *)key
{
    return [self fileDataForApplication: IDEKit_PrivatePersistentFileData project: NULL key: key];
}

- (void) setPrivateFileData: (id) value forKey: (NSString *)key
{
    [self setFileData: value forApplication: IDEKit_PrivatePersistentFileData project: NULL key: key];
}
- (void) save
{
    NSString *cachePath = [self persistentFileCachePath];
    [myData writeToFile:cachePath atomically:YES];
    myNeedsWrite = NO;
}

@end
