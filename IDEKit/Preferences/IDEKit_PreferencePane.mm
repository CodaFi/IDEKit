//
//  IDEKit_PrefsPane.mm
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

#import "IDEKit_PreferencePane.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_Delegate.h"


@implementation IDEKit_PreferencePane
- (void) setMyDefaults: (NSUserDefaults *)defaults
{
    [myDefaults autorelease];
    myDefaults = [defaults retain];
}
- (void) dealloc
{
    [myDefaults autorelease];
    [myFilePopupPanel autorelease];
    [myPathVars autorelease];
    [super dealloc];
}
- (void) loadFilePopup: (NSInteger) flags inPanel: (NSSavePanel *)panel
{
    if (flags) {
	if (!myFilePopupPanel) {
	    // the nib is in our framework, not in each panel, so we don't
	    // get the right place when NSBundle looks in NSBundle bundleForClass[self class]
	    id frameworkBundle = [NSBundle bundleForClass: [IDEKit_PreferencePane class]];
	    //NSLog(@"Looking in bundle %@",frameworkBundle);
	    NSString *nibPath = [frameworkBundle pathForResource: @"IDEKit_RelativeFilePicker" ofType: @"nib"];
	    //NSLog(@"nib path %@",nibPath);
	    NSDictionary *nameTable = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
	    if (![NSBundle loadNibFile: nibPath externalNameTable: nameTable withZone: [self zone]])  {
		NSLog(@"Failed to load IDEKit_RelativeFilePicker.nib");
		NSBeep();
	    }
	    [myFilePopupPanel retain]; // we keep this and reuse it (hopefully)
	}
	[panel setAccessoryView: myFilePopupPanel];
	int defaultItem = 0;
	for (NSUInteger i=0;i<[myFilePopup numberOfItems];i++) {
	    id item = [myFilePopup itemAtIndex: i];
	    BOOL enabled = NO;
	    if ([item tag] == 0 || ([item tag] & flags)) { // should it be shown & enabled?
		switch ([item tag]) {
		    case IDEKit_kPickFlagsAbsolute:
			enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeProj:
			if ([myPathVars objectForKey: @"{Project}"]) enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeApp:
			if ([myPathVars objectForKey: [IDEKit appPathName]]) enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeTools:
			if ([myPathVars objectForKey: [IDEKit toolchainPathName]]) enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeSDK:
			if ([myPathVars objectForKey: [IDEKit sdkPathName]]) enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeHome:
			if ([myPathVars objectForKey: @"{Home}"]) enabled = YES;
			break;
		    case IDEKit_kPickFlagsRelativeUser:
			// remove (and rebuild) all the user paths
			[myFilePopup removeItemAtIndex: i];
			i--;
			continue;
			break;
		    default:
			//NSLog(@"Unknown relative popup item %d in %@",[item tag],item);
			break;
		}
	    }	    
	    if (enabled) {
		//NSLog(@"Enabling relative popup item %@",item);
		[item setEnabled: YES];
		if ((([item tag] << IDEKit_kPickFlagDefaultShift) & IDEKit_kPickFlagDefaultMask) == (flags & IDEKit_kPickFlagDefaultMask)) {
		    //defaultItem = i;
		}
	    } else {
		//NSLog(@"Disabling relative popup item %@",item);
		[item setEnabled: NO];
	    }
	}
	// now add in the user paths to the bottom
	NSEnumerator *userKeyEnum = [myPathVars keyEnumerator];
	id key;
	NSArray *builtInPaths = [IDEKit predefinedPathsList];
	while ((key = [userKeyEnum nextObject]) != NULL) {
	    if ([builtInPaths containsObject: key] == NO) {
		[myFilePopup addItemWithTitle: key];
		id item = [myFilePopup itemAtIndex: [myFilePopup numberOfItems]-1];
		[item setTag: IDEKit_kPickFlagsRelativeUser];
		[item setRepresentedObject: key];
		if ((flags & IDEKit_kPickFlagsRelativeUser) == 0)
		    [item setEnabled: NO];
		else
		    [item setEnabled: YES];
	    }
	}

	[myFilePopup selectItemAtIndex: defaultItem];
    }
}
- (NSString *)makeRelative: (NSString *)path
{
    if (myPathVars) {
	switch ([[myFilePopup selectedItem] tag]) {
	    case IDEKit_kPickFlagsAbsolute:
		return path;
		break;
	    case IDEKit_kPickFlagsRelativeProj:
		return [path stringRelativeTo: [myPathVars objectForKey: @"{Project}"] name: @"{Project}"];
		break;
	    case IDEKit_kPickFlagsRelativeApp:
		return [path stringRelativeTo: [myPathVars objectForKey: [IDEKit appPathName]] name: [IDEKit appPathName]];
		break;
	    case IDEKit_kPickFlagsRelativeTools:
		return [path stringRelativeTo: [myPathVars objectForKey: [IDEKit toolchainPathName]] name: [IDEKit toolchainPathName]];
		break;
	    case IDEKit_kPickFlagsRelativeSDK:
		return [path stringRelativeTo: [myPathVars objectForKey: [IDEKit sdkPathName]] name: [IDEKit sdkPathName]];
		break;
	    case IDEKit_kPickFlagsRelativeHome:
		return [path stringRelativeTo: [myPathVars objectForKey: @"{Home}"] name: @"{Home}"];
		break;
	    case IDEKit_kPickFlagsRelativeUser:
		return [path stringRelativeTo: [myPathVars objectForKey: [[myFilePopup selectedItem] representedObject]] name: [[myFilePopup selectedItem] representedObject]];
	    default:
		return path;
	}
    }
    return path; // don't do anything
}
- (void) setPathVars: (NSDictionary *) pathVars
{
    [myPathVars autorelease];
    myPathVars = [pathVars retain];
}

