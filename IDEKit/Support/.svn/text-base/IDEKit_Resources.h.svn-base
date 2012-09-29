//
//  IDEKit_Resources.h
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

#import <Foundation/Foundation.h>


@interface IDEKit_Resources : NSObject {
    short myRefNum;
}
// Assumes an existing file already
+ (IDEKit_Resources *) resourceFork: (NSString *)path forWriting: (BOOL) writable;
- (id) initWithPath: (NSString *)path forWriting: (BOOL) writable;
- (NSData *) getResourceType: (long) resType resID: (short)resID;
- (void) writeResource: (NSData *)data type: (long) resType resID: (short)resID;
@end
