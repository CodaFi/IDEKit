//
//  InfoPListPrefsPane.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon Jan 10 2005.
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

#include "InfoPListPrefsPane.h"
#import "IDEKit_ProjSettings.h"

@implementation InfoPListPrefsPane
- (NSArray *) editedProperties
{
    // we keep entire infoplist in one defaults value
    return [NSArray arrayWithObjects: IDEKit_TargetInfoPList,
	NULL];
}

- (void) didSelect
{
    NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
    // load em up
    if ([infoPList objectForKey: @"CFBundleSignature"]) [myCreator setStringValue: [infoPList objectForKey: @"CFBundleSignature"]];
    //myCustomTypes;
    //myCustomTypesDelete;
    //myDocumentTypes;
    //myDocumentTypesDelete;
    if ([infoPList objectForKey: @"CFBundleExecutable"]) [myExecutable  setStringValue: [infoPList objectForKey: @"CFBundleExecutable"]];
    if ([infoPList objectForKey: @"CFBundleIconFile"]) [myIconFile setStringValue: [infoPList objectForKey: @"CFBundleIconFile"]];
    if ([infoPList objectForKey: @"CFBundleIdentifier"]) [myIdentifier setStringValue: [infoPList objectForKey: @"CFBundleIdentifier"]];
    if ([infoPList objectForKey: @"NSMainNibFile"]) [myMainNibFile setStringValue: [infoPList objectForKey: @"NSMainNibFile"]];
    if ([infoPList objectForKey: @"NSPrincipalClass"]) [myPrincipalClass setStringValue: [infoPList objectForKey: @"NSPrincipalClass"]];
    if ([infoPList objectForKey: @"CFBundlePackageType"]) [myType setStringValue: [infoPList objectForKey: @"CFBundlePackageType"]];
    if ([infoPList objectForKey: @"CFBundleVersion"]) [myVersion setStringValue: [infoPList objectForKey: @"CFBundleVersion"]];
    
}

- (void)mainViewDidLoad
{
    [super mainViewDidLoad];
    NSTableColumn *column = [myDocumentTypes tableColumnWithIdentifier:@"=CFBundleTypeRole"];
    if (column) {
	NSPopUpButtonCell *cell = [[NSPopUpButtonCell alloc] init];
	[cell setMenu:myRolesMenu];
	[cell setBordered:NO];
	[cell setControlSize:NSSmallControlSize];
	[cell setFont: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[column setDataCell:[cell autorelease]];
    }
    column = [myDocumentTypes tableColumnWithIdentifier:@"LSTypeIsPackage"];
    if (column) {
	NSPopUpButtonCell *cell = [[NSButtonCell alloc] initTextCell: @""];
	[cell setControlSize:NSSmallControlSize];
	[cell setButtonType:NSSwitchButton];
	[column setDataCell:[cell autorelease]];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}


- (void) setInfoPListObject: (id) data forKey: (NSString *)key
{
    NSMutableDictionary *infoPList = [[[myDefaults objectForKey: IDEKit_TargetInfoPList] mutableCopy] autorelease];
    if (!infoPList) infoPList = [NSMutableDictionary dictionary];
    [infoPList setObject: data forKey: key];
    [myDefaults setObject: infoPList forKey: IDEKit_TargetInfoPList];
}


- (IBAction)addCustomType:(id)sender
{
}

- (IBAction)addDocumentType:(id)sender
{
    NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
    NSMutableArray *documentTypes = [infoPList objectForKey: @"CFBundleDocumentTypes"];
    if (!documentTypes)
	documentTypes = [NSMutableArray array];
    else
	documentTypes = [[documentTypes mutableCopy] autorelease];
    [documentTypes addObject: [NSDictionary dictionaryWithObjectsAndKeys:
	NULL]];
    [self setInfoPListObject: documentTypes forKey: @"CFBundleDocumentTypes"];
    [myDocumentTypes reloadData];
    [myDocumentTypes selectRow:[documentTypes count]-1 byExtendingSelection:NO];
}

- (IBAction)deleteCustomType:(id)sender
{
}

- (IBAction)deleteDocumentType:(id)sender
{
    int row = [myDocumentTypes selectedRow];
    if (row != NSNotFound) {
	NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
	NSMutableArray *documentTypes = [infoPList objectForKey: @"CFBundleDocumentTypes"];
	// and make a copy of the rows and remove the row there
	documentTypes = [[documentTypes mutableCopy] autorelease];
	[documentTypes removeObjectAtIndex:row];
	[self setInfoPListObject:documentTypes forKey:@"CFBundleDocumentTypes"];
	[myDocumentTypes deselectAll:self];
	[myDocumentTypes reloadData];
    }
}

- (IBAction)setCreator:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundleSignature"];
}

- (IBAction)setExecutable:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundleExecutable"];
}

