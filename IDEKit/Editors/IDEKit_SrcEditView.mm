//
//  IDEKit_SrcEditView.mm
//  IDEKit
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

#import "IDEKit_SrcEditView.h"
#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_SrcScroller.h"
#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_TextView.h"
#import "IDEKit_SrcLayoutManager.h"
#import "IDEKit_PreferenceController.h"
#import "IDEKit_SrcEditViewFolding.h"
#import "IDEKit_LineCache.h"
#import "IDEKit_Snippets.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_BreakpointManager.h"
#import "IDEKit_BreakpointInspector.h"
#import "IDEKit_SnapshotFile.h"
#import "IDEKit_SrcEditViewExtensions.h"
#import "IDEKit_OpenQuicklyController.h"

static NSInteger AdjustMarkerPoint(int location, NSRange range, int newLength)
{
    if (NSEqualRanges(NSMakeRange(location,0),range)) {
		// do nothing - don't move the range
    } else if (NSLocationInRange(location,range)) {
		location = range.location;
    } else if (range.location + range.length <= location) {
		location -= range.length;
		location += newLength;
    }
    return location;
}
static NSInteger SortMarkerByRange(id first, id second, void *)
{
    return [first decl].location - [second decl].location;
}
static NSInteger SortMarkerByName(id first, id second, void *)
{
    return 0;
}

// Since we provide our own implementation, make a UI appropriate
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_3
@interface NSTextView (NSCompletion)
- (NSRange)rangeForUserCompletion;
@end
#endif

@implementation IDEKit_SrcEditView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// we want to look in the main nib first (instead of the owner's class's nib), so
		// the nib can be overridden...
		[NSBundle loadOverridenNibNamed: @"IDEKit_SrcEditView" owner: self];
		[self addSubview: myScrollView];
		[myScrollView setFrame: [self frame]];
		[myScrollView setShowFlags: IDEKit_kShowNavPopup | IDEKit_kShowFmtPopup | IDEKit_kShowSplitter | IDEKit_kShowUnsplitter | IDEKit_kShowBreakpoints];
#ifdef qIDEKIT_UseCache
		myLineCache = new IDEKit_LineCache;
#endif
		myUniqueID = [[[IDEKit_UniqueFileIDManager sharedFileIDManager] newUniqueFileID] retain]; // so we've at least got something
		[myUniqueID setRepresentedObject:self forKey: @"IDEKit_SrcEditView"];
    }
    return self;
}

- (void) dealloc
{
    if ([self displayingSnapshot]) [self setDisplaysSnapshot:NULL]; // remove us from the snapshot, if any
    [[NSNotificationCenter defaultCenter] removeObserver: self];
#ifdef qIDEKIT_UseCache
    delete myLineCache;
#endif
    [myStatusBar dealloc]; // since we retained it regardless of it being shown or not
    [myUniqueID setRepresentedObject:NULL forKey: @"IDEKit_SrcEditView"]; // remove us from the old one
    [myUniqueID release];
    [super dealloc];
}

- (void) awakeFromNib
{
    // switch to the "fixed" layout manager which does invisibles
    id layout = [[IDEKit_SrcLayoutManager alloc] init];
#ifdef notyet
    // and storage that does folding
    IDEKit_TextStorage *storage = [[IDEKit_TextStorage alloc] init];
    [storage setAttributedString: [myTextView textStorage]];
#endif
    [myStatusBar retain];
    [myStatusBar removeFromSuperview];
    // try to replace with our subclass
    if ([myTextView isKindOfClass: [IDEKit_TextView class]] == NO) {
		NSSize contentSize = [myScrollView contentSize];
		IDEKit_TextView *subTextView = [[IDEKit_TextView alloc] initWithFrame: [myTextView frame]  textContainer: [myTextView textContainer]];
		[subTextView setAllowsUndo:YES];
		[subTextView setMinSize: [myTextView minSize]];
		[subTextView setMaxSize: [myTextView maxSize]];
		[subTextView setAutoresizingMask: [myTextView autoresizingMask]];
		
		[subTextView setVerticallyResizable: [myTextView isVerticallyResizable]];
		[subTextView setHorizontallyResizable: [myTextView isHorizontallyResizable]];
		
		[subTextView setDelegate: self];
		//NSLog(@"Old text view %@",[myTextView description]);
		//NSLog(@"New text view %@",[subTextView description]);
		//[myTextView release];
		[myScrollView setDocumentView: subTextView];
		[myTextView removeFromSuperview];
		[myScrollView setHasVerticalScroller: YES];
		myTextView = subTextView;
    }
    
    [[myTextView textContainer] replaceLayoutManager: layout];
#ifdef notyet
    [layout replaceTextStorage:storage];
#endif
    //NSLog(@"Layout %@ storage %.8X = %.8X?",layout,[myTextView textStorage], storage);
    [layout release];
    [myTextView setUsesRuler: YES]; // this gets turned off when we replace layout manager
    [myTextView setRulerVisible: YES];
    // so we can update the ruler
    [myTextView setDelegate: self];
    [[myTextView textStorage] setDelegate: self];
	
    // then make it bigger
    [myTextView setHorizontallyResizable: YES];
    [myTextView setMinSize: NSMakeSize(20000,0)];
	
    NSTextContainer *container = [myTextView textContainer];
    [container setWidthTracksTextView:YES]; // do this for no wrap
    
    // and keep it this size if we resize - turn off width tracking
    [[myTextView textContainer] setWidthTracksTextView: NO];
    [[myTextView window] makeFirstResponder: myTextView];
    [myTextView setBackgroundColor: IDEKit_TextColorForColor(IDEKit_kLangColor_Background)];
	
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(changeTextViewFocus:)
	 name:NSViewFocusDidChangeNotification
	 object:myTextView];
#ifdef nomore
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(addBreakPointNotification:)
	 name:IDEKit_SourceBreakpointAddedNotification
	 object:NULL];
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(removeBreakPointNotification:)
	 name:IDEKit_SourceBreakpointRemovedNotification
	 object:NULL];
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(updateBreakPointNotification:)
	 name:IDEKit_SourceBreakpointsChangedNotification
	 object:NULL];
#endif
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(updateUserSettingsNotification:)
	 name:IDEKit_UserSettingsChangedNotification
	 object:NULL];
	
    if (myContextualMenu) {
		//[myTextView setMenu: myContextualMenu];
    }
    [self refreshSettingsFromPrefs: NO];
}

- (void) updateUserSettingsNotification: (NSNotification *)notification
{
    // for now, always update the settings
    [self refreshSettingsFromPrefs: YES];
}

- (void) refreshSettingsFromPrefs: (BOOL) redraw
{
    NSUserDefaults *defaults = myContext ? [myContext defaultsForSrcEditView: self] : [NSUserDefaults standardUserDefaults];
    mySyntaxColor = [defaults integerForKey: IDEKit_TextColorDefaultStateKey] > 0;
    myAutoClose = [defaults integerForKey: IDEKit_TextAutoCloseKey] > 0;
    myTrySmartIndent = YES;
    mySkipAutoIndent = NO;
    myWordWrap = NO;
	
    // note that if we are using character width for tabs, this value ends up being -4.0 (for 4 spaces/tab)
    // which setUniformTabStops converts with the current font to be correct
    [myTextView setUniformTabStops: 72.0 * [defaults floatForKey:IDEKit_TabStopKey] / [defaults floatForKey:IDEKit_TabStopUnitKey]];
	
    myIndentWidth = [defaults integerForKey: IDEKit_TabIndentSizeKey];
    myTabWidth = [defaults integerForKey: IDEKit_TabSizeKey];
    mySaveWithTabs = [defaults boolForKey: IDEKit_TabSavingKey];
    myAutoConvertTabs = [defaults boolForKey: IDEKit_TabAutoConvertKey];
	
    NSFont *theFont;
    theFont=[NSFont fontWithName:[defaults stringForKey: IDEKit_TextFontNameKey]
							size:[defaults floatForKey: IDEKit_TextFontSizeKey]];
    if (!theFont)
		theFont=[NSFont userFixedPitchFontOfSize:[defaults floatForKey: IDEKit_TextFontSizeKey]];
    if (theFont)
		[self setFont: theFont];
	
    if (redraw) {
		// this means we need to recolor, at the very least
		NSString *string = [myTextView string];
		[[myTextView textStorage] edited:  NSTextStorageEditedCharacters range: NSMakeRange(0, [string length]) changeInLength: 0];
		[self forceBreakpointRedraw];
    }
}

- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self refreshSettingsFromPrefs: YES];
}


- (IBAction) textSettings: (id) sender
{
    // if the context provides text settings, we'll use those
//    if ([myContext respondsToSelector: @selector(textSettings:)]) {
//		[myContext textSettings: sender];
//    }
//	else {
	NSInteger response;
		IDEKit_PreferenceController *prefs = [[IDEKit_SrcPreferenceController alloc] initWithDefaults: [myContext defaultsForSrcEditView: self]];
		[prefs beginSheetModalForWindow: [myTextView window] modalDelegate:self
						 didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:)
							contextInfo:&response];
//    }
}

- (void) setString: (NSString *) string
{
    [myTextView setSelectedRange: NSMakeRange(0,0)];
#ifdef qIDEKIT_UseCache
    myLineCache->RebuildFromString(@""); // empty it out (or delete and remake?)
#endif
    [myTextView setString: string];
    // rebuild tabs,  formatting
    float realTabStops = myTabStops;
    myTabStops = 0.0;
    [myTextView setUniformTabStops:realTabStops]; // force the NSParagraphStyleAttributeName to be reset
#ifdef qIDEKIT_UseCache
    myLineCache->RebuildFromString(string);
#endif
}

- (NSTextView *)getFocusedView
{
    //NSLog(@"Cur focus = %@/%@",[[mTextView window] firstResponder],mTextView);
    NSResponder *firstResponder = [[myTextView window] firstResponder];
#ifndef nodef
    if (mySplitView) {
		NSArray *subViews = [mySplitView subviews];
		for (NSUInteger i=0;i<[subViews count];i++) {
			if ([[subViews objectAtIndex: i] documentView] == firstResponder) {
				myTextView = firstResponder;
				return myTextView;
			}
		}
    } else {
		return myTextView;
    }
#else
    // look through our list of text views
    for (NSUInteger i=0;i<[mAllTextViews count];i++) {
		if ([mAllTextViews objectAtIndex: i] == firstResponder) {
			myTextView = firstResponder;
			return myTextView;
		}
    }
#endif
    return myTextView;
}
- (void) changeTextViewFocus: (NSNotification *)notification
{
#ifdef nodef
    static bool noRecurse = false;
    if (!noRecurse) {
		noRecurse = true;
		NSArray *subViews = [mSplitView subviews];
		// also, check for an extra pane needed
		bool gotCollapsed = false;
		if ([subViews count] < 2 || ![mSplitView isSubviewCollapsed: [subViews objectAtIndex: 0]]) {
			[self insertSplitView];
		}
		// what about removing a subpane?
		subViews = [mSplitView subviews];
		bool needsRefresh = false;
		for (NSUInteger i=1;i<[subViews count];i++) {
			if ([mSplitView isSubviewCollapsed: [subViews objectAtIndex: i]]) {
				NSScrollView *view = (NSScrollView *)[subViews objectAtIndex: i];
				[mAllTextViews removeObject: [view documentView]]; // remove text view from list
				//NSTextView *textView = (NSTextView *)[view documentView];
				// here's the magic to have both view edit the same text
				//[[textView layoutManager] autorelease];
				[view removeFromSuperview];
				subViews = [mSplitView subviews];
				i--;
				needsRefresh = true;
			}
		}
		if (needsRefresh) {
			[mSplitView adjustSubviews];
			[self updateRulers];
		}
		noRecurse = false;
    }
#else
    myTextView = [notification object];
#endif
}

#pragma mark Menu Options
- (IBAction) toggleShowInvisibles: (id) sender
{
    myShowInvisibles = !myShowInvisibles;
    [sender setState: myShowInvisibles];
    // force the syntax coloring to re-do
    // we really need to do _all_ of the layout managers in all the panes...
    NSArray *textViews = [self allTextViews];
    for (NSUInteger i=0;i<[textViews count];i++) {
		[[[textViews objectAtIndex: i]layoutManager] setShowsInvisibleCharacters: myShowInvisibles];
    }
    //[[myTextView layoutManager] setShowsControlCharacters: myShowInvisibles];
    //NSString *string = [myTextView string];
    //[[myTextView textStorage] edited:  NSTextStorageEditedCharacters range: NSMakeRange(0, [string length]) changeInLength: 0];
    //	[myTextView refresh];
}
- (IBAction) toggleShowLineNumbers: (id) sender
{
    myShowLineNums = !myShowLineNums;
    [sender setState: myShowLineNums];
    // force the syntax coloring to re-do
    // we really need to do _all_ of the layout managers in all the panes...
    NSArray *scrollViews = [self allScrollViews];
    for (NSUInteger i=0;i<[scrollViews count];i++) {
		int flags = [[scrollViews objectAtIndex: i] showFlags];
		if (myShowLineNums) {
			flags |= IDEKit_kShowLineNums;
		} else {
			flags &= ~IDEKit_kShowLineNums;
		}
		[[scrollViews objectAtIndex: i] setShowFlags: flags];
    }
}
- (IBAction) toggleShowFolding: (id) sender
{
    myShowFolding = !myShowFolding;
    [sender setState: myShowFolding];
    // force the syntax coloring to re-do
    // we really need to do _all_ of the layout managers in all the panes...
    NSArray *scrollViews = [self allScrollViews];
    for (NSUInteger i=0;i<[scrollViews count];i++) {
		int flags = [[scrollViews objectAtIndex: i] showFlags];
		if (myShowFolding) {
			flags |= IDEKit_kShowFolding;
		} else {
			flags &= ~IDEKit_kShowFolding;
		}
		[[scrollViews objectAtIndex: i] setShowFlags: flags];
    }
}
- (IBAction) toggleSyntaxColor: (id) sender
{
    mySyntaxColor = !mySyntaxColor;
    [sender setState: mySyntaxColor];
    // force the syntax coloring to re-do (only need to do the single textStorage)
    NSString *string = [myTextView string];
    [[myTextView textStorage] edited:  NSTextStorageEditedCharacters range: NSMakeRange(0, [string length]) changeInLength: 0];
    //	[myTextView refresh];
}
- (IBAction) toggleAutoIndent: (id) sender
{
    switch ([sender tag]) {
		case 0:
			mySkipAutoIndent = YES;
			break;
		case 1:
			mySkipAutoIndent = NO;
			myTrySmartIndent = NO;
			break;
		case 2:
			mySkipAutoIndent = NO;
			myTrySmartIndent = YES;
			break;
    }
}
- (IBAction) toggleAutoClose: (id) sender
{
    myAutoClose = !myAutoClose;
    [sender setState: myAutoClose];
}

