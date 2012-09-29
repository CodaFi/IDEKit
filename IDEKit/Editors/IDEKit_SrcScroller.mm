//
//  SrcScroller.mm
//  PeROXIDE
//
//  Created by Glenn Andreas on Sun Feb 09 2003.
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

#import "IDEKit_SrcScroller.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_TextView.h"
#import "IDEKit_TextViewExtensions.h"
#import "IDEKit_SrcEditViewFolding.h"
#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_Breakpoint.h"
#import "IDEKit_BreakpointInspector.h"

#define BreakPointThickness	16.0
#define LineNumberThickness	32.0
#define FoldingThickness	16.0

static id gLastHit;
@implementation IDEKit_SrcScroller
+ (Class)rulerViewClass
{
    return [IDEKit_BreakPointRuler class];
}

+ (id)lastHit // used for split hit detection
{
    return gLastHit;
}
// record the last hit so we know where split version were hit
- (NSView *)hitTest:(NSPoint)aPoint
{
    gLastHit = self;
    return [super hitTest: aPoint];
}
- (id) init {
    self = [super init];
    if (self) {
        // Initialization code here.
	myShowFlags = IDEKit_kShowNavPopup | IDEKit_kShowFmtPopup | IDEKit_kShowSplitter | IDEKit_kShowUnsplitter | IDEKit_kShowBreakpoints | IDEKit_kShowLineNums;
    }
    return self;
}
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
	myShowFlags = IDEKit_kShowNavPopup | IDEKit_kShowFmtPopup | IDEKit_kShowSplitter | IDEKit_kShowUnsplitter | IDEKit_kShowBreakpoints | IDEKit_kShowLineNums;
    }
    return self;
}
- (void) dealloc
{
    [myUnsplitter release];
    [mySplitter release];
    [myNavPopup release];
    [myFmtPopup release];
    [super dealloc];
}
- (void) awakeFromNib
{
    [self setHasHorizontalScroller: YES];
    [self setHasVerticalScroller: YES];

    [self setHasHorizontalRuler: NO];
    if (myShowFlags & (IDEKit_kShowBreakpoints | IDEKit_kShowLineNums | IDEKit_kShowFolding)) {
	[self setHasVerticalRuler: YES]; // for break points
	[self setRulersVisible: YES];
    } else {
	[self setHasVerticalRuler: YES]; // for break points later
	[self setRulersVisible: YES]; // we might later show line nums
    }
    // keep the unsplitter handy
    [myUnsplitter retain];
    [myUnsplitter removeFromSuperview];

    [myNavPopup retain];
    if (myShowFlags & IDEKit_kShowNavPopup) {
	[self addSubview: myNavPopup];
    } else {
	[myNavPopup removeFromSuperview];
    }
    [myFmtPopup retain];
    if (myShowFlags & IDEKit_kShowFmtPopup) {
	[self addSubview: myFmtPopup];
    } else {
	[myFmtPopup removeFromSuperview];
    }
    [mySplitter retain];
    if (myShowFlags & IDEKit_kShowSplitter) {
	[self addSubview: mySplitter];
    } else {
	[mySplitter removeFromSuperview];
    }
    // since we've already got this embedded, is it needed?
    [self setDocumentView: subView];
    [subView setFrame:[[self contentView] frame]];
}
- (void) tile
{
    // Besides putting the  popup buttons to the left of the horizontal scroll, we also
    // add the splitter/unsplitter as needed
    NSRect scrollerRect, buttonRect, splitterRect;
    [super tile];
    // place the buttons next to the scroller
    scrollerRect = [[self horizontalScroller] frame];
    //NSLog(@"Tile with show flags %X",myShowFlags);
    if (myShowFlags & IDEKit_kShowNavPopup) {
	buttonRect = [myNavPopup frame]; // keep the width constant
	// put it on the left
	NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, buttonRect.size.width, NSMinXEdge);
	[myNavPopup setFrame: buttonRect];
    }
    if (myShowFlags & IDEKit_kShowFmtPopup) {
	buttonRect = [myFmtPopup frame]; // keep the width constant
				  // put it on the left
	NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, buttonRect.size.width, NSMinXEdge);
	[myFmtPopup setFrame: buttonRect];
    }
    [[self horizontalScroller] setFrame: scrollerRect];

    // place the splitter on vertical scroller
    scrollerRect = [[self verticalScroller] frame];
    if (myShowFlags & IDEKit_kShowSplitter) {
	splitterRect = [mySplitter frame];
	// put it on top
	NSDivideRect(scrollerRect, &splitterRect, &scrollerRect, 18 /*splitterRect.size.height*/, NSMinYEdge);
	[mySplitter setFrame: splitterRect];
	// do we want to show the unsplitter?
	BOOL needUnsplitter = NO;
	if ([myUnsplitter superview] == NULL) {
	    // see if we need it
	    if ([[self superview] isMemberOfClass: [NSSplitView class]]  && [[[self superview] subviews] count] > 1) {
		// yes, need to add it
		needUnsplitter = YES;
		[self addSubview: myUnsplitter];
	    }
	} else {
	    if ([[self superview] isMemberOfClass: [NSSplitView class]] == NO || [[[self superview] subviews] count] == 1) {
		// no, remove it
		[myUnsplitter removeFromSuperview];
	    } else {
		needUnsplitter = YES;
	    }
	}
	if (needUnsplitter) { // put below splitter
	    splitterRect = [myUnsplitter frame];
	    NSDivideRect(scrollerRect, &splitterRect, &scrollerRect, 18 /*splitterRect.size.height*/, NSMinYEdge);
	    [myUnsplitter setFrame: splitterRect];
	}
    }
    // finally show the scroll bar where it fell
    [[self verticalScroller] setFrame: scrollerRect];
}

