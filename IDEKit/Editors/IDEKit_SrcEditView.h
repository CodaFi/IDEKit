//
//  IDEKit_SrcEditView.h
//
//  Created by Glenn Andreas on Mon Apr 21 2003.
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
#import "IDEKit_TextViewExtensions.h"
#import "IDEKit_OpenQuicklyController.h"

@protocol IDEKit_SrcEditContext;

#define qIDEKIT_UseCache

#ifdef qIDEKIT_UseCache
#ifdef __cplusplus
// try desparately to not have C++ code in the headers
typedef struct IDEKit_LineCache;
#else
typedef void *IDEKit_LineCache;
#endif
#endif

@class IDEKit_SrcEditView;
@class IDEKit_UniqueID;
@class IDEKit_SnapshotFile;
@class IDEKit_TextView;


@interface IDEKit_SrcEditView : NSView <IDEKit_OpenQuicklyFinder, NSTextViewDelegate, NSTextStorageDelegate, IDEKit_NSTextViewExtendedDelegate> {
	@public
		id<IDEKit_SrcEditContext> myContext;
		IBOutlet id myScrollView;
		IBOutlet IDEKit_TextView *myTextView;
		IBOutlet id myCurrentLanguage;
		IBOutlet NSSplitView *mySplitView;
		IBOutlet id myContextualMenu;
		IBOutlet id myStatusBar;
		IBOutlet id myStatusBarText;
		IBOutlet id myBreakpointMenu;

		BOOL myShowRulers;
		BOOL myIsScratch;
		int myIsMakingTemplate;
		
		BOOL mySkipAutoIndent;
		BOOL myTrySmartIndent;
		BOOL mySyntaxColor;
		BOOL myWordWrap;
		BOOL myShowInvisibles;
		BOOL myShowLineNums;
		BOOL myShowFolding;
		BOOL myAutoClose;

		float myTabStops;
		BOOL mySaveWithTabs;
		NSInteger myTabWidth; // for saving
		NSInteger myIndentWidth; // for saving (or converting)
		BOOL myAutoConvertTabs;
	#ifdef qIDEKIT_UseCache
		// we need to keep caches of line information since recalculating it is O(N) problem which really slows us down
		IDEKit_LineCache *myLineCache;
		int myFoldingOperation;
	#endif
		IDEKit_UniqueID *myUniqueID;
}

- (void) setContext: (id<IDEKit_SrcEditContext>) aContext;
- (id<IDEKit_SrcEditContext>) context;
- (void) setUniqueFileID: (IDEKit_UniqueID *)fileID;
- (IDEKit_UniqueID *) uniqueFileID;
+ (IDEKit_SrcEditView *)srcEditViewAssociatedWith: (IDEKit_UniqueID *)fileID;
- (void) setDisplaysSnapshot: (IDEKit_SnapshotFile *)snapshot;
- (IDEKit_SnapshotFile *) displayingSnapshot;
- (id) currentLanguage;
- (void) setCurrentLanguage: (id) newLanguage;
- (NSString *)massageInsertableText: (NSString *)text; // we are about to paste this text - fix indent, etc...
- (void) refreshSettingsFromPrefs: (BOOL) redraw;

- (IBAction) buildPopUpFuncs: (id) sender;
- (IBAction) doPopUpFuncsMarker: (id) sender;
- (IBAction) buildPopUpHeaders: (id) sender;
- (IBAction) doPopUpHeader: (id) sender;
- (IBAction) toggleSyntaxColor: (id) sender;
- (IBAction) toggleAutoIndent: (id) sender;
- (IBAction) toggleWordWrap: (id) sender;
- (IBAction) toggleShowLineNumbers: (id) sender;
- (IBAction) toggleShowFolding: (id) sender;
- (IBAction) toggleAutoClose: (id) sender;
- (IBAction) insertSplitView: (id) sender;
- (IBAction) textSettings: (id) sender;
// additional editing commands (useful to be bound to key shortcuts)

- (void) setFont: (NSFont *) font;
- (NSString *)string;
// if we are split (or not) we can have multiple views - this gets them all
- (NSArray *) allScrollViews;
- (NSArray *) allTextViews;
@end

@protocol IDEKit_SrcEditContext <NSObject, NSTextDelegate>
- (Class) currentLanguageClassForSrcEditView: (IDEKit_SrcEditView *) view;
- (NSString *) fileNameForSrcEditView: (IDEKit_SrcEditView *) view;
- (id) owningProjectForSrcEditView: (IDEKit_SrcEditView *) view;
- (BOOL) canEditForSrcEditView: (IDEKit_SrcEditView *) view;
- (void) srcEditView: (IDEKit_SrcEditView *) view specialDoubleClick: (NSInteger) modifiers selection: (NSString *) selection;
- (NSArray *) srcEditView: (IDEKit_SrcEditView *) view autoCompleteIdentifier: (NSString *) name max: (NSInteger) max;
#ifdef nomore // other mechanisms exist for storing breakpoints
- (NSDictionary *) getBreakPointsForSrcEditView: (IDEKit_SrcEditView *) view;	// get the breakpoints for this one file
#endif
- (void) srcEditView: (IDEKit_SrcEditView *) view setBreakPoints: (NSDictionary *)breakPoints;	// set the breakpoints for this one file
// note that srcEditView:setBreakPoints: is now "advisory" (to let the context know we changed our internal state)
// since the breakpoint manager actually maintains the breakpoints
- (NSMenu *) srcEditView: (IDEKit_SrcEditView *)view  breakpointMenuForLine: (NSInteger) line;
- (NSUserDefaults *) defaultsForSrcEditView: (IDEKit_SrcEditView *) view;
- (NSMenu *) updateContextualMenu: (NSMenu *) menu forSrcEditView: (IDEKit_SrcEditView *) view;
- (NSString *) toolTipForSrcEditView: (IDEKit_SrcEditView *) view;
@end

@interface NSObject(IDEKit_SrcEditContext)
- (Class) currentLanguageClassForSrcEditView: (IDEKit_SrcEditView *) view;
- (NSString *) fileNameForSrcEditView: (IDEKit_SrcEditView *) view;
- (id) owningProjectForSrcEditView: (IDEKit_SrcEditView *) view;
- (BOOL) canEditForSrcEditView: (IDEKit_SrcEditView *) view;
- (void) srcEditView: (IDEKit_SrcEditView *) view specialDoubleClick: (NSInteger) modifiers selection: (NSString *) selection;
- (NSArray *) srcEditView: (IDEKit_SrcEditView *) view autoCompleteIdentifier: (NSString *) name max: (NSInteger) max;
- (NSDictionary *) getBreakPointsForSrcEditView: (IDEKit_SrcEditView *) view;	// get the breakpoints for this one file
- (void) srcEditView: (IDEKit_SrcEditView *) view setBreakPoints: (NSDictionary *)breakPoints;	// set the breakpoints for this one file
- (NSMenu *) srcEditView: (IDEKit_SrcEditView *) view breakpointMenuForLine: (NSInteger) line;
- (NSUserDefaults *) defaultsForSrcEditView: (IDEKit_SrcEditView *) view;
- (NSMenu *) updateContextualMenu: (NSMenu *) menu forSrcEditView: (IDEKit_SrcEditView *) view;
- (NSString *) toolTipForSrcEditView: (IDEKit_SrcEditView *) view;
@end


