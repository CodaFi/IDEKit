//
//  IDEKit_ProjDocumentPaths.h
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

#import "IDEKit_ProjDocument.h"

// these can be changed, so long as you always change them consistenly
extern NSString *IDEKit_ProjectPlistFileName;
extern NSString *IDEKit_BrowserFileName;
extern NSString *IDEKit_DependsFileName;
extern NSString *IDEKit_BreaksFileName;
extern NSString *IDEKit_TagsFileName;
extern NSString *IDEKit_BuildSubDirectoryName;

@interface IDEKit_ProjDocument(Paths)
- (NSDictionary *)currentTarget;
- (NSArray *)fileList;
- (NSDictionary *)rootGroup;
- (NSArray *)targetList;

- (NSDictionary *)projectEntryForFile: (NSString *)path;
- (NSDictionary *)projectEntryForName: (NSString *)name;

- (NSString *)currentTargetDir;
- (NSString *)currentTargetSubFile: (NSString *)fileName;
- (NSString *)currentTargetSubDir: (NSString *)subDir; // will create it if needed
- (NSString *)currentTargetBuildDir;

- (NSDictionary *)pathVars;
- (NSString *)pathWithVars: (NSString *)path;
- (NSString *)escapedPathWithVars: (NSString *)path;
@end
