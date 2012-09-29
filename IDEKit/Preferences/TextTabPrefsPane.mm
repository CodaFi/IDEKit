//
//  TextTabPrefsPane.mm
//  IDEKit
//
//  Created by Glenn Andreas on Fri Aug 15 2003.
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

#import "TextTabPrefsPane.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_TextViewExtensions.h"

@implementation TextTabPrefsPane
- (NSArray *) editedProperties
{
    return @[IDEKit_TabStopKey,
	IDEKit_TabStopUnitKey,IDEKit_TabSavingKey,
	IDEKit_TabSizeKey, IDEKit_TabIndentSizeKey,
	IDEKit_TextFontNameKey, IDEKit_TextFontSizeKey];
}

- (void) didSelect
{
    [myTabStops setFloatValue: [[myDefaults objectForKey: IDEKit_TabStopKey] floatValue]];
    [myTabStopsUnits selectItemAtIndex: [myTabStopsUnits indexOfItemWithTag: [[myDefaults objectForKey: IDEKit_TabStopUnitKey] intValue]]];
    [mySaveUsing selectCellWithTag: [[myDefaults objectForKey: IDEKit_TabSavingKey] intValue]];
    [mySpacesPerTab setIntValue: [[myDefaults objectForKey: IDEKit_TabSizeKey] intValue]];
    [mySpacesPerIndent setIntValue: [[myDefaults objectForKey: IDEKit_TabIndentSizeKey] intValue]];
    [mySpacesPerIndent setEnabled: [[myDefaults objectForKey: IDEKit_TabStopUnitKey] intValue] != -72];
//    [myConvertSpaces setIntValue: [[myDefaults objectForKey: IDEKit_TabAutoConvertKey] intValue]];
    NSFont *font = [self font];
    [myTextSample setFont: font];
    [myTextName setStringValue: [NSString stringWithFormat: @"%@ - %g",[font displayName],[font pointSize]]];
}

- (void)mainViewDidLoad
{
    [super mainViewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textDidChange:) name:NSTextDidChangeNotification object: myTextSample];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}
-(IBAction) changeTabStopSize: (id) sender
{
    [myDefaults setObject: @([sender floatValue]) forKey: IDEKit_TabStopKey];
    if ([[myTabStopsUnits selectedItem] tag] == -72) { // characters - keep in sync
	[mySpacesPerIndent setIntValue: [sender intValue]];
	[myDefaults setObject: @([sender intValue]) forKey: IDEKit_TabIndentSizeKey];
    }
    [myTextSample setUniformTabStops: 72.0 * [myDefaults floatForKey:IDEKit_TabStopKey] / [myDefaults floatForKey:IDEKit_TabStopUnitKey]];
}

-(IBAction) changeTabStopUnits: (id) sender
{
    [myDefaults setObject: @([[sender selectedItem] tag]) forKey: IDEKit_TabStopUnitKey];
    if ([[sender selectedItem] tag] == -72) { // characters
	[mySpacesPerIndent setEnabled: NO];
	[mySpacesPerIndent setIntValue: [myTabStops intValue]];
	[myDefaults setObject: @([myTabStops intValue]) forKey: IDEKit_TabIndentSizeKey];
    } else {
	[mySpacesPerIndent setEnabled: YES];
    }
    [myTextSample setUniformTabStops: 72.0 * [myDefaults floatForKey:IDEKit_TabStopKey] / [myDefaults floatForKey:IDEKit_TabStopUnitKey]];
}

-(IBAction) changeTabSaving: (id) sender
{
    [myDefaults setObject: @([[sender selectedCell] tag]) forKey: IDEKit_TabSavingKey];
}

-(IBAction) changeTabSpaces: (id) sender
{
    [myDefaults setObject: @([sender intValue]) forKey: IDEKit_TabSizeKey];
}

-(IBAction) changeIndentSpaces: (id) sender
{
    [myDefaults setObject: @([sender intValue]) forKey: IDEKit_TabIndentSizeKey];
}

- (NSFont *)font;
{
    NSFont *theFont;
    theFont=[NSFont fontWithName:[myDefaults stringForKey: IDEKit_TextFontNameKey]
		     size:[myDefaults floatForKey: IDEKit_TextFontSizeKey]];
    if (!theFont)
	theFont=[NSFont userFixedPitchFontOfSize:[myDefaults floatForKey: IDEKit_TextFontSizeKey]];
    return theFont;
}


-(IBAction)changeTextFont:(id)sender
{
    [[[self mainView] window] makeFirstResponder: myTextSample];
    [myTextSample setDelegate: self];
    [myTextSample setUsesFontPanel: YES];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
    [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
}

- (void)textDidChange:(NSNotification *)notification /* Any keyDown or paste which changes the contents causes this */
{
    //NSLog(@"textDidChange %@",[notification description]);
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSFont *newFont;

    newFont=[fontManager convertFont:[self font]];
    [myDefaults setObject:[newFont fontName] forKey: IDEKit_TextFontNameKey];
    [myDefaults setFloat:[newFont pointSize] forKey: IDEKit_TextFontSizeKey];
    //[myTextSample setFont: newFont];
    [myTextName setStringValue: [NSString stringWithFormat: @"%@ - %g",[newFont displayName],[newFont pointSize]]];
}
/*
- (void)changeFont:sender;
{
    NSFontManager *fontManager=sender;
    NSFont *newFont;

    newFont=[fontManager convertFont:[self font]];
    [myDefaults setObject:[newFont fontName] forKey: IDEKit_TextFontNameKey];
    [myDefaults setFloat:[newFont pointSize] forKey: IDEKit_TextFontSizeKey];
    [myTextSample setFont: newFont];
}

*/


//-(IBAction) changeAutoConvert: (id) sender
//{
//    [myDefaults setObject: [NSNumber numberWithInt: [sender intValue]] forKey: IDEKit_TabAutoConvertKey];
//}


@end
