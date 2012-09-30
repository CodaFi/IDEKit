//
//  IDEKit_UserSettings.mm
//
//  Created by Glenn Andreas on Sat Mar 22 2003.
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

#import "IDEKit_UserSettings.h"

NSString *IDEKit_TextColorsPrefKey = @"IDEKit_TextColors";
NSString *IDEKit_TextColorDefaultStateKey = @"IDEKit_TextColorDefault";
NSString *IDEKit_TextColorDefaultBrowserKey = @"IDEKit_TextColorBrowser";

NSString *IDEKit_TextFontNameKey = @"IDEKit_TextFontNameKey";
NSString *IDEKit_TextFontSizeKey = @"IDEKit_TextFontSizeKey";

NSString *IDEKit_TabStopKey = @"IDEKit_TabStopKey";
NSString *IDEKit_TabStopUnitKey = @"IDEKit_TabStopUnitKey";
NSString *IDEKit_TabSavingKey = @"IDEKit_TabSavingKey";
NSString *IDEKit_TabSizeKey = @"IDEKit_TabSizeKey";
NSString *IDEKit_TabIndentSizeKey = @"IDEKit_TabIndentSizeKey";
NSString *IDEKit_TabAutoConvertKey = @"IDEKit_TabAutoConvertKey";

NSString *IDEKit_TextAutoCloseKey = @"IDEKit_TextAutoCloseKey";

NSString *IDEKit_TemplatesKey = @"IDEKit_TemplatesKey";
NSString *IDEKit_KeyBindingsKey = @"IDEKit_KeyBindingsKey";

NSString *IDEKit_UserPathsKey = @"IDEKit_UserPathsKey";


NSMutableDictionary *IDEKit_DefaultUserSettings()
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInt: 1],IDEKit_TextColorDefaultStateKey,
	[NSNumber numberWithFloat: 0.5],  IDEKit_TabStopKey, // 1/2
	[NSNumber numberWithInt: 1],  IDEKit_TabStopUnitKey, // inch
	[NSNumber numberWithInt: 1], IDEKit_TabSavingKey, // save tabs
	[NSNumber numberWithInt: 8], IDEKit_TabSizeKey,	// 8 spaces per tab
	[NSNumber numberWithInt: 4], IDEKit_TabIndentSizeKey,	// 4 spaces per indent
	[NSNumber numberWithInt: 1],  IDEKit_TabAutoConvertKey, // convert multiple spaces to tab
	[NSNumber numberWithFloat: 10.0], IDEKit_TextFontSizeKey,

	[NSDictionary dictionaryWithObjectsAndKeys:
	    @"Copyright $<_YEAR$>$!, $<_USER$>$!$=$|", @"copyright",
	    NULL], IDEKit_TemplatesKey,
	[NSDictionary dictionaryWithObjectsAndKeys:
	    @"transposeParameters:",@"^$T",
	    @"selectParameter:",@"^$P",
	    @"selectNextParameter:",@"^${",
	    @"selectPreviousParameter:",@"^$}",
	    @"insertPageBreak:",[NSString stringWithFormat: @"^%c",3], // enter + control
	    NULL], IDEKit_KeyBindingsKey,
	NULL
	];
}


NSString *IDEKit_UserSettingsChangedNotification = @"IDEKit_UserSettingsChangedNotification";
