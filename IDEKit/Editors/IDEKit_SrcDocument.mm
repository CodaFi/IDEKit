//
//  IDEKit_SrcDocument.mm
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

#import "IDEKit_SrcDocument.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_SrcScroller.h"
#import "IDEKit_TextViewExtensions.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_LayeredDefaults.h"
#import "IDEKit_PreferenceController.h"
#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_SrcEditViewPrinting.h"
#import "IDEKit_FindPaletteController.h"
#import "IDEKit_Resources.h"
#import "IDEKit_SrcEditviewBreakpoints.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_BreakpointManager.h"
#import "IDEKit_Autocompletion.h"

NSString *IDEKit_SrcDocument_SelectionRange = @"IDEKit_SrcDocument_SelectionRange";
NSString *IDEKit_SrcDocument_WindowLocation = @"IDEKit_SrcDocument_WindowLocation"; // we don't use the auto-save location stuff, since this will work across IDEKit apps
NSString *IDEKit_SrcDocument_VisibleRange = @"IDEKit_SrcDocument_VisibleRange";

@implementation IDEKit_SrcDocument
- (id) init
{
    self = [super init];
    if (self) {
	myDefaults = [[IDEKit_LayeredDefaults layeredDefaultsWithDict: [NSMutableDictionary dictionary] layeredSettings: NULL] retain];
#ifdef nomore
	myAuxDataProperties = [[NSMutableDictionary dictionary] retain]; // start with empty dictionary
#endif
	myUniqueID = [[[IDEKit_UniqueFileIDManager sharedFileIDManager] newUniqueFileID] retain]; // start with new file
    }
    return self;
}

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    // Unfortunately, this looks in the bundle of the owner of the class, so if you subclass
    // IDEKit_SrcDocument, you need to override this method and provide a nib for it
    return @"IDEKit_SrcDocument";
}

- (void) awakeFromNib
{
    // do nothing, in case we've got subclasses that want to call us
}

-(void)windowControllerDidLoadNib: (NSWindowController *)controller
{
    [myTextView setContext: self];
    [myTextView setUniqueFileID:myUniqueID]; // so it matches the document, or our new one
    if (myDataFromFile) {
	[self loadDocWithData: myDataFromFile];
	[myDataFromFile release];
	myDataFromFile = NULL;
    } else {
	[myTextView setCurrentLanguage: [[[[IDEKit defaultLanguage] alloc] init] autorelease]];
    }
    //[self setupToolbar: [controller window]];
}

- (void) dealloc
{
#ifdef nomore
    [myAuxDataProperties release];
#endif
    [myDefaults release];
    [myUniqueID release];
    [super dealloc];
}

-(NSStringEncoding) saveAsEncoding
{
    return NSMacOSRomanStringEncoding;
}
- (IDEKit_UniqueID *)uniqueFileID
{
    return myUniqueID;
}


- (NSData *)dataRepresentationOfType:(NSString *)type
{
    // Implement to provide a persistent data representation of your document OR remove this and implement the file-wrapper or file path based save methods.
    return [[[myTextView currentLanguage] cleanUpStringForFile: [myTextView string]] dataUsingEncoding: [self saveAsEncoding]];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    // Implement to load a persistent data representation of your document OR remove this and implement the file-wrapper or file path based load methods.
    if (myTextView) {
	[self loadDocWithData: data];
    } else {
	myDataFromFile = [data retain];
    }
    return YES;
}

// use support for resource forks (which calls the above mentioned things)
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
#ifdef nomore
    // first bring in the aux properties, if any (so readFromFile can look at them)
    IDEKit_Resources *resources = [IDEKit_Resources resourceFork: fileName forWriting: NO];
    if (resources) {
	NSData *auxData = [resources getResourceType: 'IDEK' resID: 128];
	if (auxData) {
	    [myAuxDataProperties release];
	    myAuxDataProperties = NULL; // in case the unarchiver throws an exception, we'll still be OK
	    myAuxDataProperties = [[NSUnarchiver unarchiveObjectWithData: auxData] mutableCopy]; // we want to be able to change it
	}
    } else {
	// no resource fork, no big deal
	[myAuxDataProperties release];
	myAuxDataProperties = [[NSMutableDictionary dictionary] retain]; // make a blank mutable dict for our properties
    }
    return [super readFromFile: fileName ofType: docType];
#else
    BOOL retval = [super readFromFile: fileName ofType: docType];
    if (retval) {
	[myUniqueID release];
	myUniqueID = [[[IDEKit_UniqueFileIDManager sharedFileIDManager] uniqueFileIDForFile: fileName] retain];
    }
    return retval;
#endif
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
    // write out the data fork
    bool retval = [super writeToFile: fileName ofType: docType];
