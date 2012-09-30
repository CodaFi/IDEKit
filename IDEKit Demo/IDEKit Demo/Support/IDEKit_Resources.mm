//
//  IDEKit_Resources.mm
//  IDEKit
//
//  Created by Glenn Andreas on Tue Mar 23 2004.
//  Copyright (c) 2004 by Glenn Andreas
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

#import "IDEKit_Resources.h"
#import <CoreServices/CoreServices.h>

@implementation IDEKit_Resources
+ (IDEKit_Resources *) resourceFork: (NSString *)path  forWriting: (BOOL) writable
{
    return [[self alloc] initWithPath: path forWriting: writable];
}
- (id) initWithPath: (NSString *)path  forWriting: (BOOL) writable
{
    self = [super init];
    if (self) {
#ifndef MAC_OS_X_VERSION_10_6
		FSRef ref;
		if (FSPathMakeRef([path fileSystemRepresentation],&ref,NULL) == noErr) {
			myRefNum = FSOpenResFile (&ref,writable ? fsRdWrPerm : fsRdPerm);
			if (myRefNum == kResFileNotOpened && writable) {
				// try making one first
				HFSUniStr255 resourceForkName;
				FSGetResourceForkName(&resourceForkName);
				OSErr err = FSCreateResourceFork(&ref,resourceForkName.length,resourceForkName.unicode,0);
				if (err == noErr) {
					// try again
					myRefNum = FSOpenResFile (&ref,writable ? fsRdWrPerm : fsRdPerm);
				}
			}
			//NSAssert2(myRefNum != kResFileNotOpened,@"Error openning resource fork for %@ %d",path,ResError());
			if (myRefNum == kResFileNotOpened) {
				[self release];
				return NULL;
			}
		} else {
			[self release];
			return NULL;
		}
#endif
    }
    return self;
}

- (void) dealloc
{
    if (myRefNum) {
		CloseResFile(myRefNum);
    }
}
- (NSData *) getResourceType:(unsigned int)resType resID: (short)resID
{
    short curResFile = CurResFile();
    UseResFile(myRefNum);
    Handle h = Get1Resource(resType, resID);
    NSMutableData *retval = NULL;
    if (h) {
		HLock(h); // probably not needed anymore with OSX
		retval = [NSMutableData dataWithBytes:*h length:GetHandleSize(h)];
		HUnlock(h);
    }
    UseResFile(curResFile); // set back the way it was
    return retval;
}
- (void) writeResource: (NSData *)data type: (unsigned int) resType resID: (short)resID
{
    Handle h = NewHandle([data length]);
    [data getBytes:*h];
    short curResFile = CurResFile();
    UseResFile(myRefNum);
    Handle oldh = Get1Resource(resType, resID);
    if (oldh) {
		RemoveResource(oldh);
		DisposeHandle(oldh);
    }
    AddResource(h,resType,resID,"\p");
    WriteResource(h);
    UseResFile(curResFile); // set back the way it was
}

@end
