//
//  IDEKit_plistPlugIn.mm
//  IDEKit
//
//  Created by Glenn Andreas on Thur Feb 5 2004.
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

#import "IDEKit_plistPlugIn.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"


enum {
    kPlist_heading = 1,
    kPlist_poi = 2 // points of interest
};

@implementation IDEKit_XMLplistLanguage
+ (void)load
{
    // since all subclasses end up calling this, we get called multiple times, all nice
    [IDEKit_GetLanguagePlugIns() addObject: self];
}

+ (NSString *)languageName
{
    return @"plist (XML)";
}

+ (IDEKit_LexParser *)makeLexParser
{
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex setCaseSensitive: NO];
    [lex addMarkupStart: @"<" end: @">"]; // we are a markup lanaguage
    [lex addKeyword: @"plist" color: IDEKit_kLangColor_Keywords lexID: kPlist_poi];
    [lex addKeyword: @"dict" color: IDEKit_kLangColor_Keywords lexID: kPlist_poi];
    [lex addKeyword: @"array" color: IDEKit_kLangColor_Keywords lexID: kPlist_poi];
    [lex addKeyword: @"key" color: IDEKit_kLangColor_Keywords lexID: kPlist_heading]; // show the key in the marker
    [lex addKeyword: @"string" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"data" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"date" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"real" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"integer" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"true" color: IDEKit_kLangColor_Constants lexID: 0];
    [lex addKeyword: @"false" color: IDEKit_kLangColor_Constants lexID: 0];
    // now the rest of the info
    [lex addStringStart: @"\"" end: @"\""];
    [lex addStringStart: @"'" end: @"'"];
    [lex addCommentStart: @"!--" end: @"--"]; // hm, how to handle comments
    [lex setIdentifierChars: [NSCharacterSet characterSetWithCharactersInString: @"_"]];

    return [lex autorelease];
}
- (NSString *) getLinePrefixComment
{
    return @""; // not really valid
}

+ (BOOL)isYourFile: (NSString *)name withContents: (NSString *)contents
{
    if ([[name pathExtension] isEqualToString: @"plist"]) {
	if (contents) {
	    // check to see if we are ascii or xml
	    return ([contents rangeOfString: @"<!DOCTYPE plist"].location != NSNotFound);
	}
	return YES;
    }
    return NO;
}
- (BOOL)wantsBreakpoints
{
    return NO;
}

- (NSArray *)functionList: (NSString *)source // for popup funcs - return a list of TextFunctionMarkers
{
    int pattern[] = {
	    // <h>sdfsd</h>
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kPlist_heading), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kLexContent, IDEKit_kMarkerTextEnd, IDEKit_kLexMarkupStart, '/', IDEKit_MATCH_KEYWORD(kPlist_heading), IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kPlist_poi), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerEndList
    };
    return [IDEKit_TextFunctionMarkers makeAllMarks: source inArray: nil fromPattern: pattern withLex: myParser];
}

- (NSString *) complete: (NSString *)name withParams: (NSArray *)array
{
    if ([name isEqualToString: @"dict"]) {
	return @"dict>$+$|$-</dict>";
    }
    if ([name isEqualToString: @"array"]) {
	return @"array>$+$|$-</array>";
    }
    return nil;
}

- (NSInteger) autoIndentLine: (NSString *)thisList last: (NSString *)lastLine
{
    if ([[lastLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix: @"<dict>"]) {
	return IDEKit_kIndentAction_Indent;
    }
    if ([[lastLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix: @"<array>"]) {
	return IDEKit_kIndentAction_Indent;
    }
    return IDEKit_kIndentAction_None;
}

@end


@implementation IDEKit_ASCIIplistLanguage
+ (void)load
{
    // since all subclasses end up calling this, we get called multiple times, all nice
    [IDEKit_GetLanguagePlugIns() addObject: self];
}

+ (NSString *)languageName
{
    return @"plist (ASCII)";
}
+ (BOOL)isYourFile: (NSString *)name withContents: (NSString *)contents
{
    if ([[name pathExtension] isEqualToString: @"plist"]) {
	if (contents) {
	    // check to see if we are ascii or xml
	    return ([contents rangeOfString: @"<!DOCTYPE plist"].location == NSNotFound);
	}
	return YES;
    }
    return NO;
}
- (BOOL)wantsBreakpoints
{
    return NO;
}
+ (IDEKit_LexParser *)makeLexParser
{
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex addKeyword: @"true" color: IDEKit_kLangColor_Constants lexID: 0];
    [lex addKeyword: @"false" color: IDEKit_kLangColor_Constants lexID: 0];
    [lex addStringStart: @"\"" end: @"\""];
    [lex addSingleComment: @"//"];
    [lex addCommentStart: @"/*" end: @"*/"];

    [lex setIdentifierChars: [NSCharacterSet characterSetWithCharactersInString: @"_"]];
    
    return [lex autorelease];
}  

- (NSArray *)functionList: (NSString *)source // for popup funcs - return a list of TextFunctionMarkers
{
    int pattern[] = {
	// <h>sdfsd</h>
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL, IDEKit_kLexString, '=', IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL, IDEKit_kLexIdentifier, '=', IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL, '{', IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerBOL, '(', IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerEndList
    };
    return [IDEKit_TextFunctionMarkers makeAllMarks: source inArray: nil fromPattern: pattern withLex: myParser];
}
- (NSInteger) autoIndentLine: (NSString *)thisList last: (NSString *)lastLine
{
    if ([[lastLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix: @"{"]) {
	return IDEKit_kIndentAction_Indent;
    }
    if ([[lastLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix: @"("]) {
	return IDEKit_kIndentAction_Indent;
    }
    return IDEKit_kIndentAction_None;
}

@end