//
//  IDEKit_MultiFileResults.mm
//  IDEKit
//
//  Created by Glenn Andreas on 10/1/04.
//  Copyright 2004 by Glenn Andreas.
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

#import "IDEKit_MultiFileResults.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_SnapshotFile.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_SrcEditViewFolding.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_SourceFingerprint.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_SrcScroller.h"
#import <AppKit/AppKit.h>
#import "IDEKit_TextView.h"

NSString *IDEKit_MultiFileResultIcon = @"IDEKit_MultiFileResultIcon"; // use to specific an icon image (assuming column identifier exists)
NSString *IDEKit_MultiFileResultText = @"IDEKit_MultiFileResultText"; // whatever the text message is
NSString *IDEKit_MultiFileResultID = @"IDEKit_MultiFileResultID";
NSString *IDEKit_MultiFileResultPath = @"IDEKit_MultiFileResultPath";
NSString *IDEKit_MultiFileResultLine = @"IDEKit_MultiFileResultLine";
NSString *IDEKit_MultiFileResultRange = @"IDEKit_MultiFileResultRange";


@implementation IDEKit_MultiFileResults
+ (NSString *) defaultNibName
{
    return @"IDEKit_MultiFileResult";
}

+ (id) showResults: (NSArray *)results
{
    id display = [[self alloc] initWithWindowNibName: [self defaultNibName]];
    [display setResults: results];
    [display showWindow: self];
    return display;
}
- (id)initWithWindowNibName:(NSString *)windowNibName;	// will override to look in appropriate places
{
    // look in main bundle before  class owners bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:windowNibName ofType:@"nib"];
    if ([path length]) {
	return [self initWithWindowNibPath: path owner: self];
    } else {
	return [super initWithWindowNibName: windowNibName];
    }
}
- (void)windowDidLoad
{
    [super windowDidLoad];
    NSTableColumn *iconColumn = [myTable tableColumnWithIdentifier: @"icon"];
    if (iconColumn) {
	id imageCell = [[NSImageCell alloc] initImageCell: NULL];
	[imageCell setEditable: NO];
	[imageCell setImageAlignment: NSImageAlignCenter];
	[imageCell setImageScaling: NSScaleNone];
	[iconColumn setDataCell: imageCell];
    }
    [myTable setDoubleAction:@selector(openSelectedResult:)];
    [myPreview setContext: self];
    // no splitters - we've only got one now
    IDEKit_SrcScroller *scroller = [myPreview allScrollViews][0];
    [scroller setShowFlags: [scroller showFlags] & (~(IDEKit_kShowSplitter | IDEKit_kShowUnsplitter))];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [myResults count];
}
- (IDEKit_SnapshotFile *) snapshotForEntry: (NSDictionary *)entry
{
    // snapshots are stored by fileID or path
    NSString *fileID = entry[IDEKit_MultiFileResultID];
    if (mySnapshots[fileID]) {
	return mySnapshots[fileID];
    }
    return mySnapshots[entry[IDEKit_MultiFileResultPath]];
}

- (NSString *) pathForEntry: (NSDictionary *)entry
{
    NSString *fileID = entry[IDEKit_MultiFileResultID];
    NSString *path = NULL;
    if (fileID) {
	path = [[IDEKit_UniqueFileIDManager sharedFileIDManager] pathForFileID: [IDEKit_UniqueID uniqueIDFromString: fileID]];
    }
    if (!path) {
	path = entry[IDEKit_MultiFileResultPath];
    }
    if (!path && fileID) {
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:[IDEKit_UniqueID uniqueIDFromString: fileID]];
	if (view) {
	    path = [[view context] fileNameForSrcEditView: view];
	}
    }
    return path;
}

- (NSAttributedString *) resultForEntry: (NSDictionary *)entry
{
    NSString *path = [self pathForEntry: entry];
    if (!path)
	path = @"(Untitled)";
    IDEKit_SnapshotFile *snapshot = [self snapshotForEntry: entry];
    int lineNum = [entry[IDEKit_MultiFileResultLine] intValue];
    NSString *line = [[snapshot source] substringWithRange: [[snapshot source] nthLineRange: lineNum]];
    NSMutableAttributedString *retval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"Line #%d, File: %@\n",lineNum,path] attributes: @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]}];
    [retval appendAttributedString:[[NSAttributedString alloc] initWithString: line attributes: [myPreview->myTextView typingAttributes]]];
    return retval;
}

