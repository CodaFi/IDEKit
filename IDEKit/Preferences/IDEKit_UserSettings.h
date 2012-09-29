//
//  IDEKit_UserSettings.h
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

// This is shared between the preferences panel and project
// Everything that is written to a user defaults (or similar thing) is
// declared here.

#import <Foundation/Foundation.h>

extern NSString *IDEKit_TextColorsPrefKey;
extern NSString *IDEKit_TextColorDefaultStateKey;
extern NSString *IDEKit_TextColorDefaultBrowserKey;

extern NSString *IDEKit_TextFontNameKey;
extern NSString *IDEKit_TextFontSizeKey;

extern NSString *IDEKit_TabStopKey;
extern NSString *IDEKit_TabStopUnitKey;
extern NSString *IDEKit_TabSavingKey;
extern NSString *IDEKit_TabSizeKey;
extern NSString *IDEKit_TabIndentSizeKey;
extern NSString *IDEKit_TabAutoConvertKey;
extern NSString *IDEKit_TextAutoCloseKey;


extern NSMutableDictionary *IDEKit_DefaultUserSettings();

extern NSString *IDEKit_UserSettingsChangedNotification;

extern NSString *IDEKit_TemplatesKey;
extern NSString *IDEKit_KeyBindingsKey;

extern NSString *IDEKit_UserPathsKey;

