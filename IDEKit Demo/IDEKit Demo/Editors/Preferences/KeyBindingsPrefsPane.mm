//
//  KeyBindingsPrefsPane.mm
//  IDEKit
//
//  Created by Glenn Andreas on Thurs Mar 25 2004.
//  Copyright (c) 2004 by Glenn Andreas
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

#import "KeyBindingsPrefsPane.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_TextViewExtensions.h"

@interface IDEKit_KeyboardBindingEditor : NSView
{
    NSMutableArray *myBindings;
    NSButton * myAddButton;
    NSButton * myDelButton;
    short myCurSelection;
    id myDelegate;
}
- (id)initWithFrame:(NSRect)frameRect forBindings: (NSArray *)bindings;
- (NSArray *)keyBindings;
- (void) setDelegate: (id) delegate;
- (void) addBinding: (id) sender;
- (void) delBinding: (id) sender;
@end

@interface NSObject(IDEKit_KeyboardBindingEditorDelegate)
- (BOOL) keyboardBindingShouldEndEditing: (IDEKit_KeyboardBindingEditor *) editor;
@end

@interface IDEKit_KeyboardCell : NSActionCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
+ (float)drawKeybinding: (NSAttributedString *) value withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
+ (NSFont *)keyboardFont;
+ (NSAttributedString *) attributedStringForBinding: (NSString *)binding;
@end

