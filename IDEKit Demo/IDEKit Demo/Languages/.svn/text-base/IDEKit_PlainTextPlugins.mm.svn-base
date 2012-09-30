//
//  IDEKit_PlainTextPlugins.mm
//  IDEKit
//
//  Created by Glenn Andreas on Sat Feb 08 2003.
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
// PlainTextLanguage
#import "IDEKit_PlainTextPlugins.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_UserSettings.h"

@implementation IDEKit_PlainTextLanguage
+ (void)load
{
    [IDEKit_GetLanguagePlugIns() addObject: self];
}
+ (NSString *)languageName
{
    return @"Plain Text";
}
+ (BOOL)isYourFile: (NSString *)name
{
    if (self == [IDEKit_PlainTextLanguage class]) {
	// explicitly check the class so subclasses that don't have "isYourFile:" don't respond incorrectly
	if ([[name pathExtension] isEqualToString: @"txt"] || [[name pathExtension] isEqualToString: @"text"])
	    return YES;
    }
    return NO;
}

#ifdef notyet
- (NSString *) complete: (NSString *)name withParams: (NSArray *)array
{
    // look to our defaults for an answer...
    id ourList = [[PreferencesManager sharedPreferences] prefsItem: kTEXTHAMMERPLUGINTEMPLATES forPlugIn: self];
    if (ourList) {
	for (int i=0;i<[ourList count];i++) {
	    id aTemplate = [ourList objectAtIndex: i];
	    id key = [aTemplate objectForKey: kTEXTHAMMERTEMPLATEKEY];
	    if (key && [name isEqualToString: key]) {
		return [aTemplate objectForKey: kTEXTHAMMERTEMPLATETEMPLATE];
	    }
	}
    }
    return nil;
}
#endif

@end