- (IBAction) toggleWordWrap: (id) sender
{
    //[self getFocusedView];
    myWordWrap = !myWordWrap;
    [sender setState: myWordWrap];
	
    NSArray *textViews = [self allTextViews];
    for (NSUInteger i=0;i<[textViews count];i++) {
		id aView = [textViews objectAtIndex: i];
		if (myWordWrap) {
			//[myTextView setMinSize: NSMakeSize([myScrollView contentSize].width,0)];
			[aView setFrameSize: NSMakeSize([myScrollView documentVisibleRect].size.width,[myTextView frame].size.height)];
			[[aView textContainer] setWidthTracksTextView: NO];
			// now we have to force a "resize" so it will, in fact, track
			[[aView textContainer] setContainerSize: NSMakeSize([myScrollView documentVisibleRect].size.width,[myTextView frame].size.height)];
		} else {
			[aView setMinSize: NSMakeSize(20000,0)];
			[[aView textContainer] setWidthTracksTextView: YES];
		}
    }
    // we need to update breakpoints
    [self forceBreakpointRedraw];
}
- (IBAction) optionMenuNoop: (id) sender
{
}


#pragma mark Indenting

- (void) setFont: (NSFont *) font
{
    [myTextView setFont: font];
    if (myTabStops < 0) { // relative to the size of a space
		float realTabStops = myTabStops;
		myTabStops = 0.0;
		[myTextView setUniformTabStops:realTabStops]; // force the NSParagraphStyleAttributeName to be reset
    }
}

- (IBAction) redent: (id) sender
{
}


#pragma mark AutoComplete


- (IBAction) doCompletion: (id) sender
{
    NSString *value = [sender representedObject];
    NSRange completeRange = [myTextView rangeForUserCompletion];
    [myTextView setSelectedRange: completeRange];
    [myTextView insertText: value];
}