@implementation IDEKit_KeyboardBindingEditor
- (id)initWithFrame:(NSRect)frameRect forBindings: (NSArray *)bindings
{
    self = [super initWithFrame: frameRect];
    if (self) {
		if (bindings)
			myBindings = [bindings mutableCopy];
		else
			myBindings = [NSMutableArray array];
		NSRect buttonFrame = frameRect;
		// trim a square off the right end
		buttonFrame.origin.x = buttonFrame.origin.x + buttonFrame.size.width - buttonFrame.size.height;
		buttonFrame.size.width = buttonFrame.size.height;
		// since frame is in the super class, convert to our location
		buttonFrame.origin.x -= frameRect.origin.x;
		buttonFrame.origin.y -= frameRect.origin.y;
		myDelButton = [[NSButton alloc] initWithFrame: buttonFrame];
		[myDelButton setTitle: [NSString stringWithFormat: @"%d", 0x25ac]];
		[myDelButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		//[myDelButton setShowsBorderOnlyWhileMouseInside: YES];
		[myDelButton setBezelStyle: NSShadowlessSquareBezelStyle];
		[[myDelButton cell] setGradientType: NSGradientConvexWeak];
		[[myDelButton cell] setControlSize: NSSmallControlSize];
		[[myDelButton cell] setBordered: NO];
		[myDelButton setTarget: self];
		[myDelButton setAction: @selector(delBinding:)];
		[self addSubview:myDelButton];
		buttonFrame.origin.x -= buttonFrame.size.width;
		myAddButton = [[NSButton alloc] initWithFrame: buttonFrame];
		[myAddButton setTitle: [NSString stringWithFormat: @"%d", 0x271a]];
		[myAddButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		//[myAddButton setShowsBorderOnlyWhileMouseInside: YES];
		[myAddButton setBezelStyle: NSShadowlessSquareBezelStyle];
		[[myAddButton cell] setGradientType: NSGradientConvexWeak];
		[[myAddButton cell] setControlSize: NSSmallControlSize];
		[[myAddButton cell] setBordered: NO];
		[myAddButton setTarget: self];
		[myAddButton setAction: @selector(addBinding:)];
		[self addSubview:myAddButton];
		myCurSelection = [bindings count]-1;
		if (myCurSelection == -1) {
			//[myDelButton setEnabled:NO];
			[self addBinding: self]; // if nothing there, default to automtically adding one
		}
    }
    return self;
}
- (void) setDelegate: (id) delegate
{
    myDelegate = delegate;
}
- (NSArray *)keyBindings
{
    if (myCurSelection == [myBindings count]-1 && myCurSelection != -1) {
		// we did have the last one selection, was it empty?
		if ([myBindings[myCurSelection] isEqualToString: @""]) {
			return [myBindings subarrayWithRange:NSMakeRange(0,myCurSelection-1)]; // don't return that last one
		}
    }
    return [myBindings copy];
}

- (void)drawRect:(NSRect)aRect
{
    NSRect bounds = [self bounds];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:bounds];
    [[NSColor selectedTextBackgroundColor] set];
    [NSBezierPath strokeRect:bounds];
    bounds.size.width = 50.0;
    for (NSUInteger i=0;i<[myBindings count];i++) {
		if (i == myCurSelection) {
			[[NSColor selectedTextBackgroundColor] set];
			[NSBezierPath fillRect:bounds];
		}
		[[NSColor selectedTextColor] set];
		NSString *binding = myBindings[i];
		NSAttributedString *attribForm = [IDEKit_KeyboardCell attributedStringForBinding:binding];
		[IDEKit_KeyboardCell drawKeybinding: attribForm withFrame:bounds inView: self];
		bounds.origin.x += 50.0;
    }
    [super drawRect: aRect];
}
- (BOOL)resignFirstResponder
{
    if (myDelegate == NULL || [myDelegate keyboardBindingShouldEndEditing: self]) {
		// we are done, go away
		[self removeFromSuperview];
		return YES;
    }
    return NO; // delegate said no
}
- (void) addBinding: (id) sender
{
    //NSLog(@"Adding binding");
    // make a blank one, and disable "add" to prevent multiple blanks
    [myBindings addObject: @""];
    myCurSelection = [myBindings count]-1;
    [self setNeedsDisplay: YES];
    [myDelButton setEnabled: YES];
    [myAddButton setEnabled: NO]; // we are blank
}
- (void) delBinding: (id) sender
{
    //NSLog(@"Removing binding");
    [myBindings removeObjectAtIndex: myCurSelection];
    myCurSelection = -1;
    [self setNeedsDisplay: YES];
    [myDelButton setEnabled: NO];
    [myAddButton setEnabled: YES]; // even if we were blank, we're good now
}
- (void)keyDown:(NSEvent *)theEvent
{
    if (myCurSelection != -1) {
		NSUInteger modifiers = [theEvent modifierFlags];
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
		commands[len++] = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
		// see if commands are in our bindings
		NSString *key = [NSString stringWithCharacters: commands length: len];
		myBindings[myCurSelection] = key;
		[self setNeedsDisplay: YES]; // we need to be redrawn now
		[myAddButton setEnabled: YES]; // make sure this is valid, since we just made a valid binding
    }
}
- (void) selectBinding: (NSInteger) index
{
    if (index == myCurSelection)
		return;
    if (index >= [myBindings count]) index = -1; // treat as no select
    if (myCurSelection == [myBindings count]-1 && myCurSelection != -1) {
		// we did have the last one selection, was it empty?
		if ([myBindings[myCurSelection] isEqualToString: @""]) {
			[myBindings removeObjectAtIndex:myCurSelection];
		}
    }
    myCurSelection = index;
    if (myCurSelection == -1) {
		[myDelButton setEnabled: NO];
		[myAddButton setEnabled: YES];
    } else {
		[myDelButton setEnabled: YES];
		[myAddButton setEnabled: YES]; // even if we were blank, we're good now
    }
    [self setNeedsDisplay: YES];
}
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    [self selectBinding: int(where.x / 50.0)];
    //[super mouseDown: theEvent];
}
@end

@implementation NSObject(IDEKit_KeyboardBindingEditorDelegate)
- (BOOL) keyboardBindingShouldEndEditing: (IDEKit_KeyboardBindingEditor *) editor
{
    return YES;
}
@end

@implementation IDEKit_KeyboardCell

