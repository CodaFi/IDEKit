//
//  IDEKit_LanguagePlugin.mm
//  IDEKit
//
//  Created by Glenn Andreas on Wed Aug 13 2003.
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

#import "IDEKit_LanguagePlugin.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"
#import "IDEKit_TextView.h"

extern "C" {
#import <unistd.h>
}

NSMutableArray *IDEKit_GetLanguagePlugIns()
{
    static NSMutableArray *plugIns = NULL;
    if (!plugIns) {
        plugIns = [[NSMutableArray alloc] init];
    }
    return plugIns;
}

@implementation IDEKit_LanguagePlugin
+ (NSString *)languageName
{
    return @"IDEKit_Language";
}
+ (NSString *) insertionTemplateFilename
{
    // by default, use the language name
    return [NSString stringWithFormat: @"%@ templates",[self languageName]];
}
+ (NSComparisonResult)languageNameCompare:(IDEKit_LanguagePlugin *)other
{
    return [[self languageName]  caseInsensitiveCompare: [other languageName]];
}
- (NSDictionary *) insertionTemplates
{
    if (myTemplates) {
	return myTemplates;
    }
    NSString *templateName = [[self class] insertionTemplateFilename];
    if (templateName) {
	NSString *path = [[NSBundle mainBundle] pathForResource: templateName ofType:@"plist"];
	if (!path) { // not in main bundle, look in language plugin
	    path = [[NSBundle bundleForClass: [self class] ] pathForResource: templateName ofType: @"plist"];
	}
	if (path) {
	    myTemplates = [NSDictionary dictionaryWithContentsOfFile:path];
	}
    }
    return myTemplates;
}

- (NSString *)languageName
{
    return [[self class] languageName];
}

+ (BOOL)isYourFile: (NSString *)name
{
    return NO;
}

+ (BOOL)isYourFile: (NSString *)name withContents: (NSString *)contents
{
    return [self isYourFile: name];
}


- (IDEKit_LexParser *)lexParser
{
    if (!myParser) {
	myParser = [[self class] makeLexParser];
    }
    return myParser;
}

+ (IDEKit_LexParser *)makeLexParser
{
    // plain text parse does something simple at least
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex addStringStart: @"\"" end: @"\""];
    return lex;
}

- (BOOL)wantsBreakpoints
{
    return NO;
}
- (NSInteger) autoIndentLine: (NSString *)thisList last: (NSString *)lastLine
{
    return IDEKit_kIndentAction_None;
}

- (NSArray *)functionList: (NSString *)source // for popup funcs - return a list of TextFunctionMarkers
{
    return NULL;
}

- (NSDictionary *)headersList: (NSString *)source // for popup funcs - return a dictionary with names & paths (based on what it can determine)
{
    return NULL;
}
- (NSArray *)includedFileSuffixCandidates // if we have "import foo", foo might be foo.bar or foo.inc
{
    return NULL;
}

- (NSString *) complete: (NSString *)name withParams: (NSArray *)array // handles the "auto-complete" F5
{
    return NULL;
}

// here's where we convert tabs/spaces/indents
- (NSString *) cleanUpStringFromFile: (NSString *)source
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [source convertTabsFrom: [defaults integerForKey: IDEKit_TabSizeKey] to: [defaults integerForKey: IDEKit_TabIndentSizeKey] removeTrailing: YES];
}

- (NSString *) cleanUpStringForFile: (NSString *)source
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [source convertTabsFrom: [defaults integerForKey: IDEKit_TabIndentSizeKey]
					      to: ([defaults boolForKey: IDEKit_TabSavingKey] ? [defaults integerForKey: IDEKit_TabSizeKey] : 0)
						removeTrailing: YES];
}

- (NSString *) getAutoCloseMatch: (NSString *)open // return the closing paren, etc...
{
    if ([open isEqualToString: @"("]) return @")";
    if ([open isEqualToString: @"["]) return @"]";
    if ([open isEqualToString: @"{"]) return @"}";
    return NULL; // hande the default things, let the rest of the world deal with other cases on a language specific fashion
}

- (NSString *) getLinePrefixComment
{
    return NULL; // no such comment
}
- (NSString *) toolTipForRange: (NSRange) range source: (NSString *)source
{
    return NULL; // no tool tips yet
}
- (NSCharacterSet *) characterSetForAutoCompletion // go back using these characters to form auto-complete string
{
    return [NSCharacterSet alphanumericCharacterSet];
}

- (NSRange) selectionForMultiClick: (NSEvent *)theEvent fromSelection: (NSRange)sel inView: (IDEKit_TextView *)view
{
    // do nothing by default - the view handles (), [], {}
    if ([theEvent clickCount] == 3) {
	// select statement
	return [self selectStatement: [view string] fromRange: sel]; // this is the folded string
    } else if ([theEvent clickCount] == 4) {
	// select block
	return [self selectBlock: [view string] fromRange: sel]; // this is the folded string
    }
    return NSMakeRange(0,0);
}

- (NSRange) selectStatement: (NSString*) source fromRange: (NSRange) sel
{
    return NSMakeRange(0,0);
}
- (NSRange) selectBlock: (NSString*) source fromRange: (NSRange) sel
{
    return NSMakeRange(0,0);
}

@end