#ifdef nomore
    if (retval && myAuxDataProperties) {
	[self updateAuxDataProperties]; // make sure to update anything else
	// write out the resource fork info
	IDEKit_Resources *resources = [IDEKit_Resources resourceFork: fileName forWriting: YES];
	if (resources) {
	    NSData *auxData = [NSArchiver archivedDataWithRootObject:myAuxDataProperties];
	    [resources writeResource: auxData type: 'IDEK' resID: 128];
	} else {
	    // no resource fork, no big deal
	}
    }
#else
    if (retval) {
 	// this will update our persistent file stuff (hopefully correctly).
	IDEKit_PersistentFileData *fileData = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataForFileID: myUniqueID];
	//[fileData setGlobalFileData: [[myAuxDataProperties copy] autorelease] forKey: @"IDEKit_SrcDocument"];
	[self savePersistentData: fileData];
    }
#endif
    return retval;
}

// Since writing goes to a temporary files, we can't write our persistent data here
- (BOOL)writeWithBackupToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType
{
    bool retval = [super writeWithBackupToFile: fullDocumentPath ofType: documentTypeName saveOperation:saveOperationType];
    if (retval) {
	switch (saveOperationType) {
	    case NSSaveOperation: {
		// take our existing persistent data as is, and update it with the document path
		IDEKit_PersistentFileData *fileData = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataForFileID: myUniqueID];
		[fileData writeForFile: fullDocumentPath];
		break;
	    }
	    case NSSaveAsOperation: {
		// we are now a clone of our previous thing  - get a new unique ID
		IDEKit_PersistentFileData *fileData = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataCopyForFileID: myUniqueID];
		[fileData writeForFile: fullDocumentPath];
		// and update our unique id as well
		[myUniqueID release];
		myUniqueID = [[fileData uniqueFileID] retain];
		[myTextView setUniqueFileID:myUniqueID];
		break;
	    }
	    case NSSaveToOperation: {
		// write a copy to here, but keep our unique ID the same
		IDEKit_PersistentFileData *fileData = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataCopyForFileID: myUniqueID];
		[fileData writeForFile: fullDocumentPath];
		break;
	    }
	}
    }
    return retval;
}

// give us a chance to save the breakpoint data
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    if (![self isDocumentEdited]) {
	// Closing window with no changes (so we'll never save)
	// make sure to at least update our breakpoints
	if ([self fileName]) { // is it a real file?
	    NSDictionary *bps = [myTextView breakpoints];
	    [[IDEKit_BreakpointManager sharedBreakpointManager] setBreakPoints:bps forFile: myUniqueID];
	    switch ([IDEKit breakpointStoragePolicy]) {
		case IDEKit_kStoreBreakpointsNone:
		    // toss them
		    break;
		case IDEKit_kStoreBreakpointsInFile: {
		    // write to the persistent file data (even though we aren't doing anything)
		    IDEKit_PersistentFileData *data = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataForFileID: myUniqueID];
		    [[IDEKit_BreakpointManager sharedBreakpointManager] savePersistentData:data forFile:myUniqueID];
		    break;
		}
		case IDEKit_kStoreBreakpointsInApp:
		    [IDEKit saveApplicationStoredBreakpoints: bps forFile: myUniqueID];
		    break;
		case IDEKit_kStoreBreakpointsInProject:
		    break; // projects not supported yet
	    }
	} else { // just a scratch file
	    // just in case, clear out any breakpoints  for the temporary file
	    [[IDEKit_BreakpointManager sharedBreakpointManager] setBreakPoints: NULL forFile: myUniqueID];
	    [IDEKit saveApplicationStoredBreakpoints: NULL forFile: myUniqueID];
	}
    }
    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

