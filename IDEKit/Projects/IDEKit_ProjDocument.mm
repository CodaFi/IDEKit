//
//  IDEKit_ProjDocument.mm
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
#import "IDEKit_ProjDocumentPaths.h"
#import "IDEKit_ProjSettings.h"
#import "IDEKit_NamedFlattener.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_ProjDocumentUI.h"
#import "IDEKit_LayeredDefaults.h"
#import "IDEKit_PreferenceController.h"

#define kVERSION_LATEST
@implementation IDEKit_ProjDocument
+ (NSMutableArray *)allProjects
{
    static NSMutableArray *gAllProjects = NULL;
    if (!gAllProjects)
		gAllProjects = [NSMutableArray arrayWithCapacity: 0];
    return gAllProjects;
}

+ (IDEKit_ProjDocument *)defaultProject
{
    NSMutableArray *all = [self allProjects];
    if (all && [all count])
		return all[0];
    return NULL;
}

+ (IDEKit_ProjDocument *)documentForFile: (NSString *)path
{
    NSMutableArray *all = [self allProjects];
    for (NSUInteger i=0;i<[all count];i++) {
		IDEKit_ProjDocument *proj = all[i];
		if ([proj projectEntryForFile: path])
			return proj;
		//	if ([proj isHeaderFile: path])
		//	    return proj;
    }
    return NULL;
}

- (id)init
{
    if (!(self = [super init])) return nil;
    if (self) {
		[[IDEKit_ProjDocument allProjects] addObject: self];
		
		[self createBlankProject];
    }
    return self;
}

- (void)createBlankProject
{
    myRootGroup = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				   @(IDEKit_kUIGroupEntry), IDEKit_ProjEntryKind,
				   @"__Root", IDEKit_ProjEntryName,
				   [NSMutableArray arrayWithCapacity: 0], IDEKit_ProjEntryGroup,
				   NULL];
    myFileList = [NSMutableArray arrayWithObjects: myRootGroup, NULL];
	
    myCurrentTarget = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					   @(IDEKit_kUITargetEntry), IDEKit_ProjEntryKind,
					   @"DefaultTarget", IDEKit_ProjEntryName,
					   [NSMutableArray arrayWithCapacity: 0], IDEKit_TargetEntryFiles,
					   NULL];
    myTargetList = [NSMutableArray arrayWithObjects: myCurrentTarget, NULL];
	
    myTargetBrowser = [NSMutableDictionary dictionary];
}

- (void) close
{
    [[IDEKit_ProjDocument allProjects] removeObject: self];
    [super close];
}

- (NSDictionary *) projectFileAsDictionary
{
    return @{IDEKit_ProjEntryKind: @(IDEKit_kUIRootFileEntry),
	@"IDEKit_FileList": myFileList,
	@"IDEKit_RootGroup": myRootGroup,
	@"IDEKit_TargetList": myTargetList,
	@"IDEKit_CurrentTarget": myCurrentTarget,
	@"IDEKit_Version": @IDEKit_kVERSION_LATEST};
}
- (NSData *) projectFileAsArchive
{
    return [NSArchiver archivedDataWithRootObject: [self projectFileAsDictionary]];
}

- (id) projectFileAsPList
{
#ifdef nodef
    NSDictionary *allData = [self projectFileAsDictionary];
    IDEKit_NamedFlattener *flattener = [[IDEKit_NamedFlattener alloc] init];
    [flattener addRootObject: allData];
    allData = [flattener asDictionary];
    [flattener autorelease];
    return [allData description];
    NSString *error = NULL;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList: allData format: (NSPropertyListFormat)NSPropertyListXMLFormat_v1_0 errorDescription: &error];
    if (error) {
		NSLog(@"Error archiving project: %@",error);
		return NULL;
    }
    return data;
#else
    NSString *error = NULL;
    NSData *data = [IDEKit_NamedFlattener flattenSerializedData: [self projectFileAsDictionary] format: (NSPropertyListFormat)NSPropertyListOpenStepFormat errorDescription: &error];
    if (error) {
		NSLog(@"Error archiving project: %@",error);
		return NULL;
    }
    return data;
#endif
}

