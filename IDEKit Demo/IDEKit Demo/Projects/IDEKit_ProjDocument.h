//
//  IDEKit_ProjDocument.h
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

#import <AppKit/AppKit.h>

#define IDEKit_kVERSION_LATEST	1

// Part of the concept of a project is managing finding files, either explicitly or implicitly
// To do this, we've got a couple of concepts of where files can be found, which can be expressed
// with the following flags
enum {
    // these are used for currentTargetImplicitIncludeDirs
    IDEKit_kIncludesSource = 0x1,
    IDEKit_kIncludesHeader = 0x2,
    IDEKit_kIncludesLibraries = 0x4,
    IDEKit_kIncludesResources = 0x8,
    // these are used for currentTargetAllIncludeDirs
    IDEKit_kIncludesUser = 0x10,
    IDEKit_kIncludesSystem = 0x20,
    IDEKit_kIncludesImplicit = 0x40,
    IDEKit_kIncludesAllFolders = (IDEKit_kIncludesUser | IDEKit_kIncludesSystem | IDEKit_kIncludesImplicit),
    // flags for behavior
    IDEKit_kIncludesExpandVars = 0x100,
    // and common sets of options
    IDEKit_kIncludesCompileDefault = IDEKit_kIncludesSource | IDEKit_kIncludesHeader | IDEKit_kIncludesAllFolders | IDEKit_kIncludesExpandVars,
    IDEKit_kIncludesResourceDefault = IDEKit_kIncludesResources | IDEKit_kIncludesAllFolders | IDEKit_kIncludesExpandVars,
    IDEKit_kIncludesLinkerDefault = IDEKit_kIncludesLibraries | IDEKit_kIncludesAllFolders | IDEKit_kIncludesExpandVars,
    IDEKit_kIncludesSearchDefault = IDEKit_kIncludesSource | IDEKit_kIncludesHeader | IDEKit_kIncludesResources | IDEKit_kIncludesAllFolders | IDEKit_kIncludesExpandVars,
};

@interface IDEKit_ProjDocument : NSDocument {
    // these items are all stored in the project file itself, and are critical - all parts need
    // to be checked in to work correctly (and are thus kept in a single file).  Note that this
    // file is versioned so we can update as we add/change fields.
    NSMutableArray *myFileList;	// all files in the project - each file is a dictionary
    NSMutableDictionary *myRootGroup;	// an array of objects/arrays for the groups
    NSMutableArray *myTargetList;	// all targets in the project
    NSMutableDictionary *myCurrentTarget;	// all targets in the project
					  // these items are non-critical, and wouldn't be checked in (since they are regenerated with
       // the build, or otherwise transitory).  They are stored in separate files, and, if project
       // dependant, are stored in the that target directory.  These files aren't versioned, but rather
       // if their version changes we wipe them and schedule the target for re-building
    NSMutableDictionary *myTargetDepends;	// what are the depedancies for files->headers for this project
    NSMutableDictionary *myTargetBrowser;	// symbols, etc for current target
//    ETagsFile *myTargetTags;	// etags format for target, works with  browser
    NSMutableArray *myTargetBreakpoints;	// breakpoint for current target

    // and these are for our UI, etc...

    IBOutlet NSOutlineView *myOutlineView;
    IBOutlet NSOutlineView *myLinkOrderView;
    IBOutlet NSOutlineView *myTargetsView;
    IBOutlet NSTabView *myTabView;
    IBOutlet id myTargetPopup;
    id myPrivateDrag;

    id myEdittedSettings;

    IBOutlet id myNewTargetSheet;
    IBOutlet id myNewTargetName;
    IBOutlet id myNewTargetClone;

    IBOutlet id myFileEntryCMenu;
}

+ (NSMutableArray *)allProjects;
+ (IDEKit_ProjDocument *)defaultProject;
+ (IDEKit_ProjDocument *)documentForFile: (NSString *)path;

- (void)createBlankProject;
- (void)addFilePathToProject: (NSString *)path inGroup: (id) item childIndex: (NSInteger) index;
- (void)addFileToCurrentProject: (id) file;
- (void) removeFileFromCurrentProject: (id) file;
- (NSArray *)currentlySelectedFiles;

- (NSUserDefaults *) currentTargetDefaults;

- (void) liveSave;
- (void) liveSaveTarget; // only save the target specific files
- (void) loadTargetSpecificInfo:(NSFileWrapper *)dirwrapper;

// Generic Project level commands
- (IBAction)addFilesToProject: (id) sender;
- (IBAction)createGroupInProject: (id) sender;
- (IBAction) projectSettings: (id) sender;

// should override these in the client
- (NSArray *)projectSupportedFileExtensions; // what sort of files can be put in the project?
- (BOOL) canAddFileToProject: (NSString *)filePath; // can this specific file be added?
- (BOOL) projectEntryIsLinked: (NSDictionary *)entry; // is this project entry shown in "link order"?
- (NSMutableDictionary *)defaultTargetDefaults; // provide default defaults for the target
// possible attributes values include the identifiers of columns such as "CodeSize" or "DataSize" or other custom columns
- (id) projectListColumnAttributeValue: (NSString *)attribute forEntry: (NSDictionary *)entry proto: (id) cell;
- (id) projectListColumnAttributeProto: (NSString *)attribute forEntry: (NSDictionary *)entry; // to change the cell shown there
- (void) projectListColumnSetValue: (id) value forAttribute: (NSString *)attribute forEntry: (NSDictionary *)entry; // to change the cell shown there
@end