- (IBAction)setIconFile:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundleIconFile"];
}

- (IBAction)setIdentifier:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundleIdentifier"];
}

- (IBAction)setMainNibFile:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"NSMainNibFile"];
}

- (IBAction)setPrincipalClass:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"NSPrincipalClass"];
}

- (IBAction)setType:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundlePackageType"];
}

- (IBAction)setVersion:(id)sender
{
    [self setInfoPListObject: [sender stringValue] forKey: @"CFBundleVersion"];
}

// data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
    //if ([infoPList objectForKey: @"CFBundleDocumentTypes"] && ![[infoPList objectForKey: @"CFBundleDocumentTypes"] respondsToSelector:@selector(count)])
//	[self setInfoPListObject:[NSArray array] forKey:@"CFBundleDocumentTypes"];
    NSArray *documentTypes = [infoPList objectForKey: @"CFBundleDocumentTypes"];
    //NSLog(@"Document types %@",[documentTypes description]);
    return [documentTypes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
    NSArray *documentTypes = [infoPList objectForKey: @"CFBundleDocumentTypes"];
    //NSLog(@"Document types %@",[documentTypes description]);
    NSDictionary *rowdata = [documentTypes objectAtIndex:row];
    if ([[tableColumn identifier] hasPrefix:@"="]) {
	// menu - get the title
	NSString *title = [rowdata objectForKey: [[tableColumn identifier] substringFromIndex:1]];
	if (title) {
	    return [NSNumber numberWithInt: [[tableColumn dataCell] indexOfItemWithTitle: [rowdata objectForKey: [[tableColumn identifier] substringFromIndex:1]]]];
	} else {
	    // no value set, so we need to set the row, update, and return the first item
	    NSString *firstTitle = [[tableColumn dataCell] itemTitleAtIndex: 0];
	    [self tableView: tableView setObjectValue: firstTitle forTableColumn: tableColumn row: row];
	    return [NSNumber numberWithInt: 0]; // default to the first entry
	}
    } else if ([[tableColumn identifier] hasPrefix:@"*"]) {
	// it's actually an array
	return [[rowdata objectForKey: [[tableColumn identifier] substringFromIndex:1]] componentsJoinedByString:@", "];
    } else {
	return [rowdata objectForKey: [tableColumn identifier]];
    }
    return 0;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary  *infoPList = [myDefaults objectForKey: IDEKit_TargetInfoPList];
    NSMutableArray *documentTypes = [infoPList objectForKey: @"CFBundleDocumentTypes"];
    //NSLog(@"Document types %@",[documentTypes description]);
    NSMutableDictionary *rowdata = [[[documentTypes objectAtIndex:row] mutableCopy] autorelease];
    if ([[tableColumn identifier] hasPrefix:@"="]) {
	// we get an index, we need a string from our menu
	[rowdata setObject: [[tableColumn dataCell] itemTitleAtIndex: [object intValue]] forKey: [[tableColumn identifier] substringFromIndex:1]];
    } else if ([[tableColumn identifier] hasPrefix:@"*"]) {
	// it's actually an array, so build the array - and we need to split at "," and then strip off the white space around it
	NSEnumerator *e = [[object componentsSeparatedByString:@","] objectEnumerator];
	NSMutableArray *array = [NSMutableArray array];
	NSString *entry;
	while ((entry = [e nextObject]) != NULL) {
	    entry = [entry stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	    if ([entry length])
		[array addObject: entry];
	}
	if ([array count]) {
	    [rowdata setObject:array forKey:[[tableColumn identifier] substringFromIndex:1]];
	} else {
	    [rowdata removeObjectForKey:[[tableColumn identifier] substringFromIndex:1]];
	}
    } else {
	if ([object length])
	    [rowdata setObject: object forKey: [tableColumn identifier]];
	else
	    [rowdata removeObjectForKey:[tableColumn identifier]];
    }
    // and make a copy of the rows and insert the new row there
    documentTypes = [[documentTypes mutableCopy] autorelease];
    [documentTypes replaceObjectAtIndex:row withObject:rowdata];
    [self setInfoPListObject:documentTypes forKey:@"CFBundleDocumentTypes"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return NULL;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return NULL;
}

@end
