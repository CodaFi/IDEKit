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
//
#import "IDEKit_PreferencePane.h"

@interface InfoPListPrefsPane : IDEKit_PreferencePane
{
    IBOutlet id myCreator;
    IBOutlet NSOutlineView * myCustomTypes;
    IBOutlet id myCustomTypesDelete;
    IBOutlet NSTableView * myDocumentTypes;
    IBOutlet id myDocumentTypesDelete;
    IBOutlet id myExecutable;
    IBOutlet id myIconFile;
    IBOutlet id myIdentifier;
    IBOutlet id myMainNibFile;
    IBOutlet id myPrincipalClass;
    IBOutlet id myType;
    IBOutlet id myVersion;
    IBOutlet NSMenu *myRolesMenu;
    IBOutlet NSMenu *myPListTypesMenu;
}
- (IBAction)addCustomType:(id)sender;
- (IBAction)addDocumentType:(id)sender;
- (IBAction)deleteCustomType:(id)sender;
- (IBAction)deleteDocumentType:(id)sender;
- (IBAction)setCreator:(id)sender;
- (IBAction)setExecutable:(id)sender;
- (IBAction)setIconFile:(id)sender;
- (IBAction)setIdentifier:(id)sender;
- (IBAction)setMainNibFile:(id)sender;
- (IBAction)setPrincipalClass:(id)sender;
- (IBAction)setType:(id)sender;
- (IBAction)setVersion:(id)sender;
@end
