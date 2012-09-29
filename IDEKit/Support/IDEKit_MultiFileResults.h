//
//  IDEKit_MultiFileResults.h
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

#import <Cocoa/Cocoa.h>
#import "IDEKit_SrcEditView.h"

@class IDEKit_SrcEditView;
/* IDEKit_MultiFileResult is used to handle displaying something like multiple file find results or
    build results.  The idea is that there is an array which contains each row of the table.  There are several
    special keys for the dictionaries that make each row:
	IDEKit_MultiFileResultIcon - the name of an image to use as an icon for that row (optional)
	IDEKit_MultiFileResultID - The file/buffer unique id string (so we can display results from unsaved files)
	IDEKit_MultiFileResultPath - The file/buffer path (can be used instead of unique id)
	IDEKit_MultiFileResultLine - What line of the file
	IDEKit_MultiFileResultRange - The range of the selection (optional)
	IDEKit_MultiFileResultText - Any message (optional)
    It then displays a table with an icon column (which is optional), and a results column.  The icon either
    displays the icon key for that entry, or the icon for the file.  The results column becomes populated with
    either 2 or 3 rows of text (make sure to make your row large enough for that), containing the file name
    path, the line number, a small sample of the text, and any message.  The table can have other columns as
    well (which will return corresponding key for the entry).

    IDEKit_MultiFileResult then mangages a snapshot of the thing, as well as handling double clicking.
*/

extern NSString *IDEKit_MultiFileResultIcon; // use to specific an icon image (assuming column identifier exists)
extern NSString *IDEKit_MultiFileResultText; // whatever the text message is
extern NSString *IDEKit_MultiFileResultID;
extern NSString *IDEKit_MultiFileResultPath;
extern NSString *IDEKit_MultiFileResultLine;
extern NSString *IDEKit_MultiFileResultRange;

@interface IDEKit_MultiFileResults : NSWindowController <IDEKit_SrcEditContext>{
    IBOutlet IDEKit_SrcEditView *myPreview;
    IBOutlet NSTableView *myTable;
    NSArray *myResults;
    NSMutableDictionary *mySnapshots;
    NSMutableArray *myCachedResultStrings;
    NSString *myPreviewFileName;
}
+ (id) showResults: (NSArray *)results;
- (id)initWithWindowNibName:(NSString *)windowNibName;	// will override to look in appropriate places
- (void) setResults: (NSArray *)results;
- (IBAction) showSelectedResult: (id) sender;
- (IBAction) openSelectedResult: (id) sender;

@end

@interface IDEKit_FileBrowser : IDEKit_MultiFileResults
@end