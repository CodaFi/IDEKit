//
//  IDEKit_LexParser.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon May 26 2003.
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

#import "IDEKit_LexParser.h"
#import "IDEKit_TextColors.h"

NSString *IDEKit_LexIDKey = @"IDEKit_LexIDKey";
NSString *IDEKit_LexColorKey = @"IDEKit_LexColorKey";





NSString *IDEKit_LexParserStartState = @"IDEKit_LexParserStartState";
enum {
    IDEKit_kLexStateNormal = 0,
    IDEKit_kLexStateNormalWS,
    IDEKit_kLexStateMatching,
    IDEKit_kLexStatePrePro0,
    IDEKit_kLexStatePrePro,
    IDEKit_kLexStateIdentifier,
    IDEKit_kLexStateNumber,
    IDEKit_kLexStateMarkupContent,
    IDEKit_kLexStateCount
};

#define IGNORE	myCurLoc++; mySubStart = myCurLoc; goto endLoop
#define APPEND	myCurLoc++; goto endLoop
#define APPENDTO(x)	myCurLoc++; myCurState = x; goto endLoop
#define TO(x)	myCurState = x; goto endLoop
#define REJECT	myCurState = IDEKit_kLexStateNormal; [self color:xstring from: mySubStart to: mySubStart+1 as: IDEKit_TextColorForColor(IDEKit_kLangColor_NormalText)]; myCurLoc = mySubStart+1; mySubStart = myCurLoc; goto endLoop
#define ACCEPT(x) myCurState = IDEKit_kLexStateNormal; [self color:xstring from: mySubStart to: myCurLoc as: IDEKit_TextColorForColor(x)]; mySubStart = myCurLoc;  goto endLoop
#define ACCEPTC(x) myCurState = IDEKit_kLexStateNormal; [self color:xstring from: mySubStart to: myCurLoc as: x]; mySubStart = myCurLoc;  goto endLoop
#define CONSUME(n) myCurLoc += n;
#define TOKEN [string substringWithRange: NSIntersectionRange(NSMakeRange(0,strLength),NSMakeRange(mySubStart,myCurLoc-mySubStart))]


@implementation IDEKit_LexParser
- (id) init
{
    self = [super  init];
    if (self) {
		myKeywords = [NSMutableDictionary dictionary];
		myOperators = [NSMutableDictionary dictionary];
		myPreProStart = NULL;
		myPreProcessor = [NSMutableArray array];
		myStrings = [NSMutableArray array];
		myCharacters = [NSMutableArray array];
		myMultiComments = [NSMutableArray array];
		mySingleComments = [NSMutableArray array];
		myIdentifierChars = NULL;
		myFirstIdentifierChars = NULL;
		myCaseSensitive = YES;
		myMarkupStart = NULL;
		myMarkupEnd = NULL;
    }
    return self;
}
- (void) setCaseSensitive: (BOOL) sensitive
{
    myCaseSensitive = sensitive;
}

- (id) addKeyword: (NSString *)string color: (NSInteger) color lexID: (NSInteger) lexID
{
    id retval = @{IDEKit_LexColorKey: @(color), IDEKit_LexIDKey: @(IDEKit_kLexKindKeyword | lexID)};
    myKeywords[string] = retval;
    return retval;
}
- (id) addOperator: (NSString *)string lexID: (NSInteger) lexID
{
    id retval = @{IDEKit_LexIDKey: @(IDEKit_kLexKindKeyword | lexID)};
    myOperators[string] = retval;
    return retval;
}
- (void) addStringStart: (NSString *)start end: (NSString *) end
{
    [myStrings addObject: @[start, end]];
}
- (void) addCharacterStart: (NSString *)start end: (NSString *) end
{
    [myCharacters addObject: @[start, end]];
}

- (void) addMarkupStart: (NSString *)start end: (NSString *) end
{
    myMarkupStart = start;
    myMarkupEnd = end;
}

