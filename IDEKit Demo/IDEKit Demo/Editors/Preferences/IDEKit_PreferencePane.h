//
//  IDEKit_PrefsPane.h
//
//  Created by Glenn Andreas on Sat Mar 01 2003.
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

#import <PreferencePanes/PreferencePanes.h>

#import "IDEKit_UserSettings.h"

enum {
    IDEKit_kPickFlagsRelativeProj = 1,
    IDEKit_kPickFlagsRelativeApp = 2,
    IDEKit_kPickFlagsRelativeTools = 4,
    IDEKit_kPickFlagsRelativeSDK = 8,
    IDEKit_kPickFlagsRelativeHome = 16,
    IDEKit_kPickFlagsRelativeUser = 32,
    IDEKit_kPickFlagsAbsolute = 0,

    IDEKit_kPickFlagDefaultAbs = 0x0,
    IDEKit_kPickFlagDefaultRelProj = 0x100,
    IDEKit_kPickFlagDefaultRelApp = 0x200,
    IDEKit_kPickFlagDefaultRelTools = 0x400,
    IDEKit_kPickFlagDefaultRelSDK = 0x800,

    
    IDEKit_kPickFlagDefaultShift = 8,
    IDEKit_kPickFlagDefaultMask = 0xff00,
    
    IDEKit_kDefaultTargetPickFlags = IDEKit_kPickFlagsRelativeHome | IDEKit_kPickFlagsRelativeProj | IDEKit_kPickFlagsRelativeApp | IDEKit_kPickFlagsRelativeTools | IDEKit_kPickFlagsRelativeSDK | IDEKit_kPickFlagDefaultRelProj | IDEKit_kPickFlagsRelativeUser,
    IDEKit_kDefaultAppPickFlags = IDEKit_kPickFlagsRelativeHome | IDEKit_kPickFlagsRelativeApp | IDEKit_kPickFlagsRelativeTools | IDEKit_kPickFlagsRelativeSDK | IDEKit_kPickFlagDefaultAbs
};

@interface IDEKit_PreferencePane : NSPreferencePane {
    NSUserDefaults *myDefaults;
    id myFilePopup;
    id myFilePopupPanel;
    NSDictionary *myPathVars;
}
- (void) setPathVars: (NSDictionary *) pathVars;
- (NSArray *) editedProperties;
- (void) setMyDefaults: (NSUserDefaults *)defaults;
- (NSString *) pickDirectory: (NSInteger) flags;
- (NSString *) pickFile: (NSArray *)types flags: (NSInteger) flags;
- (NSString *) pickDirectory: (NSInteger) flags fromDirectory: (NSString *)path;
- (NSString *) pickFile: (NSArray *)types flags: (NSInteger) flags fromFile: (NSString *)path;
- (NSString *) pickNewFile: (NSString *)type flags: (NSInteger) flags fromFile: (NSString *)path;

- (NSDictionary *) exportPanel;
- (void) importPanel: (NSDictionary *) data;
@end
