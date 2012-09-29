//
//  IDEKit_Delegate.h
//  IDEKit
//
//  Created by Glenn Andreas on Wed Aug 13 2003.
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

/*
 The IDEKit_Delegate class provides a way to override a wide variety of application level
 behavior (not unlike NSApplication's delegate).  However, this is a separate object, and not
 an informal protocol like NSApplication's delegate.  This is because there _must_ be an
 IDEKit_Delegate available at any time (and only one - this is a singleton class).

 To provide your own (and you should), simply subclass IDEKit_Delegate and instantiate it
 either in your main(), or as an object in the MainMenu.nib
 
 */

@class IDEKit_LanguagePlugin;
@class IDEKit_SrcEditContext;
@class IDEKit_UniqueID;

enum {
    IDEKit_kStoreBreakpointsNone, // we don't store them persistently
    IDEKit_kStoreBreakpointsInFile,// only store breakpoints in file persistent data (usually a bad idea)
    IDEKit_kStoreBreakpointsInApp, // app keeps track in it's prefs (doesn't preclude project as well)
    IDEKit_kStoreBreakpointsInProject // stored _only_ in the project (does preclude app storage)
};

@interface IDEKit_Delegate : NSObject {

}
+ (IDEKit_Delegate *) sharedDelegate;
- (NSString *) appPathName;	// @"{IDE}"
- (NSString *) bundlePathName;	// @"{IDEBundle}"
- (NSString *) sdkPathName;	// @"{SDK}"
- (NSString *) sdkLocation;	// @"/" - should be defined
- (NSString *) toolchainPathName;	// @"{Tools}"
- (NSString *) toolchainLocation;	// @"/" - should be defined
- (NSArray *) predefinedPathsList; // return a list of "names" that are in a file popup for relative location bases
- (NSDictionary *) predefinedPathsVars; // a dictionary of the default path variables and their values
// This is how we match file names to language plug-ins
- (NSDictionary *) fileTypeToLanguage; // return a dictionary mapping file type to language plug ins
- (Class) languageFromFileName: (NSString *)fileName; // depricated - implement below if possible
- (Class) languageFromFileName: (NSString *)fileName withContents: (NSString *)source;
- (Class) defaultLanguage;
- (BOOL) languageSupportDebugging: (IDEKit_LanguagePlugin *) language;
- (BOOL) languageSupportFolding: (IDEKit_LanguagePlugin *) language;
- (NSDictionary *) factoryDefaultUserSettings;
- (NSParagraphStyle *) defaultParagraphStyle;
- (void) loadPlugIn: (NSBundle *)bundle; // called for all plugins - loads appropriate info
- (void) loadPlugIns;
- (NSArray *) findFilesFromImport: (NSString *) importCommand forLanguage: (IDEKit_LanguagePlugin *) language  flags: (NSInteger)flags;
// if the user drops a file or folder, this is what should be produced
- (NSString *) representationOfDropFiles: (NSArray *)files forOperation: (NSDragOperation) operation;
- (NSString *) directoryListEntryForFile: (NSString *)path;
- (NSString *) directoryListEntryForDir: (NSString *)path;
- (NSDictionary *) appSnippets; // return a dictionary of app specific snippets
- (void) drawBreakpointKind: (NSInteger) kind x: (float) midx y: (float) midy;
- (void) registerCustomBreakpointKind: (NSInteger) kind image: (NSImage *)image; // image should be around 8x8 (and definitely not larger than 16x16)
// breakpoints can be in the file, up to the app, or up to a project - these are the default behaviors
// and implementations
- (NSInteger) breakpointStoragePolicy;
- (NSDictionary *) loadApplicationBreakpointsForFile: (IDEKit_UniqueID *)fileID;
- (void) saveApplicationStoredBreakpoints: (NSDictionary *) breakpoints forFile: (IDEKit_UniqueID *)fileID;
@end

// Provide a simple macro to get at the sharedDelegate
#define IDEKit [IDEKit_Delegate sharedDelegate]
