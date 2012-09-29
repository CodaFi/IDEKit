//
//  IDEKit_ProjDocumentPaths.m
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

#import "IDEKit_ProjDocumentPaths.h"
#import "IDEKit_ProjSettings.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_PreferencePane.h"

NSString *IDEKit_ProjectPlistFileName = @"IDEKit_Project.plist";
NSString *IDEKit_BuildSubDirectoryName = @"IDEKit_Build";
NSString *IDEKit_BrowserFileName = @"IDEKit_Browser.plist";
NSString *IDEKit_DependsFileName = @"IDEKit_Depends.plist";
NSString *IDEKit_BreaksFileName = @"IDEKit_Breaks.plist";
NSString *IDEKit_TagsFileName = @"IDEKit_Tags.plist";

@implementation IDEKit_ProjDocument(Paths)
- (NSDictionary *)currentTarget
{
    return myCurrentTarget;
}
- (NSArray *)fileList
{
    return myFileList;
}
- (NSDictionary *)rootGroup
{
    return myRootGroup;
}
- (NSArray *)targetList
{
    return myTargetList;
}



- (NSDictionary *)projectEntryForFile: (NSString *)path
{
    for (NSUInteger j=0;j<[myFileList count];j++) {
	NSDictionary *entry = [myFileList objectAtIndex: j];
	if ([path isEqualToString: [entry objectForKey: IDEKit_ProjEntryPath]])
	    return entry;
    }
    return NULL;
}
- (NSDictionary *)projectEntryForName: (NSString *)name
{
    for (NSUInteger j=0;j<[myFileList count];j++) {
	NSDictionary *entry = [myFileList objectAtIndex: j];
	if ([name isEqualToString: [entry objectForKey: IDEKit_ProjEntryName]])
	    return entry;
    }
    return NULL;
}

- (NSString *)currentTargetDir
{
    NSString *dir = [[self fileName] stringByAppendingPathComponent: [myCurrentTarget objectForKey: IDEKit_ProjEntryName]];
    [[NSFileManager defaultManager] createDirectoryAtPath: dir attributes: NULL];
    return dir;
}


- (NSString *)currentTargetSubFile: (NSString *)fileName
{
    NSString *dir = [self currentTargetDir];
    return [dir stringByAppendingPathComponent: fileName];
}


- (NSString *)currentTargetSubDir: (NSString *)subDir
{
    NSString *dir = [self currentTargetDir];
    dir = [dir stringByAppendingPathComponent: subDir];
    [[NSFileManager defaultManager] createDirectoryAtPath: dir attributes: NULL];
    return dir;
}

- (NSString *)currentTargetBuildDir
{
    return [self currentTargetSubDir: IDEKit_BuildSubDirectoryName];
}


- (NSDictionary *)pathVars
{
    // start with the default values from the system
    id retval = [[IDEKit predefinedPathsVars] mutableCopy];
    // add project paths
    [retval setObject: [[self fileName]stringByDeletingLastPathComponent] forKey: @"{Project}"];
    [retval setObject: [self currentTargetBuildDir] forKey: @"{BuildDir}"];
    // and add in the user paths
    id userPaths = [[self currentTargetDefaults] objectForKey: IDEKit_UserPathsKey];
    if (!userPaths) {
	userPaths = [[NSUserDefaults standardUserDefaults] objectForKey: IDEKit_UserPathsKey];
    }

    for (NSUInteger i=0;i<[userPaths count];i++) {
	id entry = [userPaths  objectAtIndex: i];
	[retval setObject: [entry objectAtIndex: 1] forKey: [entry objectAtIndex: 0]];
    }
    return retval;
}

- (NSString *)pathWithVars: (NSString *)path
{
    return [path stringByReplacingVars: [self pathVars]];
}
- (NSString *)escapedPathWithVars: (NSString *)path
{
    return [[self pathWithVars: path] stringByEscapingShellChars];
}


- (IBAction) changeEntryRelative: (id) sender
{
    id entry = [sender representedObject];
    id pathVars = [self pathVars];
    id fullPath = [entry objectForKey: IDEKit_ProjEntryPath];
    id newRelative = NULL;
    NSString *varName = NULL;
    switch ([sender tag]) {
	case IDEKit_kPickFlagsAbsolute:
	    [entry removeObjectForKey: IDEKit_ProjEntryRelative];
	    [self liveSave];
	    break;
	case IDEKit_kPickFlagsRelativeProj:
	    varName = @"{Project}";
	    break;
	case IDEKit_kPickFlagsRelativeApp:
	    varName = [IDEKit appPathName];
	    break;
	case IDEKit_kPickFlagsRelativeTools:
	    varName = [IDEKit toolchainPathName];
	    break;
	case IDEKit_kPickFlagsRelativeSDK:
	    varName = [IDEKit sdkPathName];
	    break;
	case IDEKit_kPickFlagsRelativeHome:
	    varName = @"{Home}";
	    break;
	case IDEKit_kPickFlagsRelativeUser:
	    // not supported yet
	    break;
    }
    if (varName) {
	newRelative = [fullPath stringRelativeTo:[pathVars objectForKey: varName] name: varName];
    }
    if (newRelative) {
	[entry setObject: newRelative forKey: IDEKit_ProjEntryRelative];
	[self liveSave];
    }
}
@end
