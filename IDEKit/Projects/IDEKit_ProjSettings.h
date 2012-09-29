//
//  IDEKit_ProjSettings.h
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

// Keys used in various project dictionaries
// All entries in the project (stored as a dictionary) have a numeric key - in some cases
// this is redundant, other cases, required, so put it everywhere to make life simpler
extern NSString *IDEKit_ProjEntryKind; // an NSNumber
enum {
    IDEKit_kUIUnknownEntry,
    IDEKit_kUIFileEntry, // a file that was dragged here
    IDEKit_kUIGroupEntry, // a folder group
    IDEKit_kUITargetEntry, // a specific project
    IDEKit_kUIDependantEntry, // a rule mapping another target to this target
    IDEKit_kUISettingsEntry, // target settings
    IDEKit_kUISegmentEntry,
    IDEKit_kUIRootFileEntry,
    IDEKit_kUIBreakpointEntry, // the parts of the breakpoint itself (eventually)
    IDEKit_kUIBrowserCatEntry,
    IDEKit_kUIBrowserSymbolEntry,
};

@interface NSDictionary(IDEKit_UIEntry)
- (NSInteger) uiKind;
@end;

// Just about anything can have these entries
extern NSString *IDEKit_ProjEntryName; // the unique name of the entry
extern NSString *IDEKit_ProjEntryGroup; // an array of other entries
extern NSString *IDEKit_ProjEntryLastFound; // a variable path where we last found this thing
extern NSString *IDEKit_ProjEntryRelative; // relative to this variable path is where to look
extern NSString *IDEKit_ProjEntryPath; // full path for something

// IDEKit_kUITargetEntry have these
extern NSString *IDEKit_TargetEntryFiles; // a given target has a list of files
extern NSString *IDEKit_TargetBreakPoints; // and break points in the target
extern NSString *IDEKit_TargetDependsOnTargets; // a target can depend on other targets
extern NSString *IDEKit_TargetEntryDefaults; // the user visible settings for this target
extern NSString *IDEKit_TargetKind; // is it for an app, library, etc...
extern NSString *IDEKit_TargetInfoPList;

// IDEKit_kUIDependantEntry have these
extern NSString *IDEKit_DependantOnTarget; // a target can depend on other targets