-(void) loadDocWithData: (NSData *) data
{
    [myTextView setContext: self];

    // figure out the encoding, if possible
    NSStringEncoding encoding = [self saveAsEncoding]; // use what we save as by default
    if ([data length] >= 2) {
	unsigned short bom16;
	[data getBytes: &bom16 length: 2];
	if (bom16 == 0xfeff || bom16 == 0xfffe) {
	    encoding = NSUnicodeStringEncoding; // either UTF16 BE or UTF16 LE
	} else if ([data length] >= 3) {
	    unsigned long bom32 = 0;
	    if ([data length] >= 4) {
		[data getBytes: &bom32 length: 4];
	    } else {
		[data getBytes: &bom32 length: 3]; // for an empty file with only the UTF8 BOM
	    }
	    if ((bom32 & 0xffffff00) == 0xefbbbf00) {
		encoding = NSUTF8StringEncoding;
	    } else if (bom32 == 0x0000feff || bom32 == 0xfffe0000) {
		// either UTF32 BE or UTF32 LE
		encoding = NSUnicodeStringEncoding;
	    } else {
		// try to detect what encoding we are using?
	    }
	}
    }
    NSString *srcString = [[[NSString alloc] initWithData: data encoding: encoding] autorelease];
    srcString = [srcString sanitizeLineFeeds: IDEKit_kUnixEOL];
    // figure out a good language, based on the contents
    Class language = [IDEKit languageFromFileName: [self fileName] withContents: srcString];
    if (language) {
	[myTextView setCurrentLanguage: [[[language alloc] init] autorelease]];
    }
    srcString = [[myTextView currentLanguage] cleanUpStringFromFile: srcString];
    [myTextView setString: (NSString *)srcString];
    [myTextView updateBreakpointsFromProject];
#ifdef nomore
    [self refreshFromAuxDataProperties];
#else
    IDEKit_PersistentFileData *fileData = [[IDEKit_UniqueFileIDManager sharedFileIDManager] persistentDataForFileID: myUniqueID];
    [self loadPersistentData: fileData];
#endif
}

#ifdef nomore
-(void) updateAuxDataProperties
{
#ifdef nodef
    NSRect bounds = [[myTextView window] frame];
    if (!NSIsEmptyRect(bounds)) {
	[myAuxDataProperties setObject: [NSValue valueWithRect:bounds] forKey: IDEKit_SrcDocument_WindowLocation];
    }
#else
    [myAuxDataProperties setObject: [[myTextView window] stringWithSavedFrame] forKey: IDEKit_SrcDocument_WindowLocation];
#endif
    [myAuxDataProperties setObject: [NSValue valueWithRange:[myTextView visibleRange]] forKey: IDEKit_SrcDocument_VisibleRange];
    [myAuxDataProperties setObject: [NSValue valueWithRange:[myTextView selectedRange]] forKey: IDEKit_SrcDocument_SelectionRange];
}

-(void) refreshFromAuxDataProperties
{
    id auxData = [myAuxDataProperties objectForKey: IDEKit_SrcDocument_WindowLocation];
    if (auxData) {
	// remove the old preference for this window, if any, since it can conflict with where we saved it
	if ([[[myTextView window] frameAutosaveName] length] > 0) {
	    [NSWindow removeFrameUsingName:[[myTextView window] frameAutosaveName]];
	}
	[[myTextView window] setFrameFromString: auxData];
    }
    auxData = [myAuxDataProperties objectForKey: IDEKit_SrcDocument_VisibleRange];
    if (auxData) {
	NSRange range = [auxData rangeValue];
	[myTextView scrollRangeToVisible:range];
    }
    auxData = [myAuxDataProperties objectForKey: IDEKit_SrcDocument_SelectionRange];
    if (auxData) {
	NSRange range = [auxData rangeValue];
	[myTextView setSelectedRange:range];
    }
}
#else
-(void) savePersistentData: (IDEKit_PersistentFileData *)data
{
    [data setGlobalFileData: [[myTextView window] stringWithSavedFrame] forKey: IDEKit_SrcDocument_WindowLocation];
    [data setGlobalFileData: NSStringFromRange([myTextView visibleRange]) forKey: IDEKit_SrcDocument_VisibleRange];
    [data setGlobalFileData: NSStringFromRange([myTextView selectedRange]) forKey: IDEKit_SrcDocument_SelectionRange];
    // now is as good as any to save the breakpoints
    switch ([IDEKit breakpointStoragePolicy]) {
	case IDEKit_kStoreBreakpointsNone:
	    // toss them
	    break;
	case IDEKit_kStoreBreakpointsInFile:
	    [[IDEKit_BreakpointManager sharedBreakpointManager] savePersistentData:data forFile:myUniqueID];
	    break;
	case IDEKit_kStoreBreakpointsInApp:
	    [IDEKit saveApplicationStoredBreakpoints: [[IDEKit_BreakpointManager sharedBreakpointManager] getBreakPointsForFile: myUniqueID] forFile: myUniqueID];
	    break;
	case IDEKit_kStoreBreakpointsInProject:
	    break; // projects not supported yet
    }
}

