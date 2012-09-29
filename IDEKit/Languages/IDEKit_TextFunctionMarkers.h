//
//  IDEKit_TextFunctionMarkers.h
//  IDEKit
//
//  Created by Glenn Andreas on Mon Aug 18 2003.
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

#import <Foundation/Foundation.h>

#ifdef nomore
// we really want old regex to go away here
extern "C" {
#import <sys/types.h>
#import <regex.h>
}
#else
#import "regex.h" // new regex
#endif

#import "IDEKit_TextColors.h"

// This replaces regex for patterns - we provide a list of IDEKit_kLexFoo's with some addtional structure comments here
enum {
    IDEKit_kMarkerKind = 0x01000000,
    IDEKit_kMarkerBeginPattern = IDEKit_kMarkerKind | 0,
    IDEKit_kMarkerEndPattern = IDEKit_kMarkerKind | 1,
    IDEKit_kMarkerEndList = IDEKit_kMarkerKind | 3,
    IDEKit_kMarkerTextStart = IDEKit_kMarkerKind | 4,
    IDEKit_kMarkerTextEnd = IDEKit_kMarkerKind | 5,
    IDEKit_kMarkerBOL = IDEKit_kMarkerKind | 6,
    //IDEKit_kMarkerWS = IDEKit_kMarkerKind | 7,
    //IDEKit_kMarkerUntilEOL = IDEKit_kMarkerKind | 8,
    //IDEKit_kMarkerGroupBegin = IDEKit_kMarkerKind | 9,
    //IDEKit_kMarkerGroupEnd = IDEKit_kMarkerKind | 210,
    IDEKit_kMarkerOptional = IDEKit_kMarkerKind | 11,
    IDEKit_kMarkerMatchBegin = IDEKit_kMarkerKind | 12,
    IDEKit_kMarkerMatchEnd = IDEKit_kMarkerKind | 13,
    IDEKit_kMarkerAnyUntil = IDEKit_kMarkerKind | 14,

    // to add things to the marker menu, we do this (and provide common forms)
    // Note that additional ones can be defined as images IDEKit_MarkerCategoryX (where X is the category)
    IDEKit_kMarkerCategory = 0x02000000,
    IDEKit_kMarkerIsClass = IDEKit_kMarkerCategory | 'C',
    IDEKit_kMarkerIsMethod = IDEKit_kMarkerCategory | 'M',
    IDEKit_kMarkerIsFunction = IDEKit_kMarkerCategory | 'F',
    IDEKit_kMarkerIsDefine = IDEKit_kMarkerCategory | '#',
    
    IDEKit_kMarkerPatternSize = 30
};

#define IDEKit_MATCH_OP(x) (x)
#define IDEKit_MATCH_KEYWORD(x) (IDEKit_kLexKindKeyword | (x))
#define IDEKit_MATCH_PREPRO(x) (IDEKit_kLexKindPrePro | (x))
#define IDEKit_MATCH_PATTERN(...) IDEKit_kMarkerBeginPattern, __VA_ARGS__, IDEKit_kMarkerEndPattern
#define IDEKit_MATCH_OPT(x) IDEKit_kMarkerOptional,(x)
#define IDEKit_MATCH_ANY(...) IDEKit_kMarkerMatchBegin, __VA_ARGS__, IDEKit_kMarkerMatchEnd
#define IDEKit_MATCH_UNTIL(x) IDEKit_kMarkerAnyUntil,(x)


@class IDEKit_LexParser;
@interface IDEKit_TextFunctionMarkers : NSObject
{
    NSMutableString *mName;
    NSString *mImage;
    NSRange mDecl;
    NSRange mBody;
    int mIndent;
    int mColor;
}
+ (IDEKit_TextFunctionMarkers *)markWithName: (NSString *)name decl: (NSRange) decl body: (NSRange) body;
+ (IDEKit_TextFunctionMarkers *)markWithName: (NSString *)name decl: (NSRange) decl body: (NSRange) body image: (NSString *)imageName;
+ (NSMutableArray *) makeAllMarks: (NSString *) source inArray: (NSMutableArray *)array fromRegex: (regex_t *)regex withNameIn: (NSInteger) grouping;
+ (NSMutableArray *) makeAllMarks: (NSString *) source inArray: (NSMutableArray *)array fromPattern: (int *)pattern withLex: (IDEKit_LexParser *)lex;
- (id)initWithName: (NSString *)name decl: (NSRange) decl body: (NSRange) body image: (NSString *)imageName;
- (NSString *)name;
- (NSString *)image;
- (NSRange) decl;
- (NSRange) body;
- (void) setIndent: (NSInteger) indent;
- (void) setColor: (NSInteger) color;
- (NSInteger) indent;
- (NSInteger) color;
@end