- (id) projectFileAsXML
{
#ifdef nodef
    NSDictionary *allData = [self projectFileAsDictionary];
    IDEKit_NamedFlattener *flattener = [[IDEKit_NamedFlattener alloc] init];
    [flattener addRootObject: allData];
    allData = [flattener asDictionary];
    NSString *error = NULL;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList: allData format: (NSPropertyListFormat)NSPropertyListXMLFormat_v1_0 errorDescription: &error];
    [flattener autorelease];
    if (error) {
		NSLog(@"Error archiving project: %@",error);
		return NULL;
    }
    return data;
#else
    NSString *error = NULL;
    NSData *data = [IDEKit_NamedFlattener flattenSerializedData: [self projectFileAsDictionary] format: (NSPropertyListFormat)NSPropertyListXMLFormat_v1_0 errorDescription: &error];
    if (error) {
		NSLog(@"Error archiving project: %@",error);
		return NULL;
    }
    return data;
#endif
}

- (NSData *) browserFile
{
    NSData *data = [NSArchiver archivedDataWithRootObject: myTargetBrowser];
    return data;
}

- (NSUserDefaults *) currentTargetDefaults
{
    NSMutableDictionary *defaults = myCurrentTarget[IDEKit_TargetEntryDefaults];
    if (!defaults) {
		defaults = [self defaultTargetDefaults];
		myCurrentTarget[IDEKit_TargetEntryDefaults] = defaults;
    }
    return [IDEKit_LayeredDefaults layeredDefaultsWithDict: defaults layeredSettings: [self defaultTargetDefaults]];
}

- (void) liveSave
{
#ifdef nodef
    NSString *path = [[[self fileURL] absoluteString] stringByAppendingPathComponent: @"idekit_project"];
    NSData *data = [self projectFileAsArchive];
    [data writeToFile: path atomically: YES];
#else
    NSString *path = [[[self fileURL] absoluteString] stringByAppendingPathComponent: IDEKit_ProjectPlistFileName];
    NSData *data = [self projectFileAsPList];
    [data writeToFile: path atomically: YES];
#endif
    [self liveSaveTarget];
	
    [myOutlineView reloadData];
    [myTargetsView reloadData];
    [myLinkOrderView reloadData];
	
    [self rebuildTargetPopup];
    [self adjustTabTitles];
}

- (void) liveSaveTarget // only save the target specific files
{
#ifdef nodef
    [[NSArchiver archivedDataWithRootObject: myTargetBrowser] writeToFile: [self currentTargetSubFile: IDEKit_BrowserFileName] atomically: YES];
    [[NSArchiver archivedDataWithRootObject: myTargetDepends] writeToFile: [self currentTargetSubFile: IDEKit_DependsFileName] atomically: YES];
    [[NSArchiver archivedDataWithRootObject: myTargetBreakpoints] writeToFile: [self currentTargetSubFile: IDEKit_BreaksFileName] atomically: YES];
#ifdef notyet
    [[NSArchiver archivedDataWithRootObject: myTargetTags] writeToFile: [self currentTargetSubFile: IDEKit_TagsFileName] atomically: YES];
#endif
#else
    [[IDEKit_NamedFlattener flattenSerializedData: myTargetBrowser format: NSPropertyListOpenStepFormat errorDescription: NULL] writeToFile: [self currentTargetSubFile: IDEKit_BrowserFileName] atomically: YES];
    [[IDEKit_NamedFlattener flattenSerializedData: myTargetDepends format: NSPropertyListOpenStepFormat errorDescription: NULL] writeToFile: [self currentTargetSubFile: IDEKit_DependsFileName] atomically: YES];
    [[IDEKit_NamedFlattener flattenSerializedData: myTargetBreakpoints format: NSPropertyListOpenStepFormat errorDescription: NULL] writeToFile: [self currentTargetSubFile: IDEKit_BreaksFileName] atomically: YES];
#ifdef notyet
    [[IDEKit_NamedFlattener flattenSerializedData: myTargetTags format: NSPropertyListOpenStepFormat errorDescription: NULL] writeToFile: [self currentTargetSubFile: IDEKit_TagsFileName] atomically: YES];
#endif
#endif
}

- (IBAction)saveDocument:(id)sender
{
    // do nothing for manual saves - this would wipe all the target info
}
- (IBAction)revertDocumentToSaved:(id)sender
{
    // and this makes no sense
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type
{
#ifdef nodef
    //NSFileWrapper *retval = [[NSFileWrapper alloc] initWithPath: fileName];
    NSData *data = [self projectFileAsArchive];
    if (!data)
		return NULL;
    NSFileWrapper *project = [[NSFileWrapper alloc] initRegularFileWithContents: data];
    //NSFileWrapper *browser = [[NSFileWrapper alloc] initRegularFileWithContents: [self browserFile]];
    //[retval addRegularFileWithContents: data preferredFilename: @"project"];
    NSFileWrapper *retval = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionaryWithObjectsAndKeys:
																				   project, @"project",
																				   //browser, BrowserFileName,
																				   NULL]];
    // need to figure a way to copy over what we've got here (or a way to avoid explicitly updating it)
    return retval;
