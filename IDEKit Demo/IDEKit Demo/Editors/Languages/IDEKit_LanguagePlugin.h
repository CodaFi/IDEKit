//
//  IDEKit_LanguagePlugin.h
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

#import <Foundation/Foundation.h>

#import "IDEKit_TextColors.h"
#import "IDEKit_TextFunctionMarkers.h"

// Stand alone commands
@class IDEKit_LexParser;
@class IDEKit_TextView;

enum {
    IDEKit_kIndentAction_None = 0,
    IDEKit_kIndentAction_Indent,
    IDEKit_kIndentAction_Dedent,
    IDEKit_kIndentAction_Undent
};

NSMutableArray *IDEKit_GetLanguagePlugIns();

@class IDEKit_LexParser;

// for plug-in language support
@interface IDEKit_LanguagePlugin : NSObject
{
    IDEKit_LexParser *myParser;
    NSDictionary *myTemplates;
}
+ (NSString *)languageName;
- (NSString *)languageName;

+ (NSComparisonResult)languageNameCompare:(IDEKit_LanguagePlugin *)other;

+ (BOOL)isYourFile: (NSString *)name; // depicated
// isYourFile:withContents is what should be implemented - note that contents _may_ be NULL
// (and at some point, name may as well).  This is provided for things like xml based languages
// that all have xml suffix, but contents indicate the actual language.  isYourFile:withContents:
// will call isYourFile: by default
+ (BOOL)isYourFile: (NSString *)name withContents: (NSString *)contents;
+ (IDEKit_LexParser *)makeLexParser;
- (IDEKit_LexParser *)lexParser;
- (NSArray *)functionList: (NSString *)source; // for popup funcs - return a list of TextFunctionMarkers
- (NSDictionary *)headersList: (NSString *)source; // for popup funcs - return a dictionary with names & paths (based on what it can determine)
- (NSArray *)includedFileSuffixCandidates; // if we have "import foo", foo might be foo.bar or foo.inc
- (BOOL)wantsBreakpoints;
- (NSInteger) autoIndentLine: (NSString *)thisList last: (NSString *)lastLine;
- (NSString *) complete: (NSString *)name withParams: (NSArray *)array; // handles the "auto-complete" F5
- (NSString *) cleanUpStringFromFile: (NSString *)source;
- (NSString *) cleanUpStringForFile: (NSString *)source;
- (NSString *) getAutoCloseMatch: (NSString *)open; // return the closing paren, etc...
// to "comment out" a selection
- (NSString *) getLinePrefixComment;
// the templates to insert for the language - defaults to getting a plist in the bundle based on the language
// name (with overriding via the client app's bundle)
- (NSDictionary *) insertionTemplates;
+ (NSString *) insertionTemplateFilename;
- (NSString *) toolTipForRange: (NSRange) range source: (NSString *)source;
- (NSCharacterSet *) characterSetForAutoCompletion; // go back using these characters to form auto-complete string
- (NSRange) selectionForMultiClick: (NSEvent *)theEvent fromSelection: (NSRange)sel inView: (IDEKit_TextView *)view;
- (NSRange) selectStatement: (NSString*) source fromRange: (NSRange) sel;
- (NSRange) selectBlock: (NSString*) source fromRange: (NSRange) sel;
@end



