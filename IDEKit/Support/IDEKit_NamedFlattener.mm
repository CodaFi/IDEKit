//
//  IDEKit_NamedFlattener.mm
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

#import "IDEKit_NamedFlattener.h"

@interface NSObject(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener;
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener;
@end
@interface NSArray(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener;
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener;
@end
@interface NSDictionary(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener;
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener;
@end
@implementation NSObject(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener;
{
    return self; // assume we are flat
}
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener;
{
    return self;
}
@end
@implementation NSArray(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener
{
    BOOL found;
    id retval = [flattener nameForObject: self found: &found];
    if (found)
	return retval; // we are already there
    NSMutableArray *value = [NSMutableArray arrayWithCapacity: [self count]];
    for (NSUInteger i=0;i<[self count];i++) {
	[value addObject: [[self objectAtIndex: i] flattenWithFlattener: flattener]];
    }
    [flattener setValue: value forObject: retval];
    return retval;
}
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener
{
    NSMutableArray *value = [NSMutableArray arrayWithCapacity: [self count]];
    for (NSUInteger i=0;i<[self count];i++) {
	[value addObject: [flattener unflattenObject: [self objectAtIndex: i]]];
    }
    return value;
}
@end
@implementation NSDictionary(IDEKit_NamedFlattener)
- (id) flattenWithFlattener: (IDEKit_NamedFlattener *)flattener
{
    BOOL found;
    id retval = [flattener nameForObject: self found: &found];
    if (found)
	return retval; // we are already there
    NSMutableDictionary *value = [NSMutableDictionary dictionaryWithCapacity: [self count]];
    NSEnumerator *keyEnumerator = [self keyEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject]) != NULL) {
	[value setObject: [[self objectForKey: key] flattenWithFlattener: flattener] forKey: key];
    }
    [flattener setValue: value forObject: retval];
    return retval;
}
- (id) unflattenWihtUnflattener: (IDEKit_NamedUnflattener *)flattener
{
    NSMutableDictionary *value = [NSMutableDictionary dictionaryWithCapacity: [self count]];
    NSEnumerator *keyEnumerator = [self keyEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject]) != NULL) {
	[value setObject: [flattener unflattenObject: [self objectForKey: key]] forKey: key];
    }
    return value;
}
@end


@implementation IDEKit_NamedFlattener
- (id) nameForObject: (id) what found: (BOOL *)found;
{
    // does this need a unique name?
    // see if it is in our object cache
#ifdef nodef
    NSArray *keys = [myObjects allKeysForObject: what];
    if (keys && [keys count]) {
	NSAssert2([keys count] == 1,@"Should one be a single key instance for an object (found %@ for %@)",[keys description],[what description]);
	if (found)
	    *found = YES;
	return [keys objectAtIndex: 0];
    }
#else
    // need to find _exact_ matches, so empty lists aren't shared, for example
    NSEnumerator *keyEnumerator = [myObjects keyEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject]) != NULL) {
	if ([myObjects objectForKey: key] == what) {
	    if (found)
		*found = YES;
	    return key;
	}
    }
#endif
    if (found)
	*found = NO;
    time_t clock;
    time(&clock);
    long checkSum = (clock ^ ((long)(what)));
    id newKey = [NSString stringWithFormat: @"%@%.8lX%.8lX",what,clock,checkSum];
    [myObjects setObject: [NSNull null] forKey: newKey];
    //NSLog(@"Object %.8X is now flattened as %@",what,newKey);
    return newKey;
}
- (void) dealloc
{
    [myObjects release];
    [super dealloc];
}
- (id) init
{
    self = [super init];
    if (self) {
	myObjects = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}
- (void) setValue: (id) value forObject: (id) what
{
    [myObjects setObject: value forKey: what];
}

- (void) addRootObject: (id) what
{
    // see if the thing is in our object cache
    myRoot = [what flattenWithFlattener: self];
}
- (id) addNamableObject: (id) what
{
    return [what flattenWithFlattener: self];
}

- (NSDictionary *)asDictionary
{
    NSDictionary *retval = [NSDictionary dictionaryWithObjectsAndKeys:
	myObjects, @"objects",
	[NSNumber numberWithInt: 1], @"version",
	myRoot, @"rootObject",
	NULL
	];
    //NSLog(@"Flattened as %@",[retval description]);
    return retval;
}

+ (NSData *) flattenSerializedData: (id) propertyList format:(NSPropertyListFormat)format errorDescription: (NSString **)error
{
    if (propertyList == NULL)
	return NULL;
    //NSLog(@"Flattening %@",[propertyList description]);
    IDEKit_NamedFlattener *flattener = [[IDEKit_NamedFlattener alloc] init];
    [flattener addRootObject: propertyList];
    NSDictionary *flattenedPlist = [flattener asDictionary];
    NSData *data;
    if (format == NSPropertyListOpenStepFormat) {
	data = [[flattenedPlist description] dataUsingEncoding: NSUTF8StringEncoding];
	NSAssert1(data ,@"flattening serial data didn't convert",[flattenedPlist description]);
    } else {
	NSString *err1 = NULL;
	data = [NSPropertyListSerialization dataFromPropertyList: flattenedPlist format: (NSPropertyListFormat)format errorDescription: &err1];
	NSAssert1(data || error,@"flattening serial data without error %@ being checked",err1);
	if (error)
	    *error = err1;
    }
    return data;
}

@end



@implementation IDEKit_NamedUnflattener
- (id) initWithFlattened: (id) flat
{
    self = [super init];
    if (self) {
	[myObjects release];
	myObjects = [[flat objectForKey: @"objects"] retain];
	myUnflattened = [[NSMutableDictionary dictionaryWithCapacity: [myObjects count]] retain];
	myRoot = [[flat objectForKey: @"rootObject"] retain];
    }
    return self;
}
- (void) dealloc
{
    [myUnflattened release];
    [myRoot release];
    [super dealloc];
}
- (id) unflattenObject: (id) name
{
    id retval = [myUnflattened objectForKey: name];
    if (retval == NULL) {
	// this one isn't unflattened yet
	id toUnflatten = [myObjects objectForKey: name];
	if (toUnflatten == NULL) {
	    // keep it as a "whatever"
	    return name;
	}
	NSAssert1(toUnflatten,@"No such flattened object %@",name);
	retval = [toUnflatten unflattenWihtUnflattener: self];
	NSAssert1(retval,@"Couldn't unflatten %@",name);
	[myUnflattened setObject: retval forKey: name];
    }
    return retval;
}

- (id) unflattenRootObject
{
    return [self unflattenObject: myRoot];
}

+ (id) unflattenSerializedData: (NSData *) data errorDescription: (NSString **) error
{
    // convert from data (as in from file) to a flattened plist
    NSString *err1 = NULL;
    id plist = [NSPropertyListSerialization propertyListFromData: data mutabilityOption: NSPropertyListImmutable format: NULL errorDescription: &err1];
    if (error) {
	*error = err1;
    }
    if (!plist) {
	NSAssert1(error,@"unflattening serial data without error %@ being checked",err1); 
	return NULL;
    }
    // and then unflatten that
    IDEKit_NamedUnflattener *unflattener = [[self alloc] initWithFlattened: plist];
    NSDictionary *allData = [unflattener unflattenRootObject];
    return allData;
}

@end