- (void) addCommentStart: (NSString *)start end: (NSString *) end
{
    [myMultiComments addObject: @[start, end]];
}

- (void) addSingleComment: (NSString *)start
{
    [mySingleComments addObject: start];
}

- (void) setIdentifierChars: (NSCharacterSet *)set
{
    myIdentifierChars = set;
}

- (void) setFirstIdentifierChars: (NSCharacterSet *)set
{
    myFirstIdentifierChars = set;
}


- (void) setPreProStart: (NSString *)start
{
    myPreProStart = start;
}

- (void) addPreProcessor: (NSString *)token
{
    [myPreProcessor addObject: token];
}

- (BOOL) match: (NSString *) string withPattern: (NSString *)pattern
{
#define PEEK(n) (myCurLoc+n < [string length] ? [string characterAtIndex: myCurLoc+n] : 0)
    if (!pattern || [pattern length] == 0)
		return NO;
    for (NSUInteger i=0;i<[pattern length];i++) {
		if (PEEK(i) != [pattern characterAtIndex: i])
			return NO;
    }
    //CONSUME([pattern length]);  // don't consume
    //NSLog(@"Matched %@",pattern);
    return YES;
}
- (void) color: (NSMutableAttributedString *)string from: (NSUInteger) start to: (NSUInteger) end as: (NSColor *) color
{
    //NSLog(@"Coloring %d-%d with %d (%@)",start,end,color,[[string string] substringWithRange:NSMakeRange(start,end-start)]);
    [string addAttribute: NSForegroundColorAttributeName value: color range: NSIntersectionRange(NSMakeRange(0,[string length]),NSMakeRange(start,end-start))];
}



- (void) startParsingString: (NSString *)string range: (NSRange) range
{
    myString = nil;
    myCurLoc = range.location;
    myStopLoc = range.location + range.length;
    if (myCurLoc >= [string length])
		return; // nothing to color - at end of string
    myString = string;
    myCurState = IDEKit_kLexStateNormal;
    if (myMarkupStart)
		myCurState = IDEKit_kLexStateMarkupContent; // if we are a markup language, start in the content area
    mySubStart = myCurLoc;
    // myCurState will be 0 by default unless we are in a multi line comment, string
    myCloser = NULL;
    mySubColor = 0; mySubLexID = 0;
}

enum {
    IDEKit_kLexActionIgnore = 	0x00000000,
    IDEKit_kLexActionAppend = 	0x10000000,
    IDEKit_kLexActionReturn = 	0x20000000,
    IDEKit_kLexActionAppendTo = 0x30000000,
    IDEKit_kLexActionMask = 	0x0fffffff
};