- (NSString *) pickDirectory: (NSInteger) flags
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setResolvesAliases: NO];
    [self loadFilePopup: flags inPanel: panel];
    if ([panel runModalForTypes: NULL] == NSOKButton) {
	NSString *path = [[panel filenames] objectAtIndex: 0];
	return [self makeRelative: path];
    }
    return 0;
}
- (NSString *) pickFile: (NSArray *)types flags: (NSInteger) flags
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: NO];
    [panel setCanChooseFiles: YES];
    [panel setResolvesAliases: NO];
    [self loadFilePopup: flags inPanel: panel];
    if ([panel runModalForTypes: types] == NSOKButton) {
	NSString *path = [[panel filenames] objectAtIndex: 0];
	return [self makeRelative: path];
    }
    return 0;
}
- (NSString *) pickDirectory: (NSInteger) flags fromDirectory: (NSString *)path
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setResolvesAliases: NO];
    [self loadFilePopup: flags inPanel: panel];
    if (myPathVars) path = [path stringByReplacingVars: myPathVars];
    if ([panel runModalForDirectory: [path stringByDeletingLastPathComponent] file: [path lastPathComponent] types: NULL] == NSOKButton) {
	NSString *path = [[panel filenames] objectAtIndex: 0];
	return [self makeRelative: path];
    }
    return 0;
}
- (NSString *) pickFile: (NSArray *)types flags: (NSInteger) flags fromFile: (NSString *)path
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: NO];
    [panel setCanChooseFiles: YES];
    [panel setResolvesAliases: NO];
    [self loadFilePopup: flags inPanel: panel];
    if (myPathVars) path = [path stringByReplacingVars: myPathVars];
    if ([panel runModalForDirectory: [path stringByDeletingLastPathComponent] file: [path lastPathComponent] types: types] == NSOKButton) {
	NSString *path = [[panel filenames] objectAtIndex: 0];
	return [self makeRelative: path];
    }
    return 0;
}
- (NSString *) pickNewFile: (NSString *)type flags: (NSInteger) flags fromFile: (NSString *)path
{
    NSSavePanel *panel = [NSSavePanel savePanel];
//    [panel setPrompt: @"Export"];
//    [panel setTitle: @"Export panel settings"];
    [panel setRequiredFileType: type];
    [self loadFilePopup: flags inPanel: panel];
    if (myPathVars) path = [path stringByReplacingVars: myPathVars];
    if ([panel runModal] == NSOKButton) {
	NSString *path = [panel filename];
	return [self makeRelative: path];
    }
    return NULL;
}

- (NSArray *) editedProperties
{
    return [NSArray array];
}

- (NSDictionary *) exportPanel
{
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSArray *properties = [self editedProperties];
    for (NSUInteger i=0;i<[properties count];i++) {
	id key = [properties objectAtIndex: i];
	if ([myDefaults objectForKey: key]) {
	    [retval setObject: [myDefaults objectForKey: key] forKey: key];
	}
    }
    return retval;
}

- (void) importPanel: (NSDictionary *) data
{
    NSArray *properties = [self editedProperties];
    for (NSUInteger i=0;i<[properties count];i++) {
	id key = [properties objectAtIndex: i];
	if ([data objectForKey: key]) {
	    [myDefaults setObject: [data objectForKey: key] forKey: key];
	}
    }
    [self didSelect]; // reload our values
}

@end