- (IBAction) complete: (id) sender
{
    // Used in both 10.2 and 10.3 (replace default complete to use our own UI, etc...)
    NSRange completeRange = [myTextView rangeForUserCompletion];
    NSArray *completions = [myContext srcEditView: self autoCompleteIdentifier: [[myTextView string] substringWithRange: completeRange] max: 100];
    if (completions && [completions count]) {
		//NSLog(@"Completions %@",completions);
		// for now, just go to the first one
		if ([completions count] == 1) {
			[myTextView setSelectedRange:completeRange];
			[myTextView insertText: [completions objectAtIndex: 0]];
		} else {
			id completion = [myTextView popupCompletionAtInsertion: completions];
			if (completion) {
				NSRange completeRange = [myTextView rangeForUserCompletion];
				[myTextView setSelectedRange: completeRange];
				[myTextView insertText: completion];
			}
		}
    } else {
		[myTextView popupHelpTagAtInsertion: [[[NSAttributedString alloc] initWithString: @"No completions"] autorelease]];
    }
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index
{
    NSArray *completions = [myContext srcEditView: self autoCompleteIdentifier: [[textView string] substringWithRange:charRange] max: 100];
    if ([completions count]) {
		// add these to whatever it thinks is good
		NSMutableArray *retval = [words mutableCopy];
		BOOL setIndex = NO;
		for (int i=0;i<[completions count];i++) {
			id complete = [completions objectAtIndex: i];
			if (![retval containsObject: complete]) {
				if (!setIndex) {// pick our first item by default
					*index = [retval count];
					setIndex = YES;
				}
				[retval addObject: complete];
			}
		}
		return retval;
    }
    return words;
}


-(void) updatePseudoTooltipForView: (NSTextView *)view
{
    // make sure the tool tip refer to the current line only
    [view removeAllToolTips];
    // get the bounds of the current line
    NSRange range = [[view string] lineRangeForRange: [view selectedRange]];
    NSRange glyphRange = [[view layoutManager] glyphRangeForCharacterRange: range actualCharacterRange: NULL];
    NSRect boundingRect = [[view layoutManager] boundingRectForGlyphRange: glyphRange inTextContainer: [view textContainer]];
    boundingRect.size.width = 9999.0;
    [view addToolTipRect: boundingRect owner: self userData: NULL];
}
- (NSString *) view: (NSView *)view stringForToolTip: (NSToolTipTag) tag point: (NSPoint) point userData: (void *)userData
{
    // see if the context has it
    NSString *tip = NULL;
    if ([myContext respondsToSelector: @selector(toolTipForSrcEditView:)]) {
		tip = [myContext toolTipForSrcEditView: (IDEKit_SrcEditView *)view];
    }
    if (!tip) {
		NSRange range = [(NSTextView *)view selectedRange];
		range = myLineCache->UnfoldedRange(range);
		tip = [myCurrentLanguage toolTipForRange: range source: [self string]];
    }
    if (!tip) {
#ifdef nomore
		//tip = @"argle bargle";
		NSRange lineRange = [[view string] lineRangeForRange: [view selectedRange]];
		NSString *line = [[view string] substringWithRange:lineRange];
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return line;
		// for now
#endif
    }
    return tip;
}

#pragma mark Delegate Commands
// pass along various delegate commands to the context, as needed
- (void)textDidChange: (NSNotification *)aNotification
{
    // pass along to context
    if ([myContext respondsToSelector: @selector(textDidChange:)]) {
		[myContext textDidChange: aNotification];
    }
    // update the tooltip now
    [self updatePseudoTooltipForView: [aNotification object]];
}

- (void) removeTempBackgroundColor: (NSValue *)valueRange
{
	//    [[myTextView layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:[valueRange rangeValue]];
    // remove _all_ of them
    [[myTextView layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0,[[myTextView string] length])];
}
- (BOOL)textView:(NSTextView *)textView shouldInterpretKeyEvents: (NSArray *)eventArray
{
    [self removeTempBackgroundColor: NULL]; // if we have a temp hilite, remove it now
    // unclear how to handle multiple events correctly yet...
    for (NSUInteger i=0;i<[eventArray count];i++) {
		NSEvent *event = [eventArray objectAtIndex: i];
		NSUInteger modifiers = [event modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask); // just the modifieres we look for
		if (myAutoClose && myCurrentLanguage && (modifiers  | NSShiftKeyMask) == NSShiftKeyMask) { // only look at things that have at most a shift key
			NSString *closer = [myCurrentLanguage getAutoCloseMatch: [event charactersIgnoringModifiers]];
			// this is actually pretty ugly - we really should instead return NO and treat this as a macro
			if (closer) {
				// got a closing event, post that as a key down to happen next
				NSEvent *closeEvent = [NSEvent keyEventWithType: [event type]
													   location: [event locationInWindow]
												  modifierFlags: 0
													  timestamp:1
												   windowNumber:[[NSApp mainWindow] windowNumber]
														context:[NSGraphicsContext currentContext]
													 characters:closer
									charactersIgnoringModifiers:closer
													  isARepeat:NO
														keyCode: 0];
				
				[NSApp postEvent:closeEvent atStart: NO];
				NSEvent *arrowEvent = [NSEvent keyEventWithType: [event type]
													   location: [event locationInWindow]
												  modifierFlags: 0
													  timestamp:1
												   windowNumber:[[NSApp mainWindow] windowNumber]
														context:[NSGraphicsContext currentContext]
													 characters:[NSString stringWithFormat: @"%C",NSLeftArrowFunctionKey]
									charactersIgnoringModifiers:[NSString stringWithFormat: @"%C",NSLeftArrowFunctionKey]
													  isARepeat:NO
														keyCode: 0];
				[NSApp postEvent:arrowEvent atStart: NO];
				continue; // and don't try to process the command
			}
		}
		// auto-hilite to openning param
		if ((modifiers  | NSShiftKeyMask) == NSShiftKeyMask) { // only look at things that have at most a shift key
			NSString *closer = [event charactersIgnoringModifiers];
			NSString *openner = NULL;
			if ([closer isEqualToString: @")"]) openner = @"(";
			if ([closer isEqualToString: @"]"]) openner = @"[";
			if ([closer isEqualToString: @"}"]) openner = @"{";
			if (openner) {
				int curloc = [myTextView selectedRange].location;
				int openloc = [myTextView balanceBackwards: curloc startCharacter: [openner characterAtIndex: 0]];
				if (openloc >= 0) {
					NSRange hilite = NSMakeRange(openloc,1); //NSMakeRange(openloc+1,curloc - openloc -1);
					[[myTextView layoutManager] addTemporaryAttributes:[NSDictionary dictionaryWithObject:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName] forCharacterRange: hilite];
					[self display];
					[self performSelector: @selector(removeTempBackgroundColor:) withObject: [NSValue valueWithRange:hilite] afterDelay: 0.5];
				} else {
					NSBeep();
				}
				continue; // and don't try to process the command
			}
		}
		// Hopefully this is the correct ordering
		// @ = command
		// ~ = alt
		// ^ = control
		// $ = shift
		unichar commands[10];
		int len = 0;
		if (modifiers & NSCommandKeyMask)
			commands[len++] = '@';
		if (modifiers & NSAlternateKeyMask)
			commands[len++] = '~';
		if (modifiers & NSControlKeyMask)
			commands[len++] = '^';
		if (modifiers & NSShiftKeyMask)
			commands[len++] = '$';
		commands[len++] = [[event charactersIgnoringModifiers] characterAtIndex: 0];
		// see if commands are in our bindings
		NSString *key = [NSString stringWithCharacters: commands length: len];
		//NSLog(@"Trying bound key %@",key);
		NSUserDefaults *defaults = myContext ? [myContext defaultsForSrcEditView: self] : [NSUserDefaults standardUserDefaults];
		NSDictionary *keyBinds = [defaults dictionaryForKey: IDEKit_KeyBindingsKey];
		NSString *selector = [keyBinds objectForKey: key];
		if (selector) {
			//NSLog(@"Corresponding selector %@",selector);
			SEL sel = NSSelectorFromString(selector);
			if ([textView respondsToSelector: sel]) {
				[textView doCommandBySelector: sel]; // for commands implemented by sel
				return NO;
			}
			// for commands implemented by us...
			if ([self respondsToSelector: sel]) {
				[self doCommandBySelector: sel];
				return NO;
			}
		}
    }
    return YES;
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    // see if the context disabled editing...
    BOOL retval = YES;
    if (myContext) retval = [myContext canEditForSrcEditView: self];
#ifdef qIDEKIT_UseCache
    if (retval && myFoldingOperation==0) { // only do this if we aren't folding
		myLineCache->ReplaceRangeWithString(affectedCharRange, replacementString);
    }
#endif
    return retval;
}
#ifdef qPEROXIDE
- (IBAction) gotoTagFromMenu: (id) sender
{
    PrXDocument *project = [myContext owningProjectForSrcEditView: self];
    [project gotoTag: [sender representedObject]];
}
#endif
- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    NSRange range = [[notification object] selectedRange];
    NSString *text = [[notification object] string];
    int line = [myTextView lineNumberFromOffset: range.location];
    int unfoldedLineNum = [self lineNumberFromOffset: [self unfoldedLocation:range.location]];
    NSRange entireLine = [self nthLineRange: line];
    int col = range.location - entireLine.location;
    //NSLog(@"Changed selection to %d,%d",line,col);
    NSString *startString = [text substringWithRange: NSMakeRange(entireLine.location,col)];
    // figure out the width (including tabs) of this text
    int realCols = 0;
    for (NSUInteger i=0;i<col;i++) {
		if ([startString characterAtIndex:i] == '\t') {
			realCols = (realCols + 4) / 4 * 4; // round up to next tab stop
		} else {
			realCols++;
		}
    }
    IDEKit_Breakpoint *bp = NULL; // update the focused breakpoint in the inspector
    if (range.length == 0) {
		[(IDEKit_SrcScroller *)[[[notification object] superview]superview] setLine: unfoldedLineNum col: realCols+1]; // convert to scroll view
		bp = [self getBreakpoint: unfoldedLineNum];
    } else {
		NSRange lineRange = NSMakeRange(unfoldedLineNum,[self lineNumberFromOffset: [self unfoldedLocation: range.location + range.length]] - unfoldedLineNum+1);
		if (lineRange.length == 0)
			bp = [self getBreakpoint: unfoldedLineNum];
		NSRange colsRange = NSMakeRange(realCols+1,range.length);
		[(IDEKit_SrcScroller *)[[[notification object] superview]superview] setLineRange: lineRange colRange: colsRange]; // convert to scroll view
    }
    [[IDEKit_BreakpointInspector sharedBreakpointInspector] setBreakpoint:bp]; // and focus on this breakpoint
	
    if (range.length) {
		// see if we have a double click for the last one with option down
		NSEvent *event = [NSApp currentEvent];
		if ([event type] == NSLeftMouseUp) {
			if ([event clickCount] == 2 && ([event modifierFlags] & (NSAlternateKeyMask | NSCommandKeyMask))) {
				//NSLog(@"Command/Option Double click");
#ifdef nodef
				PrXDocument *project = [myContext owningProjectForSrcEditView: self];
				if (project) {
					NSArray *definitions = [project declarationsForIdentifier: [text substringWithRange: range]];
					if (definitions && [definitions count]) {
						// for now, just go to the first one
						if ([definitions count] == 1) {
							[project gotoTag: [definitions objectAtIndex: 0]];
						} else {
							NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Jump To Def"] autorelease];
							for (NSUInteger i=0;i<[definitions count];i++) {
								id tag = [definitions objectAtIndex: i];
								id item = [menu addItemWithTitle: [tag ETagsAsMenuItem] action: @selector(gotoTagFromMenu:) keyEquivalent: @""];
								[item setRepresentedObject: tag];
								[item setTarget: self];
							}
							[myTextView popupSmallMenuAtInsertion: menu];
						}
					}
				}
#else
				[myContext srcEditView: self specialDoubleClick: [event modifierFlags] selection: [text substringWithRange: range]];
#endif
			}
		}
    }
    // update the tooltip now
    [self updatePseudoTooltipForView: [notification object]];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    // other useful selectors found in <NSResponder.h> in
    // 		@interface NSResponder (NSStandardKeyBindingMethods)
    myTextView = aTextView;
    if (aSelector == @selector(insertNewline:) && mySkipAutoIndent == NO) {
		if (myTrySmartIndent) {
			int action = IDEKit_kIndentAction_None;
			if (myCurrentLanguage) {
				NSRange selectedRange = [myTextView selectedRange]; // figure out the start of this line
				selectedRange.length = 0; // make sure that we work with the start of the range
				NSString *text = [myTextView string];
				NSUInteger startIndex;
				NSUInteger lineEndIndex;
				NSUInteger contentsEndIndex;
				[text getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: selectedRange];
				NSString *thisLine = [text substringWithRange: NSMakeRange(startIndex,lineEndIndex - startIndex)];
				
				action = [myCurrentLanguage autoIndentLine: @"" last: thisLine];
			}
			switch (action) {
				case IDEKit_kIndentAction_None:
					[myTextView insertNewlineAndDent: self];
					break;
				case IDEKit_kIndentAction_Indent:
					[myTextView insertNewlineAndIndent: self];
					break;
				case IDEKit_kIndentAction_Dedent:
					[myTextView insertNewlineAndDedent: self];
					break;
				default:
					return NO; // let it do a normal newline
					break;
			}
		} else  {
			[myTextView insertNewlineAndDent: self];
		}
		return YES;
    } else if (aSelector == @selector(insertBacktab:)) {
		// find next location of template
		//			[templateAttributes setObject: [NSNumber numberWithInt: 1] forKey: IDEKit_TemplateInternalAttributeName];
		//		NSLog(@"textView: %@ doCommandBySelector: %s",aTextView,aSelector);
		// search forward until we find something with a TextHammerTemplate attribute
		id storage =[myTextView textStorage];
		for (NSUInteger i=[myTextView selectedRange].location;i<[(NSString *)storage length];) {
			NSRange range;
			//id attrib = [storage attribute: IDEKit_TemplateInternalAttributeName atIndex: i effectiveRange: &range];
			id attrib = [storage attribute: IDEKit_TemplateInternalAttributeName atIndex: i longestEffectiveRange: &range inRange: NSMakeRange(0,[(NSString *)storage length])];
			if (attrib) {
				// found one - but is it where we are?
				if (NSEqualRanges(range,[myTextView selectedRange])) {
					i = range.location + range.length; // move to just past where we were
					continue; // get the _next_ template then
				}
				[myTextView setSelectedRange: range];
				return YES;
			} else {
				i = range.location + range.length; // move to just past where we were
			}
		}
		return NO;
    } else if (aSelector == @selector(expandMacro:)) { // default binding F5
		NSString *name;
		NSArray *params;
		NSRange range = [self buildMacro: &name params: &params];
		if (range.length) {
			NSString *complete = [self expandMacro: name withParams: params];
			if (complete) {
				[myTextView setSelectedRange: range];
				[myTextView insertText: complete];
				return YES;
			}
		}
		return NO;
    } else {
		//NSLog(@"textView: %@ doCommandBySelector: %s",aTextView,aSelector);
		return NO;
    }
}