-(void) loadPersistentData: (IDEKit_PersistentFileData *)data
{
    NSString *auxData = [data globalFileDataForKey: IDEKit_SrcDocument_WindowLocation];
    if (auxData) {
	// remove the old preference for this window, if any, since it can conflict with where we saved it
	if ([[[myTextView window] frameAutosaveName] length] > 0) {
	    [NSWindow removeFrameUsingName:[[myTextView window] frameAutosaveName]];
	}
	[[myTextView window] setFrameFromString: auxData];
    }
    auxData = [data globalFileDataForKey: IDEKit_SrcDocument_VisibleRange];
    if (auxData) {
	NSRange range = NSRangeFromString(auxData);
	[myTextView scrollRangeToVisible:range];
    }
    auxData = [data globalFileDataForKey: IDEKit_SrcDocument_SelectionRange];
    if (auxData) {
	NSRange range = NSRangeFromString(auxData);
	[myTextView setSelectedRange:range];
    }
    // now is as good as any to load the breakpoints
    switch ([IDEKit breakpointStoragePolicy]) {
	case IDEKit_kStoreBreakpointsNone:
	    // clear them
	    [[IDEKit_BreakpointManager sharedBreakpointManager] setBreakPoints: [NSDictionary dictionary] forFile: myUniqueID];
	    break;
	case IDEKit_kStoreBreakpointsInFile:
	    [[IDEKit_BreakpointManager sharedBreakpointManager] loadPersistentData:data forFile:myUniqueID];
	    break;
	case IDEKit_kStoreBreakpointsInApp:
	    [[IDEKit_BreakpointManager sharedBreakpointManager] setBreakPoints: [IDEKit loadApplicationBreakpointsForFile: myUniqueID] forFile: myUniqueID];
	    break;
	case IDEKit_kStoreBreakpointsInProject:
	    break; // projects not supported yet
    }
}
#endif

-(void)textDidChange:(NSNotification *)aNotification
{
    [self updateChangeCount: NSChangeDone];
#ifdef notyet
    PrXDocument *project = [PrXDocument documentForFile:[self fileName]];
    if (project) {
	[project fileTouched: [self fileName]];
    }
#endif
}

#pragma mark IDEKit_SrcEditContext routines
- (Class) currentLanguageClassForSrcEditView: (IDEKit_SrcEditView *) view;
{
    return [IDEKit languageFromFileName: [self fileName] withContents: [view string]];
}

- (NSString *) fileNameForSrcEditView: (IDEKit_SrcEditView *) view;
{
    return [self fileName];
}

- (id) owningProjectForSrcEditView: (IDEKit_SrcEditView *) view
{
    return self; //[PrXDocument documentForFile:[self fileName]];
}

- (BOOL) canEditForSrcEditView: (IDEKit_SrcEditView *) view
{
    return YES; // for now - perhaps disable if debugging
}

- (void) srcEditView: (IDEKit_SrcEditView *) view specialDoubleClick: (NSInteger) modifiers selection: (NSString *) selection
{
}


- (void) srcEditView: (IDEKit_SrcEditView *) view setBreakPoints: (NSDictionary *)breakPoints	// set the breakpoints for this one file
{
    // ignore this
}

- (NSUserDefaults *) defaultsForSrcEditView: (IDEKit_SrcEditView *) view
{
    return myDefaults;
}

- (NSArray *) srcEditView: (IDEKit_SrcEditView *) view autoCompleteIdentifier: (NSString *) name max: (NSInteger) max
{
    // return everything in us or any other subclass of SrcDocument
    return [IDEKit_SrcDocument defaultAutocompleteForIdentifier: name];
}
#pragma mark Printing
- (void)printShowingPrintPanel:(BOOL)flag
{
    NSPrintInfo *printInfo = [self printInfo];
    NSView *view = [myTextView viewForPrinting: printInfo];
    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
    [printOp setShowPanels: flag];
    [printOp runOperation];
}
- (NSMenu *) updateContextualMenu: (NSMenu *) menu forSrcEditView: (IDEKit_SrcEditView *) view
{
    // this menu is what the myContextualMenu outlet is set to - we can make a new one if we want...
    return menu;
}

+ (NSArray *)defaultAutocompleteForIdentifier: (NSString *)ident
{
    NSMutableArray *retval = [NSMutableArray array];
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    NSArray *allDocuments = [controller documents];
    for (NSUInteger i=0;i<[allDocuments count];i++) {
	IDEKit_SrcDocument *doc = [allDocuments objectAtIndex: i];
	if ([doc respondsToSelector:@selector(defaultAutocompleteForIdentifier:)]) {
	    [retval addObjectsFromArray:[doc defaultAutocompleteForIdentifier: ident]];
	}
    }
    return [retval sortedUniqueArray];
}

- (NSArray *)defaultAutocompleteForIdentifier: (NSString *)ident
{
    NSString *contents = [myTextView string];
    return [contents findAllIdentifiers: ident selectedRange: NSMakeRange(0,[contents length]) options: 0 wordSet: [[myTextView currentLanguage] characterSetForAutoCompletion]];
}

- (NSMenu *) srcEditView: (IDEKit_SrcEditView *) view breakpointMenuForLine: (NSInteger) line;
{
    return NULL;
}

@end