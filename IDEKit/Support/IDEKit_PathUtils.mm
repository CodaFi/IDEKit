//
//  IDEKit_PathUtils.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon Feb 24 2003.
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

#import "IDEKit_PathUtils.h"
//#import <CoreServices/Folders.h>
#import <CoreFoundation/CFURL.h>

@implementation  NSString(IDEKit_EscapedShellChars)
- (NSString *)stringByEscapingShellChars
{
    BOOL needEscape = NO;
    NSUInteger length = [self length];
    unichar *orig = new unichar[length ]; // worse case - everything is escaped (and a copy of ourselves)
    [self getCharacters: orig range: NSMakeRange(0,length)];
    for (NSUInteger i=0;i<length;i++) {
		if (orig[i] == '\\')
			i++; // ignore next character
		if (orig[i] == ' ') {
			needEscape = YES;
			break;
		}
    }
    if (!needEscape) {
		delete [] orig;
		return self;
    }
    unichar *escaped = new unichar[length * 2];
    unichar *p = escaped;
    for (NSUInteger i=0;i<length;i++) {
		if (orig[i] == '\\') {
			*p++ = orig[i++]; // copy the escape & character
		} else if (orig[i] == ' ') {
			*p++ = '\\'; // escape before copying
		}
		*p++ = orig[i];
    }
    NSString *retval = [NSString stringWithCharacters: escaped length: p - escaped];
    delete [] orig;
    delete [] escaped;
    return retval;
}
- (NSString *)stringByReplacingShellChars
{
    BOOL needEscape = NO;
    NSUInteger length = [self length];
    unichar *orig = new unichar[length]; // worse case - everything is escaped (and a copy of ourselves)
    [self getCharacters: orig range: NSMakeRange(0,length)];
    for (NSUInteger i=0;i<length;i++) {
		if (orig[i] == ' ') {
			needEscape = YES;
			break;
		}
    }
    if (!needEscape) {
		delete [] orig;
		return self;
    }
    for (NSUInteger i=0;i<length;i++) {
		if (orig[i] == ' ') {
			orig[i] = '_'; // escape before copying
		}
    }
    NSString *retval = [NSString stringWithCharacters: orig length: length];
    delete [] orig;
    return retval;
}

- (NSString *)stringByReplacingVars: (NSDictionary *)vars
{
    NSArray *components = [self pathComponents];
    NSMutableArray *newComponents = [NSMutableArray arrayWithCapacity:[components count]];
    BOOL sub = NO;
    for (NSUInteger i=0;i<[components count];i++) {
		NSString *component = components[i];
		if (vars[component]) { // we could check if component is of the form "{...}"
			component = vars[component]; // substitute
			sub = YES;
		}
		[newComponents addObject: component];
    }
    if (sub) {
		return [NSString pathWithComponents: newComponents];
    } else {
		// keep string as is
		return self;
    }
}


- (NSString *)stringRelativeTo: (NSString *)path name: (NSString *)name withFlags: (NSInteger) flags;
{
    if ([path length] == 0)
		return self; // keep as is - relative to nothing!
    if ([self isEqualToString: path])
		return name; // this is the place to be - same file
    // are we within "path"?
    NSArray *ourParts = [self pathComponents];
    NSArray *relParts = [path pathComponents];
    NSUInteger i=0;
    while (i < [ourParts count] && i < [relParts count]) {
		if ([ourParts[i] isEqualToString: relParts[i]] == NO)
			break;
		i++;
    }
    // i is now the first component that doesn't match.
    // if i == [ourParts count] then we are above path
    // if i == [relParts count] then we are below path
    // otherwise we need to move up from "path" until we are somewhere
    // so first find out how many "parts" are left in path
    NSUInteger parCount = [relParts count] - i;
    if (parCount && (flags & IDEKit_kPathRelDontAllowUpPath))
		return (flags & IDEKit_kPathRelReturnSelfOnErr) ? self : NULL; // don't allow ".."
    if (parCount == [relParts count] && (flags & IDEKit_kPathRelDontGoToRoot)) // would remove all of relative parts
		return (flags & IDEKit_kPathRelReturnSelfOnErr) ? self : NULL; // don't allow going to root
    if (parCount == [relParts count] - 1 && [relParts[0] isEqualToString: @"Volumes"]  && (flags & IDEKit_kPathRelDontGoToRoot)) {
		// not quite root, but close enough
		return (flags & IDEKit_kPathRelReturnSelfOnErr) ? self : NULL; // don't allow going to root
    }
    NSMutableArray *retParts = [NSMutableArray arrayWithCapacity: parCount];
    for (NSUInteger j=0;j<parCount;j++) {
		[retParts addObject: @".."];
    }
    // this will take us from wherever "relParts" is, and bring us to the base of "ourParts"
    for (NSUInteger j=i;j<[ourParts count];j++) {
		[retParts addObject: ourParts[j]];
    }
    // and we've made it all the way - tack on the name, and bail
    return [name stringByAppendingPathComponent: [NSString pathWithComponents: retParts]];
}
- (NSString *)stringRelativeTo: (NSString *)path name: (NSString *)name
{
    return [self stringRelativeTo: path name: name withFlags: IDEKit_kPathRelAlwaysRelative];
}