- (NSString *)massageInsertableText: (NSString *)text // we are about to paste this text - fix indent, tabs, returns, etc...
{
    // first, clean up format (but if don't have a newline, don't force one
    BOOL hadNewLine = [text hasSuffix:@"\n"];
    if (myCurrentLanguage)
		text = [myCurrentLanguage cleanUpStringFromFile: text];
    while ([text hasSuffix: @"\n"] && !hadNewLine) {
		text = [text substringToIndex:[text length]-1]; // remove that
    }
    if (myTrySmartIndent) {
		NSString *currentIndent = [myTextView getCurrentIndentLimited: YES];
		NSArray *lines = [text componentsSeparatedByString:@"\n"]; // split into lines
		NSString *commonIndent = NULL;
		NSEnumerator *i = [lines objectEnumerator];
		NSString *line;
		while ((line = [i nextObject]) != NULL) {
			if ([line length] == 0)
				continue; // ignore empty lines
			NSString *indent = [line leadingIndentString];
			if ([indent length] == [line length])
				continue; // ignore empty indented lines
			if (commonIndent == NULL || [indent length] < [commonIndent length]) {
				commonIndent = indent;
				if ([commonIndent length] == 0)
					break; // no indent in common, stop looking
			}
		}
		// now, reformat each line accordingly
		NSUInteger removeLeading = [commonIndent length];
		NSMutableArray *reformatted = [NSMutableArray array];
		i = [lines objectEnumerator];
		BOOL first = YES;
		while ((line = [i nextObject]) != NULL) {
			// trim out the common leading indent
			if ([line length] < removeLeading || [line isEqualToString: [line leadingIndentString]])
				line = @""; // blank line
			else
				line = [line substringFromIndex:removeLeading];
			if (first) {
				// don't indent the first line - we already are indented in the textview
				[reformatted addObject: line];
				first = NO;
			} else {
				[reformatted addObject: [currentIndent stringByAppendingString:line]];
			}
		}
		return [reformatted componentsJoinedByString:@"\n"];
    }
    return text;
}

- (void) changeLanguage: (id) sender
{
    if ([sender representedObject] != [myCurrentLanguage class]) {
		[self setCurrentLanguage: [[[[sender representedObject] alloc] init] autorelease]];
    }
}
- (void) buildLanguages: (id) sender
{
}
-(void) buildTemplatesInSubmenu: (id)sender
{
}

static id gPopupTextView;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // is this a plugin?
#ifdef notyet
    if ([menuItem action] == @selector(performPlugInTool:)) {
		// it's a plug in
		//NSLog(@"Validating plug in %@",menuItem);
		id repObject = [menuItem representedObject];
		if (repObject /*&& [repObject conformsToProtocol: @protocol(TextHammerTool)]*/) {
			// have the rep object validate?
			if ([repObject respondsToSelector: @selector(validateMenuItem:)]) {
				//NSLog(@"Asking plug in to handle validation of %s",[menuItem tag]);
				[repObject setForObject: self];
				// un-munge the action
				[menuItem setAction: (SEL)[menuItem tag]];
				BOOL retval = [repObject validateMenuItem: menuItem];
				[menuItem setAction: @selector(performPlugInTool:)];
				return retval;
			}
			return YES;
		}
		return NO;
    }
