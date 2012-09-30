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
	@1,IDEKit_TextColorDefaultStateKey,
	@0.5f,  IDEKit_TabStopKey, // 1/2
	@1,  IDEKit_TabStopUnitKey, // inch
	@1, IDEKit_TabSavingKey, // save tabs
	@8, IDEKit_TabSizeKey,	// 8 spaces per tab
	@4, IDEKit_TabIndentSizeKey,	// 4 spaces per indent
	@1,  IDEKit_TabAutoConvertKey, // convert multiple spaces to tab
	@10.0f, IDEKit_TextFontSizeKey,

	@{@"copyright": @"Copyright $<_YEAR$>$!, $<_USER$>$!$=$|"}, IDEKit_TemplatesKey,
	@{@"^$T": @"transposeParameters:",
	    @"^$P": @"selectParameter:",
	    @"^${": @"selectNextParameter:",
	    @"^$}": @"selectPreviousParameter:",
	    [NSString stringWithFormat: @"^%c",3]: @"insertPageBreak:"}, IDEKit_KeyBindingsKey,
	NULL
	];
}


NSString *IDEKit_UserSettingsChangedNotification = @"IDEKit_UserSettingsChangedNotification";