+ (float)drawKeybinding: (NSAttributedString *) value withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    // for places where we need to look elsewhere for glyphs
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:value];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init]; // use this to map other glpyh name stuff
    [storage addLayoutManager: layoutManager];
    
    float left = 0.0;
    for (NSUInteger i=0;i < [[value string] length]; i++) {
		NSFont *font = [value attribute: NSFontAttributeName atIndex: i effectiveRange: NULL];
		if (!font)
			font = [[[[self superclass] alloc] init] font]; // use cell font if not specified replaces [super font]
		NSGlyphInfo *info = [value attribute:NSGlyphInfoAttributeName atIndex: i effectiveRange:NULL];
		NSString *glyphName = nil;
		NSGlyph glyph = 0xffff;
		if (info) {
			glyphName = [info glyphName];
		} else {
			glyphName = [[[value string] substringWithRange:NSMakeRange(i,1)] uppercaseString]; // try use the character as the glyph name
		}
		if (glyphName) {
			glyph = [font glyphWithName:glyphName];
		}
		
		if (glyph == 0xffff || glyph > [font numberOfGlyphs]) {
			// Switch to getting it from the system font for "normal" keys
			// get the glyph from the layout manager (this normally will be the ascii value)
			glyph = [layoutManager glyphAtIndex: i];
			font = [NSFont systemFontOfSize:[font pointSize]]; // use the system font
			//NSLog(@"Asking layout manager for glyph for %@, got %d", glyphName, glyph);
		}
		if (glyph != 0xffff && glyph < [font numberOfGlyphs]) {
//unused			NSRect bounds = [font boundingRectForGlyph:glyph];
			[path moveToPoint: NSMakePoint(left, 0.0 - [font descender])];
			[path appendBezierPathWithGlyph: glyph inFont: font];
			left += [font advancementForGlyph: glyph].width;
			continue; // rendered a character
		}
		NSLog(@"Can't make glyph yet for %@",glyphName);
		// at this point, we may not have a glyph for this character in the font - hm...
    }
    if ([path isEmpty])
		return 0.0; // nothing to do
    // take that entire thing and center
    NSRect bounds = [path bounds];
    NSAffineTransform *transform = [NSAffineTransform transform];
    if (![controlView isFlipped]) {
		[transform translateXBy:NSMidX(cellFrame) - NSMidX(bounds) yBy: NSMidY(cellFrame) - NSMidY(bounds)];
    } else {
		[transform translateXBy:NSMidX(cellFrame) - NSMidX(bounds) yBy: NSMidY(cellFrame) + NSMidY(bounds)];
		[transform scaleXBy:1.0 yBy:-1.0];
    }
    [path transformUsingAffineTransform:transform];
    [[NSColor blackColor] set];
    [path fill];
    return bounds.size.width; // how wide was it
}

+ (NSFont *)keyboardFont
{
    return [NSFont fontWithName: @".Keyboard" size: [NSFont systemFontSize]];
}