- (void) setShowFlags: (NSInteger) flags
{
    if (flags != myShowFlags) {
	//NSLog(@"Changing show flags from %X to %X",myShowFlags,flags);
	if ((myShowFlags & IDEKit_kShowNavPopup) != (flags & IDEKit_kShowNavPopup)) {
	    if (flags & IDEKit_kShowNavPopup) {
		[self addSubview: myNavPopup];
	    } else {
		[myNavPopup removeFromSuperview];
	    }
	}
	if ((myShowFlags & IDEKit_kShowFmtPopup) != (flags & IDEKit_kShowFmtPopup)) {
	    if (flags & IDEKit_kShowFmtPopup) {
		[self addSubview: myFmtPopup];
	    } else {
		[myFmtPopup removeFromSuperview];
	    }
	}
	if ((myShowFlags & IDEKit_kShowSplitter) != (flags & IDEKit_kShowSplitter)) {
	    if (flags & IDEKit_kShowSplitter) {
		[self addSubview: mySplitter];
		[self addSubview: myUnsplitter];
	    } else {
		[mySplitter removeFromSuperview];
		[myUnsplitter removeFromSuperview];
	    }
	}
	myShowFlags = flags;
	// update the rulers (or else don't show on 10.3)
	//[self setRulersVisible: NO];
	if (myShowFlags & (IDEKit_kShowBreakpoints | IDEKit_kShowLineNums | IDEKit_kShowFolding))
	    [self setHasVerticalRuler: YES]; // make sure it is shown (sometimes gets turned off in 10.3)
	//[[self verticalRulerView] setRuleThickness: 0.0];
	//[[self verticalRulerView] setRuleThickness: [[self verticalRulerView] ruleThickness]];
	//[self setRulersVisible: YES];
	[self tile];
    }
}
- (NSInteger) showFlags
{
    return myShowFlags;
}

