//
//  IDEKit_LayeredDefaults.mm
//  IDEKit
//
//  Created by Glenn Andreas on Sun Aug 17 2003.
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

#import "IDEKit_LayeredDefaults.h"


@implementation IDEKit_LayeredDefaults
+ (IDEKit_LayeredDefaults *) layeredDefaultsWithDict: (NSMutableDictionary *)settings layeredSettings: (NSDictionary *)layeredSettings
{
    return [[self alloc] initWithDict: settings layeredSettings: layeredSettings];
}
- (id) initWithDict: (NSMutableDictionary *)settings layeredSettings: (NSDictionary *)layeredSettings
{
    self = [super init];

    if (self) {
	mySettings = settings;
	myLayeredSettings = layeredSettings;
	myChangedKeys = [NSMutableSet set];
    }
    return self;
}
- (id)objectForKey:(NSString *)defaultName
{
    if (mySettings[defaultName]) {
	//NSLog(@"Found setting %@ = %@",defaultName,[[mySettings objectForKey: defaultName] description]);
	return mySettings[defaultName];
    }
    if (myLayeredSettings && myLayeredSettings[defaultName]) {
	//NSLog(@"Found layered %@ = %@",defaultName,[[mySettings objectForKey: defaultName] description]);
	return myLayeredSettings[defaultName];
    }
    //NSLog(@"Requiring super objectForKey %@ = %@",defaultName,[[super objectForKey: defaultName] description]);
    // we want all the defaults that standardUserDefaults has
    return [[NSUserDefaults standardUserDefaults] objectForKey: defaultName];
}
- (void)setObject:(id)value forKey:(NSString *)defaultName
{
    mySettings[defaultName] = value;
    [myChangedKeys addObject: defaultName];
}
- (void)removeObjectForKey:(NSString *)defaultName
{
    [mySettings removeObjectForKey: defaultName];
    [myChangedKeys addObject: defaultName];
}
- (BOOL) wasKeyChanged: (NSString *)key
{
    return [myChangedKeys containsObject: key];
}

- (void)reset
{
    // need to clear everything in mySettings
    [mySettings removeAllObjects];
    myChangedKeys = [NSMutableSet set];
}

@end