#endif
    // is this a language in a menu?  If so, check the current language
    if ([menuItem action] == @selector(changeLanguage:)) {
		//NSLog(@"Validating language check %@",menuItem);
		if ([menuItem representedObject] == [myCurrentLanguage class])
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    // Handle our options menu
    if ([menuItem action] == @selector(toggleWordWrap:)) {
		if (myWordWrap)
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    if ([menuItem action] == @selector(toggleAutoClose:)) {
		if (myAutoClose)
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    if ([menuItem action] == @selector(toggleScratch:)) {
		if (myIsScratch)
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    if ([menuItem action] == @selector(toggleSyntaxColor:)) {
		if (mySyntaxColor)
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    if ([menuItem action] == @selector(toggleShowInvisibles:)) {
		if (myShowInvisibles)
			[menuItem setState: NSOnState];
		else
			[menuItem setState: NSOffState];
		return YES;
    }
    if ([menuItem action] == @selector(toggleAutoIndent:)) {
		switch ([menuItem tag]) {
			case 0:
				if (mySkipAutoIndent)
					[menuItem setState: NSOnState];
				else
					[menuItem setState: NSOffState];
				break;
			case 1:
				if (mySkipAutoIndent == NO && myTrySmartIndent == NO)
					[menuItem setState: NSOnState];
				else
					[menuItem setState: NSOffState];
				break;
			case 2:
				if (mySkipAutoIndent == NO && myTrySmartIndent == YES)
					[menuItem setState: NSOnState];
				else
					[menuItem setState: NSOffState];
				break;
		}
		return YES;
    }
    if ([menuItem action] == @selector(buildPopUpFuncs:) || ([menuItem action] == @selector(doPopUpFuncsMarker:) && [menuItem representedObject] == NULL)) {
		gPopupTextView = [[IDEKit_SrcScroller lastHit] documentView];
		//NSLog(@"buildPopUpFuncs validate from %@",menuItem);
		// since we are going to remove it, make it go away "later"
		[menuItem retain];
		NSMenu *menu = [menuItem menu];
		// remove the old things
		while ([menu numberOfItems] > 1) {
			[menu removeItemAtIndex: 1];
		}
		if ([menuItem action]  == @selector(doPopUpFuncsMarker:)) {
			[menu removeItemAtIndex: 0]; // this was a sub-menu, not a popup
		}
		// add in the new
		NSArray *markers = [myCurrentLanguage functionList: [myTextView string]];
		if (!markers || ![markers count]) {
			id item = [menu addItemWithTitle: @"No Functions" action: @selector(someImpossibleAction:) keyEquivalent: @""];
			[item setEnabled: NO];
			return YES;
		}
		// sort them as appropriate
		markers = [markers sortedArrayUsingFunction: SortMarkerByRange context: nil];
		for (NSUInteger i=0;i<[markers count];i++) {
			IDEKit_TextFunctionMarkers *marker = [markers objectAtIndex: i];
			NSMenuItem *markerItem = [[[NSMenuItem alloc] initWithTitle:[marker name] action: @selector(doPopUpFuncsMarker:) keyEquivalent:@""] autorelease];
#ifdef notyet
			NSString *imageName = [marker image];
			if (imageName) {
				NSImage *image = NULL;
				NS_DURING {
					image = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[myCurrentLanguage class]] pathForImageResource:imageName]] autorelease]; // look in language plug in first
				} NS_HANDLER {
				} NS_ENDHANDLER
				if (!image) {
					// look in ours
					NS_DURING {
						image = [[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:imageName]] autorelease];
					} NS_HANDLER {
					} NS_ENDHANDLER
				}
				if (image)
					[markerItem setImage:image];
			}
#endif
			[markerItem setRepresentedObject: marker];
			[menu addItem: markerItem];
		}
		if ([menu numberOfItems] > 1)
			return YES;
		return YES;
    }
    if ([menuItem action] == @selector(buildLanguages:)) {
        //NSLog(@"Building languages");
        [menuItem retain];
        NSMenu *menu = [menuItem menu];
        // remove the old things
        while ([menu numberOfItems] > 0) {
            [menu removeItemAtIndex: 0];
        }
        // change the sel of "None"
        [menuItem setAction: @selector(changeLanguage:)];
        // add in the new (sorted)
        NSArray *langs = [IDEKit_GetLanguagePlugIns() sortedArrayUsingSelector:@selector(languageNameCompare:)];
		
        for (NSUInteger i=0;i<[langs count];i++) {
            id lang = [langs objectAtIndex: i];
            NSMenuItem *langItem = [[[NSMenuItem alloc] initWithTitle:[lang languageName] action: @selector(changeLanguage:) keyEquivalent:@""] autorelease];
            [langItem setRepresentedObject: lang];
			if ([myCurrentLanguage class] == lang)
				[langItem setState: NSOnState];
            [menu addItem: langItem];
        }
        return YES;
    }
    if ([menuItem action] == @selector(buildPopUpHeaders:) || ([menuItem action] == @selector(doPopUpHeader:) && [menuItem representedObject] == NULL)) {
		// since we are going to remove it, make it go away "later"
		//NSLog(@"Wanting to rebuild headers");
		[menuItem retain];
		NSMenu *menu = [menuItem menu];
		// remove the old things
		while ([menu numberOfItems] > 1) {
			[menu removeItemAtIndex: 1];
		}
#ifdef qPEROXIDE
		PrXDocument *project = [myContext owningProjectForSrcEditView: self]; // look up identifiers in the project browser database
		NSArray *headers = [project headersForEntry: [project projectEntryForFile: [myContext fileNameForSrcEditView: self]]];
		if (headers && [headers count]) {
			for (NSUInteger i=0;i<[headers count];i++) {
				id marker = [headers objectAtIndex: i];
				NSMenuItem *markerItem = [[[NSMenuItem alloc] initWithTitle:marker action: @selector(doPopUpHeader:) keyEquivalent:@""] autorelease];
				[markerItem setRepresentedObject: marker];
				[menu addItem: markerItem];
			}
		} else {
			NSMenuItem *markerItem = [[[NSMenuItem alloc] initWithTitle:@"No headers" action: NULL keyEquivalent:@""] autorelease];
			[menu addItem: markerItem];
			[markerItem setEnabled: NO];
		}
#endif
		// really should ask project, but for now, first step
		NSDictionary *headers = [myCurrentLanguage headersList:[self string]]; // use our expanded string for this
		NSMutableArray *names = [[headers allKeys] mutableCopy];
		[names sortUsingSelector: @selector(compare:)];
		if ([names count]) {
			NSEnumerator *e = [names objectEnumerator];
			NSString *name;
			while ((name = [e nextObject]) != NULL) {
				NSMenuItem *markerItem = [[[NSMenuItem alloc] initWithTitle:name action: @selector(doPopUpHeader:) keyEquivalent:@""] autorelease];
				[markerItem setRepresentedObject: [headers objectForKey: name]];
				[menu addItem: markerItem];
			}
		}
		
		if ([menu numberOfItems] < 2) {
			id item = [menu addItemWithTitle: @"No Headers" action: @selector(someImpossibleAction:) keyEquivalent: @""];
			[item setEnabled: NO];
		}
    }
    if ([menuItem action] == @selector(buildTemplatesInSubmenu:)) {
        //NSLog(@"Building languages");
        //[self buildSnippetMenu: [menuItem submenu]];
//		NSMenu *snippetMenu = [self buildSnippetMenu: [menuItem submenu]];
//		if (snippetMenu != [menuItem submenu]) {
//			[menuItem setSubmenu:snippetMenu];
//		}
        return YES;
    }
    if ([menuItem action] == @selector(insertTemplate:)) {
		return YES;
    }
    return YES;
}

#pragma mark Text Coloring
// When the text is changed, we can find out
- (void)color: obj from: (NSInteger)startindex to: (NSInteger)endindex matches: (regex_t *) pattern with: color
{
    if (pattern) {
		NSString *text = [obj string];
		regmatch_t pmatch[1];
		pmatch[0].rm_so = startindex;
		pmatch[0].rm_eo = endindex;
		
#ifndef oldregex
		NSData *stringData = [text dataUsingEncoding: NSUnicodeStringEncoding];
#endif
#ifdef qPEROXIDE
		PrXDocument *project = NULL; // look up identifiers in the project browser database
		if (!color) project = [PrXDocument documentForFile: [myContext fileNameForSrcEditView: self]];
#endif
		while
#ifdef oldregex
			(regexec(pattern,[text lossyCString],1,pmatch,REG_STARTEND) == 0 && pmatch[0].rm_eo != pmatch[0].rm_so)
#else
			(re_uniexec(pattern,(unichar *)[stringData bytes],0,NULL,1,pmatch,REG_STARTEND) == 0 && pmatch[0].rm_eo != pmatch[0].rm_so)
#endif
		{
			// found something
			NSRange foundRange = NSMakeRange(pmatch[0].rm_so,pmatch[0].rm_eo - pmatch[0].rm_so);
#ifdef qPEROXIDE
			if (project) {
				color = [project colorForIdentifier: [text substringWithRange: foundRange]];
			}
#endif
			if (color) {
				[obj addAttribute: NSForegroundColorAttributeName
							value: color range: foundRange];
			}
			pmatch[0].rm_so = pmatch[0].rm_eo;
			pmatch[0].rm_eo = endindex;
		}
    }
}
- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // this, btw, is where we would do automatic syntax coloring...
    // Of course, how to tell if the font has change, which is why we wanted this,
    // isn't obvious
    NSTextStorage *obj = [notification object];
    NSUInteger mask =[obj editedMask];
    if (mask == NSTextStorageEditedAttributes)
		return; // don't care about attributes being edited
    NSRange editedRange = [obj editedRange];
    // if we are doing syntax coloring...
    // figure out what we need to recolor - for now, do the entire line
    NSString *text = [obj string];
    NSUInteger startIndex;
    NSUInteger lineEndIndex;
    NSUInteger contentsEndIndex;
    [text getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: editedRange];
    // start by clearing the attributes
    // for some reason, this screws over the selection, so try this
    [obj removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(startIndex,contentsEndIndex-startIndex)];
    if (!myIsMakingTemplate) {
		// if we make templates, we want to leave these attributes, otherwise remove them
		// (though this may end up nuking things that we don't want - better see how to handle
		// selecting & removing text works)
		[obj removeAttribute: IDEKit_TemplateInternalAttributeName range: editedRange];
		//[obj removeAttribute: NSUnderlineStyleAttributeName range: editedRange];
		[obj removeAttribute: IDEKit_TemplateVisualAttributeName range:editedRange];
    }
    //[obj addAttribute: NSForegroundColorAttributeName value: [NSColor blackColor] range: NSMakeRange(startIndex,contentsEndIndex-startIndex)];
    //[obj addAttribute: NSForegroundColorAttributeName value: [NSColor blackColor] range: editedRange];
    if (mySyntaxColor) {
		IDEKit_LexParser *lexer = [myCurrentLanguage lexParser];
		if (lexer) {
			// let new lexer color the thing
			id doc =
#ifdef qPEROXIDE
			[PrXDocument documentForFile: [myContext fileNameForSrcEditView: self]];
#else
			NULL;
#endif
			[lexer colorString: obj range: NSMakeRange(startIndex,contentsEndIndex-startIndex) colorer: doc];
		} else {
			// use old pattern matching
#ifdef qPEROXIDE
			if ([PrXDocument documentForFile: [myContext fileNameForSrcEditView: self]]) {
				// things from the browser
				pattern = [myCurrentLanguage identifierRegex];
				if (pattern) {
					[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: NULL];
				}
			}
#endif
#ifdef nomore
			regex_t *pattern;
			pattern = [myCurrentLanguage keywordRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_Keywords)];
			}
			pattern = [myCurrentLanguage altKeywordRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_AltKeywords)];
			}
			pattern = [myCurrentLanguage preProcessorRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_Preprocessor)];
			}
			pattern = [myCurrentLanguage docCommentRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_DocKeywords)];
			}
			pattern = [myCurrentLanguage stringRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_Strings)];
			}
			pattern = [myCurrentLanguage commentRegex];
			if (pattern) {
				[self color: obj from: startIndex to: contentsEndIndex matches: pattern with: IDEKit_TextColorForColor(IDEKit_kLangColor_Comments)];
			}
