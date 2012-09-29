//
//  IDEKit_RSSPlugIn.mm
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

#import "IDEKit_RSSPlugIn.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"


enum {
    kRSS_heading = 1,
    kRSS_poi = 2 // points of interest
};

@implementation IDEKit_RSSLanguage
+ (void)load
{
    // since all subclasses end up calling this, we get called multiple times, all nice
    [IDEKit_GetLanguagePlugIns() addObject: self];
}

+ (NSString *)languageName
{
    return @"RSS (XML)";
}
+ (NSString *) insertionTemplateFilename
{
    // by default, use the language name
    return @"RSS templates";
}

+ (IDEKit_LexParser *)makeLexParser
{
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex setCaseSensitive: NO];
    [lex addMarkupStart: @"<" end: @">"]; // we are a markup lanaguage
    [lex addKeyword: @"rss" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"channel" color: IDEKit_kLangColor_Keywords lexID: kRSS_poi];
	[lex addKeyword: @"title" color: IDEKit_kLangColor_Keywords lexID: kRSS_heading];
	[lex addKeyword: @"link" color: IDEKit_kLangColor_Keywords lexID: kRSS_heading];
	[lex addKeyword: @"description" color: IDEKit_kLangColor_Keywords lexID: kRSS_heading];
	[lex addKeyword: @"language" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"copyright" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"managingeditor" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"webmaster" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"pubdate" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"lastbuilddate" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"category" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"generator" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"docs" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"cloud" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"ttl" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"image" color: IDEKit_kLangColor_Keywords lexID: kRSS_poi];
	    [lex addKeyword: @"url" color: IDEKit_kLangColor_Keywords lexID: 0];
	    // link, title already there
	    [lex addKeyword: @"width" color: IDEKit_kLangColor_Keywords lexID: 0];
	    [lex addKeyword: @"height" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"rating" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"textInput" color: IDEKit_kLangColor_Keywords lexID: 0];
	    // title, description, link
	    [lex addKeyword: @"name" color: IDEKit_kLangColor_Keywords lexID: kRSS_heading];
	[lex addKeyword: @"skipHours" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"skipDays" color: IDEKit_kLangColor_Keywords lexID: 0];
	[lex addKeyword: @"item" color: IDEKit_kLangColor_Keywords lexID: kRSS_poi];
	    // title, link, description, category, pubDate
	    [lex addKeyword: @"author" color: IDEKit_kLangColor_Keywords lexID: 0];
	    [lex addKeyword: @"comments" color: IDEKit_kLangColor_Keywords lexID: 0];
	    [lex addKeyword: @"enclosure" color: IDEKit_kLangColor_Keywords lexID: 0];
	    [lex addKeyword: @"guid" color: IDEKit_kLangColor_Keywords lexID: 0];
	    [lex addKeyword: @"source" color: IDEKit_kLangColor_Keywords lexID: 0];

    // now the rest of the info
    [lex addStringStart: @"\"" end: @"\""];
    [lex addStringStart: @"'" end: @"'"];
    [lex addCommentStart: @"!--" end: @"--"]; // hm, how to handle comments
    [lex setIdentifierChars: [NSCharacterSet characterSetWithCharactersInString: @"_"]];

    return lex;
}
- (NSString *) getLinePrefixComment
{
    return @""; // not really valid
}

+ (BOOL)isYourFile: (NSString *)name withContents: (NSString *)contents
{
    if ([[name pathExtension] isEqualToString: @"xml"] && contents && ([contents rangeOfString: @"<rss"].location != NSNotFound))
	return YES;
    if ([[name pathExtension] isEqualToString: @"rss"])
	return YES;
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
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kRSS_heading), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kLexContent, IDEKit_kMarkerTextEnd, IDEKit_kLexMarkupStart, '/', IDEKit_MATCH_KEYWORD(kRSS_heading), IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kRSS_poi), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerEndList
    };
    return [IDEKit_TextFunctionMarkers makeAllMarks: source inArray: nil fromPattern: pattern withLex: myParser];
}

- (NSString *) complete: (NSString *)name withParams: (NSArray *)array
{
    // we use templates, since completion is just too ugly
    return nil;
}


@end