#else
    NSData *data = [self projectFileAsPList];
    if (!data)
		return NULL;
    NSFileWrapper *project = [[NSFileWrapper alloc] initRegularFileWithContents: data];
    NSFileWrapper *retval = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: @{IDEKit_ProjectPlistFileName: project}];
    NSLog(@"fileWrapperRepresentationOfType: %@ = %@",type,[retval description]);
    // need to figure a way to copy over what we've got here (or a way to avoid explicitly updating it)
    return retval;
#endif
}

- (BOOL) validateProject
{
#ifdef notyet
    NSString *problem = NULL;
    // make sure there are no duplicates in the master file entry list
    for (NSUInteger i=1;i<[myFileList count];i++) {
		id fileEntry1 = [myFileList objectAtIndex: i];
		for (NSUInteger j=0;j<i;j++) {
			id fileEntry2 = [myFileList objectAtIndex: j];
			if ([[fileEntry1 objectForKey: IDEKit_ProjEntryPath] isEqualToString: [fileEntry2 objectForKey: IDEKit_ProjEntryPath]]) {
				NSLog(@"Warning - found file in target entry twice (%@)",[fileEntry1 objectForKey: IDEKit_ProjEntryName]);
				problem = @"Duplicate master file entry";
				// remove the last one
				[myFileList removeObjectAtIndex: j];
				j--;
			}
		}
    }
    for (NSUInteger i=0;i<[myTargetList count];i++) {
		id targetFileList = [[myTargetList objectAtIndex: i] objectForKey:IDEKit_TargetEntryFiles];
		for (NSUInteger j=0;j<[targetFileList count];j++) {
			id fileEntry = [targetFileList objectAtIndex: j];
			id masterEntry = [self projectEntryForFile: [fileEntry objectForKey: IDEKit_ProjEntryPath]];
			if (masterEntry && masterEntry != fileEntry) {
				NSLog(@"Warning - found file in target entry list not same as master entry (%@)",[masterEntry objectForKey: IDEKit_ProjEntryName]);
				if (!problem) problem = @"Inconsistent target entry and master entry";
				// these should be the same, fix it
				[targetFileList replaceObjectAtIndex: j withObject: masterEntry];
			}
		}
    }
    // make sure that there are no duplicates in the file entry
    for (NSUInteger i=0;i<[myTargetList count];i++) {
		id targetFileList = [[myTargetList objectAtIndex: i] objectForKey:IDEKit_TargetEntryFiles];
		for (NSUInteger j=1;j<[targetFileList count];j++) {
			id fileEntry = [targetFileList objectAtIndex: j];
			NSUInteger otherIndex = [targetFileList indexOfObjectIdenticalTo: fileEntry];
			if (otherIndex != j) {
				NSLog(@"Warning - found duplicate file in target entry list (%@)",[fileEntry objectForKey: IDEKit_ProjEntryName]);
				if (!problem) problem = @"Duplicate target entry";
				[targetFileList removeObjectAtIndex: j];
				j--;
			}
		}
    }
    if (problem) {
		NSRunInformationalAlertPanel(@"Minor Project Problem",@"This project had a minor problem (%@) which has been corrected.",NULL,NULL,NULL,problem);
    }
#endif
    return YES;
}