#endif
		}
		// for some reason, this screws over the selection, so we are in textStorageDidProcessEditing
		// insteda of textStorageWillProcessEditing
    }
}

#pragma mark PopUp Funcs
// Popup menu Funcs stuff
- (IBAction) buildPopUpFuncs: (id) sender
{
    NSLog(@"Got buildPopUpFuncs");
}
- (IBAction) doPopUpFuncsMarker: (id) sender
{
    //	NSLog(@"Funct marker go to %d",[sender tag]);
    //[self getFocusedView];
    // figure out which text view
    id marker = [sender representedObject];
    id theTextView = /*[sender menu]*/ myTextView;
    if (gPopupTextView)
		theTextView = gPopupTextView;
    [theTextView setSelectedRange: [marker decl]];
    [theTextView scrollRangeToVisible: [marker decl]];
}

- (IBAction) buildPopUpHeaders: (id) sender
{
    NSLog(@"Got buildPopUpHeaders");
}

- (IBAction) doPopUpHeader: (id) sender
{
    id path = [sender representedObject];
    if (path) {
		[[NSDocumentController sharedDocumentController] openQuicklyWithText: path helper: self context: NULL];
    }
}
- (NSArray *) findFilesWithPattern: (NSString *)pattern context: (void *) context flags: (NSInteger) flags
{
    return [self findIncludedFiles: pattern flags: flags];
}

#pragma mark Proxy Support
- (id) currentLanguage
{
    return myCurrentLanguage;
}

- (void) setCurrentLanguage: (id) newLanguage
{
    if (newLanguage == myCurrentLanguage)
		return;
    [myCurrentLanguage autorelease];
    myCurrentLanguage = [newLanguage retain];
    [myCurrentLanguage lexParser]; // make sure that the lex parser is made
    // should recolor everything
    NSString *string = [myTextView string];
    [[myTextView textStorage] edited:  NSTextStorageEditedCharacters range: NSMakeRange(0, [string length]) changeInLength: 0];
    // make sure breakpoints are shown/hidden accordingly
    NSArray *scrollers = [self allScrollViews];
    for (NSUInteger i=0;i<[scrollers count];i++) {
		IDEKit_SrcScroller *scroller = [scrollers objectAtIndex: i];
		int flags = [scroller showFlags];
		if ([myCurrentLanguage wantsBreakpoints]) {
			flags |= IDEKit_kShowBreakpoints;
		} else {
			flags &= ~IDEKit_kShowBreakpoints;
		}
		if ([IDEKit languageSupportFolding: myCurrentLanguage] && myShowFolding) {
			flags |= IDEKit_kShowFolding;
		} else {
			flags &= ~IDEKit_kShowFolding;
		}
		[scroller setShowFlags: flags];
    }
    [self updateSnippets]; // since snippets are language specific
}

- (id<IDEKit_SrcEditContext>) context
{
    return myContext;
}

- (void) setContext: (id<IDEKit_SrcEditContext>) aContext
{
    myContext = aContext;
    // has the language changed?
    if (1 || [aContext currentLanguageClassForSrcEditView: self] != [myCurrentLanguage class]) {
		[self setCurrentLanguage: [[[[aContext currentLanguageClassForSrcEditView: self] alloc] init] autorelease]];
    }
    [self refreshSettingsFromPrefs: YES]; // this context will have different settings
    //[self updateBreakpointsFromProject];  // Caller must do this after it loads the source
}

