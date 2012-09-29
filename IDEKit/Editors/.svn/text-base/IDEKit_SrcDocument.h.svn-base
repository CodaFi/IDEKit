//
//  IDEKit_TextDocument.h
//  IDEKit
//
//  Created by Glenn Andreas on Sun Aug 17 2003.
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
#import "IDEKit_SrcEditView.h"

@class IDEKit_LayeredDefaults;
@class IDEKit_PersistentFileData;
@class IDEKit_UniqueID;
// We automatically save a number of things in the resource fork of the document, in resource IDEK 128
// It is converted to a dictionary with the following keys (not that you should care)
extern NSString *IDEKit_SrcDocument_SelectionRange;
extern NSString *IDEKit_SrcDocument_WindowLocation; // we don't use the auto-save location stuff, since this will work across IDEKit apps
extern NSString *IDEKit_SrcDocument_VisibleRange;

@interface IDEKit_SrcDocument : NSDocument<IDEKit_SrcEditContext> {
    id myDataFromFile; // a temporary thing used when loading
    NSMutableDictionary *myAuxDataProperties; // similar - will be saved as well (a dictionary with various properties)
    id myTextView;
    IDEKit_LayeredDefaults *myDefaults;
    IDEKit_UniqueID *myUniqueID;
}
-(void) loadDocWithData: (NSData *) data;
#ifdef nomore
// subclasses with additional aux properties can override these (remember to call the original)
-(void) updateAuxDataProperties;
-(void) refreshFromAuxDataProperties;
#else
-(void) savePersistentData: (IDEKit_PersistentFileData *)data;
-(void) loadPersistentData: (IDEKit_PersistentFileData *)data;
#endif
- (IDEKit_UniqueID *)uniqueFileID;
// override this to change the encoding that we write files with
-(NSStringEncoding) saveAsEncoding;

+ (NSArray *)defaultAutocompleteForIdentifier: (NSString *)ident; // for all documents
- (NSArray *)defaultAutocompleteForIdentifier: (NSString *)ident; // for one document
@end