- (NSInteger) lexStateNormal: (unichar) peekChar
{
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionIgnore;
    }
    if ([[NSCharacterSet controlCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexError);
		//IGNORE;
    }
    if ([[NSCharacterSet illegalCharacterSet] characterIsMember: peekChar]) {
		// by default, ignore unknown characters
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexError);
		//IGNORE;
    }
    if (myMarkupStart && [myMarkupStart characterAtIndex: 0] == peekChar) {
		// start of markup (which we actually detected previously, but we returned the content that time)
		myCurLoc++;
		mySubColor = IDEKit_kLangColor_NormalText;
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexMarkupStart);
    }
    if (myMarkupEnd && [myMarkupEnd characterAtIndex: 0] == peekChar) {
		// end of markup, back to content
		myCurLoc++;
		mySubColor = IDEKit_kLangColor_NormalText;
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexMarkupEnd);
    }
    
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateNumber);
    }
    if ([myFirstIdentifierChars characterIsMember: peekChar] || [myIdentifierChars characterIsMember: peekChar] || [[NSCharacterSet letterCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateIdentifier);
    }
    if ([self match: myString withPattern: myPreProStart]) {
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStatePrePro0);
    }
    for (NSUInteger i=0;i<[myStrings count];i++) {
		if ([self match: myString withPattern: myStrings[i][0]]) {
			myCloser = myStrings[i][1];
			mySubColor = IDEKit_kLangColor_Strings;
			mySubLexID = IDEKit_kLexString;
			return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateMatching);
		}
    }
    for (NSUInteger i=0;i<[myCharacters count];i++) {
		if ([self match: myString withPattern: myCharacters[i][0]]) {
			myCloser = myCharacters[i][1];
			mySubColor = IDEKit_kLangColor_Constants;
			mySubLexID = IDEKit_kLexCharacter;
			return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateMatching);
		}
    }
    for (NSUInteger i=0;i<[myMultiComments count];i++) {
		if ([self match: myString withPattern: myMultiComments[i][0]]) {
			myCloser = myMultiComments[i][1];
			mySubColor = IDEKit_kLangColor_Comments;
			mySubLexID = IDEKit_kLexComment;
			return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateMatching);
		}
    }
    for (NSUInteger i=0;i<[mySingleComments count];i++) {
		if ([self match: myString withPattern: mySingleComments[i]]) {
			myCloser = @"\n"; // go to EOL
			mySubColor = IDEKit_kLangColor_Comments;
			mySubLexID = IDEKit_kLexComment;
			return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateMatching);
		}
    }
    // otherwise, it is just some operator that we ignore (for now)
    myCurLoc++;
    mySubColor = IDEKit_kLangColor_NormalText;
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & peekChar); // treat operator as the character constant
}

- (NSInteger) lexStateNormalWS: (unichar) peekChar
{
    // treat WS special
    if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember: peekChar]) {
		myCurLoc++;
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexWhiteSpace);
    }
    // and EOL
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: peekChar]) {
		myCurLoc++;
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexEOL);
    }
    return [self lexStateNormal: peekChar];
}

- (NSInteger) lexStateIdentifier: (unichar) peekChar
{
    // we've got an identifier, consume the rest of it
    if ([myIdentifierChars characterIsMember: peekChar] || [[NSCharacterSet alphanumericCharacterSet] characterIsMember: peekChar] ) {
		// stay here
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateIdentifier);
    }
    // otherwise we've got an identifier of some sort, possibly a reserved or alt word
    NSString *token = [myString substringWithRange: NSIntersectionRange(NSMakeRange(0,[myString length]),NSMakeRange(mySubStart,myCurLoc-mySubStart))];
    //NSLog(@"Token '%@'",token);
    NSString *utoken = (myCaseSensitive ? token : [token lowercaseString]);
    if (myKeywords[utoken]) {
		id entry = myKeywords[utoken];
		if ([entry[IDEKit_LexIDKey] intValue]) {
			return IDEKit_kLexActionReturn |(IDEKit_kLexActionMask & [entry[IDEKit_LexIDKey] intValue]);
		}
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexToken); // generic token
    }
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexIdentifier);
}

- (NSInteger) lexStatePrePro0: (unichar) peekChar
{
    // got the "#" of a pre-processor, consume all the white space
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionAppend;
    }
    if ([myIdentifierChars characterIsMember: peekChar] || [[NSCharacterSet letterCharacterSet] characterIsMember: peekChar]) {
		// we are now in a pre-processor thing (hopefully)
		myTempBackState = myCurLoc;
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStatePrePro);
    }
    //REJECT; // this moves us back to parsing, but after the "#"
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexError);
}

