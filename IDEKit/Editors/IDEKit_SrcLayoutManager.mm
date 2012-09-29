//
//  IDEKit_SrcLayoutManager.mm
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

#import "IDEKit_SrcLayoutManager.h"


@implementation IDEKit_SrcLayoutManager
- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    if ([self showsInvisibleCharacters]) {
	// figure out what invisibles to draw
	NSRange charRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	NSString *characters = [[self textStorage] string];
	for (NSUInteger i=charRange.location;i<charRange.location+charRange.length;i++) {
	    unichar c = [characters characterAtIndex: i];
	    unichar draw = 0;
	    if (c == ' ') {		// "real" space
		draw = 0x2024; // one dot leader 0x00b7; // "middle dot" 0x22c5; // "Dot centered"
	    } else if (c == '\t') {	// "correct" indentation
		draw = 0x2192; // "Arrow right"
	    } else if (c == 0x21e4 || c == 0x21e5) {	// not "correct" indentation (leftward tab, rightward tab)
		draw = 0x2192; // "Arrow right"
	    } else if (c == '\n') {	// "correct" line feed
		draw = 0x00b6; // "Pilcrow sign"
	    } else if (c == 0x0c) {	// page break
		draw = 0x21cb; // leftwards harpoon over rightwards harpoon
	    } else if (c < 0x20 || (0x007f <= c && c <= 0x009f) || [[NSCharacterSet illegalCharacterSet] characterIsMember: c]) {	// some other mystery control character
		draw = 0xfffd; // replacement character for controls that don't belong there
	    } else {
		NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(i,1) actualCharacterRange:NULL];
		if (glyphRange.length == 0) {
		    // something that doesn't show up as a glpyh
		    draw = 0xfffd; // replacement character
		}
	    }
	    if (draw) {
		// where is that one?
		NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(i,1) actualCharacterRange:NULL];
		NSPoint where = [self locationForGlyphAtIndex: glyphRange.location];
		NSRect fragment = [self lineFragmentRectForGlyphAtIndex: glyphRange.location effectiveRange: NULL];
		where.x += /*containerOrigin.x +*/ fragment.origin.x;
		where.y += /*containerOrigin.y +*/ fragment.origin.y - fragment.size.height;
		where.y = /*containerOrigin.y +*/ fragment.origin.y; //- fragment.size.height;
		//NSLog(@"Drawing invisible %C at %g,%g",draw,where.x,where.y);
		// now draw the thing in the right font/size, attributes, etc...
		//c = '*';
		NSDictionary *attributes = [[self textStorage] attributesAtIndex: i effectiveRange: NULL];
		[[NSString stringWithCharacters: &draw length: 1] drawAtPoint: where withAttributes: attributes];
	    }
	}
    }
    // we should also see if we are at the start of a line that is indendent
    NSUInteger index = glyphRange.location;
    while (index < glyphRange.location + glyphRange.length) {
	NSRange totalRange;
	NSRect fragmentUsed = [self lineFragmentUsedRectForGlyphAtIndex: index effectiveRange: &totalRange]; // start at beginning
	NSRect fragment = [self lineFragmentRectForGlyphAtIndex: index effectiveRange: NULL]; // start at beginning
	//NSPoint where = [self locationForGlyphAtIndex: index];
	//NSLog(@"glpyh %d, point is %@, fragRect %@, fragRectUsed %@",index, NSStringFromPoint(where), NSStringFromRect(fragment), NSStringFromRect(fragmentUsed));
	if (fragmentUsed.origin.x != fragment.origin.x) {
	    NSPoint where = [self locationForGlyphAtIndex: index];
	    where.x = /*containerOrigin.x +*/ (fragment.origin.x + fragmentUsed.origin.x) / 2;
	    where.y = /*containerOrigin.y +*/ fragment.origin.y; //- fragment.size.height;
	    NSDictionary *attributes = [[self textStorage] attributesAtIndex: index effectiveRange: NULL];
	    // 0x2025 - two dot leader
	    [[NSString stringWithFormat: @"%d",0x2025] drawAtPoint: where withAttributes: attributes];
	}
	index = totalRange.location + totalRange.length + 1;
    }
//    NSRect total = [self usedRectForTextContainer: [self x] ];
    // draw the real glyphs
    [super drawGlyphsForGlyphRange: glyphRange atPoint: containerOrigin];
}

@end
