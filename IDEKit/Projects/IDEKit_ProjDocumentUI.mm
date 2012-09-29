//
//  IDEKit_ProjDocumentUI.mm
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

#import "IDEKit_ProjDocumentUI.h"

#import "IDEKit_ProjDocumentPaths.h"
#import "IDEKit_ProjSettings.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_PreferencePane.h"
#import "IDEKit_Delegate.h"

static NSString *PrivateDragPboardType = @"PrivateDragPboardType";


@implementation NSMutableArray(MovingItems)
- (void) moveItemAt: (NSUInteger) oldIndex to: (NSUInteger) newIndex
{
    if (oldIndex == NSNotFound)
		return; // not in our list
    id  entry = [self objectAtIndex: oldIndex];
    //NSLog(@"Moving %@ from %d to %d",[entry description],oldIndex,index);
    if (newIndex > [self count] || newIndex == NSNotFound)
		newIndex = [self count]; // put at end of list
    if (oldIndex == newIndex)
		return; // already there
    [entry retain]; // so we don't lose it
    if (newIndex < oldIndex) {
		// move up in the list
		[self removeObjectAtIndex: oldIndex];
		[self insertObject: entry atIndex: newIndex];
    } else {
		// move down in the list
		[self removeObjectAtIndex: oldIndex];
		[self insertObject: entry atIndex: newIndex-1]; // since we were removed, index is smaller
    }
    [entry release];
}
@end

@implementation NSOutlineView(Parentage)
- (id) parentItemForItem: (id) item;
{
    if (item == NULL)
		return NULL;
    int row = [self rowForItem: item];
    int level = [self levelForRow: row];
    if (level == 0)
		return NULL; // at root already
    row--;
    while (row > 0) {
		if ([self levelForRow: row] == level - 1)
			break;
		row--;
    }
    return [self itemAtRow: row];
}
@end


@implementation IDEKit_ProjDocument(UI)
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    // save and revert are not valid for us
    if ([menuItem action] == @selector(saveDocument:) ||
		[menuItem action] == @selector(revertDocumentToSaved:)) {
		return NO;
    }
#ifdef nodef
    if ([menuItem action] == @selector(createGroupInProject:)) {
		if ([[[myTabView selectedTabViewItem] identifier] isEqualToString: @"fileorder"]) {
			[menuItem setTitle: @"Create Group..."];
			return YES;
		}
		int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
		switch (targetType) {
			case kTargetTypeSingleSegment: {
				//[menuItem setTitle: @"Create Segment..."];
				return NO;
				break;
			}
			case kTargetTypeMultiSegment: {
				[menuItem setTitle: @"Create Group..."];
				return YES;
				break;
			}
			default:
				return NO;
		}
    }
#endif
    if ([menuItem action] == @selector(delete:)) {
		if ([[[myTabView selectedTabViewItem] identifier] isEqualToString: @"targets"]) {
			if ([myTargetsView numberOfSelectedRows]) {
				id sel = [myTargetsView itemAtRow: [myTargetsView selectedRow]];
				if ([sel uiKind] == IDEKit_kUIDependantEntry) {
					return YES;
				}
				if ([sel uiKind] == IDEKit_kUITargetEntry) {
					return YES;
				}
			}
		}
		if ([[[myTabView selectedTabViewItem] identifier] isEqualToString: @"fileorder"]) {
			if ([myOutlineView numberOfSelectedRows]) {
				id sel = [myOutlineView itemAtRow: [myOutlineView selectedRow]];
				if ([sel uiKind] == IDEKit_kUIFileEntry) {
					return YES;
				}
				if ([sel uiKind] == IDEKit_kUIGroupEntry) {
					return YES;
				}
			}
		}
		return NO;
    }
    return [super validateMenuItem: menuItem];
}

- (void) removeEntryFromProject: (id) entry parent: (id) parent
{
    switch ([entry uiKind]) {
		case IDEKit_kUIFileEntry: {
			// remove us from our group list and all targets
			for (NSUInteger i=0;i<[myTargetList count];i++) {
				id target = [myTargetList objectAtIndex: i];
				// remove from the file entry
				if ([[target objectForKey: IDEKit_TargetEntryFiles] containsObject: entry]) {
					[[target objectForKey: IDEKit_TargetEntryFiles] removeObjectIdenticalTo: entry];
				}
				// remove from the breakpoints
				if ([[target objectForKey: IDEKit_TargetBreakPoints] objectForKey: [entry objectForKey: IDEKit_ProjEntryName]]) {
					[[target objectForKey: IDEKit_TargetBreakPoints] removeObjectForKey: [entry objectForKey: IDEKit_ProjEntryName]];
				}
			}
			// now the group list
			[[parent objectForKey: IDEKit_ProjEntryGroup] removeObjectIdenticalTo: entry];
			// hopefully that's all the references
			break;
		}
		case IDEKit_kUIGroupEntry: {
			// remove everything in us recursively, then remove us
			id groupList = [entry objectForKey: IDEKit_ProjEntryGroup];
			while ([groupList count]) {
				// as we remove them from us, this list gets smaller
				[self removeEntryFromProject: [groupList objectAtIndex: 0] parent: entry];
			}
			[[parent objectForKey: IDEKit_ProjEntryGroup] removeObjectIdenticalTo: entry];
			break;
		}
		case IDEKit_kUITargetEntry: {
			// remove us from target dependancies
			for (NSUInteger i=0;i<[myTargetList count];i++) {
				id target = [myTargetList objectAtIndex: i];
				if (target == entry)
					continue; // skip this
				id dependancies = [target objectForKey: IDEKit_TargetDependsOnTargets];
				for (NSUInteger j=0;j<[dependancies count];j++) {
					id dependancy = [dependancies objectAtIndex: j];
					if ([dependancy objectForKey: IDEKit_DependantOnTarget] == entry) {
						// remove this dependancy
						[dependancies removeObjectAtIndex: j];
						j--;
					}
				}
			}
			// remove us from the target list
			[myTargetList removeObjectIdenticalTo: entry];
			// update current target to not be us
			if (myCurrentTarget == entry) {
				if ([myTargetList count]) {
					myCurrentTarget = [myTargetList objectAtIndex: 0];
				} else {
					// removed last target - might be bad?
					myCurrentTarget = NULL;
				}
			}
			break;
		}
		default:
			NSAssert1(0,@"Removing unknown entry from IDEKit_Proj %@",[entry description]);
    }
}