- (NSInteger) lexStatePrePro: (unichar) peekChar
{
    if ([myIdentifierChars characterIsMember: peekChar] || [[NSCharacterSet letterCharacterSet] characterIsMember: peekChar]) {
		// stay here
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStatePrePro);
    }
    // otherwise, we've got something
    NSString *token = [myString substringWithRange: NSMakeRange(myTempBackState,myCurLoc-myTempBackState)]; // just grab after the ws
	//NSLog(@"Checking pre-pro '%@'",token);
    for (NSUInteger i=0;i<[myPreProcessor count];i++) {
		if ([token isEqualToString: myPreProcessor[i]]) {
			if (peekChar == '\n') {
				myCurLoc++; // we are at the end of it already
				mySubColor = IDEKit_kLangColor_Preprocessor;
				mySubLexID = (IDEKit_kLexKindPrePro | (i+1));
				return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & (IDEKit_kLexKindPrePro | (i+1)) );
			} else {
				myCloser = @"\n"; // go to EOL
				mySubColor = IDEKit_kLangColor_Preprocessor;
				mySubLexID = (IDEKit_kLexKindPrePro | (i+1));
				return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateMatching);
			}
		}
    }
    // this means we didn't get a pre-processor command
    //REJECT;
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexError);
}

- (NSInteger) lexStateMatching: (unichar) peekChar
{
    // this is used a lot - continue until we get the matching thing (we don't support nesting yet)
    if (peekChar == '\\') {
		myCurLoc += 1; //CONSUME(1);
		return IDEKit_kLexActionAppend; // grab the next thing as an escaped thing
    }
    if ([self match: myString withPattern: myCloser]) {
		// got the end!
		myCurLoc += ([myCloser length]);
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & mySubLexID);
    }
    // otherwise, just stay here in this state
    return IDEKit_kLexActionAppend;
}

- (NSInteger) lexStateNumber: (unichar) peekChar
{
    // not quite perfect - only grabs [0-9]+
    if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember: peekChar]) {
		return IDEKit_kLexActionAppendTo | (IDEKit_kLexStateNumber);
    }
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexNumber);
}

- (NSInteger) lexStateMarkupContent: (unichar) peekChar
{
    if (myMarkupStart && [myMarkupStart characterAtIndex: 0] == peekChar) {
		return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexContent); // return body of content as string
		// (and as a side effect of "Return" we end up as plain or whitespace mode)
    }
    // otherwise, just stay here in this state
    return IDEKit_kLexActionAppend;
}
- (NSInteger) examineCharacter: (unichar) peekChar inState: (NSInteger) state
{
    switch (state) {
		case IDEKit_kLexStateNormal:
			return [self lexStateNormal: peekChar];
		case IDEKit_kLexStateNormalWS:
			return [self lexStateNormalWS: peekChar];
		case IDEKit_kLexStateIdentifier:
			return [self lexStateIdentifier: peekChar];
		case IDEKit_kLexStatePrePro0:
			return [self lexStatePrePro0: peekChar];
		case IDEKit_kLexStatePrePro:
			return [self lexStatePrePro: peekChar];
		case IDEKit_kLexStateMatching:
			return [self lexStateMatching: peekChar];
		case IDEKit_kLexStateNumber:
			return [self lexStateNumber: peekChar];
		case IDEKit_kLexStateMarkupContent:
			return [self lexStateMarkupContent: peekChar];
		default:
			NSLog(@"Lex state %ld not handled",state);
			
    }
    return IDEKit_kLexActionReturn | (IDEKit_kLexActionMask & IDEKit_kLexError);
}