// These proxy to our real text view (so we can be treated like a text view)
- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([myTextView respondsToSelector: aSelector]) return YES;
    return [super respondsToSelector: aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([myTextView respondsToSelector: aSelector]) {
		return [myTextView methodSignatureForSelector: aSelector];
    }
    return NULL;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([myTextView respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:myTextView];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

#pragma mark Split views
// our split view support
- (IBAction) insertSplitView: (id) sender;
{
    if (mySplitView == nil) {
		// make the split view, inside us (with our old scroll view inside it)
		mySplitView = [[[NSSplitView alloc] initWithFrame: [myScrollView frame]] autorelease];
		[self addSubview: mySplitView];
		[mySplitView setFrame: [self frame]];
		[mySplitView addSubview: myScrollView];
		[mySplitView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    }
    NSRect frame = [mySplitView frame];
    frame.origin.y = frame.size.height;
    frame.size.height = frame.size.height / 2;
    // save off our current values
    NSTextView *oldTextView = myTextView;
    IDEKit_SrcScroller *oldScrollView = myScrollView;
    // make us anew, so that everything points back to us
    [NSBundle loadOverridenNibNamed: @"IDEKit_SrcEditView" owner: self];
    [self addSubview: myScrollView];
    [myScrollView setFrame: [self frame]];
    // grab the new values
    IDEKit_SrcScroller *newScrollView = myScrollView;
    NSTextView *newTextView = myTextView;
    // restore the old
    myScrollView = oldScrollView;
    // since the new one goes above, nuke the fmt option here
    [newScrollView setShowFlags: [myScrollView showFlags]& (~IDEKit_kShowFmtPopup)];
    myTextView = oldTextView;
	
    //[mAllTextViews addObject: newTextView];
    //[self makeRulersForView: newTextView inView: newScrollView];
    // here's the magic to have both view edit the same text
    NSTextStorage *masterStorage = [myTextView textStorage];
    [masterStorage addLayoutManager: [[newTextView layoutManager] retain]];
	
#ifdef nomore
    [masterStorage retain]; // this retain looks ugly, but it prevents problems when we close the split view
    id layout = [[IDEKit_SrcLayoutManager alloc] init];
    [layout replaceTextStorage: [myTextView textStorage]];
    [[newTextView textContainer] replaceLayoutManager: layout];
    [layout release];
#else
    // the layout manager has already been replaced (in awake)
#endif
    [newTextView setUsesRuler: YES]; // this gets turned off when we replace layout manager
    [newTextView setRulerVisible: YES];
    [newScrollView setHasHorizontalRuler: NO];
    [newScrollView setHasVerticalRuler: YES];
	
    [[myTextView layoutManager] setShowsInvisibleCharacters: myShowInvisibles];
    [newTextView setHorizontallyResizable: YES];
	
    [newTextView setDelegate: self];
    if (myWordWrap) {
		//[myTextView setMinSize: NSMakeSize([myScrollView contentSize].width,0)];
		[newTextView setFrameSize: NSMakeSize([myScrollView documentVisibleRect].size.width,[myTextView frame].size.height)];
		[[newTextView textContainer] setWidthTracksTextView: YES];
		// now we have to force a "resize" so it will, in fact, track
		[[newTextView textContainer] setContainerSize: NSMakeSize([myScrollView documentVisibleRect].size.width,[myTextView frame].size.height)];
    } else {
		[newTextView setMinSize: NSMakeSize(20000,0)];
		[[newTextView textContainer] setWidthTracksTextView: NO];
    }
    [[newTextView layoutManager] setShowsInvisibleCharacters: myShowInvisibles];
	
    [[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(changeTextViewFocus:)
	 name:NSViewFocusDidChangeNotification
	 object:newTextView];
	
    //[clipView setDocumentView: newTextView]; // clip on our text view as well
    //[view setContentView: clipView];
    [newScrollView setHasHorizontalScroller: YES]; // so turn on the horizontal scroll bar
    [newScrollView setHasVerticalScroller: YES];
    //NSArray *subViews = [mySplitView subviews];
    [mySplitView addSubview: newScrollView positioned: NSWindowBelow relativeTo: sender];
    [mySplitView adjustSubviews];
    // make sure that
#ifdef nodef
    // make sure that the rulers are correct
    if (mShowRulers) {
		[view setRulersVisible:YES];
    }
    //[self updateRulers];
#endif
}
- (IBAction) closeSplitView: (id) sender;
{
    // we just get rid of whomever sent us, right?
    BOOL needAddFmt = NO;
    if ([sender showFlags] & IDEKit_kShowFmtPopup) {
		// getting rid of pane with format, so add them to another
		needAddFmt = YES;
    }
    [sender removeFromSuperview];
    [mySplitView adjustSubviews];
    id subviews = [mySplitView subviews];
    IDEKit_SrcScroller *lastScroller = [subviews objectAtIndex: 0];
    if (sender == myScrollView)
		myScrollView = lastScroller; // that was myScrollView that went away
    if (myTextView == [sender contentView])
		myTextView = [lastScroller documentView];
    if (needAddFmt) {
		[lastScroller setShowFlags: [lastScroller showFlags] | IDEKit_kShowFmtPopup];
    }
}
- (NSArray *) allScrollViews
{
    if (mySplitView) {
		return [mySplitView subviews];
    } else {
		return [NSArray arrayWithObject: myScrollView];
    }
}

- (NSArray *) allTextViews
{
    if (mySplitView) {
		id viewList = [mySplitView subviews];
		NSMutableArray *retval = [NSMutableArray arrayWithCapacity: [viewList count]];
		for (NSUInteger i=0;i<[viewList count];i++) {
			[retval addObject: [[viewList objectAtIndex: i] documentView]];
		}
		return retval;
    } else {
		return [NSArray arrayWithObject: myTextView];
    }
}

#pragma mark Contextual Menu

- (NSMenu *) menu
{
    if (myContextualMenu) {
		if (myContext) {
			return [myContext updateContextualMenu: myContextualMenu forSrcEditView: self];
		}
		return myContextualMenu;
    } else {
		return [super menu];
    }
}
#pragma mark Printing
- (void)drawRect:(NSRect)r
{
}

#pragma mark Unqiue file id
- (void) setUniqueFileID: (IDEKit_UniqueID *)fileID
{
    [myUniqueID setRepresentedObject:NULL forKey: @"IDEKit_SrcEditView"]; // remove us from the old one
    [myUniqueID release];
    myUniqueID = [fileID retain];
    [myUniqueID setRepresentedObject:self forKey: @"IDEKit_SrcEditView"];
}

- (IDEKit_UniqueID *) uniqueFileID
{
    return myUniqueID;
}
+ (IDEKit_SrcEditView *)srcEditViewAssociatedWith: (IDEKit_UniqueID *)fileID
{
    return [fileID representedObjectForKey:@"IDEKit_SrcEditView"];
}

- (void) setDisplaysSnapshot: (IDEKit_SnapshotFile *)snapshot
{
    if (snapshot && [self displayingSnapshot] == snapshot)
		return; // already there...
    if ([self displayingSnapshot]) {
//deprecated
//		[self updateProjectWithBreakpoints];
    }
    if (snapshot) {
		[self setUniqueFileID: [snapshot uniqueID]];
		[self setString:[self massageInsertableText:[snapshot source]]];
    } else {
		[self setUniqueFileID: [IDEKit_UniqueID uniqueID]]; // make us a new, unique view
		[self setString: @""]; // and no source
    }
    [self updateBreakpointsFromProject];
}
- (IDEKit_SnapshotFile *) displayingSnapshot
{
    return [IDEKit_SnapshotFile snapshotFileAssociatedWith: myUniqueID];
}

@end


@implementation NSObject(IDEKit_SrcEditContext)
- (Class) currentLanguageClassForSrcEditView: (IDEKit_SrcEditView *) view
{
    return [IDEKit languageFromFileName: [self fileNameForSrcEditView: view]withContents: [view string]];
}
- (NSString *) fileNameForSrcEditView: (IDEKit_SrcEditView *) view
{
    return @"";
}
- (id) owningProjectForSrcEditView: (IDEKit_SrcEditView *) view
{
    return self; //[PrXDocument documentForFile:[self fileName]];
}
- (BOOL) canEditForSrcEditView: (IDEKit_SrcEditView *) view
{
    return YES;
}
- (void) srcEditView: (IDEKit_SrcEditView *) view specialDoubleClick: (NSInteger) modifiers selection: (NSString *) selection
{
}
- (NSArray *) srcEditView: (IDEKit_SrcEditView *) view autoCompleteIdentifier: (NSString *) name max: (NSInteger) max
{
    return NULL;
}
#ifdef nomore
- (NSDictionary *) getBreakPointsForSrcEditView: (IDEKit_SrcEditView *) view	// get the breakpoints for this one file
{
#ifdef nomore
    // One should use the IDEKit_BreakpointManager, but we won't require it
    return [NSDictionary dictionary]; // make an empty set
#else
    return [[IDEKit_BreakpointManager sharedBreakpointManager] getBreakPointsForFile: [view uniqueFileID]];
#endif
}
#endif
- (void) srcEditView: (IDEKit_SrcEditView *) view setBreakPoints: (NSDictionary *)breakPoints // notifies the settting of breakpoints for this one file
{
    // ignore this - just something letting us know what happened
}

- (NSUserDefaults *) defaultsForSrcEditView: (IDEKit_SrcEditView *) view
{
    return [NSUserDefaults standardUserDefaults];
}
- (NSMenu *) updateContextualMenu: (NSMenu *) menu forSrcEditView: (IDEKit_SrcEditView *) view
{
    // this menu is what the myContextualMenu outlet is set to - we can make a new one if we want...
    return menu;
}
- (NSString *) toolTipForSrcEditView: (IDEKit_SrcEditView *) view
{
    return NULL;
}

- (NSMenu *) srcEditView: (IDEKit_SrcEditView *) view breakpointMenuForLine: (NSInteger) line;
{
    return NULL;
}
@end