- (void) loadTargetSpecificInfo:(NSFileWrapper *)dirwrapper
{
    NSFileWrapper *fileWrapper = [dirwrapper fileWrappers][IDEKit_BrowserFileName];
    if (fileWrapper) {
#ifdef nodef
		myTargetBrowser = [[NSUnarchiver unarchiveObjectWithData:[fileWrapper regularFileContents]] retain];
#else
		myTargetBrowser = [IDEKit_NamedUnflattener unflattenSerializedData: [fileWrapper regularFileContents] errorDescription: NULL];
#endif
    } else {
		myTargetBrowser = [NSMutableDictionary dictionary];
    }
	
#ifdef notyet
    [myTargetTags autorelease];
    fileWrapper = [[dirwrapper fileWrappers] objectForKey: IDEKit_TagsFileName];
    if (fileWrapper) {
		myTargetTags = [[NSUnarchiver unarchiveObjectWithData:[fileWrapper regularFileContents]] retain];
    } else {
		myTargetTags = [[ETagsFile etagsFile] retain];
    }
#endif
	
    fileWrapper = [dirwrapper fileWrappers][IDEKit_DependsFileName];
    if (fileWrapper) {
#ifdef nodef
		myTargetDepends = [[NSUnarchiver unarchiveObjectWithData:[fileWrapper regularFileContents]] retain];
#else
		myTargetDepends = [IDEKit_NamedUnflattener unflattenSerializedData: [fileWrapper regularFileContents] errorDescription: NULL];
#endif
    } else {
		myTargetDepends = [NSMutableDictionary dictionary];
    }
	
    fileWrapper = [dirwrapper fileWrappers][IDEKit_BreaksFileName];
    if (fileWrapper) {
#ifdef nodef
		myTargetBreakpoints = [[NSUnarchiver unarchiveObjectWithData:[fileWrapper regularFileContents]] retain];
#else
		myTargetBreakpoints = [IDEKit_NamedUnflattener unflattenSerializedData: [fileWrapper regularFileContents] errorDescription: NULL];
#endif
    } else {
		myTargetBreakpoints = [NSMutableArray array];
    }
}


- (BOOL) loadFileWrapperRepresentation:(NSFileWrapper *)wrapper ofType:(NSString *)docType
{
    NSFileWrapper *projectFileWrapper = [wrapper fileWrappers][IDEKit_ProjectPlistFileName];
    BOOL rebuild = NO;
    if (projectFileWrapper) {
#ifdef nodef
		NSDictionary *allData = [NSUnarchiver unarchiveObjectWithData:[projectFileWrapper regularFileContents]];
#else
		NSString *error = NULL;
		NSDictionary *allData = [IDEKit_NamedUnflattener unflattenSerializedData: [projectFileWrapper regularFileContents] errorDescription: &error];
		if (!allData) {
			NSRunInformationalAlertPanel(@"Error loading project",error,NULL,NULL,NULL);
			return NO;
		}
#endif
		
		myFileList = allData[@"IDEKit_FileList"];
		myRootGroup = allData[@"IDEKit_RootGroup"];
		myTargetList = allData[@"IDEKit_TargetList"];
		myCurrentTarget = allData[@"IDEKit_CurrentTarget"];
		switch ([allData[@"IDEKit_Version"] intValue]) {
			default:
				break;
		}
		//if ([[allData objectForKey: @"Version"] intValue] != kVERSION_LATEST) rebuild = YES;
    } else {
		[self createBlankProject];
    }
	
    if (![self validateProject]) {
		NSRunAlertPanel(@"Corrupted project",@"Sorry, but this project is corrupted",NULL,NULL,NULL);
		return NO;
    }
    [self loadTargetSpecificInfo: [wrapper fileWrappers][myCurrentTarget[IDEKit_ProjEntryName]]];
    if (myOutlineView) {
		[myOutlineView reloadData];
    }
    if (myTargetsView) {
		[myTargetsView reloadData];
    }
    if (myLinkOrderView) {
		[myLinkOrderView reloadData];
    }
	
    if (myTargetPopup) {
		// rebuild the popup to reflect the thing
		[self rebuildTargetPopup];
		//[myOutlineView reloadData];
    }
    if (myTabView) {
		[self adjustTabTitles];
    }
	
    if (rebuild) {
#ifdef notyet
		[self makeAllClean: self];
#endif
    }
    return YES;
}