- (NSInteger) parseOneToken: (NSRangePointer) result ignoreWhiteSpace: (BOOL) ignoreWS
{
    if (myString == NULL)
		return IDEKit_kLexEOF;
    NSInteger strLength = [myString length];
    if (myCurLoc >= strLength) {
		myString = nil;
		return IDEKit_kLexEOF;
    }
    myTempBackState = 0;
    doneWithToken = NO;
    while (myCurLoc <= myStopLoc+1) {
		if (myCurState == IDEKit_kLexStateNormal || myCurState == IDEKit_kLexStateNormalWS) {
			myCurState = ignoreWS ? IDEKit_kLexStateNormal : IDEKit_kLexStateNormalWS;
		}
		unichar peekChar = 0;
		if (myCurLoc < strLength) peekChar = [myString characterAtIndex: myCurLoc];
		NSInteger action = [self examineCharacter: peekChar inState: myCurState];
		NSInteger actionParam = (action & IDEKit_kLexActionMask);
		action = action & (~IDEKit_kLexActionMask);
		switch (action) {
			case IDEKit_kLexActionIgnore:
				myCurLoc++;
				mySubStart = myCurLoc;
				break;
			case IDEKit_kLexActionAppend:
				myCurLoc++;
				break;
			case IDEKit_kLexActionReturn:
				if (result)
					*result = NSIntersectionRange(NSMakeRange(0,strLength),NSMakeRange(mySubStart,myCurLoc-mySubStart));
				if (actionParam == IDEKit_kLexError)
					myCurLoc++; // consume the one thing there
				mySubStart = myCurLoc;
				if (actionParam == IDEKit_kLexMarkupEnd) {
					myCurState = IDEKit_kLexStateMarkupContent;
				} else {
					myCurState = ignoreWS ? IDEKit_kLexStateNormal : IDEKit_kLexStateNormalWS;
				}
				return actionParam; //(actionParam << 4) >> 4; // sign extend it
			case IDEKit_kLexActionAppendTo:
				myCurLoc++;
				myCurState = actionParam;
				break;
			default:
				NSLog(@"Invalid lexical action %.8lX",action | actionParam);
				myCurLoc++;
		}
    }
    return IDEKit_kLexEOF; // we are at the end of the string
}

- (void) colorString: (NSMutableAttributedString *)string range: (NSRange) range colorer: (id) colorer
{
    [self startParsingString: [string string] range: range];
    if (myCurLoc >= [string length])
		return; // nothing to color - at end of string
    while (myCurLoc <= myStopLoc+1) { // make sure to go up to the EOL after the selection, just to be safe
		NSRange tokenRange;
		NSInteger nextToken = [self parseOneToken: &tokenRange ignoreWhiteSpace: YES];
		int color = IDEKit_kLangColor_NormalText;
		NSString *token = [[string string] substringWithRange: tokenRange];
		//NSLog(@"'%@' = %d",token,nextToken);
		NSColor *realColor = NULL;
		switch ((nextToken & IDEKit_kLexKindMask)) {
			case IDEKit_kLexKindSpecial: {
				switch (nextToken) {
					case IDEKit_kLexEOF:
						return; // done
					case IDEKit_kLexError:
						color = IDEKit_kLangColor_Errors;
						break;
					case IDEKit_kLexWhiteSpace:
						break;
					case IDEKit_kLexComment:
						color = IDEKit_kLangColor_Comments;
						break;
					case IDEKit_kLexString:
						color = IDEKit_kLangColor_Strings;
						break;
					case IDEKit_kLexCharacter:
						color = IDEKit_kLangColor_Characters;
						break;
					case IDEKit_kLexNumber:
						color = IDEKit_kLangColor_Numbers;
						break;
					case IDEKit_kLexIdentifier:
						if (colorer) {
							realColor = [colorer colorForIdentifier: token];
						} else {
							color = IDEKit_kLangColor_NormalText;
						}
						break;
				}
				break;
			}
			case IDEKit_kLexKindOperator:
				color = IDEKit_kLangColor_NormalText;
				break;
			case  IDEKit_kLexKindKeyword:
				color = IDEKit_kLangColor_Keywords;
				break;
			case IDEKit_kLexKindPrePro:
				color = IDEKit_kLangColor_Preprocessor;
				break;
			default:
				color = IDEKit_kLangColor_NormalText; // unknown
		}
		if (!realColor)
			realColor = IDEKit_TextColorForColor(color);
		[self color:string from: tokenRange.location to: tokenRange.location+tokenRange.length as: realColor];
    }
    if (myString) {
		myString = nil;
    }
}

@end