// Pass insert & close split view to text view delegate, with us as the sender so it knows
// how to split things
- (IBAction) insertSplitView: (id) sender
{
    id textView = [self documentView];
    id delegate = [textView delegate];
    if (delegate && [delegate respondsToSelector: @selector(insertSplitView:)]) {
	[delegate insertSplitView: self];
    }
}
- (IBAction) closeSplitView: (id) sender
{
    id textView = [self documentView];
    id delegate = [textView delegate];
    if (delegate && [delegate respondsToSelector: @selector(closeSplitView:)]) {
	[delegate closeSplitView: self];
    }
}

- (void) setLine: (NSInteger) line col: (NSInteger) col
{
    [myLineButton setTitle: [NSString stringWithFormat: @"L:%d C:%d",line, col]];
}
- (void) setLineRange: (NSRange) lines colRange: (NSRange) cols;
{
    if (lines.length <= 1) {
	if (cols.length > 0)
	    [myLineButton setTitle: [NSString stringWithFormat: @"L:%d C:%d(%d)",lines.location, cols.location,cols.length]];
	else
	    [myLineButton setTitle: [NSString stringWithFormat: @"L:%d C:%d",lines.location, cols.location]];
    } else {
	[myLineButton setTitle: [NSString stringWithFormat: @"L:%d(%d) C:%d(%d)",lines.location,lines.length, cols.location,cols.length]];
    }
}
@end

#ifdef nomore
#define kBPLineSize 8.0
#define kBPOvalSize 8.0
#endif
@implementation IDEKit_BreakPointRuler
- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation
{
    self = [super initWithScrollView: scrollView orientation: orientation];
    //[self setRuleThickness: 16.0];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(srcDidEdit:) name: NSTextDidChangeNotification object: [scrollView documentView]];
    return self;
}

- (float)requiredThickness
{
    return [self ruleThickness];
}

- (float) ruleThickness
{
    float thickness = 0.0;
    int flags = [(IDEKit_SrcScroller *)[self scrollView] showFlags];
    if (flags & IDEKit_kShowBreakpoints)
	thickness += BreakPointThickness;
    if (flags & IDEKit_kShowLineNums)
	thickness += LineNumberThickness;
    if (flags & IDEKit_kShowFolding)
	thickness += FoldingThickness;
    [super setRuleThickness: thickness]; // make sure internal version is the same as our calculated version
    //NSLog(@"Flags %x thickness %g",flags,thickness);
    return thickness;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}
