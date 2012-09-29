//
//  IDEKit_HTMLPlugIn.mm
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

#import "IDEKit_HTMLPlugIn.h"
#import "IDEKit_LexParser.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_UserSettings.h"
#import "IDEKit_PathUtils.h"


enum {
    kHTML_heading = 1,
    kHTML_poi = 2 // points of interest
};

@implementation IDEKit_HTMLLanguage
+ (void)load
{
    // since all subclasses end up calling this, we get called multiple times, all nice
    [IDEKit_GetLanguagePlugIns() addObject: self];
}

+ (NSString *)languageName
{
    return @"HTML";
}

#define CHAR_ATTR IDEKit_kLangColor_Macros
#define BLOCK_ATTR IDEKit_kLangColor_Constants
#define CONSTRUCT   IDEKit_kLangColor_Preprocessor
#define EOL_ATTR    IDEKit_kLangColor_Keywords
#define LAYOUT    IDEKit_kLangColor_Templates
#define LINKS   IDEKit_kLangColor_Globals
+ (IDEKit_LexParser *)makeLexParser
{
    IDEKit_LexParser *lex = [[IDEKit_LexParser alloc] init];
    [lex setCaseSensitive: NO];
    [lex addMarkupStart: @"<" end: @">"]; // we are a markup lanaguage
    [lex addKeyword: @"html" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"head" color: IDEKit_kLangColor_Keywords lexID: kHTML_poi];
    [lex addKeyword: @"body" color: IDEKit_kLangColor_Keywords lexID: kHTML_poi];
    [lex addKeyword: @"meta" color: IDEKit_kLangColor_DocKeywords lexID: 0];
    [lex addKeyword: @"title" color: IDEKit_kLangColor_Keywords lexID: kHTML_heading];
    [lex addKeyword: @"h1" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];
    [lex addKeyword: @"h2" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];
    [lex addKeyword: @"h3" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];
    [lex addKeyword: @"h4" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];
    [lex addKeyword: @"h5" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];
    [lex addKeyword: @"h6" color: IDEKit_kLangColor_Functions lexID: kHTML_heading];

    [lex addKeyword: @"a" color: LINKS lexID: kHTML_heading];

    [lex addKeyword: @"abbr" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"acronym" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"address" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"applet" color: LINKS lexID: kHTML_poi];
    [lex addKeyword: @"area" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"b" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"base" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"basefont" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"bdo" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"bgsound" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"big" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"blink" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"blockquote" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"br" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"button" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"caption" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"center" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"cite" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"code" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"col" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"colgroup" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"dd" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"del" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"dir" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"div" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"di" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"dt" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"em" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"embed" color: LINKS lexID: kHTML_poi];
    [lex addKeyword: @"fieldset" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"font" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"form" color: CONSTRUCT lexID: kHTML_poi];
    [lex addKeyword: @"frame" color: LAYOUT lexID: kHTML_poi];
    [lex addKeyword: @"frameset" color: LAYOUT lexID: 0];
    [lex addKeyword: @"hr" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"i" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"iframe" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"img" color: LINKS lexID: 0];
    [lex addKeyword: @"input" color: CONSTRUCT lexID: 0];
	[lex addKeyword: @"type" color: CONSTRUCT lexID: 0];
	[lex addKeyword: @"button" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"checkbox" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"file" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"hidden" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"image" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"password" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"radio" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"reset" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"submit" color: IDEKit_kLangColor_Classes lexID: 0];
	[lex addKeyword: @"text" color: IDEKit_kLangColor_Classes lexID: 0];
    [lex addKeyword: @"ins" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"isindex" color: IDEKit_kLangColor_Keywords lexID: 0];
    [lex addKeyword: @"kbd" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"keygen" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"label" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"layer" color: LAYOUT lexID: 0];
    [lex addKeyword: @"legend" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"li" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"link" color: LINKS lexID: kHTML_poi];
    [lex addKeyword: @"map" color: CONSTRUCT lexID: kHTML_poi];
    [lex addKeyword: @"marquee" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"menu" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"multicol" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"nobr" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"noembed" color: LINKS lexID: 0];
    [lex addKeyword: @"noframes" color: LAYOUT lexID: 0];
    [lex addKeyword: @"noframes" color: LAYOUT lexID: 0];
    [lex addKeyword: @"nolayer" color: LAYOUT lexID: 0];
    [lex addKeyword: @"noscript" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"object" color: LINKS lexID: kHTML_poi];
    [lex addKeyword: @"ol" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"optgroup" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"option" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"p" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"param" color: LINKS lexID: 0];
    [lex addKeyword: @"pre" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"q" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"s" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"samp" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"script" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"select" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"server" color: LINKS lexID: kHTML_poi];
    [lex addKeyword: @"small" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"spacer" color: EOL_ATTR lexID: 0];
    [lex addKeyword: @"span" color: LAYOUT lexID: 0];
    [lex addKeyword: @"strike" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"strong" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"sub" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"sup" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"table" color: CONSTRUCT lexID: kHTML_poi];
    [lex addKeyword: @"tbody" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"tbody" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"td" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"textarea" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"tfoot" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"th" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"thead" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"tr" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"tt" color: BLOCK_ATTR lexID: 0];
    [lex addKeyword: @"u" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"ul" color: CONSTRUCT lexID: 0];
    [lex addKeyword: @"var" color: CHAR_ATTR lexID: 0];
    [lex addKeyword: @"wbr" color: EOL_ATTR lexID: 0];

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

+ (BOOL)isYourFile: (NSString *)name
{
    if ([[name pathExtension] isEqualToString: @"html"] || [[name pathExtension] isEqualToString: @"htm"])
	return YES;
    return NO;
}
- (BOOL)wantsBreakpoints
{
    // we are a programming language, let IDE delegate determine if debugger available for us
    return NO;
}

- (NSArray *)functionList: (NSString *)source // for popup funcs - return a list of TextFunctionMarkers
{
    int pattern[] = {
	    // <h>sdfsd</h>
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kHTML_heading), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kLexContent, IDEKit_kMarkerTextEnd, IDEKit_kLexMarkupStart, '/', IDEKit_MATCH_KEYWORD(kHTML_heading), IDEKit_kLexMarkupEnd, IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerBeginPattern, IDEKit_kMarkerTextStart, IDEKit_kLexMarkupStart, IDEKit_MATCH_KEYWORD(kHTML_poi), IDEKit_MATCH_UNTIL(IDEKit_kLexMarkupEnd), IDEKit_kMarkerEndPattern,
	IDEKit_kMarkerEndList
    };
    return [IDEKit_TextFunctionMarkers makeAllMarks: source inArray: nil fromPattern: pattern withLex: myParser];
}

- (NSString *) complete: (NSString *)name withParams: (NSArray *)array
{
    if ([name isEqualToString: @"html"]) {
	return @"html><head>$+$-</head>$=<body>$+$-</body></html>";
    }
    return nil;
}


@end
