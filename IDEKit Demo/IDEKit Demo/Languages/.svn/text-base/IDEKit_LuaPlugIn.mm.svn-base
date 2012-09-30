//
//  IDEKit_LuaPlugIn.mm
//  IDEKit
//
//  Created by Glenn Andreas on Sat Jan 17 2004.
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

#import "IDEKit_LuaPlugIn.h"
//#import "PythonInterface.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"


enum {
    kLua_function = 1,
	kLua_local = 2,
};

@implementation IDEKit_LuaLanguage
+ (void)load
{
    // since all subclasses end up calling this, we get called multiple times, all nice
    [IDEKit_GetLanguagePlugIns() addObject: self];
}

+ (NSString *)languageName
{
    return @"Lua";
}
+ (IDEKit_LexParser *)makeLexParser
{
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex addKeyword: @"and" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"break" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"do" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"else" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"elseif" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"end" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"false" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"for" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"function" color: IDEKit_kLangColor_Keywords lexID: kLua_function];
    [lex addKeyword: @"if" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"in" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"local" color: IDEKit_kLangColor_Keywords lexID: kLua_local];
    [lex addKeyword: @"nil" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"not" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"or" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"repeat" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"return" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"then" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"true" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"until" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"while" color: IDEKit_kLangColor_Keywords lexID: 0];
    // and alternates
    // common doc attributes
    [lex addKeyword: @"__doc__" color: IDEKit_kLangColor_DocKeywords lexID: 0];
    // these are sort of like docs, but set for modules by default
    // not quite doc, but close (or other predifined __foo__ attributes for built ins)
    // pre-processor
    // now the rest of the info
    [lex addStringStart: @"[[" end: @"]]"];
    [lex addStringStart: @"\"" end: @"\""];
    [lex addStringStart: @"'''" end: @"'''"];
    [lex addStringStart: @"'" end: @"'"];
    [lex addSingleComment: @"#"];
    [lex setIdentifierChars: [NSCharacterSet characterSetWithCharactersInString: @"_"]];

    return [lex autorelease];
}
- (NSString *) getLinePrefixComment
{
    return @"##"; // use modified comment
}

+ (BOOL)isYourFile: (NSString *)name
{
    if ([[name pathExtension] isEqualToString: @"lua"])
	return YES;
    return NO;
}
- (BOOL)wantsBreakpoints
{
    // we are a programming language, let IDE delegate determine if debugger available for us
    return [IDEKit languageSupportDebugging: self];
}

- (NSArray *)functionList: (NSString *)source // for popup funcs - return a list of TextFunctionMarkers
{
    int pattern[] = {
		// for the "function f()..." form
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL,IDEKit_MATCH_OPT(IDEKit_MATCH_KEYWORD(kLua_local)), IDEKit_MATCH_KEYWORD(kLua_function),IDEKit_kLexIdentifier,IDEKit_kMarkerTextEnd,IDEKit_MATCH_UNTIL('('),IDEKit_kMarkerEndPattern,
		// for f = function() ... form
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL,IDEKit_MATCH_OPT(IDEKit_MATCH_KEYWORD(kLua_local)), IDEKit_MATCH_KEYWORD(kLua_function),IDEKit_kMarkerTextEnd,'(',IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerEndList
    };
    return [IDEKit_TextFunctionMarkers makeAllMarks: source inArray: nil fromPattern: pattern withLex: myParser];
}

- (NSString *) complete: (NSString *)name withParams: (NSArray *)array
{
    if ([name isEqualToString: @"if"]) {
	return @"if $<condition$>then$+$<#true block$>$-end";
    } else if ([name isEqualToString: @"ife"]) {
	return @"if $<condition$>then$+$<#true block$>$-else$+$<#true block$>$-end";
    }
    return nil;
}


@end