- (void) srcDidEdit: (NSNotification *)notification
{
	// need to redraw, but setNeedsDisplay doesn't do it in the middle of text editing
    //[self setNeedsDisplay: YES];
    [[self scrollView] setRulersVisible: NO];
    [[self scrollView] setRulersVisible: YES];
}
- (void) drawHashMarksAndLabelsInRect: (NSRect) aRect
{
    //NSLog(@"drawHashMarksAndLabelsInRect %g,%g - %g,%g",aRect.origin.x,aRect.origin.y,aRect.size.width,aRect.size.height);
    int flags = [(IDEKit_SrcScroller *)[self scrollView] showFlags];
    if (flags & (IDEKit_kShowLineNums | IDEKit_kShowBreakpoints | IDEKit_kShowFolding) == 0)
	return; // nothing to draw
    NSRect lineNumColumn = aRect;
    NSRect breakColumn = aRect;
    NSRect foldColumn = aRect;
    if (flags & IDEKit_kShowLineNums) {
	breakColumn.origin.x += LineNumberThickness;
	breakColumn.size.width -= LineNumberThickness;
	foldColumn = breakColumn;
    }
    if (flags & IDEKit_kShowBreakpoints) {
	foldColumn.origin.x += BreakPointThickness;
	foldColumn.size.width -= BreakPointThickness;
    }
    if (flags & IDEKit_kShowFolding) {
	breakColumn.size.width -= FoldingThickness;
    }
    [[NSColor highlightColor] set];
    [NSBezierPath fillRect: NSInsetRect(aRect,0.5,0.0)];
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(aRect.origin.x + aRect.size.width - 1.2, aRect.origin.y) toPoint: NSMakePoint(aRect.origin.x + aRect.size.width - 1.2, aRect.origin.y + aRect.size.height)];
    [[NSColor controlLightHighlightColor] set];
    [NSBezierPath strokeLineFromPoint: NSMakePoint(aRect.origin.x + aRect.size.width - 2.0, aRect.origin.y) toPoint: NSMakePoint(aRect.origin.x + aRect.size.width - 2.0, aRect.origin.y + aRect.size.height)];

    NSRect docRect = [[self scrollView] documentVisibleRect];
    id textView = [[self scrollView] documentView];
    IDEKit_SrcEditView *delegate = [textView delegate];
    NSLayoutManager *lm = [textView layoutManager];
    float lineHeight = 15.0; // just a guess in case we can't otherwise determine it
    if (!lm)
	return;
    if ([lm numberOfGlyphs] == 0)
	return; // nothing to draw...
    NSRect lineRect = [lm lineFragmentRectForGlyphAtIndex: 0 effectiveRange: NULL]; // get the first one
    if (lineRect.size.height)
	lineHeight = lineRect.size.height;
    // find the glpyh at the top of the page
    NSUInteger firstGlyph = [lm glyphIndexForPoint: docRect.origin inTextContainer:  [textView textContainer]];
    NSUInteger lastGlyph = [lm glyphIndexForPoint: NSMakePoint(docRect.origin.x, docRect.origin.y + docRect.size.height) inTextContainer:  [textView textContainer]];
    NSUInteger firstChar = [lm characterIndexForGlyphAtIndex: firstGlyph];
    NSUInteger lastChar = [lm characterIndexForGlyphAtIndex: lastGlyph];
    // these line numbers are in folded coordinates
    int firstLine = [delegate foldedLineNumberFromOffset: firstChar];
    int lastLine = [delegate foldedLineNumberFromOffset: lastChar]+1; // we need to draw the gutter below the visible area since it is shown where the scroll bar is, and if we don't, when we scroll, we never show that part
    int previousUnfoldedLine = -1;
    for (int lineNum = firstLine; lineNum <= lastLine; lineNum++) { // iterate through folded lines
	if (lineNum < 0)
	    continue;
	NSRange lineRange = [delegate nthFoldedLineRange: lineNum];
	if (lineRange.length == 0) {
	    //continue; // blank line, or end
	}
	int unfoldedLineNum = [delegate lineNumberFromOffset: [delegate unfoldedLocation: lineRange.location]];
	if (unfoldedLineNum == previousUnfoldedLine)
	    continue; // we've already done this line (happens at the end when we draw more so we draw where the scrollbar is)
	previousUnfoldedLine = unfoldedLineNum;
	NSRange glpyhRange = [lm glyphRangeForCharacterRange: lineRange actualCharacterRange: NULL];
	if (glpyhRange.location >= [lm numberOfGlyphs])
	    break; // past end of text
	NSRect fragment = [lm lineFragmentRectForGlyphAtIndex: glpyhRange.location effectiveRange: NULL];
	//float baseline = [[lm typesetter] baselineOffsetInLayoutManager: lm glyphIndex: glpyhRange.location];
	//if (lineNum < 3)
	//    NSLog(@"Line %d, fragment origin %g, fragment height %g",lineNum, fragment.origin.y, fragment.size.height);
	fragment = NSOffsetRect(fragment,-docRect.origin.x,-docRect.origin.y);
	if (flags & IDEKit_kShowLineNums) {
	    NSRect numRect = NSMakeRect(lineNumColumn.origin.x, fragment.origin.y, lineNumColumn.size.width, fragment.size.height);
	    if (1 || numRect.size.height >= lineHeight) {
		// now convert to folded line number
		[[NSString stringWithFormat: @"%d", unfoldedLineNum] drawAtPoint: numRect.origin withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSColor disabledControlTextColor],NSForegroundColorAttributeName, NULL]];
	    }
	}
	if (flags & IDEKit_kShowBreakpoints) {
	    //[IDEKit drawBreakpointKind: what x: midx y: midy];
	    float midx = breakColumn.origin.x + breakColumn.size.width/2.0;
	    float midy = fragment.origin.y + fragment.size.height / 2.0;
	    IDEKit_Breakpoint *breakpoint = [delegate getBreakpointForDisplay: unfoldedLineNum];
	    if (breakpoint) {
		[breakpoint drawAtX: midx y: midy];
	    } else {
		// draw the possibility of a breakpoint
		[IDEKit drawBreakpointKind: [delegate getBreakpointCapability: unfoldedLineNum] x: midx y: midy];
	    }
	}
	if (flags & IDEKit_kShowFolding) {
	    unichar foldable = 0; // what foldability to show here?
	    switch ([textView foldabilityAtOffset: lineRange.location foldedAtOffset: NULL]) {
		case 0:
		    break; // do nothing
		case 1: // uncollapse
		    foldable = 0x25ba; // black right pointing triangle
		    break; // do nothing
		case -1:
		    foldable = 0x25bc; // black down-pointing triangle
		    break;
	    }
	    if (foldable) {
		NSRect iRect = NSMakeRect(foldColumn.origin.x, fragment.origin.y, foldColumn.size.width, fragment.size.height);
		if (iRect.size.height >= lineHeight) {
		    [[NSString stringWithCharacters:&foldable length:1] drawAtPoint: iRect.origin withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSColor disabledControlTextColor],NSForegroundColorAttributeName, NULL]];
		}
	    }
	}
    }
    [[NSColor blackColor] set];
}