@end


@implementation NSString(PathlessComparison)
- (BOOL) isEqualToLastPathComponent: (NSString *)what
{
    return [[self lastPathComponent] isEqualToString: [what lastPathComponent]];
}
@end


@implementation NSFileHandle(StringWriting)
- (void) writeString: (NSString *)string
{
    [self writeData: [string dataUsingEncoding: NSUTF8StringEncoding]];
}
- (void) writeStringWithFormat: (NSString *)format,...
{
    va_list myArgs;
    va_start(myArgs,format);
    NSString *string = [[NSString alloc] initWithFormat: format arguments: myArgs];
    [self writeString: string];
    va_end(myArgs);
}

@end


@implementation NSBundle(IDEKit_OverrideNibLoading)
+ (BOOL) loadOverridenNibNamed: (NSString *)nibName owner: (id) owner
{
    // try the main bundle first
    NSDictionary *nameTable = @{@"NSOwner": owner};
    if ([[NSBundle mainBundle] loadNibFile: nibName externalNameTable: nameTable withZone: NSDefaultMallocZone()])
		return YES; // we were loaded there
    // then do where the class was
    return [[NSBundle bundleForClass: [owner class]] loadNibFile: nibName externalNameTable: nameTable withZone: NSDefaultMallocZone()];
}
@end


@implementation NSString(IDEKit_TabsAndEOL)

- (NSString *) convertTabsFrom: (NSInteger) tabWidth to: (NSInteger) indentWidth removeTrailing: (BOOL) removeTrailing;
{
    // this may not be the fastest way to do it, but as long as it works correctly...
    NSInteger srcCol = 0;
    NSInteger dstCol = 0;
    NSInteger curPos = 0;
    if (tabWidth == 0) tabWidth = 1; // convert tab to a single space from input if none given
    NSMutableString *retval = [NSMutableString stringWithCapacity: [self length]]; // give a good guess at it
    while (curPos < [self length]) {
		unichar c = [self characterAtIndex: curPos];
		if (c == '\t') {
			srcCol = (srcCol + tabWidth) / tabWidth * tabWidth;
		} else if (c == ' ') {
			srcCol ++;
		} else {
			BOOL atEOL = (c == '\n' || c == '\r');
			if (atEOL && removeTrailing) {
				srcCol = dstCol; // remove the trailing white space, if any
			}
			// add in any whitespace as needed
			if (srcCol > dstCol) {
				// our srcCol is further to the right than dstCol - we've got tabs or white space in here
				if (indentWidth && srcCol - 1 > dstCol) { // don't insert a tab for a single space _ever_
					// try to add indents to the dst to move as close as possible
					while (srcCol / indentWidth > dstCol / indentWidth) {
						[retval appendString: @"\t"];
						dstCol = (dstCol + indentWidth) / indentWidth * indentWidth;
					}
				}
				while (srcCol > dstCol) {
					[retval appendString: @" "];
					dstCol++;
				}
			}
			if (atEOL) {
				// end of line, moves us back to first column
				srcCol = 0;
				dstCol = 0;
			} else {
				srcCol++;
				dstCol++;
			}
			[retval appendFormat: @"%C", c];
		}
		curPos++;
    }
    // and we may have trailing white space at end of line
    if (!removeTrailing && srcCol > dstCol) {
		// our srcCol is further to the right than dstCol - we've got tabs or white space in here
		if (indentWidth) {
			// try to add indents to the dst to move as close as possible
			while (srcCol / indentWidth > dstCol / indentWidth) {
				[retval appendString: @"\t"];
				dstCol = (srcCol + indentWidth) / indentWidth * indentWidth;
			}
		}
		while (srcCol > dstCol) {
			[retval appendString: @" "];
			dstCol++;
		}
    }
    return retval;
}