- (void) setResults: (NSArray *)results
{
    //NSLog(@"Results = %@",results);
    myResults = [results copy];
    // build the snapshots
    mySnapshots = [NSMutableDictionary dictionary];
    myCachedResultStrings = [NSMutableArray arrayWithCapacity: [results count]];
    NSEnumerator *e = [myResults objectEnumerator];
    NSDictionary *entry;
    while ((entry = [e nextObject]) != NULL) {
	IDEKit_UniqueID *fileID = [IDEKit_UniqueID uniqueIDFromString:entry[IDEKit_MultiFileResultID]];
	
	if ([IDEKit_SrcEditView srcEditViewAssociatedWith:fileID]) { // this is a buffer
	    mySnapshots[[fileID stringValue]] = [IDEKit_SnapshotFile snapshotFileWithBufferID: fileID];
	} else {
	    NSString *path = [self pathForEntry: entry];
	    if (path) {
		mySnapshots[path] = [IDEKit_SnapshotFile snapshotFileWithExternalFile: path];
	    }
	}
	[myCachedResultStrings addObject: [NSNull null]];
    }
    [myTable reloadData];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *entry = myResults[row];
    if ([[tableColumn identifier] isEqualToString: @"icon"]) {
	NSString *icon = entry[IDEKit_MultiFileResultIcon];
	if (icon)
	    return [NSImage imageNamed:icon];
	// otherwise get the icon for the file
	NSString *path = [self pathForEntry: entry];
	if (path) {
	    return [[NSWorkspace sharedWorkspace] iconForFile:path];
	}
	return NULL;
    } else if ([[tableColumn identifier] isEqualToString: @"result"]) {
	id retval = myCachedResultStrings[row];
	if (retval == [NSNull null]) {
	    retval = [self resultForEntry: entry];
	    myCachedResultStrings[row] = retval;
	}
	return retval;
    } else {
	return entry[[tableColumn identifier]];
    }
}

- (void) showSelectedResult: (id) sender
{
    NSDictionary *entry = myResults[[sender selectedRow]];
    if (entry) {
	myPreviewFileName = [self pathForEntry:entry];
	IDEKit_SnapshotFile *snapshot = [self snapshotForEntry:entry];
	[myPreview setDisplaysSnapshot: snapshot];
	// should go through mapping here?  Not needed
	//[myPreview setSelect: [[entry objectForKey: IDEKit_MultiFileResultRange] rangeValue];
	[myPreview selectNthLine: [entry[IDEKit_MultiFileResultLine] intValue]];
    }
}

- (IBAction) openSelectedResult: (id) sender
{
    NSDictionary *entry = myResults[[sender selectedRow]];
    if (entry) {
	IDEKit_UniqueID *fileID = [IDEKit_UniqueID uniqueIDFromString:entry[IDEKit_MultiFileResultID]];
	IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:fileID];
	if (!view) {
	    // make the document and open it
	    id controller = [NSDocumentController sharedDocumentController];
	    id document = [controller openDocumentWithContentsOfFile: [self pathForEntry: entry] display: YES];
	    if (document) {
		[controller addDocument: document];
		view = [IDEKit_SrcEditView srcEditViewAssociatedWith:fileID]; // file now open
	    }
	}
	if (view) {
	    // should go through mapping
	    [[view window] makeKeyAndOrderFront:self];
	    [[view window] makeFirstResponder:view];
	    IDEKit_SourceMapping *mapping = [[IDEKit_SourceMapping alloc] initMappingFrom: [[self snapshotForEntry: entry] fingerprint] to: [view fingerprint]];
	    NSRange range = [entry[IDEKit_MultiFileResultRange] rangeValue];
	    if (![mapping isTrivial]) {
		NSUInteger endRange = range.location + range.length;
		range.location = [mapping mapForward:range.location];
		endRange = [mapping mapForward: endRange];
		if (endRange < range.location)
		    range.length = 0;
		else
		    range.length = endRange - range.location;
	    }
	    [view->myTextView setSelectedRange: range];
	    [view->myTextView scrollRangeToVisible: range];
	} else {
	    NSBeep();
	}
    }
}

// SrcEditView context
- (BOOL) canEditForSrcEditView: (IDEKit_SrcEditView *) view
{
    return NO;
}
- (Class) currentLanguageClassForSrcEditView: (IDEKit_SrcEditView *) view;
{
    return [IDEKit languageFromFileName: myPreviewFileName withContents: [view string]];
}

- (NSString *) fileNameForSrcEditView: (IDEKit_SrcEditView *) view;
{
    return myPreviewFileName;
}

@end


@implementation IDEKit_FileBrowser
- (void)windowDidLoad
{
    [super windowDidLoad];
    [myTable setRowHeight:18];
    NSTableColumn *iconColumn = [myTable tableColumnWithIdentifier: @"icon"];
    if (iconColumn) {
	[[iconColumn dataCell] setImageScaling: NSScaleProportionally];
    }
}
- (NSAttributedString *) resultForEntry: (NSDictionary *)entry
{
    // don't show line
    NSString *path = [self pathForEntry: entry];
    if (!path)
	path = @"(Untitled)";
    NSMutableAttributedString *retval = [[NSMutableAttributedString alloc] initWithString:path attributes: @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]}];
    return retval;
}

- (void) showSelectedResult: (id) sender
{
    NSDictionary *entry = myResults[[sender selectedRow]];
    if (entry) {
	myPreviewFileName = [self pathForEntry:entry];
	IDEKit_SnapshotFile *snapshot = [self snapshotForEntry:entry];
	[myPreview setDisplaysSnapshot: snapshot];
    }
}

@end