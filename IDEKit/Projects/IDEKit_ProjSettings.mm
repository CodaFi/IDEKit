//
//  IDEKit_ProjSettings.mm
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

#import "IDEKit_ProjSettings.h"

NSString *IDEKit_ProjEntryKind = @"IDEKit_ProjEntryKind";
NSString *IDEKit_ProjEntryName = @"IDEKit_ProjEntryName"; // the unique name of the entry
NSString *IDEKit_ProjEntryGroup = @"IDEKit_ProjEntryGroup"; // an array of other entries
NSString *IDEKit_ProjEntryLastFound = @"IDEKit_ProjEntryLastFound"; // a variable path where we last found this thing
NSString *IDEKit_ProjEntryRelative = @"IDEKit_ProjEntryRelative"; // relative to this variable path is where to look
NSString *IDEKit_ProjEntryPath = @"IDEKit_ProjEntryPath"; // full path for something

NSString *IDEKit_TargetEntryFiles = @"IDEKit_TargetEntryFiles";
NSString *IDEKit_TargetBreakPoints = @"IDEKit_TargetBreakPoints";
NSString *IDEKit_TargetDependsOnTargets = @"IDEKit_TargetDependsOnTargets";
NSString *IDEKit_TargetEntryDefaults = @"IDEKit_TargetEntryDefaults";
NSString *IDEKit_TargetKind = @"IDEKit_TargetKind";
NSString *IDEKit_TargetInfoPList = @"IDEKit_TargetInfoPList";

NSString *IDEKit_DependantOnTarget = @"IDEKit_DependantOnTarget";

@implementation NSDictionary(IDEKit_UIEntry)
- (NSInteger) uiKind
{
    return [self[IDEKit_ProjEntryKind] intValue];
}
@end;