+ (NSAttributedString *) attributedStringForBinding: (NSString *)binding
{
    binding = [binding uppercaseString]; // convert to uppercase for display
    NSMutableAttributedString *retval = [[NSMutableAttributedString alloc] initWithString: binding];
    [retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(0, [binding length])];
    int index = 0;
    if ([binding length] == 0)
		return retval; // empty string
    if ([binding characterAtIndex: index] == '@') {
		//[retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(index,1)];
		[retval addAttribute: NSGlyphInfoAttributeName value: [NSGlyphInfo glyphInfoWithGlyphName: @"propellor" forFont: [self keyboardFont] baseString: [binding substringWithRange:NSMakeRange(index,1)]] range: NSMakeRange(index,1)];
		index++;
    }
    if ([binding characterAtIndex: index] == '~') {
		//[retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(index,1)];
		[retval addAttribute: NSGlyphInfoAttributeName value: [NSGlyphInfo glyphInfoWithGlyphName: @"option" forFont: [self keyboardFont] baseString: [binding substringWithRange:NSMakeRange(index,1)]] range: NSMakeRange(index,1)];
		index++;
    }
    if ([binding characterAtIndex: index] == '^') {
		//[retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(index,1)];
		[retval addAttribute: NSGlyphInfoAttributeName value: [NSGlyphInfo glyphInfoWithGlyphName: @"control" forFont: [self keyboardFont] baseString: [binding substringWithRange:NSMakeRange(index,1)]] range: NSMakeRange(index,1)];
		index++;
    }
    if ([binding characterAtIndex: index] == '$') {
		//[retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(index,1)];
		[retval addAttribute: NSGlyphInfoAttributeName value: [NSGlyphInfo glyphInfoWithGlyphName: @"arrowupwhite" forFont: [self keyboardFont] baseString: [binding substringWithRange:NSMakeRange(index,1)]] range: NSMakeRange(index,1)];
		index++;
    }
    NSString *glyphName = NULL;
    switch ([binding characterAtIndex: index]) {
		case NSUpArrowFunctionKey:  glyphName = @"arrowup"; break;
		case NSDownArrowFunctionKey:  glyphName = @"arrowdown"; break;
		case NSLeftArrowFunctionKey:  glyphName = @"arrowleft"; break;
		case NSRightArrowFunctionKey:  glyphName = @"arrowright"; break;
		case NSF1FunctionKey: glyphName = @"F_one"; break;
		case NSF2FunctionKey: glyphName = @"F_two"; break;
		case NSF3FunctionKey: glyphName = @"F_three"; break;
		case NSF4FunctionKey: glyphName = @"F_four"; break;
		case NSF5FunctionKey: glyphName = @"F_five"; break;
		case NSF6FunctionKey: glyphName = @"F_six"; break;
		case NSF7FunctionKey: glyphName = @"F_seven"; break;
		case NSF8FunctionKey: glyphName = @"F_eight"; break;
		case NSF9FunctionKey: glyphName = @"F_nine"; break;
		case NSF10FunctionKey: glyphName = @"F_one_zero"; break;
		case NSF11FunctionKey: glyphName = @"F_one_one"; break;
		case NSF12FunctionKey: glyphName = @"F_one_two"; break;
		case NSF13FunctionKey: glyphName = @"F_one_three"; break;
		case NSF14FunctionKey: glyphName = @"F_one_four"; break;
		case NSF15FunctionKey: glyphName = @"F_one_five"; break;
		case '\n':
		case '\r':
			glyphName = @"carriagereturn"; break;
		case 0x03: glyphName = @"enter"; break; // enter key
		case 0x1b: glyphName = @"escape"; break;
		case NSHomeFunctionKey: glyphName = @"arrowupleft"; break;
		case NSEndFunctionKey: glyphName = @"arrowdownright"; break;
		case NSPageUpFunctionKey: glyphName = @"pageup"; break;
		case NSPageDownFunctionKey: glyphName = @"pagedown"; break;
		case 0x7f: glyphName = @"deleteright"; break;
		case 0x08: glyphName = @"deleteleft"; break;
		case NSClearDisplayFunctionKey: glyphName = @"clear"; break;
		case 0x09: glyphName = @"arrowtabright"; break;
		case NSBackTabCharacter: glyphName = @"arrowtableft"; break;
		case ' ': glyphName = @"nobreakspacebox"; break;
		default: break;
    }
    if (glyphName) {
		[retval addAttribute: NSFontAttributeName value: [self keyboardFont] range: NSMakeRange(index,1)];
		[retval addAttribute: NSGlyphInfoAttributeName value: [NSGlyphInfo glyphInfoWithGlyphName: glyphName forFont: [self keyboardFont] baseString: [binding substringWithRange:NSMakeRange(index,1)]] range: NSMakeRange(index,1)];
    } else {
		[retval addAttribute: NSUnderlineStyleAttributeName value: @2 range: NSMakeRange(index,1)];
    }
    //NSLog(@"Binding %@ = %@",binding,[retval description]);
    return retval;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSString *value = NULL; //[super stringValue];
    if (value && [value length]) {
		[IDEKit_KeyboardCell drawKeybinding: [IDEKit_KeyboardCell attributedStringForBinding: value] withFrame:cellFrame inView:controlView];
    } else {
		NSArray *values = [self objectValue];
		if ([values count]) {
			NSRect subFrame = cellFrame;
			subFrame.size.width = 50.0;
			for (NSUInteger i=0;i<[values count];i++) {
				value = values[i];
				[IDEKit_KeyboardCell drawKeybinding: [IDEKit_KeyboardCell attributedStringForBinding: value] withFrame:subFrame inView:controlView];
				subFrame = NSOffsetRect(subFrame, 50.0, 0.0);
			}
		}
    }
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    //NSLog(@"Edit with frame");
    //if ([self objectValue]) {
	IDEKit_KeyboardBindingEditor *editor = [[IDEKit_KeyboardBindingEditor alloc] initWithFrame: aRect forBindings: [self objectValue]];
    [editor setDelegate: self];
	[controlView addSubview: editor];
	[[controlView window] makeFirstResponder:editor];
    //}
}
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    NSLog(@"Select with frame");
    //[self performClick: self]; // send our action instead
    IDEKit_KeyboardBindingEditor *editor = [[IDEKit_KeyboardBindingEditor alloc] initWithFrame: aRect forBindings: [self objectValue]];
    [controlView addSubview: editor];
}