- (void) delete: (id) sender
{
    if ([[[myTabView selectedTabViewItem] identifier] isEqualToString: @"targets"]) {
		if ([myTargetsView numberOfSelectedRows]) {
			int selRow = [myTargetsView selectedRow];
			id sel = [myTargetsView itemAtRow: selRow];
			if ([sel uiKind] == IDEKit_kUIDependantEntry) {
				// we are removing a dependancy
#ifdef nodef
				while ([myTargetsView levelForRow: selRow] != 0) selRow--;
				// find the parent
				id parent = [myTargetsView itemAtRow: selRow];
#else
				id parent = [myTargetsView parentItemForItem: sel];
#endif
				[[parent objectForKey: IDEKit_TargetDependsOnTargets] removeObjectIdenticalTo: sel];
				[self liveSave];
			} else if ([sel uiKind] == IDEKit_kUITargetEntry) {
				if ([myTargetList count] == 1) {
					NSRunInformationalAlertPanel(@"Can't remove target",@"You can't remove the last target %@ from the project",NULL,NULL,NULL,[sel objectForKey: IDEKit_ProjEntryName]);
				} else if (NSRunCriticalAlertPanel(@"Remove target",@"Are you sure you want to remove the target %@ from the project?",@"OK",@"Cancel",NULL,[sel objectForKey: IDEKit_ProjEntryName]) == NSAlertDefaultReturn) {
					[self removeEntryFromProject: sel parent: NULL];
					[self liveSave];
				}
			}
		}
    }
    if ([[[myTabView selectedTabViewItem] identifier] isEqualToString: @"fileorder"]) {
		if ([myOutlineView numberOfSelectedRows]) {
			int selRow = [myOutlineView selectedRow];
			id sel = [myOutlineView itemAtRow: selRow];
			int myIndent = [myOutlineView levelForRow: selRow];
			// find the parent
			id parent;
			if (myIndent == 0) {
				parent = myRootGroup;
			} else {
#ifdef nodef
				while ([myOutlineView levelForRow: selRow] >= myIndent) selRow--;
				parent = [myOutlineView itemAtRow: selRow];
#else
				parent = [myOutlineView parentItemForItem: sel];
#endif
			}
			
			if ([sel uiKind] == IDEKit_kUIFileEntry) {
				if (NSRunCriticalAlertPanel(@"Remove file",@"Are you sure you want to remove the file %@ from the project?",@"OK",@"Cancel",NULL,[sel objectForKey: IDEKit_ProjEntryName]) == NSAlertDefaultReturn) {
					[self removeEntryFromProject: sel parent: parent];
					[self liveSave];
				}
			} else if ([sel uiKind] == IDEKit_kUIGroupEntry) {
				if ([[sel objectForKey: IDEKit_ProjEntryGroup] count] == 0) {
					// easy
					[self removeEntryFromProject: sel parent: parent];
					[self liveSave];
				} else {
					if (NSRunCriticalAlertPanel(@"Remove group & files?",@"Are you sure you want to remove the group %@ and all it's files from the project?",@"OK",@"Cancel",NULL,[sel objectForKey: IDEKit_ProjEntryName]) == NSAlertDefaultReturn) {
						[self removeEntryFromProject: sel parent: parent];
						[self liveSave];
					}
				}
			}
		}
    }
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"PrXDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.
    // so we can drag tokens onto us
    [myOutlineView registerForDraggedTypes: [NSArray arrayWithObjects:
											 NSFilenamesPboardType,
											 PrivateDragPboardType,
											 NULL]];
    [myLinkOrderView registerForDraggedTypes: [NSArray arrayWithObjects:
											   PrivateDragPboardType,
											   NULL]];
    [myTargetsView registerForDraggedTypes: [NSArray arrayWithObjects:
											 PrivateDragPboardType,
											 NULL]];
    // Don't expand outline column, since it pushes off size column
    [myOutlineView setAutoresizesOutlineColumn: NO];
    [myOutlineView setAutoresizesAllColumnsToFit: YES];
    // put a checkbox in the first col
    NSTableColumn *col;
    id checkboxProto = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
    [checkboxProto setEditable: YES];
    [checkboxProto setButtonType: NSSwitchButton];
    [checkboxProto setImagePosition: NSImageOnly];
    [checkboxProto setControlSize: NSSmallControlSize];
    col = [myOutlineView tableColumnWithIdentifier: @"Check"];
    [col setDataCell: checkboxProto];
#ifdef nomore
    [self addWindowController: [[NSWindowController alloc] initWithWindow: myMakeWindow]];
#endif
    //    [self addWindowController: [[NSWindowController alloc] initWithWindow: myDebugWindow]];
    [myOutlineView setDoubleAction: @selector(doubleClickList:)];
    [myOutlineView setTarget: self];
    [myOutlineView setRowHeight: 17.0];
    col = [myOutlineView tableColumnWithIdentifier: @"File"];
    id aCell = [[[NSBrowserCell alloc] initTextCell: @""] autorelease];
    [col setDataCell: aCell];
    [aCell setMenu: myFileEntryCMenu];
    [aCell setLeaf: YES];
    [aCell setEditable: YES];
	
    //    [myLinkOrderView setDoubleAction: @selector(doubleClickList:)];
    if (myTargetList) {
		// rebuild the popup to reflect the thing
		[self rebuildTargetPopup];
		//[myOutlineView reloadData];
		[myOutlineView reloadData];
		[myTargetsView reloadData];
		[myLinkOrderView reloadData];
    }
}

