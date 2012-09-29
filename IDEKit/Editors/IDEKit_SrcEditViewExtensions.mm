//
//  IDEKit_SrcEditViewExtensions.mm
//  IDEKit
//
//  Created by Glenn Andreas on Tue Aug 19 2003.
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

#import "IDEKit_SrcEditViewExtensions.h"
#import "IDEKit_TextView.h"
#import "IDEKit_TextViewExtensions.h"
#import "IDEKit_DialogController.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_LexParserUtils.h"
#import "IDEKit_Snippets.h"
#import "IDEKit_SrcEditViewStatusBar.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_OpenQuicklyController.h"

@implementation IDEKit_SrcEditView(MovementExtensions)

- (IBAction) transposeParameters: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    if (selectedRange.length == 0) {
	selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
	if (selectedRange.length < 2)
	    return; // no parameters
	selectedRange.location += 1;
	selectedRange.length -= 2;
    }
    NSArray *parameters = [self extractParameters: selectedRange];
    if ([parameters count] >= 2) {
	NSString *laterParams = [[parameters subarrayWithRange: NSMakeRange(1,[parameters count]-1)] componentsJoinedByString: @","];
	NSString *result = [NSString stringWithFormat: @"%@,%@",laterParams,[parameters objectAtIndex: 0]];
	[myTextView replaceCharactersInRange: selectedRange withString: result];
	selectedRange.length = [result length];
    }
    [myTextView setSelectedRange: selectedRange];
}

- (IBAction) selectStatement: (id) sender
{
}
- (IBAction) selectRoutine: (id) sender
{
}
- (IBAction) selectParameter: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    NSUInteger targetIndex = selectedRange.location;
    selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
    if (selectedRange.length < 2)
	return; // no parameters
    selectedRange.location += 1;
    selectedRange.length -= 2;
    NSArray *parameters = [self extractParameters: selectedRange];
    NSRange parameterRange = NSMakeRange(selectedRange.location,0);
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (NSLocationInRange(targetIndex,parameterRange)) {
	    parameterRange.length--;
	    [myTextView setSelectedRange: parameterRange];
	    return;
	}
	parameterRange.location += parameterRange.length;
    }
}
- (IBAction) moveToStartOfParmeter: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    NSUInteger targetIndex = selectedRange.location;
    selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
    if (selectedRange.length < 2)
	return; // no parameters
    selectedRange.location += 1;
    selectedRange.length -= 2;
    NSArray *parameters = [self extractParameters: selectedRange];
    NSRange parameterRange = NSMakeRange(selectedRange.location,0);
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (NSLocationInRange(targetIndex,parameterRange)) {
	    parameterRange.length--;
	    [myTextView setSelectedRange: NSMakeRange(parameterRange.location,0)];
	    return;
	}
	parameterRange.location += parameterRange.length;
    }
}
- (IBAction) moveToEndOfParameter: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    NSUInteger targetIndex = selectedRange.location;
    selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
    if (selectedRange.length < 2)
	return; // no parameters
    selectedRange.location += 1;
    selectedRange.length -= 2;
    NSArray *parameters = [self extractParameters: selectedRange];
    NSRange parameterRange = NSMakeRange(selectedRange.location,0);
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (NSLocationInRange(targetIndex,parameterRange)) {
	    [myTextView setSelectedRange: NSMakeRange(parameterRange.location+parameterRange.length-1,0)];
	    return;
	}
	parameterRange.location += parameterRange.length;
    }
}
- (IBAction) selectNextParameter: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    NSUInteger targetIndex = selectedRange.location;
    selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
    if (selectedRange.length < 2)
	return; // no parameters
    selectedRange.location += 1;
    selectedRange.length -= 2;
    NSArray *parameters = [self extractParameters: selectedRange];
    NSRange parameterRange = NSMakeRange(selectedRange.location,0);
    NSUInteger paramToSelect = 99999;
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (NSLocationInRange(targetIndex,parameterRange)) {
	    paramToSelect = (i+1) % ([parameters count]);
	    break;
	}
	parameterRange.location += parameterRange.length;
    }
    parameterRange = NSMakeRange(selectedRange.location,0);
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (i == paramToSelect) {
	    parameterRange.length--;
	    [myTextView setSelectedRange: parameterRange];
	    return;
	}
	parameterRange.location += parameterRange.length;
    }
}
- (IBAction) selectPreviousParameter: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    NSUInteger targetIndex = selectedRange.location;
    selectedRange = [myTextView balanceFrom: selectedRange.location]; // this includes the '('...')'
    if (selectedRange.length < 2)
	return; // no parameters
    selectedRange.location += 1;
    selectedRange.length -= 2;
    NSArray *parameters = [self extractParameters: selectedRange];
    NSRange parameterRange = NSMakeRange(selectedRange.location,0);
    NSUInteger paramToSelect = 99999;
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (NSLocationInRange(targetIndex,parameterRange)) {
	    paramToSelect = (i+[parameters count]-1) % ([parameters count]);
	    break;
	}
	parameterRange.location += parameterRange.length;
    }
    parameterRange = NSMakeRange(selectedRange.location,0);
    for (NSUInteger i=0;i<[parameters count];i++) {
	parameterRange.length = [(NSString *)[parameters objectAtIndex: i] length]+1; // add trailing ','
	if (i == paramToSelect) {
	    parameterRange.length--;
	    [myTextView setSelectedRange: parameterRange];
	    return;
	}
	parameterRange.location += parameterRange.length;
    }
}
- (IBAction) moveToStartOfStatement: (id) sender
{
}
- (IBAction) moveToEndOfStatement: (id) sender
{
}
- (IBAction) moveToStartOfRoutine: (id) sender
{
}
- (IBAction) moveToEndOfRoutine: (id) sender
{
}


