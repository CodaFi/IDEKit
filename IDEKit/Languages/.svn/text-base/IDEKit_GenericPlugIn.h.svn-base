//
//  IDEKit_GenericPlugIn.h
//  IDEKit
//
//  Created by Glenn Andreas on Fri Aug 6 2004.
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

#import "IDEKit_LanguagePlugin.h"

/*
 GenericLanguage adds support for languages defined in plists - doesn't give the full powers
 of a real language plug-in, but better than nothing.  The way it does this is to create a bunch
 of classes at runtime - one for each plist it finds.  These are then subclasses of IDEKit_GenericLanguage
 which then use those plists to perform class & instance functions (based on the name of the class).
 
 Essentially, we'd want to use class variables, but those don't exist.
 
 A language is defined in a property list with the following keys (very similar to XCode):
    Name : User visible language name
    Keywords : List of keywords
    AltKeywords : List of keywords
    DocCommentKeywords : List of keywords colored as Doc Keywords
    MultiLineComment : List of comment pairs (so an array of arrays)
    SingleLineComments : List of "to end of line" comments
    CaseSensitive : Is the language case sensitive?
    String : Like multi-line comment, an array of string pairs for string literals
    Character : Like multi-line comment, an array of string pairs for character literals
    PreprocessorKeywordStart : what (if preprocessors exist) does the preprocessor command start with (e.g., #)
    PreprocessorKeywords : a list of preprocessor commands (which appear after PreprocessorKeywordStart)
    Operators : a list of operators (not terribly useful with the current lexing approach)
    CaseSensitive : is language case senstive (YES/NO, YES by default)
    Markup : Again, an array of string pairs demarking markup from "text"
    IdentifierChars : A string of characters in addition to [A-Za-z0-9]
    IdentifierStartChars : Characters in addition to [A-Za-z0-9] that can be used for the first character of an identifier (but not later).  Note that unlike XCode, we assume that IdentifierStartChars automatically includes IdentifierChars (so it technically isn't possible to have "_" in an identifier but not as the first character - i.e. "[A-za-z0-9][_A-Za-z0-9]*").
 
    LinePrefixComment : What to use to prefix a line that is commented out (if not SingleLineComments[0])
    Extensions : List of possible file extensions (case dependant)
    MagicWord : A list of strings that match the first line of the file
    MIMETypes : A list of mimetypes for this language [not yet supported]
    FunctionRegexs : List of regular expressions that can find function popups (name should be in group) [not yet supported]
 */
@interface IDEKit_GenericLanguage : IDEKit_LanguagePlugin {
}
@end