#define qSANITIZEFORMFEED

- (NSString *) sanitizeLineFeeds: (NSInteger) style;
{
    NSMutableString *retval = [NSMutableString stringWithCapacity: [self length]]; // give a good guess at it
    int curPos = 0;
    BOOL lastWasReturn = NO;
    BOOL lastWasEOL = NO;
    NSString *eol = @"\n";
    switch (style) {
		case IDEKit_kUnixEOL:
			eol = @"\n";
			break;
		case IDEKit_kMacintoshEOL:
			eol = @"\r";
			break;
		case IDEKit_kWindowsEOL:
			eol = @"\r\n";
			break;
		case IDEKit_kUnicodeEOL:
			eol = [NSString stringWithFormat: @"%d",0x2028];
			break;
		case IDEKit_kUnicodeEOP:
			eol = [NSString stringWithFormat: @"%d",0x2029];
			break;
    }
    while (curPos < [self length]) {
		unichar c = [self characterAtIndex: curPos];
		if (c == '\n') {
			if (lastWasReturn == NO) {
				lastWasEOL = YES;
				[retval appendString: eol]; // only treat this as an eol if last wasn't \r
			}
			lastWasReturn = NO;
		} else {
			lastWasReturn = NO;
			if (c == '\r') {
				lastWasReturn = YES;
				lastWasEOL = YES;
				[retval appendString: eol];
			} else if (c == 0x2029 /* Paragraph sep */ || c == 0x2028 /* line sep */) {
				lastWasEOL = YES;
				[retval appendString: eol];
#ifdef qSANITIZEFORMFEED
			} else if (c == 0x000c) {
				// form feed - we want to make sure it is the first thing on a line, or
				// NSTextView doesn't show anything
				if (!lastWasEOL) {
					[retval appendString: eol];
				}
				[retval appendFormat: @"%C", c];
				lastWasEOL = NO;
#endif
			} else {
				lastWasEOL = NO;
				[retval appendFormat: @"%C", c];
			}
		}
		curPos++;
    }
    return retval;
}
@end