- (IBAction) commentOutSelection: (id) sender
{
    NSString *prefix = [myCurrentLanguage getLinePrefixComment];
    if (prefix) {
	[myTextView prefixSelectedLinesWith: prefix];
    }
}

- (IBAction) uncommentOutSelection: (id) sender
{
    NSString *prefix = [myCurrentLanguage getLinePrefixComment];
    if (prefix) {
	[myTextView unprefixSelectedLinesWith: prefix];
    }
}

- (IBAction) closeUnbalancedOpens: (id) sender
{
    NSRange selectedRange = [myTextView selectedRange];
    IDEKit_LexParser *lexer = [myCurrentLanguage lexParser];
    NSString *source = [self string];
    NSMutableString *balance = [NSMutableString string]; // what we've seen before the insertion point
    NSMutableString *unbalanced = [NSMutableString string]; // what we've got after the insertion point
    IDEKit_LexTokenEnumerator *i = [lexer tokenEnumeratorForSource: source];
    IDEKit_LexToken *token;
    while ((token = [i nextObject]) != NULL) {
	if ([token operator] != -1) {
	    NSString *tokenStr = [token tokenStr];
	    if ([token range].location < selectedRange.location + selectedRange.length) {
		// before the insertion
		NSString *closer = [myCurrentLanguage getAutoCloseMatch: tokenStr];
		if (closer)
		    [balance insertString:closer atIndex: 0];
		else if ([balance hasPrefix: tokenStr]) {
		    // we've got the closing one, remove it
		    [balance deleteCharactersInRange: NSMakeRange(0,1)];
		}
		
	    } else {
		// after the insertion
		NSString *closer = [myCurrentLanguage getAutoCloseMatch: tokenStr];
		if (closer)
		    [unbalanced insertString:closer atIndex: 0];
		else if ([unbalanced hasPrefix: tokenStr]) {
		    // we've got the closing one, remove it
		    [unbalanced deleteCharactersInRange: NSMakeRange(0,1)];
		} else if ([balance hasPrefix: tokenStr]) {
		    // we've got the closing one, remove it from the openning in the pre-insertion point
		    [balance deleteCharactersInRange: NSMakeRange(0,1)];
		}
		
	    }
	}
    }
    [myTextView insertText:balance];
}

- (IBAction) handleGotoLine: (id) sender
{
    int line = [[sender valueForKey: @"myGoto"] intValue];
    if (line) {
	[myTextView selectNthLine: line];
    }
}

- (IBAction) gotoLine: (id) sender
{
    IDEKit_DialogController *dialog = [IDEKit_DialogController dialogControllerForNib: @"IDEKit_GoToLine"];
    if (dialog) {
	NSRange range = [myTextView selectedRange];
	[[dialog valueForKey: @"myGoto"] setIntegerValue:[myTextView lineNumberFromOffset: range.location]];
	[dialog beginSheetModalForWindow: [self window] modalDelegate: self didEndSelector: @selector(handleGotoLine:)];
    }
}