- (void) adjustTabTitles
{
#ifdef nodef
    int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
    switch (targetType) {
		case kTargetTypeSingleSegment: {
			[[myTabView tabViewItemAtIndex: [myTabView indexOfTabViewItemWithIdentifier: @"linkorder"]] setLabel: @"Link Order"];
			break;
		}
		case kTargetTypeMultiSegment: {
			[[myTabView tabViewItemAtIndex: [myTabView indexOfTabViewItemWithIdentifier: @"linkorder"]] setLabel: @"Segments"];
			break;
		}
    }
#endif
}

- (NSString *) isTargetNameValid: (NSString *)name
{
    for (NSUInteger i=0;i<[myTargetList count];i++) {
		id entry = [myTargetList objectAtIndex: i];
		if ([name isEqualToString: [entry objectForKey: IDEKit_ProjEntryName]]) {
			return @"That target name already exists - please pick another";
		}
    }
    if ([name length] == 0) {
		return @"Need to specify a target name";
    }
    return NULL;
}

- (IBAction) doMakeNewTarget: (id) sender
{
    NSString *err = [self isTargetNameValid: [myNewTargetName stringValue]];
    if (err) {
		NSRunAlertPanel(@"Bad Target Name",err,NULL,NULL,NULL);
    } else {
		[NSApp endSheet: myNewTargetSheet returnCode: NSRunStoppedResponse];
    }
}
- (IBAction) dontMakeNewTarget: (id) sender
{
    [NSApp endSheet: myNewTargetSheet returnCode: NSRunAbortedResponse];
}

- (void) switchToTarget: (id) newTarget
{
    if (newTarget == myCurrentTarget)
		return;
    [self liveSaveTarget]; // make any changes to the current target
    myCurrentTarget = newTarget;
    [self loadTargetSpecificInfo: [[[NSFileWrapper alloc] initWithPath: [self currentTargetDir]]autorelease]]; // load the specifics
    [self liveSave];
}
- (void)newTargetSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSRunStoppedResponse) {
		// create the new target
		id clone = [[myNewTargetClone selectedItem] representedObject];
		id newTarget = NULL;
		if (clone) {
			newTarget = [NSMutableDictionary dictionaryWithDictionary: clone];
			[newTarget setObject: [myNewTargetName stringValue] forKey: IDEKit_ProjEntryName];
			newTarget = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInt: IDEKit_kUITargetEntry], IDEKit_ProjEntryKind,
						 [myNewTargetName stringValue], IDEKit_ProjEntryName,
						 [NSMutableArray arrayWithArray: [clone objectForKey: IDEKit_TargetEntryFiles]], IDEKit_TargetEntryFiles,
						 [NSMutableArray arrayWithArray: [clone objectForKey: IDEKit_TargetDependsOnTargets]], IDEKit_TargetDependsOnTargets,
						 NULL];
		} else {
			newTarget = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInt: IDEKit_kUITargetEntry], IDEKit_ProjEntryKind,
						 [myNewTargetName stringValue], IDEKit_ProjEntryName,
						 [NSMutableArray arrayWithCapacity: 0], IDEKit_TargetEntryFiles,
						 [NSMutableArray arrayWithCapacity: 0], IDEKit_TargetDependsOnTargets,
						 NULL];
		}
		[myTargetList addObject: newTarget];
		[self switchToTarget: newTarget];
    }
    [sheet orderOut: self];
}