- (bool) findLine: (int *)lineNumFound andRange: (NSRange *)rangeFound forVerticalCoordinate: (float) y
{
    id textView = [[self scrollView] documentView];
    NSLayoutManager *lm = [textView layoutManager];
    NSRect docRect = [[self scrollView] documentVisibleRect];
    float lineHeight = 15.0;
    if (!lm)
	return false;
    if ([lm numberOfGlyphs] == 0)
	return false; // nothing to draw...
    NSRect lineRect = [lm lineFragmentRectForGlyphAtIndex: 0 effectiveRange: NULL]; // get the first one
    if (lineRect.size.height)
	lineHeight = lineRect.size.height;
    // find the glpyh at the top of the page
    NSUInteger firstGlyph = [lm glyphIndexForPoint: docRect.origin inTextContainer:  [textView textContainer]];
    NSUInteger lastGlyph = [lm glyphIndexForPoint: NSMakePoint(docRect.origin.x, docRect.origin.y + docRect.size.height) inTextContainer:  [textView textContainer]];
    NSUInteger firstChar = [lm characterIndexForGlyphAtIndex: firstGlyph];
    NSUInteger lastChar = [lm characterIndexForGlyphAtIndex: lastGlyph];
    IDEKit_SrcEditView *delegate = [textView delegate];

    int firstLine = [delegate lineNumberFromOffset: [delegate unfoldedLocation: firstChar]]-1;
    int lastLine = [delegate lineNumberFromOffset: [delegate unfoldedLocation: lastChar]]+1;
    for (int lineNum = firstLine; lineNum <= lastLine; lineNum++) {
	NSRange lineRange = [delegate foldedRange: [delegate nthLineRange: lineNum]];
	if (lineRange.length == 0)
	    continue; // blank line, or end, or folded away
	NSRange glpyhRange = [lm glyphRangeForCharacterRange: lineRange actualCharacterRange: NULL];
	NSRect fragment = [lm lineFragmentRectForGlyphAtIndex: glpyhRange.location effectiveRange: NULL];
	fragment = NSOffsetRect(fragment,-docRect.origin.x,-docRect.origin.y);
	if (fragment.origin.y <= y && y < fragment.origin.y + fragment.size.height) {
	    // found it
	    if (lineNumFound) *lineNumFound = lineNum;
	    if (rangeFound) *rangeFound = lineRange;
	    return YES;
	}
    }
    return NO;
}