- (IBAction) handlePrefixSuffix: (id) sender
{
    NSInteger action = [[[sender valueForKey: @"myInsertDelete"] selectedCell] tag];
    NSInteger where = [[[sender valueForKey: @"myBeginEnd"] selectedCell] tag];
    NSInteger selectOrFile = [[[sender valueForKey: @"mySelectOrFile"] selectedCell] tag];
    if (selectOrFile) {
	[myTextView selectAll:self]; // replace in entire file
    }
    NSString *str = [[sender valueForKey: @"myString"] stringValue];
    if ([str length]) {
	if (action == 0) { // insert
	    if (where == 0) { // prefix
		[myTextView prefixSelectedLinesWith: str];
	    } else {
		[myTextView suffixSelectedLinesWith: str];
	    }
	} else {
	    if (where == 0) { // prefix
		[myTextView unprefixSelectedLinesWith: str];
	    } else {
		[myTextView unsuffixSelectedLinesWith: str];
	    }
	}
    }
}

- (IBAction) prefixSuffix: (id) sender
{
    IDEKit_DialogController *dialog = [IDEKit_DialogController dialogControllerForNib: @"IDEKit_PrefixSuffix"];
    if (dialog) {
	NSRange range = [myTextView selectedRange];
	NSMatrix *selectOrFile = [dialog valueForKey: @"mySelectOrFile"];
	if (range.length) {
	    // can do selection
	    [selectOrFile selectCellWithTag: 0];
	    [selectOrFile setEnabled: YES];
	} else {
	    [selectOrFile selectCellWithTag: 1];
	    [selectOrFile setEnabled: NO];
	}
	[dialog beginSheetModalForWindow: [self window] modalDelegate: self didEndSelector: @selector(handlePrefixSuffix:)];
    }
}

- (IBAction) dumpParse: (id) sender
{
    IDEKit_LexParser *lexer = [myCurrentLanguage lexParser];
    NSString *source = [self string];
    IDEKit_LexTokenEnumerator *i = [lexer tokenEnumeratorForSource: source];
    IDEKit_LexToken *token;
    while ((token = [i nextObject]) != NULL) {
	NSLog(@"%@",[token description]);
    }
}

- (IBAction) wordCount: (id) sender
{
    int tokenCount = 0;
    int commentSize = 0;
    IDEKit_LexParser *lexer = [myCurrentLanguage lexParser];
    NSString *source = [self string];
    if ([source length] == 0) {
	[self setStatusBar: @"Empty file"];
	return;
    }
    IDEKit_LexTokenEnumerator *i = [lexer tokenEnumeratorForSource: source range: NSMakeRange(0,[source length]) ignoreWhiteSpace:NO];
    IDEKit_LexToken *token;
    BOOL blankLine = YES;
    int blankLines = 0;
    int nonBlankLines = 0;
    while ((token = [i nextObject]) != NULL) {
	switch ([token token]) {
	    case IDEKit_kLexComment:
		commentSize += [token range].length;
		blankLine = NO;
		break;
	    case IDEKit_kLexEOL:
		if (blankLine) {
		    blankLines++;
		} else {
		    nonBlankLines++;
		}
		blankLine = YES;
		break;
	    case IDEKit_kLexWhiteSpace:
		break; // ignore this
	    case IDEKit_kLexString:
		// count string to comments
		commentSize += [token range].length;
		// and fall through
	    default:
		blankLine = NO;
		tokenCount++;
		break;
	}
    }
    [self setStatusBar:[NSString stringWithFormat: @"%ld chars (%ld%% comments/strings), %d lines (%d%% blank), %d tokens, %g tokens/lines",(long)[source length],((long)commentSize * 100 / [source length]), blankLines+nonBlankLines,blankLines * 100 / (blankLines+nonBlankLines), tokenCount, (float)tokenCount / (float)nonBlankLines]];
}

- (NSArray *) findIncludedFiles: (NSString *)partialPath flags: (NSInteger) flags
{
    // first, relative to us
    NSString *myDir = [[myContext fileNameForSrcEditView: self] stringByDeletingLastPathComponent];
    NSArray *candidates = [myDir pathsToSubFilesEndingWith: partialPath extensions: [myCurrentLanguage includedFileSuffixCandidates]];
    if ([candidates count])
	return candidates;
    // ask our project
    // ask the delegate
    return [IDEKit findFilesFromImport: partialPath forLanguage: myCurrentLanguage flags: flags];
}

- (IBAction) openSelection: (id) sender
{
    NSRange range = [myTextView selectedRange];
    if (range.length) {
	if ([[NSDocumentController sharedDocumentController] openQuicklyWithText: [[myTextView string] substringWithRange:range] helper: self context: NULL])
	    return; // found one
    }
    // empty string, or invalid
    [IDEKit_OpenQuicklyController openQuicklyWithText: [[myTextView string] substringWithRange:range] helper: self context: NULL];
}

@end


