//
//  IDEKit_NamedFlattener.h
//  IDEKit
//
//  Created by Glenn Andreas on Wed Aug 20 2003.
//  Copyright (c) 2003, 2004 by Glenn Andreas
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


@interface IDEKit_NamedFlattener : NSObject {
    id myRoot;
    NSMutableDictionary *myObjects;
}
- (id) nameForObject: (id) what found: (BOOL *)found;
- (id) addNamableObject: (id) what;
- (void) setValue: (id) value forObject: (id) what;
- (void) addRootObject: (id) what;
- (NSDictionary *)asDictionary;

+ (NSData *) flattenSerializedData: (id) propertyList format:(NSPropertyListFormat)format errorDescription: (NSString **) error;
@end

@interface IDEKit_NamedUnflattener : IDEKit_NamedFlattener {
    NSMutableDictionary *myUnflattened;
}
- (id) initWithFlattened: (id) flat;
- (id) unflattenObject: (id) name;
- (id) unflattenRootObject;

+ (id) unflattenSerializedData: (NSData *) data errorDescription: (NSString **) error;
@end