- (void) exportXML: (id) sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setDirectoryURL:[[self fileURL] URLByDeletingLastPathComponent]];
	[panel setNameFieldStringValue:[[[[[self fileURL] absoluteString]lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension: @"xml"]];
    if ([panel runModal] == NSOKButton) {
		[[self projectFileAsXML] writeToURL:[panel URL] atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
}


- (void)addFileToCurrentProject: (id) file
{
    if (![myCurrentTarget[IDEKit_TargetEntryFiles] containsObject: file]) {
		[myCurrentTarget[IDEKit_TargetEntryFiles] addObject: file];
		[self liveSave]; //[self updateChangeCount: NSChangeDone];
    }
}

- (void) removeFileFromCurrentProject: (id) file
{
    if ([myCurrentTarget[IDEKit_TargetEntryFiles] containsObject: file]) {
		[myCurrentTarget[IDEKit_TargetEntryFiles] removeObject: file];
		[self liveSave]; //[self updateChangeCount: NSChangeDone];
    }
}

- (NSArray *)currentlySelectedFiles
{
    NSInteger  rows = [myOutlineView numberOfSelectedRows];
    if (rows) {
		NSMutableArray *retval = [NSMutableArray arrayWithCapacity: rows];
		NSIndexSet *selection = [myOutlineView selectedRowIndexes];
		NSUInteger currentIndex = [selection firstIndex];
		while (currentIndex != NSNotFound) {
			id entry = [myOutlineView itemAtRow: currentIndex];
			if (entry[IDEKit_ProjEntryPath]) {
				// it is a file
				[retval addObject: entry];
			}
			currentIndex = [selection indexGreaterThanIndex:currentIndex];
		}
		if ([retval count] > 0)
			return retval;
		else
			return NULL;
    } else {
		return NULL;
    }
}

- (void)addFileEntryToProject: (NSMutableDictionary *)entry inGroup: (id) item childIndex: (NSInteger) index
{
    // should make sure that we aren't already in here, somewhere
    if ([myFileList containsObject: entry])
		return;
    if (item == NULL) {
		item = myRootGroup;
		index = 0x7ffffffff;
    }
    if (index < -1)
		index = 0;
    if ((NSUInteger)index > [item[IDEKit_ProjEntryGroup] count])
		index = [item[IDEKit_ProjEntryGroup] count];
    [item[IDEKit_ProjEntryGroup] insertObject: entry atIndex: index];
    [myFileList addObject: entry];
    if (item == myRootGroup)
		[myOutlineView reloadData];
    else
		[myOutlineView reloadItem: item reloadChildren: YES];
    [self liveSave]; //[self updateChangeCount: NSChangeDone];
}

- (void)addFilePathToProject: (NSString *)path inGroup: (id) item childIndex: (NSInteger) index
{
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  @(IDEKit_kUIFileEntry), IDEKit_ProjEntryKind,
								  [path lastPathComponent], IDEKit_ProjEntryName,
								  path, IDEKit_ProjEntryPath,
								  NULL];
    NSString *relPath = [path stringRelativeTo: [[[self fileURL] absoluteString]stringByDeletingLastPathComponent] name: @"{Project}" withFlags: IDEKit_kPathRelDontGoToRoot];
    if (relPath) {
		// make it relative to target, if possible
		entry[IDEKit_ProjEntryRelative] = relPath;
    }
	
    [self addFileEntryToProject: entry inGroup: item childIndex: index];
    [self addFileToCurrentProject: entry];
}

#pragma mark Project Level Commands
- (IBAction)addFilesToProject: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: YES];
	[panel setDirectoryURL:nil];
	[panel beginSheetModalForWindow:[myOutlineView window] completionHandler:^(NSInteger result){
		NSArray *filenames = [panel URLs];
		for (NSUInteger i=0;i<[filenames count];i++) {
			NSURL *file = filenames[i];
			// we can edit it for sure
			if ([self canAddFileToProject:[file absoluteString]])
				[self addFilePathToProject:[file absoluteString] inGroup: NULL childIndex: 0];
		}
	}];
}

- (IBAction)createGroupInProject: (id) sender
{
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  @(IDEKit_kUIGroupEntry), IDEKit_ProjEntryKind,
								  @"Group", IDEKit_ProjEntryName,
								  [NSMutableArray arrayWithCapacity: 0], IDEKit_ProjEntryGroup,
								  NULL];
    [self addFileEntryToProject: entry inGroup: NULL childIndex: 0];
}

- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSMutableDictionary *context = (__bridge NSMutableDictionary *)contextInfo;
    if ([context[@"CurrentTargetDefaults"] wasKeyChanged: IDEKit_TargetKind]) { // the "kind" of this target was changed
		[self adjustTabTitles];
		[myLinkOrderView reloadData];
    }
    [self liveSave]; // save any changes we made
}

- (void) projectSettings: (id) sender
{
    id targetDefaults = [self currentTargetDefaults];
    IDEKit_ProjectPreferenceController *prefs = [[IDEKit_ProjectPreferenceController alloc] initWithDefaults: targetDefaults forProject: self];
    NSMutableDictionary *context = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									targetDefaults, @"CurrentTargetDefaults",
									prefs, @"PrefsController",
									NULL];
    [prefs beginSheetModalForWindow: [myOutlineView window] modalDelegate:self
					 didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:)
						contextInfo:(void *)context];
}