- (IBAction) newTarget: (id) sender
{
    [self buildMenuOfTargets: [myNewTargetClone menu] skipItems: 2 command: NULL target: NULL];
    [NSApp beginSheet: myNewTargetSheet modalForWindow: [myTabView window] modalDelegate:self
	   didEndSelector:@selector(newTargetSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (IBAction) changeCurrentTarget: (id) sender
{
    //NSLog(@"Changing to target %@",[[sender representedObject] description]);
    [self switchToTarget: [sender representedObject]];
}

- (void) rebuildTargetPopup
{
    //NSLog(@"rebuildTargetPopup %@",myTargetPopup);
    [myTargetPopup removeAllItems];
    [self buildMenuOfTargets: [myTargetPopup menu] skipItems: 0 command: @selector(changeCurrentTarget:) target: self];
    int cur2 = [myTargetPopup indexOfItemWithRepresentedObject: myCurrentTarget];
    if (cur2 == -1) {
		//NSLog(@"Couldn't find current target in popup");
    } else {
		[myTargetPopup selectItemAtIndex: cur2];
    }
    //if (cur >= 0)
    //[myTargetPopup selectItemAtIndex: cur];
}

- (NSInteger) buildMenuOfTargets: (NSMenu *)menu skipItems: (NSInteger) skip command: (SEL) sel target: (id) target;
{
    // remove the old
    for (int i=skip;i<[menu numberOfItems];i++) {
		[menu removeItemAtIndex: 0];
    }
    int retval = skip-1;
    // add the new
    for (NSUInteger i=0;i<[myTargetList count];i++) {
		id entry = [myTargetList objectAtIndex: i];
		if (entry == myCurrentTarget)
			retval = i;
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: [entry objectForKey: IDEKit_ProjEntryName] action: sel keyEquivalent: @""] autorelease];
		[item setTarget: target];
		[item setRepresentedObject: entry];
		[menu addItem: item];
		//NSLog(@"Added target menu %@",item);
    }
    return retval;
}

- (IBAction) singleClickList: (id) sender
{
}

- (IBAction) doubleClickList: (id) sender
{
    NSArray *targets = [self currentlySelectedFiles];
    for (NSUInteger i=0;i<[targets count];i++) {
		NSString *path = [[targets objectAtIndex: i] objectForKey: IDEKit_ProjEntryPath];
		if (path) {
			if ([[NSDocumentController  sharedDocumentController] typeFromFileExtension: [path pathExtension]]) { // we can open it
				[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile: path display: YES];
			} else {
				[[NSWorkspace sharedWorkspace] openFile: path];
			}
		}
    }
}

- (NSUInteger)targetFileIndexForEntry: (NSDictionary *)entry
{
    NSArray *targetList = [myCurrentTarget objectForKey: IDEKit_TargetEntryFiles];
#ifdef nodef
    for (NSUInteger i=0;i<[targetList count];i++) {
		if ([[[targetList objectAtIndex: i] objectForKey: IDEKit_ProjEntryName] isEqualToString: [entry objectForKey: IDEKit_ProjEntryName]])
			return i;
    }
    return NSNotFound;
#else
    return [targetList indexOfObjectIdenticalTo: entry];
#endif
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == myLinkOrderView) {
		//int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
		NSArray *targetList = [myCurrentTarget objectForKey: IDEKit_TargetEntryFiles];
		//switch (targetType) {
		//case kTargetTypeSingleSegment: {
		int count = 0;
		for (NSUInteger i=0;i<[targetList count];i++) {
			NSDictionary *entry = [targetList objectAtIndex: i];
			if ([self projectEntryIsLinked: entry]) {
				if (count == index)
					return entry;
				count++;
			}
		}
		return NULL;
		//}
		//}
		return NULL;
    } else if (outlineView == myTargetsView) {
		//NSLog(@"Getting target #%d",index);
		if (item == NULL) {
			// return the entire target
			return [myTargetList objectAtIndex: index];
		} else {
			// return the dict
			return [[item objectForKey: IDEKit_TargetDependsOnTargets] objectAtIndex: index];
		}
    } else  if (outlineView == myOutlineView) {
		if (item == NULL)
			item = myRootGroup;
		return [[item objectForKey: IDEKit_ProjEntryGroup] objectAtIndex: index];
    }
    return NULL;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (outlineView == myLinkOrderView) {
		//int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
		//NSArray *targetList = [myCurrentTarget objectForKey: IDEKit_TargetEntryFiles];
		//switch (targetType) {
		//case kTargetTypeSingleSegment: {
		return NO;
		//break;
		//}
		//}
		return NO;
    } else if (outlineView == myTargetsView) {
		if (item == NULL)
			return YES;
		//if ([outlineView levelForItem: item] < 1)
		//    return YES;
		if ([item uiKind] == IDEKit_kUIDependantEntry)
			return NO;
		return YES;
		return NO;
    } else  if (outlineView == myOutlineView) {
		if (item == NULL)
			return YES;
		if ([item objectForKey: IDEKit_ProjEntryGroup] != NULL)
			return YES;
		return NO;
    }
    return NO;
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (outlineView == myLinkOrderView) {
		//int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
		NSArray *targetList = [myCurrentTarget objectForKey: IDEKit_TargetEntryFiles];
		//switch (targetType) {
		//case kTargetTypeSingleSegment: {
		if (item == NULL) {
			int count = 0;
			for (NSUInteger i=0;i<[targetList count];i++) {
				NSDictionary *entry = [targetList objectAtIndex: i];
				if ([self projectEntryIsLinked: entry])
					count++;
			}
			return count;
		} else
			return 0;
		//break;
		//}
		//}
		return NULL;
    } else if (outlineView == myTargetsView) {
		if (item == NULL)
			return [myTargetList count];
		return [[item objectForKey: IDEKit_TargetDependsOnTargets] count];
    } else  if (outlineView == myOutlineView) {
		if (item == NULL)
			item = myRootGroup;
		return [[item objectForKey: IDEKit_ProjEntryGroup] count];
    }
    return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (outlineView == myLinkOrderView) {
		return [item objectForKey: IDEKit_ProjEntryName];
    } else if (outlineView == myTargetsView) {
		if ([item uiKind] == IDEKit_kUIDependantEntry)
			return [NSString stringWithFormat: @"<%@>",[[item objectForKey: IDEKit_DependantOnTarget] objectForKey: IDEKit_ProjEntryName]];
		else
			return [item objectForKey: IDEKit_ProjEntryName]; // just a string
    } else  if (outlineView == myOutlineView) {
		if ([[tableColumn identifier] isEqualToString: @"File"]) {
			//NSLog(@"Table entry %@",[item objectForKey: IDEKit_ProjEntryName]);
			// what if we want icon and name?
			id aCell = [tableColumn dataCell];
			NSImage *image = NULL;
			if ([item objectForKey: IDEKit_ProjEntryPath] && [item uiKind] == IDEKit_kUIFileEntry) {
				image = [[NSWorkspace sharedWorkspace] iconForFile: [item objectForKey: IDEKit_ProjEntryPath]];
				//[aCell setTitle: [item objectForKey: IDEKit_ProjEntryName]];
			} else {
				image = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode('fldr')];
			}
			[image setSize: NSMakeSize(16,16)];
			[aCell setImage: image];
			return [item objectForKey: IDEKit_ProjEntryName];
		} else if ([[tableColumn identifier] isEqualToString: @"Check"]){
			if ([item objectForKey: IDEKit_ProjEntryGroup]) {
				id checkboxProto = [[[NSTextFieldCell alloc] initTextCell: @""] autorelease];
				[tableColumn setDataCell: checkboxProto];
				return @""; // nothing for group entry (hopefully)
			} else {
				// put a checkbox in the first col
				id checkboxProto = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
				[checkboxProto setEditable: YES];
				[checkboxProto setButtonType: NSSwitchButton];
				[checkboxProto setImagePosition: NSImageOnly];
				[checkboxProto setControlSize: NSSmallControlSize];
				[tableColumn setDataCell: checkboxProto];
				
				return [NSNumber numberWithBool: [[myCurrentTarget objectForKey: IDEKit_TargetEntryFiles] containsObject: item]];
			}
		} else  {
			id proto = [self projectListColumnAttributeProto: [tableColumn identifier] forEntry: item];
			if (proto) {
				[tableColumn setDataCell: proto];
			}
			return [self projectListColumnAttributeValue: [tableColumn identifier] forEntry: item proto: [tableColumn dataCell]];
		}
    }
    return NULL;
}