- (BOOL) keyboardBindingShouldEndEditing: (IDEKit_KeyboardBindingEditor *) editor
{
    [self setObjectValue: [editor keyBindings]]; // grab the value
    [self performClick: self]; // finish our "button press"
    return YES; // and done
}
@end

@implementation KeyBindingsPrefsPane
- (NSArray *) editedProperties
{
    return @[IDEKit_KeyBindingsKey];
}

- (void) didSelect
{
    myCategories = [NSMutableArray array];
    myCommands = [NSMutableDictionary dictionary];
    myLocalized = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass: [self class]] pathForResource: @"KeyBindingSelectors" ofType: @"strings"]];
    myInverseBindings = [NSMutableDictionary dictionary];
    NSDictionary *bindings = [myDefaults objectForKey: IDEKit_KeyBindingsKey];
    id dictEnum = [bindings keyEnumerator];
    id key;
    while ((key = [dictEnum nextObject]) != NULL) {
		if (!myInverseBindings[bindings[key]])
			myInverseBindings[bindings[key]] = [NSMutableArray array];
		[myInverseBindings[bindings[key]] addObject: key]; // maps from a command to a list of keys
    }
    NSArray *keyBindingList = [NSArray arrayWithContentsOfFile:[[NSBundle bundleForClass: [self class]] pathForResource: @"KeyBindingList" ofType: @"plist"]];
    for (NSUInteger cat = 0; cat < [keyBindingList count]; cat++) {
		NSArray *entry = keyBindingList[cat];
		[myCategories addObject: entry[0]]; // the name of the category
		myCommands[entry[0]] = entry[1]; // and map between the category name and the list of commands
    }
    IDEKit_KeyboardCell *keyCell = [[IDEKit_KeyboardCell alloc] init];
    [keyCell setAlignment:NSCenterTextAlignment];
    [keyCell setAction: @selector(changeKeystroke:)];
    [keyCell setTarget: self];
    [keyCell setEditable:YES];
    [keyCell setFont: [IDEKit_KeyboardCell keyboardFont]];
    [[myOutline tableColumnWithIdentifier:@"keys"] setDataCell: keyCell];
	
    [myOutline reloadData];
}

- (void) saveOutBindings
{
    NSMutableDictionary *rebuildBindings = [NSMutableDictionary dictionary];
    id dictEnum = [myInverseBindings keyEnumerator];
    id key;
    while ((key = [dictEnum nextObject]) != NULL) { // key is the selector
		NSArray *bindings = myInverseBindings[key];
		if ([bindings count]) {
			for (NSUInteger i=0;i<[bindings count];i++) {
				rebuildBindings[bindings[i]] = key; // and for each binding, set action to the selector
			}
		}
    }
    [myDefaults setObject: rebuildBindings forKey: IDEKit_KeyBindingsKey];
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == NULL)
		return [myCategories count];
    else
		return [myCommands[item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([myCategories containsObject: item]) // item is the category
		return YES;
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == NULL)
		return myCategories[index];
    else
		return myCommands[item][index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString: @"commands"]) {
		id retval = myLocalized[item];
		if (!retval)
			retval = item; // use the unlocalized version if we must
		return retval;
    } else if ([[tableColumn identifier] isEqualToString: @"keys"]) {
		return myInverseBindings[item];
    }
    return item;
}

- (IBAction) changeKeystroke: (id) sender
{
    NSArray *strokes = [sender objectValue];
    if (strokes) {
		NSInteger row = [myOutline selectedRow];
		// figure out what we were editing
		NSString *selectorString = [myOutline itemAtRow: row];
		if (selectorString) {
			myInverseBindings[selectorString] = strokes;
			[myOutline reloadItem: selectorString];
			[self saveOutBindings];
		}
    }
}

@end

