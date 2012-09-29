//
//  IDEKit_ProjDocumentInfoPList.mm
//  IDEKit
//
//  Created by glenn andreas on 1/11/05.
//  Copyright (c) 2005 by Glenn Andreas
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

#import "IDEKit_ProjDocumentInfoPList.h"
#import "IDEKit_ProjSettings.h"
#import "NSString102.h"
#import "IDEKit_ProjDocumentPaths.h"

@implementation IDEKit_ProjDocument(InfoPList)
- (NSDictionary *) currentTargetDefaultInfoPList // generate a "new" one based on default values
{
    return @{@"CFBundleInfoDictionaryVersion": @"6.0",
	@"CFBundleDevelopmentRegion": @"English",
	@"CFBundleSignature": @"????",
	@"CFBundleIdentifier": [NSString stringWithFormat: @"com.example.%@",[[[[self fileURL] absoluteString] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]],
	@"CFBundleVersion": @"1.0",
	@"CFBundleExecutable": [self currentTarget][IDEKit_TargetInfoPList],
	@"NSPrincipalClass": @"NSApplication",
	@"NSMainNibFile": @"MainMenu"};
}
- (NSDictionary *) currentTargetInfoPList
{
    NSDictionary *retval = [[self currentTargetDefaults] objectForKey: IDEKit_TargetInfoPList];
    if (!retval)
	retval = [self currentTargetDefaultInfoPList];
    return retval;
}
- (void) setCurrentTargetInfoPList: (NSDictionary *)infoPList
{
    myCurrentTarget[IDEKit_TargetInfoPList] = infoPList;
    [self liveSaveTarget];
}

- (id) currentTargetInfoPListObjectForKey: (NSString *)key
{
    return [self currentTargetInfoPList][key];
}
- (void) setCurrentTargetInfoPListObject: (id) object forKey: (NSString *)key
{
    NSMutableDictionary *infoPlist = [[self currentTargetInfoPList] mutableCopy];
    infoPlist[key] = [object copy];
    [self setCurrentTargetInfoPList:infoPlist];
}
- (NSArray *) currentTargetInfoPListDocuments
{
    return [self currentTargetInfoPList][@"CFBundleDocumentTypes"];
}

@end
