//
//  IDEKit_LexParserUtils.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/6/04.
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

#import "IDEKit_LexParserUtils.h"


@implementation IDEKit_LexParser(Utils)

- (IDEKit_LexTokenEnumerator *) tokenEnumeratorForSource: (NSString *)source;
{
    return [self tokenEnumeratorForSource: source range: NSMakeRange(0,[source length]) ignoreWhiteSpace: YES];
}

- (IDEKit_LexTokenEnumerator *) tokenEnumeratorForSource: (NSString *)source range: (NSRange) range ignoreWhiteSpace: (BOOL) ignoreWS;
{
    return [IDEKit_LexTokenEnumerator tokenEnumeratorForSource: source range: range lexer: self ignoreWhiteSpace: ignoreWS];
}
@end

@implementation IDEKit_LexToken
- (id) initWithRange: (NSRange) range inString: (NSString *)source kind: (NSInteger) kind
{
    self = [super init];
    if (self) {
	mySource = [source retain];
	myRange = range;
	myKind = kind;
    }
    return self;
}
- (NSString *) tokenStr
{
    return [mySource substringWithRange: myRange];
}
- (NSInteger) token
{
    return myKind;
}
- (NSRange) range
{
    return myRange;
}
- (NSInteger) operator
{
    if ((myKind & IDEKit_kLexKindMask) == IDEKit_kLexKindOperator)
	return myKind & IDEKit_kLexIDMask;
    return -1;
}
- (NSInteger) keyword
{
    if ((myKind & IDEKit_kLexKindMask) == IDEKit_kLexKindKeyword)
	return myKind & IDEKit_kLexIDMask;
    return -1;
}
- (NSInteger) preprocessor
{
    if ((myKind & IDEKit_kLexKindMask) == IDEKit_kLexKindPrePro)
	return myKind & IDEKit_kLexIDMask;
    return -1;
}

- (NSString *) description
{
    NSString *tokenStr = [mySource substringWithRange: myRange];
    switch (myKind) {
	case IDEKit_kLexEOF:
	    return @"EOF<>";
	    break;
	case IDEKit_kLexError:
	    return [NSString stringWithFormat:@"Error<%@>",tokenStr];
	    break;
	case IDEKit_kLexWhiteSpace:
	    //NSLog(@"Error<%@>",tokenStr);
	    return [NSString stringWithFormat: @"WhiteSpace<%@>", tokenStr];
	    break;
	case IDEKit_kLexEOL:
	    return @"EOL<>";
	    break;
	case IDEKit_kLexComment:
	    return [NSString stringWithFormat:@"Comment<%@>",tokenStr];
	    break;
	case IDEKit_kLexString:
	    return [NSString stringWithFormat:@"String<%@>",tokenStr];
	    break;
	case IDEKit_kLexCharacter:
	    return [NSString stringWithFormat:@"Character<%@>",tokenStr];
	    break;
	case IDEKit_kLexNumber:
	    return [NSString stringWithFormat:@"Number<%@>",tokenStr];
	    break;
	case IDEKit_kLexIdentifier:
	    return [NSString stringWithFormat:@"Identifier<%@>",tokenStr];
	    break;
	case IDEKit_kLexMarkupStart:
	    return [NSString stringWithFormat:@"MarkupStart<%@>",tokenStr];
	    break;
	case IDEKit_kLexMarkupEnd:
	    return [NSString stringWithFormat:@"MarkupEnd<%@>",tokenStr];
	    break;
	case IDEKit_kLexContent:
	    return [NSString stringWithFormat:@"Content<%@>",tokenStr];
	    break;
	default:
	    switch (myKind & IDEKit_kLexKindMask) {
		case IDEKit_kLexKindOperator:
		    return [NSString stringWithFormat:@"Operator %C<%@>",myKind & IDEKit_kLexIDMask, tokenStr];
		    break;
		case IDEKit_kLexKindKeyword:
		    return [NSString stringWithFormat:@"Keyword %d<%@>",myKind & IDEKit_kLexIDMask, tokenStr];
		    break;
		case IDEKit_kLexKindPrePro:
		    return [NSString stringWithFormat:@"PrePro %d<%@>",myKind & IDEKit_kLexIDMask, tokenStr];
		    break;
		default:
		    return [NSString stringWithFormat:@"Unknown %.8X/%d:%d<%@>",myKind,myKind >> 16, myKind & IDEKit_kLexIDMask, tokenStr];
		    break;
	    }
    }
}

@end

@implementation IDEKit_LexTokenEnumerator
- (id) initWithSource: (NSString *)source lexer: (IDEKit_LexParser *)lexer range: (NSRange) range ignoreWhiteSpace: (BOOL) ignoreWS
{
    self = [super init];
    if (self) {
	mySource = [source retain];
	myLexer = [lexer retain];
	[myLexer startParsingString: mySource range: range];
	myIgnoreWS = ignoreWS;
    }
    return self;
}
- (void) dealloc
{
    [mySource release];
    [myLexer release];
    [super dealloc];
}
- (id) nextObject
{
    NSRange range;
    int token = [myLexer parseOneToken: &range ignoreWhiteSpace: myIgnoreWS];
    if (token == IDEKit_kLexEOF)
	return NULL;
    return [[[IDEKit_LexToken alloc] initWithRange: range inString: mySource kind: token] autorelease];
}

+ (IDEKit_LexTokenEnumerator *) tokenEnumeratorForSource: (NSString *)source range: (NSRange) range lexer: (IDEKit_LexParser *)lexer ignoreWhiteSpace: (BOOL) ignoreWS;
{
    return [[[self alloc] initWithSource: source lexer: lexer range: range ignoreWhiteSpace: ignoreWS] autorelease];
}
@end