- (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    if (outlineView == myLinkOrderView) {
		if ( [[pboard types] containsObject: PrivateDragPboardType]  && myPrivateDrag && [myPrivateDrag uiKind] == IDEKit_kUIFileEntry) {
			NSDictionary *entry = myPrivateDrag; // but we only support 1 of them
			[myPrivateDrag autorelease]; myPrivateDrag = NULL;
			//int targetType = [[[self currentTargetDefaults] objectForKey: TargetDefaultsTargetType] intValue];
			// just one thing, index is the new row index
			// The problem is that our UI only shows "linkable" objects, not everything (i.e., the entire target entry list)
			// so we need to convert our desination to that index
			//NSUInteger oldIndex = [self targetFileIndexForEntry: entry];
			NSUInteger oldIndex = [[myCurrentTarget objectForKey: IDEKit_TargetEntryFiles] indexOfObjectIdenticalTo: entry];
			NSAssert1(oldIndex != NSNotFound,@"Entry %@ wasn't in target list",[entry  description]);
			// index is in the UI - convert to target entry list index
			if (index == 0) {
				// index 0 will always be index 0
			} else {
				id oldItemAtIndex = [self outlineView: myLinkOrderView child: index-1 ofItem: NULL];
				index = [[myCurrentTarget objectForKey: IDEKit_TargetEntryFiles] indexOfObjectIdenticalTo: oldItemAtIndex];
				NSAssert1(index  != NSNotFound,@"Entry %@ wasn't in target list",[oldItemAtIndex  description]);
				index++; // we want it after this item (so if index = 1 coming in, we find item 0 in the list, and put it after that)
			}
			//NSLog(@"Moving %@ from %d to %d",[entry description],oldIndex,index);
			[[myCurrentTarget objectForKey: IDEKit_TargetEntryFiles] moveItemAt: oldIndex to: index];
			//[outlineView reloadData];
			[self liveSave];
			return YES;
		}
		return NO;
    } else if (outlineView == myTargetsView) {
		if ( [[pboard types] containsObject: PrivateDragPboardType] && myPrivateDrag ) {
			NSDictionary *entry = myPrivateDrag; // but we only support 1 of them
			[myPrivateDrag autorelease]; myPrivateDrag = NULL;
			switch ([entry uiKind]) {
				case IDEKit_kUITargetEntry: {
					if (entry == item)
						return NO; // can't drop on ourselves
					// add this our ourselves
					if ([[item objectForKey: IDEKit_TargetDependsOnTargets] containsObject: entry]) {
						return NO; // already there - perhaps reorder it?
					}
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												 [NSNumber numberWithInt: IDEKit_kUIDependantEntry], IDEKit_ProjEntryKind,
												 entry,IDEKit_DependantOnTarget,
												 NULL];
					//NSLog(@"Adding %@ to %@",[dict description],[item description]);
					if (![item objectForKey: IDEKit_TargetDependsOnTargets]) {
						[item setObject: [NSMutableArray arrayWithObject: dict] forKey: IDEKit_TargetDependsOnTargets];
					} else {
						[[item objectForKey: IDEKit_TargetDependsOnTargets] addObject: dict];
					}
					[self liveSave];
					return YES;
				}
				default:
					return NO;
			}
		}
		return NO;
    } else  if (outlineView == myOutlineView) {
		if ( [[pboard types] containsObject: NSFilenamesPboardType]) {
			NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
			BOOL retval = NO;
			if (item == NULL)
				item = myRootGroup;
			for (NSUInteger i=0;i<[files count];i++) {
				// see what kind of file this is
				id file = [files objectAtIndex: i];
				if ([self canAddFileToProject: file]) {
					// we want it in the project
					retval = YES;
					[self addFilePathToProject: file inGroup: item childIndex: index];
					index++; // future children in future indices
				}
				// other file types might exist that we can't handle but want in our project (like libraries)
			}
			if (retval && item) {
				if (item == myRootGroup)
					[outlineView reloadData];
				else
					[outlineView reloadItem: item reloadChildren: YES];
				[myLinkOrderView reloadData];
			}
			return retval;
		} else if ([[pboard types] containsObject: PrivateDragPboardType] && myPrivateDrag) {
			NSDictionary *entry = myPrivateDrag; // but we only support 1 of them
			[myPrivateDrag autorelease]; myPrivateDrag = NULL;
			// there are several possibilities - we can reorder an item in the same
			// container, or we can move it somewhere else.
			if (index == NSOutlineViewDropOnItemIndex)
				index = 0; // put it at the top of the list
			if (item == NULL)
				item = myRootGroup;
			id oldParent = [myOutlineView parentItemForItem: entry];
			if (oldParent == NULL)
				oldParent = myRootGroup;
			NSUInteger startIndex = [[oldParent objectForKey: IDEKit_ProjEntryGroup] indexOfObjectIdenticalTo: entry];
			NSAssert2(startIndex != NSNotFound, @"Couldn't find %@ in parent group %@",[entry description],[oldParent description]);
			if (oldParent == item) {
				// in same parent
				[[item objectForKey: IDEKit_ProjEntryGroup] moveItemAt: startIndex to: index];
			} else {
				// remove from old
				[[oldParent objectForKey: IDEKit_ProjEntryGroup] removeObjectAtIndex: startIndex];
				// put in new
				[[item objectForKey: IDEKit_ProjEntryGroup] insertObject: entry atIndex: index];
			}
			[self liveSave];
			return YES;
		}
    }
    return NO; // for now
}