@implementation NSString(IDEKit_EscapedXMLChars)
- (NSString *)stringByEscapingXMLChars
{
    if ([self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&<>'\""]].location == NSNotFound)
		return self; // contain nothing that needs to be escaped
    NSMutableString *retval = [self mutableCopy];
    // '&' must be first (since the rest create such things)
    [retval replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"'" withString:@"&apos;" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    return [NSString stringWithString: retval];
}
- (NSString *)stringFromEscapedXMLChars
{
    if ([self rangeOfString:@"&"].location == NSNotFound)
		return self; // we contain no "&" so we have nothing that was escaped
    NSMutableString *retval = [self mutableCopy];
    [retval replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    [retval replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    // '&' must be last (just in case we've got the text "&amp;lt;" which needs to become "&lt;" and not "<")
    [retval replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0,[retval length])];
    return [NSString stringWithString: retval];
}
@end


@implementation NSString(IDEKit_LineNumbers)
- (NSRange) nthLineRange: (NSInteger) n
{
    // line num are 1 based
    if (n == 0) return NSMakeRange(0,0);
    // not sure if it is better to walk the array of line separated ranges, or to use lineRangeForRange
#ifdef nodef
    NSArray *lines = [self componentsSeparatedByString: @"\n"];
    if (n > [lines count])
		return NSMakeRange([self length],0);
    n--;
    NSUInteger start = 0;
    for (NSUInteger i=0;i<n;i++) {
		start += [[lines objectAtIndex: i] length] + 1;
    }
    return NSMakeRange(start,[[lines objectAtIndex: n] length] + 1); // this includes the return
#else
    NSUInteger lastStart = 0;
    NSUInteger numberOfLines = 0;
    NSUInteger curStart = 0;
    for (curStart=0;curStart<[self length] && numberOfLines < n;numberOfLines++) {
		lastStart = curStart;
		curStart = NSMaxRange([self lineRangeForRange: NSMakeRange(curStart,0)]);
    }
    if (numberOfLines < n)
		return NSMakeRange([self length],0); // return empty range at end of file
	// now select/show lastStart..curStart
    return NSMakeRange(lastStart,curStart - lastStart);
#endif
}
- (NSInteger) lineNumberFromOffset: (NSUInteger) offset
{
    NSUInteger curStart = 0;
    int lineNum = 1; // line num are 1 based
    for (curStart=0;curStart<[self length];lineNum++) {
		curStart = NSMaxRange([self lineRangeForRange: NSMakeRange(curStart,0)]);
		if (curStart > offset)
			break;
    }
    return lineNum;
}
@end


@implementation NSString(IDEKit_Sorting)
- (NSComparisonResult)caseSensitiveCompare:(NSString *)aString
{
    return [self compare: aString options: 0];
}
- (NSComparisonResult)literalCompare:(NSString *)aString
{
    return [self compare: aString options: NSLiteralSearch];
}
@end


@implementation NSString(IDEKit_Indentation)
- (NSString *) leadingIndentString
{
    NSString *indentString = @"";
    NSScanner *scanner = [NSScanner scannerWithString: self];
    [scanner setCharactersToBeSkipped: [NSCharacterSet illegalCharacterSet]];
    [scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet] intoString: &indentString];
    //NSLog(@"Found indent string '%@' (len = %d)",indentString,[indentString length]);
    return indentString;
}
@end


@implementation NSString(IDEKit_FindFolder)

+ (NSString *) findFolder: (NSInteger) folderType forDomain: (NSInteger) domain
{
    NSString *retval = NULL;
    FSRef folder;
    OSErr err = FSFindFolder(domain, folderType, false, &folder);
    if (err == noErr) {
		CFURLRef asURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
		if (asURL) {
			retval = [(__bridge NSURL *)asURL path];
			CFRelease(asURL);
		}
    }
    return retval;
}

+ (NSString *) userPrefFolderPath
{
    return [self findFolder: kPreferencesFolderType forDomain:kUserDomain];
}

+ (NSString *) userAppSupportFolderPath
{
    return [self findFolder: kApplicationSupportFolderType forDomain:kUserDomain];
}

+ (NSString *) userScratchFolderPath // "chewable" - temp and will be deleted at reboot
{
    return [self findFolder: kChewableItemsFolderType forDomain:kUserDomain];
}

@end

@implementation NSString(IDEKit_SearchFile)
- (NSArray *)pathsToSubFilesEndingWith: (NSString *)pattern extensions: (NSArray *)extensions
{
    return [self pathsToSubFilesEndingWith:pattern extensions:extensions glob:NO];
}
- (NSArray *)pathsToSubFilesEndingWith: (NSString *)pattern extensions: (NSArray *)extensions glob: (BOOL) glob;
{
    if (![pattern hasPrefix:@"/"])
		pattern = [@"/" stringByAppendingString:pattern]; // make sure starts with / to not glob leading edge
    if (!extensions && [[pattern pathExtension] length]) {
		// convert "foo.bar" to "foo",["bar"]
		extensions = @[[pattern pathExtension]];
		pattern = [pattern stringByDeletingPathExtension];
    }
    NSMutableArray *retval = [NSMutableArray  array];
    NSEnumerator *pathEnum = [[NSFileManager defaultManager] enumeratorAtPath: self];
    NSString *file;
    while ((file = [pathEnum nextObject]) != NULL) {
		if (extensions) {
			if (![extensions containsObject: [file pathExtension]]) {
				continue;
			}
		}
		NSString *fullPath = [self stringByAppendingPathComponent:file];
		if ([[fullPath stringByDeletingPathExtension] hasSuffix:pattern])
			[retval addObject: fullPath];
    }
    return retval;
}
@end