#pragma mark To Be Overriden by Client
- (NSArray *)projectSupportedFileExtensions // what sort of files can be put in the project?
{
#ifdef example
    NSMutableArray *types = [NSMutableArray array];
    // add everything we can explicitly get
    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: CHeaderType]];
    //    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: CPPHeaderType]];
    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: CSourceType]];
    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: CPPSourceType]];
    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: PilRCSourceType]];
    [types addObjectsFromArray: [[NSDocumentController sharedDocumentController] fileExtensionsFromType: PalmStaticLibType]];
#endif
    return NULL;
}

- (BOOL) canAddFileToProject: (NSString *)filePath // can this specific file be added?
{
#ifdef example
    id type = [[NSDocumentController sharedDocumentController] typeFromFileExtension: [filePath pathExtension]];
    Class documentClass = [[NSDocumentController sharedDocumentController] documentClassForType: type];
    return (documentClass && documentClass != [self class]);
#endif
    return [[self projectSupportedFileExtensions] containsObject: [filePath pathExtension]];
}

- (BOOL) projectEntryIsLinked: (NSDictionary *)entry // is this project entry shown in "link order"?
{
#ifdef example
    NSString *type = [[NSDocumentController sharedDocumentController] typeFromFileExtension: [[entry objectForKey: IDEKit_ProjEntryName] pathExtension]];
    return ([type isEqualToString: CSourceType] || [type isEqualToString: CPPSourceType] || [type isEqualToString: PalmStaticLibType]);
#endif
    return YES;
}

- (id) projectListColumnAttributeValue: (NSString *)attribute forEntry: (NSDictionary *)entry proto: (id) cel;
{
    if (entry[IDEKit_ProjEntryGroup]) {
		return @""; // nothing for group entry (hopefully)
    } else if (![myCurrentTarget[IDEKit_TargetEntryFiles] containsObject: entry]){
		return @"-"; // not in our current target
    } else {
		return @"N/A";
    }
}

- (id) projectListColumnAttributeProto: (NSString *)attribute forEntry: (NSDictionary *)entryl // to change the cell shown there
{
    return NULL;
}

- (void) projectListColumnSetValue: (id) value forAttribute: (NSString *)attribute forEntry: (NSDictionary *)entry; // to change the cell shown there
{
}

- (NSMutableDictionary *)defaultTargetDefaults // provide default defaults for the target
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
#ifdef example
			[NSNumber numberWithInt: kUISettingsEntry], ProjectEntryKind,
			[[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension: @"prc"], TargetDefaultsTarget,
			[[[self fileName] stringByDeletingPathExtension] lastPathComponent], TargetDefaultsPalmName,
			@"XXXX", TargetDefaultsPalmCreator,
			[NSNumber numberWithBool: YES], TargetDefaultsIsDebug,
			[NSMutableArray arrayWithObjects: @"{Project}",@"{PalmSDK}",NULL], TargetDefaultsIncludeDirs,
			[NSMutableArray array], TargetDefaultsDefines,
			@"",TargetDefaultsPrefixFile,
			@"50",TargetPalmOSVersion,
			[NSMutableArray array], TargetDefaultsExtraLibs,
			[NSNumber numberWithBool: NO], TargetDefaultsRCPAllowEditID,
			[NSNumber numberWithInt: kTargetTypeSingleSegment], TargetDefaultsTargetType,
			[NSMutableArray array], TargetDefaultsTargetSegments,
			[NSNumber numberWithBool: NO], TargetDefaultsForceCpp,
			[NSNumber numberWithInt: 0], TargetDefaultsOptimizationLevel,
			@"English", TargetDefaultsRCPLanguage,
			[NSNumber numberWithInt: 0], TargetDefaultsRCPAutoFont,
			[NSNumber numberWithInt: 1], TargetDefaultsWarningLevel,
			[NSNumber numberWithBool: NO], TargetDefaultsWarningAsErrors,
			[NSNumber numberWithInt: 1], TargetDefaultsPalmModNumber,
			[NSNumber numberWithInt: 1], TargetDefaultsPalmVersionNumber,
			[NSNumber numberWithInt: 0], TargetDefaultsPalmFlags,
#endif
			NULL];
}

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"IDEKit_ProjDocument";
}

@end