- (BOOL) target: (id) target isDependantOn: (id) subtarget
{
    NSArray *dependants = [target objectForKey: IDEKit_TargetDependsOnTargets];
    for (NSUInteger i=0;i<[dependants count];i++) {
		id rule = [dependants objectAtIndex: i];
		if ([rule objectForKey: IDEKit_DependantOnTarget] == subtarget) {
			return YES;
		}
    }
    return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    if (outlineView == myLinkOrderView) {
		if ( [[pboard types] containsObject: PrivateDragPboardType] && myPrivateDrag) {
			if (index == NSOutlineViewDropOnItemIndex) { // convert "in" to "between"
				if (item == NULL) { // convert to "after end of list"
					[outlineView setDropItem: NULL dropChildIndex: [outlineView numberOfRows]];
				} else {
					[outlineView setDropItem: NULL dropChildIndex: [outlineView rowForItem: item]];
				}
			}
			return NSDragOperationMove;
		} else {
			return NSDragOperationNone;
		}
    } else if (outlineView == myTargetsView) {
		if ( [[pboard types] containsObject: PrivateDragPboardType] && myPrivateDrag) {
			NSDictionary *entry = myPrivateDrag; // but we only support 1 of them
			// entry is a IDEKit_kUITargetEntry
			switch ([entry uiKind]) {
				case IDEKit_kUITargetEntry:
					if (index == NSOutlineViewDropOnItemIndex) { // convert "in" to "between"
						// we can drop "on" a target, or "between" items
						if (item == NULL)
							return NSDragOperationNone; // if we are dropping on list, this is bad.
						if ([item uiKind] == IDEKit_kUIDependantEntry)
							return NSDragOperationNone; //If we are dropping on a rule, this is bad.
						if ([self target:item isDependantOn: entry])
							// If we are dropping where we already exist, this is bad
							return NSDragOperationNone;
						return NSDragOperationLink;
					} else {
						// we can put a target between another target (to reorder the target) or inside something (to made rule)
						// but not inside ourselves
						if (entry == item)
							return NSDragOperationNone; // can't drop between something inside us
						if ([self target:item isDependantOn: entry])
							return NSDragOperationNone; // we are already there
						if (item == NULL)
							return NSDragOperationMove;
						else
							return NSDragOperationLink;
					}
					break;
				case IDEKit_kUIDependantEntry:
					if (index == NSOutlineViewDropOnItemIndex)
						return NSDragOperationNone; // can't drop on anything
					if ([item uiKind] != IDEKit_kUITargetEntry) {
						return NSDragOperationNone; // can't drop between anything other than inside the target
					}
					if ([[item objectForKey: IDEKit_TargetDependsOnTargets] containsObject: entry] == NO) {
						return NSDragOperationNone; // don't move to another thing
					}
					return NSDragOperationMove; // otherwise it is OK
				default:
					NSAssert1(0,@"Dropping a target that is invalid %@",[entry description]);
			}
		} else {
			return NSDragOperationNone;
		}
    } else if (outlineView == myOutlineView) {
		if ( [[pboard types] containsObject: NSFilenamesPboardType]) {
			if (item == NULL) {
				//[outlineView setDropItem: myRootGroup dropChildIndex: 0];
			}
			NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
			for (NSUInteger i=0;i<[files count];i++) {
				// see what kind of file this is
				id file = [files objectAtIndex: i];
				if ([self canAddFileToProject: file]) {
					// we can edit it for sure
					if (sourceDragMask & NSDragOperationLink) {
						return NSDragOperationLink;
					} else if (sourceDragMask & NSDragOperationCopy) {
						return NSDragOperationCopy;
					}
				}
				// other file types might exist that we can't handle but want in our project (like libraries)
			}
			// if we get here, we don't want the file
			return NSDragOperationNone;
		} else if ([[pboard types] containsObject: PrivateDragPboardType] && myPrivateDrag) {
			// see if we can drop it on/in here
			if (index == NSOutlineViewDropOnItemIndex) {
				if (item == NULL)
					return NSDragOperationNone; // can't drop anything on the thing as a whole
				if ([item uiKind] == IDEKit_kUIFileEntry) {
					return NSDragOperationNone; // can't drop anything on a file
				}
			}
			// see if we are dropping a folder inside itself
			if ([myPrivateDrag uiKind] == IDEKit_kUIGroupEntry) {
				// make sure we aren't dropping inside itself
				id parent = item;
				while (parent != NULL) {
					// find the parent
					if (parent == myPrivateDrag)
						return NSDragOperationNone;
					parent = [outlineView parentItemForItem: parent];
				}
			}
			return NSDragOperationMove;
		}
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    [myPrivateDrag release]; myPrivateDrag = NULL;
    if (outlineView == myLinkOrderView) {
		myPrivateDrag = [[items objectAtIndex: 0] retain];
		[pboard declareTypes:[NSArray arrayWithObject:PrivateDragPboardType]
					   owner:self];
		//[pboard setPropertyList:items forType:LinkOrderEntryPboardType];
		//if (rowCount == 1) _moveRow = [[rows objectAtIndex:0]intValue];
		return YES;
    } else if (outlineView == myTargetsView) {
		myPrivateDrag = [[items objectAtIndex: 0] retain];
		[pboard declareTypes: [NSArray arrayWithObject:PrivateDragPboardType] owner:self];
		return YES;
    } else if (outlineView == myOutlineView) {
		myPrivateDrag = [[items objectAtIndex: 0] retain];
		[pboard declareTypes: [NSArray arrayWithObject:PrivateDragPboardType] owner:self];
		return YES;
    }
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (outlineView == myLinkOrderView) {
		return NO;
    } else if (outlineView == myTargetsView) {
		return [item uiKind] == IDEKit_kUITargetEntry; // only edit the main entry
    } else {
		// only edit if we are a group
		if ([[tableColumn identifier] isEqualToString: @"File"]) {
			return [item objectForKey: IDEKit_ProjEntryGroup] != NULL;
		}
		return YES;
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (outlineView == myLinkOrderView) {
    } else if (outlineView == myTargetsView) {
		//return [outlineView levelForItem: item] == 1; // only edit the main entry
		// see if this new value already exists
		if ([[item objectForKey: IDEKit_ProjEntryName] isEqualToString: object]) {
			// we are good
			return;
		} else {
			for (NSUInteger i=0;i<[myTargetList count];i++) {
				id targ = [myTargetList objectAtIndex: i];
				if ([[targ objectForKey: IDEKit_ProjEntryName] isEqualToString: object]) {
					NSBeep(); // already used
					return;
				}
			}
			// OK, we can rename this
			// we should rename the folder as well
			[[NSFileManager defaultManager] movePath: [[self fileName] stringByAppendingPathComponent: [item objectForKey: IDEKit_ProjEntryName]] toPath: [[self fileName] stringByAppendingPathComponent: object] handler: NULL];
			[item setObject: object forKey: IDEKit_ProjEntryName];
			[self liveSave];
			return;
		}
    } else {
		if ([[tableColumn identifier] isEqualToString: @"File"]) {
			// we changed the name of a group - pretty simple
			[item setObject: object forKey: IDEKit_ProjEntryName];
			return;
		} else if ([[tableColumn identifier] isEqualToString: @"Check"]) {
			if ([object boolValue]) {
				// add if not already there
				[self addFileToCurrentProject: item];
			} else {
				// remove if there
				[self removeFileFromCurrentProject: item];
			}
			[myLinkOrderView reloadData];
			return;
		}
    }
    // try the custom ones
    [self projectListColumnSetValue: object forAttribute: [tableColumn identifier] forEntry: item];
    [outlineView reloadData];
}

- (NSColor *)outlineView: (NSOutlineView *)outlineView colorForItem: (id) item
{
    if (outlineView == myOutlineView) {
		if ([item uiKind] == IDEKit_kUIGroupEntry) { // the child
			return [NSColor colorWithCalibratedRed: (237.0 / 255.0) green: (243.0 / 255.0) blue: (254.0 / 255.0) alpha: 1.0];
		}
    } else if (outlineView == myTargetsView) {
		if ([item uiKind] == IDEKit_kUITargetEntry) {
			return [NSColor colorWithCalibratedRed: (237.0 / 255.0) green: (243.0 / 255.0) blue: (254.0 / 255.0) alpha: 1.0];
		}
		//return [NSColor colorWithCalibratedRed: (243.0 / 255.0) green: (237.0 / 255.0)  blue: (254.0 / 255.0) alpha: 1.0];
    }
    return NULL;
}

- (NSMenu *)outlineView: (NSOutlineView *)outlineView menuForItem: (id) item
{
    if (outlineView == myOutlineView) {
		if ([item uiKind] == IDEKit_kUIGroupEntry) { // the child
			return NULL;
		}
		// update the menu for this item
		NSString *relPath = [item objectForKey: IDEKit_ProjEntryRelative];
		NSString *fullPath = [item objectForKey: IDEKit_ProjEntryPath];
		id pathVars = [self pathVars];
		for (NSUInteger i=0;i<[myFileEntryCMenu numberOfItems];i++) {
			id mitem = [myFileEntryCMenu itemAtIndex: i];
			BOOL enabled = NO;
			BOOL set = NO;
			NSString *name = NULL;
			int searchFlags = IDEKit_kPathRelDontAllowUpPath;
			switch ([mitem tag]) {
				case IDEKit_kPickFlagsAbsolute:
					enabled = YES;
					if (relPath == NULL)
						set = YES;
					break;
				case IDEKit_kPickFlagsRelativeProj:
					name = @"{Project}";
					searchFlags = IDEKit_kPathRelDontGoToRoot;
					break;
				case IDEKit_kPickFlagsRelativeApp:
					name = [IDEKit appPathName];
					break;
				case IDEKit_kPickFlagsRelativeTools:
					name = [IDEKit toolchainPathName];
					break;
				case IDEKit_kPickFlagsRelativeSDK:
					name = [IDEKit sdkPathName];
					break;
				case IDEKit_kPickFlagsRelativeHome:
					name = @"{Home}";
					break;
				case IDEKit_kPickFlagsRelativeUser:
					// remove (and rebuild) all the user paths
					[myFileEntryCMenu removeItemAtIndex: i];
					i--;
					continue;
					break;
				default:
					//NSLog(@"Unknown relative popup item %d in %@",[mitem tag],mitem);
					break;
			}
			if (name) { // we've got a give name to see if it is relative
				if ([pathVars objectForKey: name] && [fullPath stringRelativeTo:[pathVars objectForKey: name] name: name withFlags: searchFlags]) {
					enabled = YES;
					set = [relPath hasPrefix: name];
				}
			}
			
			[mitem setRepresentedObject: item];
			if (set) {
				[mitem setState: NSOnState];
			} else {
				[mitem setState: NSOffState];
			}
			if (enabled) {
				[mitem setEnabled: YES];
			} else {
				[mitem setEnabled: NO];
			}
		}
		// now add in the user paths to the bottom
		NSEnumerator *userKeyEnum = [pathVars keyEnumerator];
		id key;
		NSArray *builtInPaths = [IDEKit predefinedPathsList];
		while ((key = [userKeyEnum nextObject]) != NULL) {
			if ([builtInPaths containsObject: key] == NO) {
				id mitem = [myFileEntryCMenu addItemWithTitle: key action: @selector(changeEntryRelative:) keyEquivalent: @""];
				[mitem setTag: IDEKit_kPickFlagsRelativeUser];
				[mitem setTarget: self];
				[mitem setRepresentedObject: item];
				if ([fullPath stringRelativeTo:[pathVars objectForKey: key] name: key withFlags:IDEKit_kPathRelDontAllowUpPath]) {
					[mitem setEnabled: YES];
					if ([relPath hasPrefix: key]) {
						[mitem setState: NSOnState];
					} else {
						[mitem setState: NSOffState];
					}
				} else {
					[mitem setEnabled: NO];
				}
			}
		}
		return myFileEntryCMenu;
    }
    return NULL;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (outlineView == myTargetsView) {
		if ([item uiKind] == IDEKit_kUIDependantEntry) { // the child
			//	    [aCell setBackgroundColor: [NSColor whiteColor]];
			//	    if ([aCell respondsToSelector: @selector(setBackgroundColor:)])
			//		[aCell setBackgroundColor:[NSColor whiteColor]];
			[[NSColor darkGrayColor] set];
			//	    [aCell setForegroundColor: [NSColor darkGrayColor]];
			[aCell setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		} else { // the parent
			//	    if ([aCell respondsToSelector: @selector(setBackgroundColor:)])
			//		[aCell setBackgroundColor: [NSColor colorWithCalibratedRed: (237.0 / 255.0) green: (243.0 / 255.0) blue: (254.0 / 255.0) alpha: 1.0]];
			//	    [aCell setForegroundColor: [NSColor blackColor]];
			[[NSColor blackColor] set];
			[aCell setFont: [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]]];
		}
    } else if (outlineView == myOutlineView) {
		if ([item objectForKey: IDEKit_ProjEntryGroup] == NULL) { // an item
			//	    if ([aCell respondsToSelector: @selector(setBackgroundColor:)])
			//		[aCell setBackgroundColor: [NSColor whiteColor]];
			[aCell setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		} else { // a group
			//	    if ([aCell respondsToSelector: @selector(setBackgroundColor:)])
			//		[aCell setBackgroundColor: [NSColor colorWithCalibratedRed: (237.0 / 255.0) green: (243.0 / 255.0) blue: (254.0 / 255.0) alpha: 1.0]];
			[aCell setFont: [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]]];
		}
		if ([item objectForKey: IDEKit_ProjEntryPath] && [[tableColumn identifier] isEqualToString: @"File"]) {
			//[aCell setImage: [[NSWorkspace sharedWorkspace] iconForFile: [item objectForKey: IDEKit_ProjEntryPath]]];
			//[aCell setTitle: [item objectForKey: IDEKit_ProjEntryName]];
		}
		//	[[aCell controlView] setBackgroundColor:[NSColor whiteColor]];
    }
    if ([aCell respondsToSelector: @selector(setBackgroundColor:)]) {
		NSColor *bgColor = [self outlineView: outlineView colorForItem: item];
		if (bgColor) {
			[aCell setBackgroundColor: bgColor];
		} else {
			[aCell setBackgroundColor: [NSColor whiteColor]];
		}
    }
}
@end




// Provide a way to color background lines of items
@implementation IDEKit_ColoredOutlineView
- (void)drawRow:(NSInteger)row clipRect:(NSRect)rect
{
    if (![self isRowSelected: row]) {
		id item = [self itemAtRow: row];
		NSColor *color = [[self delegate] outlineView: self colorForItem: item];
		if (color) {
			//NSLog(@"Coloring row %d with %@",row,color);
			//[self setBackgroundColor:color];
			[color set];
			NSRect rowRect = [self rectOfRow: row];
			rowRect = NSIntersectionRect(rowRect,rect);
			[NSBezierPath fillRect: rowRect];
			[[NSColor blackColor] set];
		} else {
			//NSLog(@"Not coloring row %d",row);
			//[self setBackgroundColor:[NSColor whiteColor]];
		}
    }
    [super drawRow:row clipRect:rect];
    // set us back to white
    [self setBackgroundColor:[NSColor whiteColor]];
}

#ifdef nodef
- (void)rightMouseDown:(NSEvent *)theEvent
{
         NSEvent * tEvent;
         NSPoint tPoint;
         NSRect tBounds=[self bounds];
	
         tPoint=NSMakePoint(0,NSHeight(tBounds)+5);
	
         tPoint=[self convertPoint:tPoint toView:nil];
	
         tEvent=[NSEvent mouseEventWithType:[theEvent type]
				                                location:tPoint
				                           modifierFlags:[theEvent modifierFlags]
				                               timestamp:[theEvent timestamp]
				                            windowNumber:[theEvent windowNumber]
				                                 context:[theEvent context]
				                             eventNumber:[theEvent eventNumber]
				                              clickCount:[theEvent clickCount]
				                                pressure:[theEvent pressure]];
	
         [NSMenu popUpContextMenu:[self menu] withEvent:tEvent forView:self];
}
#else
- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
{
    // just return what is appropriate
    int row = [self rowAtPoint: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
    if (row != -1) {
		[self selectRow: row byExtendingSelection: NO];
		// if we have a selection, we should really be checking to see if we are clicking on it...
		id item = [self itemAtRow: row];
		return [[self delegate] outlineView: self menuForItem: item];
    }
    return [super menu]; // use what we've got
}
#endif

@end