- (BOOL) findFoldedLine: (int *)lineNumFound andFoldedRange: (NSRange *)rangeFound forVerticalCoordinate: (float) y
{
    if (lineNumFound) *lineNumFound = 0;
    if (rangeFound) *rangeFound = NSMakeRange(0,NSNotFound);
    id textView = [[self scrollView] documentView];
    NSLayoutManager *lm = [textView layoutManager];
    NSRect docRect = [[self scrollView] documentVisibleRect];
    if (!lm)
	return NO;
    if ([lm numberOfGlyphs] == 0)
	return NO; // nothing to draw...

    NSUInteger glyphIndex = [lm glyphIndexForPoint: NSMakePoint(docRect.origin.x, docRect.origin.y + y) inTextContainer:  [textView textContainer] fractionOfDistanceThroughGlyph: NULL];
    NSUInteger charIndex = [lm characterIndexForGlyphAtIndex: glyphIndex];
    //int lineNum = [[textView delegate] foldedLineNumberFromOffset: charIndex];
    //NSLog(@"Mouse down at %g is glpyh %d, char %d, lineNum %d",y,glyphIndex,charIndex, lineNum);
    NSRange lineRange = [[[textView textStorage] string] lineRangeForRange: NSMakeRange(charIndex,0)];
    if (lineNumFound) *lineNumFound = [[textView delegate] foldedLineNumberFromOffset: charIndex];
    if (rangeFound) *rangeFound = lineRange;
    return YES;
}

- (void)rightMouseDown: (NSEvent *)theEvent
{
    [self mouseDown: theEvent]; // same mechanism, will treat accordingly
}
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint where = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
    id textView = [[self scrollView] documentView];
    IDEKit_SrcEditView *delegate = [textView delegate];
    // figure out the "column" we are in
    float right = 0.0;
    float left = 0.0;
    int flags = [(IDEKit_SrcScroller *)[self scrollView] showFlags];
    if (flags & IDEKit_kShowLineNums) {
	left = right;
	right +=  LineNumberThickness;
	if (left <= where.x && where.x < right) {
	    return; // clicking in line number does nothing
	}
    }
    if (flags & IDEKit_kShowBreakpoints) {
	left = right;
	right += BreakPointThickness;
	if (left <= where.x && where.x < right) {
	    int lineNum;
	    if ([self findLine: &lineNum andRange: NULL forVerticalCoordinate: where.y]) {
		if ([theEvent type] == NSRightMouseDown)
		    [[IDEKit_BreakpointInspector sharedBreakpointInspector] showWindow: self];
		if (delegate) {
		    // does something
		    IDEKit_Breakpoint *bp = [delegate getBreakpoint: lineNum];
		    if (bp) {
			// already got one, remove it
			if ([theEvent type] == NSRightMouseDown) {
			    [[IDEKit_BreakpointInspector sharedBreakpointInspector] setBreakpoint: bp];
			} else {
			    [delegate removeBreakpoint: lineNum];
			}
		    } else if ([delegate getBreakpointCapability: lineNum] == IDEKit_kNoBreakPoint) {
			// we can put a brekpoint here
			[delegate addBreakpoint: lineNum];
		    }
		    [self setNeedsDisplay: YES];
		}
	    }
	    return;
	}
    }
    if (flags & IDEKit_kShowFolding) {
	left = right;
	right += FoldingThickness;
	if (left <= where.x && where.x < right) {
	    NSRange lineRange;
	    int lineNum;
	    if ([self findFoldedLine: &lineNum andFoldedRange: &lineRange forVerticalCoordinate: where.y]) {
		// find the first attachement and expand that
		NSUInteger foldOffset;
		switch ([textView foldabilityAtOffset: lineRange.location foldedAtOffset: &foldOffset]) {
		    case 0:
			break; // do nothing
		    case 1: // uncollapse
			[delegate uncollapseAtIndex: foldOffset selectResult: NO];
			break;
		    case -1:
			[delegate foldFromOffset: lineRange.location];
			break;
		}
		[self setNeedsDisplay: YES];
	    }
	}
    }
}


@end