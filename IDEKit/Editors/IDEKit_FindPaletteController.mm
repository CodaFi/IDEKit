/*
 TextFinder.m
 Copyright (c) 1995-2001 by Apple Computer, Inc., all rights reserved.
 Author: Ali Ozer
 
 Find and replace functionality with a minimal panel...
 Would be nice to have the buttons in the panel validate; this would allow the
 replace buttons to become disabled for readonly docs
 */
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation,
 modification or redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 In consideration of your agreement to abide by the following terms, and subject to these
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in
 this original Apple software (the "Apple Software"), to use, reproduce, modify and
 redistribute the Apple Software, with or without modifications, in source and/or binary
 forms; provided that if you redistribute the Apple Software in its entirety and without
 modifications, you must retain this notice and the following text and disclaimers in all
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be incorporated.
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE,
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import <Cocoa/Cocoa.h>
#import "IDEKit_FindPaletteController.h"
extern "C" {
#import <sys/types.h>
#import <regex.h>
};
#import "IDEKit_PathUtils.h"
#import "IDEKit_TextView.h"
#import "IDEKit_MultiFileResults.h"
#import "IDEKit_SrcEditView.h"
#import "IDEKit_UniqueFileIDManager.h"

@implementation IDEKit_TextFinder

+ (id)sharedInstance {
	static dispatch_once_t pred = 0;
	__strong static id _sharedObject = nil;
	dispatch_once(&pred, ^{
		_sharedObject = [[self alloc] init]; // or some other init method
	});
	return _sharedObject;
}

- (id)init {
	if (!(self = [super init]))
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
	[self setFindString:@"" writeToPasteboard:NO];
	[self loadFindStringFromPasteboard];
	
	return self;
}
- (void)appDidActivate:(NSNotification *)notification {
    [self loadFindStringFromPasteboard];
}
- (void)loadFindStringFromPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        NSString *string = [pasteboard stringForType:NSStringPboardType];
        if (string && [string length]) {
            [self setFindString:string writeToPasteboard:NO];
        }
    }
}
- (void)loadFindStringToPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteboard setString:[self findString] forType:NSStringPboardType];
}

- (void)loadUI {
    if (!findTextField) {
        if (![NSBundle loadOverridenNibNamed:@"IDEKit_FindPanel" owner:self])  {
            NSLog(@"Failed to load IDEKit_FindPanel.nib");
            NSBeep();
        }
		[[findTextField window] setFrameAutosaveName:@"Find"];
    }
    [findTextField setStringValue:[self findString]];
    if ([self replaceString]) [replaceTextField setStringValue:[self replaceString]];
}
- (NSString *)findString
{
    return findString;
}
- (NSString *)findRegex {
    NSString *pattern = [self findString];
    switch ([[wholeWordsButton selectedItem] tag]) {
		case 1: // anywhere
			break; // use pattern as such
		case 2:	// whole word
		case 3: // identifier
			// enclose with "beginnning of word/end of word" bracket expressions
			pattern = [NSString stringWithFormat: @"%@%@%@", @"[[:<:]]",pattern,@"[[:>:]]"];
    }
    return pattern;
}
- (NSCharacterSet *)wordSet
{
    switch ([[wholeWordsButton selectedItem] tag]) {
		case 1: // anywhere
			break;
		case 2:	// whole word
			return [NSCharacterSet letterCharacterSet];
			break;
		case 3: // identifier
		{
			NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
			[set formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
			[set addCharactersInRange: NSMakeRange('_',1)];
			return set;
			break;
		}
    }
    return NULL;
}
- (void)setFindString:(NSString *)string {
    [self setFindString:string writeToPasteboard:YES];
}
- (void)setFindString:(NSString *)string writeToPasteboard:(BOOL)flag {
    if ([string isEqualToString:findString]) return;
    if ([string length]) {
		NSMutableArray *pastFinds = [[[NSUserDefaults standardUserDefaults] objectForKey: @"IDEKit_recentFinds"] mutableCopy];
		if (!pastFinds) {
			pastFinds = [NSMutableArray array];
		}
		if ([pastFinds containsObject:string]) {
			[pastFinds removeObject:string]; // remove so we add at the end
		}
		while ([pastFinds count] > 10) { // limit to 10 items
			[pastFinds removeObjectAtIndex:0];
		}
		[pastFinds addObject: string];
		[[NSUserDefaults standardUserDefaults] setObject:pastFinds forKey:@"IDEKit_recentFinds"];
		[findTextField reloadData];
    }
    findString = [string copyWithZone:nil];
    if (findTextField) {
        [findTextField setStringValue:string];
        [findTextField selectText:nil];
    }
    if (flag) [self loadFindStringToPasteboard];
}
- (NSString *)replaceString
{
    return replaceString;
}

- (NSString *)fullReplaceString // including regex
{
    return replaceString;
}
- (void)setReplaceString:(NSString *)string {
    if ([string isEqualToString:replaceString]) return;
    if ([string length]) {
		NSMutableArray *pastReplace = [[[NSUserDefaults standardUserDefaults] objectForKey: @"IDEKit_recentReplaces"] mutableCopy];
		if (!pastReplace) {
			pastReplace = [NSMutableArray array];
		}
		if ([pastReplace containsObject:string]) {
			[pastReplace removeObject:string]; // remove so we add at the end
		}
		while ([pastReplace count] > 10) { // limit to 10 items
			[pastReplace removeObjectAtIndex:0];
		}
		[pastReplace addObject: string];
		[[NSUserDefaults standardUserDefaults] setObject:pastReplace forKey:@"IDEKit_recentReplaces"];
		[replaceTextField reloadData];
    }
    replaceString = [string copyWithZone:nil];
    if (replaceTextField) {
        [replaceTextField setStringValue:string];
        [replaceTextField selectText:nil];
    }
}
- (NSTextView *)textObjectToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    if (obj) {
		if ([obj isKindOfClass:[IDEKit_TextView class]])
			return [obj delegate]; // return the IDEKit_SrcView so we are synced correctly
		if ([obj isKindOfClass:[NSTextView class]])
			return obj;
    }
    return nil;
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}
- (NSPanel *)findPanel {
    if (!findTextField) [self loadUI];
    return (NSPanel *)[findTextField window];
}
/* The primitive for finding; this ends up setting the status field (and beeping if necessary)...
 */
- (BOOL)find:(BOOL)direction {
    NSTextView *text = [self textObjectToSearchIn];
    lastFindWasSuccessful = NO;
    if (text) {
        NSString *textContents = [text string];
        NSUInteger textLength;
        if (textContents && (textLength = [textContents length])) {
            NSRange range;
            NSUInteger options = 0;
			if (direction == Backward) options |= NSBackwardsSearch;
            if ([ignoreCaseButton state]) options |= NSCaseInsensitiveSearch;
            BOOL wrap = YES;
            if ([stopAtEndOfFileButton state])
				wrap = NO;
			
			regexGroupRange = NSMakeRange(0, NSNotFound);
			regexGroups = nil;

            if ([regularExpressionButton state]) {
				range = [textContents findExpression:[self findRegex] selectedRange:[text selectedRange] options:options wrap:wrap groups: &regexGroups];
				if (regexGroups) {
					regexGroupRange = range;
				} else {
					regexGroupRange = NSMakeRange(0, NSNotFound);
				}
            } else {
				range = [textContents findString:[self findString] selectedRange:[text selectedRange] options:options wrap:wrap wordSet: [self wordSet]];
			}
            if (range.length) {
                [text setSelectedRange:range];
                [text scrollRangeToVisible:range];
                lastFindWasSuccessful = YES;
            }
        }
    }
    if (!lastFindWasSuccessful) {
        NSBeep();
        [statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
    } else {
        [statusField setStringValue:@""];
    }
    return lastFindWasSuccessful;
}
- (void)orderFrontFindPanel:(id)sender {
    NSPanel *panel = [self findPanel];
    [findTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}
/**** Action methods for gadgets in the find panel; these should all end up setting or clearing the status field ****/
- (void)findNextAndOrderFindPanelOut:(id)sender {
    [findNextButton performClick:nil];
    if (lastFindWasSuccessful) {
        [[self findPanel] orderOut:sender];
    } else {
		[findTextField selectText:nil];
    }
}
- (void)findNext:(id)sender {
    if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
    (void)[self find:Forward];
}
- (void)findPrevious:(id)sender {
    if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
    (void)[self find:Backward];
}
- (void)replace:(id)sender {
    NSTextView *text = [self textObjectToSearchIn];
    // shouldChangeTextInRange:... should return NO if !isEditable, but doesn't...
    if (replaceTextField) [self setReplaceString:[replaceTextField stringValue]];
    NSString *replacement = [replaceTextField stringValue];
    if ([regularExpressionButton state] && regexGroups && NSEqualRanges([text selectedRange],regexGroupRange)) {
		replacement = [replaceString makeReplacementString: regexGroups];
    }
    if (text && [text isEditable] && [text selectedRange].length != 0 && [text shouldChangeTextInRange:[text selectedRange] replacementString:replacement] ) {
		//[[text textStorage] replaceCharactersInRange:[text selectedRange] withString:replaceString];
		[text replaceCharactersInRange:[text selectedRange] withString:replacement];
        [text didChangeText];
    } else {
        NSBeep();
    }
    [statusField setStringValue:@""];
}
- (void)replaceAndFind:(id)sender {
    [self replace:sender];
    [self findNext:sender];
}
- (void)replaceAndFindPrevious:(id)sender {
    [self replace:sender];
    [self findPrevious:sender];
}
#define ReplaceAllScopeEntireFile 42
#define ReplaceAllScopeSelection 43
/* The replaceAll: code is somewhat complex.  One reason for this is to support undo well --- To play along with the undo mechanism in the text object, this method goes through the shouldChangeTextInRange:replacementString: mechanism. In order to do that, it precomputes the section of the string that is being updated. An alternative would be for this method to handle the undo for the replaceAll: operation itself, and register the appropriate changes. However, this is simpler...
 Turns out this approach of building the new string and inserting it at the appropriate place in the actual text storage also has an added benefit of performance; it avoids copying the contents of the string around on every replace, which is significant in large files with many replacements. Of course there is the added cost of the temporary replacement string, but we try to compute that as tightly as possible beforehand to reduce the memory requirements.
 */
- (void)replaceAll:(id)sender {
    NSTextView *text = [self textObjectToSearchIn];
    if (!text || ![text isEditable]) {
		[statusField setStringValue:@""];
        NSBeep();
    }
	else {
		NSTextStorage *textStorage = [text textStorage];
		NSString *textContents = [text string];
		BOOL entireFile = replaceAllScopeMatrix ? ([replaceAllScopeMatrix selectedTag] == ReplaceAllScopeEntireFile) : YES;
		NSRange replaceRange = entireFile ? NSMakeRange(0, [textStorage length]) : [text selectedRange];
		NSUInteger searchOption = ([ignoreCaseButton state] ? NSCaseInsensitiveSearch : 0);
		NSUInteger replaced = 0;
		NSRange firstOccurence;
		
		if (findTextField)
			[self setFindString:[findTextField stringValue]];
		if (replaceTextField)
			[self setReplaceString:[replaceTextField stringValue]];
		// Find the first occurence of the string being replaced; if not found, we're done!
		if ([regularExpressionButton state]) {
			firstOccurence = [textContents rangeOfExpression:[self findRegex] options:searchOption range:replaceRange groups: NULL];
		}
		else
			firstOccurence = [textContents rangeOfString:[self findString] options:searchOption range:replaceRange];
		
		if (firstOccurence.length > 0) {
			@autoreleasepool {
				NSString *targetString = [self findString];
				NSString *replaceString = [self fullReplaceString];
				NSMutableAttributedString *temp;	/* This is the temporary work string in which we will do the replacements... */
				NSRange rangeInOriginalString;	/* Range in the original string where we do the searches */
				// Find the last occurence of the string and union it with the first occurence to compute the tightest range...
				if ([regularExpressionButton state])
					rangeInOriginalString = replaceRange = NSUnionRange(firstOccurence, [textContents rangeOfExpression:[self findRegex] options:NSBackwardsSearch|searchOption range:replaceRange groups: NULL]);
				else
					rangeInOriginalString = replaceRange = NSUnionRange(firstOccurence, [textContents rangeOfString:targetString options:NSBackwardsSearch|searchOption range:replaceRange]);
				temp = [[NSMutableAttributedString alloc] init];
				[temp beginEditing];
				// The following loop can execute an unlimited number of times, and it could have autorelease activity.
				// To keep things under control, we use a pool, but to be a bit efficient, instead of emptying everytime through
				// the loop, we do it every so often. We can only do this as long as autoreleased items are not supposed to
				// survive between the invocations of the pool!
				@autoreleasepool {
					while (rangeInOriginalString.length > 0) {
						NSRange foundRange;
						if (regexGroups) {
							regexGroupRange = NSMakeRange(0, NSNotFound);
							regexGroups = NULL;
						}
						if ([regularExpressionButton state]) {
							//foundRange = [textContents findExpression:[self findRegex] selectedRange:rangeInOriginalString options:searchOption wrap:NO groups: &regexGroups];
							foundRange = [textContents rangeOfExpression:[self findRegex] options: searchOption range: rangeInOriginalString groups: &regexGroups];
							if (regexGroups) {
								regexGroupRange = foundRange;
							}
							else {
								regexGroupRange = NSMakeRange(0, NSNotFound);
							}
						}
						else {
							//foundRange = [textContents findString:targetString selectedRange:rangeInOriginalString options:searchOption wrap:NO wordSet: [self wordSet]];
							foundRange = [textContents rangeOfString:[self findRegex] options: searchOption range: rangeInOriginalString boundBy: [self wordSet]];
						}
						// range = [textContents rangeOfString:targetString options:searchOption range:rangeInOriginalString];
						if (foundRange.length == 0) {
							[temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeInOriginalString]];	// Copy the remainder
							rangeInOriginalString.length = 0;	// And signal that we're done
						}
						else {
							NSRange rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location + 1);	// Copy upto the start of the found range plus one char (to maintain attributes with the overlap)...
							[temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeToCopy]];
							[temp replaceCharactersInRange:NSMakeRange([temp length] - 1, 1) withString:[replaceString makeReplacementString: regexGroups]];
							rangeInOriginalString.length -= NSMaxRange(foundRange) - rangeInOriginalString.location;
							rangeInOriginalString.location = NSMaxRange(foundRange);
							replaced++;
							if (replaced % 100 == 0) {	// Refresh the pool... See warning above!
								@autoreleasepool {
								}
								
							}
						}
					}
				}
				[temp endEditing];
				// Now modify the original string
				if ([text shouldChangeTextInRange:replaceRange replacementString:[temp string]]) {
					[textStorage replaceCharactersInRange:replaceRange withAttributedString:temp];
					[text didChangeText];
				} else {	// For some reason the string didn't want to be modified. Bizarre...
					replaced = 0;
				}
			}
			if (replaced == 0) {
				NSBeep();
				[statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
			} else {
				[statusField setStringValue:[NSString localizedStringWithFormat:NSLocalizedStringFromTable(@"%d replaced", @"FindPanel", @"Status displayed in find panel when indicated number of matches are replaced."), replaced]];
			}
		}
	}
}
- (void)takeFindStringFromSelection:(id)sender {
	NSTextView *textView = [self textObjectToSearchIn];
	if (textView) {
		NSString *selection = [[textView string] substringWithRange:[textView selectedRange]];
		[self setFindString:selection];
	}
	if (regularExpressionButton) {
		[regularExpressionButton setState: NO];
	}
}
- (void)takeReplaceStringFromSelection:(id)sender {
	NSTextView *textView = [self textObjectToSearchIn];
	if (textView) {
		NSString *selection = [[textView string] substringWithRange:[textView selectedRange]];
		[self setReplaceString:selection];
		if (regexGroups) {
			regexGroupRange = NSMakeRange(0, NSNotFound);
			regexGroups = NULL;
		}
	}
}
- (void) jumpToSelection:sender {
	NSTextView *textView = [self textObjectToSearchIn];
	if (textView) {
		[textView scrollRangeToVisible:[textView selectedRange]];
	}
}
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if (aComboBox == findTextField) {
		return [[[NSUserDefaults standardUserDefaults]  objectForKey:@"IDEKit_recentFinds"] count];
	} else if (aComboBox == replaceTextField) {
		return [[[NSUserDefaults standardUserDefaults]  objectForKey:@"IDEKit_recentReplaces"] count];
	}
	return 0;
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	if (aComboBox == findTextField) {
		return [[NSUserDefaults standardUserDefaults]  objectForKey:@"IDEKit_recentFinds"][index];
	} else if (aComboBox == replaceTextField) {
		return [[NSUserDefaults standardUserDefaults]  objectForKey:@"IDEKit_recentReplaces"][index];
	}
	return NULL;
}
- (void) findAll: (id) sender
{
	if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
	NSMutableArray *results = [NSMutableArray array];
	NSTextView *text = [self textObjectToSearchIn];
	if (text) {
		NSString *textContents = [text string];
		NSUInteger textLength;
		if (textContents && (textLength = [textContents length])) {
			NSRange fullRange = NSMakeRange(0,textLength);
			NSUInteger options = 0;
			if ([ignoreCaseButton state]) options |= NSCaseInsensitiveSearch;
			while (fullRange.length) {
				
				regexGroupRange = NSMakeRange(0, NSNotFound);
				regexGroups = nil;
				
				NSRange range;
				if ([regularExpressionButton state]) {
					range = [textContents findExpression:[self findRegex] selectedRange:NSMakeRange(fullRange.location,0) options:options wrap:NO groups: &regexGroups];
					if (regexGroups) {
						regexGroupRange = range;
					} else {
						regexGroupRange = NSMakeRange(0, NSNotFound);
					}
				} else {
					range = [textContents findString:[self findString] selectedRange:NSMakeRange(fullRange.location,0) options:options wrap:NO wordSet: [self wordSet]];
				}
				if (range.length) {
					fullRange.location = range.location + range.length;
					fullRange.length = textLength - fullRange.location;
					[results addObject: @{IDEKit_MultiFileResultID: [[(IDEKit_SrcEditView *) text uniqueFileID] stringValue],
										 IDEKit_MultiFileResultRange: [NSValue valueWithRange:range],
										 IDEKit_MultiFileResultLine: @([textContents lineNumberFromOffset: range.location])}];
				} else {
					break;
				}
			}
		}
	}
	if ([results count]) {
		[IDEKit_MultiFileResults showResults: results];
	} else {
		NSBeep();
		[statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
	}
}
@end

@implementation NSString (NSStringTextFinding)
- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)options wrap:(BOOL)wrap wordSet:(NSCharacterSet *)word
{
	BOOL forwards = (options & NSBackwardsSearch) == 0;
	NSUInteger length = [self length];
	NSRange searchRange, range;
	if (forwards) {
		searchRange.location = NSMaxRange(selectedRange);
		searchRange.length = length - searchRange.location;
		range = [self rangeOfString:string options:options range:searchRange boundBy:word];
		if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
			searchRange.location = 0;
			searchRange.length = selectedRange.location;
			range = [self rangeOfString:string options:options range:searchRange boundBy:word];
		}
	} else {
		searchRange.location = 0;
		searchRange.length = selectedRange.location;
		range = [self rangeOfString:string options:options range:searchRange boundBy:word];
		if ((range.length == 0) && wrap) {
			searchRange.location = NSMaxRange(selectedRange);
			searchRange.length = length - searchRange.location;
			range = [self rangeOfString:string options:options range:searchRange boundBy:word];
		}
	}
	return range;
}
- (NSRange)rangeOfString:(NSString *)aString options:(NSUInteger)mask range:(NSRange)searchRange boundBy:(NSCharacterSet *)word
{
	NSRange range = [self rangeOfString:aString options:mask range:searchRange];
	if (word) {
		while (1) {
			range = [self rangeOfString:aString options:mask range:searchRange];
			if (range.length) {
				// was this a "whole word"?
				BOOL wasWord = YES;
				// first, check character before the range to see if it was alpha-numeric
				if (range.location > 0 && [word characterIsMember: [self characterAtIndex: range.location-1]] == YES)
					wasWord = NO;
				// then check character after the range
				if (range.location+range.length+1 < [self length] &&
					[word characterIsMember: [self characterAtIndex: range.location+range.length]] == YES)
					wasWord = NO;
				if (wasWord) {
					break; // we found it
				}
				// otherwise, keep searching, but adjust range
				if (mask & NSBackwardsSearch) {
					searchRange.length = range.location + range.length - searchRange.location - 1;
				} else {
					searchRange.length -= range.location + 1 - searchRange.location;
					searchRange.location = range.location + 1;
				}
				if (searchRange.length <= 0) {
					range.length = 0;
					break;
				}
			} else
				break;
		}
	}
	return range;
}

- (NSRange)findExpression:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrap  groups: (NSArray * __strong*)groups
{
	BOOL forwards = (mask & NSBackwardsSearch) == 0;
	NSUInteger length = [self length];
	NSRange searchRange, range;
	if (forwards) {
		searchRange.location = NSMaxRange(selectedRange);
		searchRange.length = length - searchRange.location;
		range = [self rangeOfExpression:string options:mask range:searchRange groups: groups];
		if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
			searchRange.location = 0;
			searchRange.length = selectedRange.location;
			range = [self rangeOfExpression:string options:mask range:searchRange groups: groups];
		}
	} else {
		searchRange.location = 0;
		searchRange.length = selectedRange.location;
		range = [self rangeOfExpression:string options:mask range:searchRange groups: groups];
		if ((range.length == 0) && wrap) {
			searchRange.location = NSMaxRange(selectedRange);
			searchRange.length = length - searchRange.location;
			range = [self rangeOfExpression:string options:mask range:searchRange groups: groups];
		}
	}
	return range;
}
- (NSRange)rangeOfExpression:(NSString *)aString options:(NSUInteger)mask range:(NSRange)searchRange  groups: (NSArray *__strong*)groups
{
	regex_t preg;
	static regmatch_t pmatch[99];
	NSInteger numMatches = 1;
	NSRange range = NSMakeRange(0,0);
	int cflags = REG_EXTENDED|REG_NEWLINE /*| REG_PROGRESS | REG_DUMP*/;
	if (mask & NSCaseInsensitiveSearch)
		cflags |= REG_ICASE;
	if (regcomp(&preg, [aString cStringUsingEncoding:NSUTF8StringEncoding], cflags))
		return range;
	numMatches = preg.re_nsub + 1;
	if (numMatches > 99)
		numMatches = 99;
	// since we've got a range, use it rather than making a new string
	int eflags = REG_STARTEND;
	if (mask & NSBackwardsSearch) {
		// this is trickier (and slower) - need to start with the end and make it larger until we find it
		BOOL found = NO;
		for (int i=1;i<=searchRange.length;i++) {
			pmatch[0].rm_so = searchRange.location + searchRange.length - i;
			pmatch[0].rm_eo = searchRange.location + searchRange.length;
			if (regexec(&preg,[self cStringUsingEncoding:NSUTF8StringEncoding],numMatches,pmatch,eflags))
			{
				// found something
				range = NSMakeRange(pmatch[0].rm_so,pmatch[0].rm_eo - pmatch[0].rm_so);
				found = YES;
				break;
			}
			// need to keep backing up the start until we find something
		}
		if (!found) NSBeep();
	} else {
		pmatch[0].rm_so = searchRange.location;
		pmatch[0].rm_eo = searchRange.location + searchRange.length;
		if (regexec(&preg,[self cStringUsingEncoding:NSUTF8StringEncoding],numMatches,pmatch,eflags)) {
			// found something
			range = NSMakeRange(pmatch[0].rm_so,pmatch[0].rm_eo - pmatch[0].rm_so);
		}
	}
	if (range.length && groups) {
		NSMutableArray *a = [NSMutableArray arrayWithCapacity: numMatches+1];
		for (int i=0;i<=numMatches;i++) {
			if (pmatch[i].rm_eo > pmatch[i].rm_so)
				[a addObject: @([self cStringUsingEncoding:NSUTF8StringEncoding]+pmatch[i].rm_so + searchRange.location)];
		}
		*groups = a;
	} else {
		if (groups) *groups = NULL;
	}
	regfree(&preg);
	return range;
}
- (NSArray *)findAllExpressions:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask
{
	NSMutableArray *retval = [NSMutableArray array];
	while (1) {
		NSRange range = [self rangeOfExpression: string options: mask range: selectedRange groups: NULL];
		if (range.length == 0)
			break;
		[retval addObject: [self substringWithRange:range]];
		// move selectedRange to end of range
		selectedRange.length = selectedRange.length + selectedRange.location - (range.location + range.length);
		selectedRange.location = range.location + range.length;
		if (selectedRange.length == 0)
			break; // exhaused the range
	}
	return retval;
}
- (NSArray *)findAllIdentifiers:(NSString *)startsWith selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wordSet:(NSCharacterSet *)word
{
	NSMutableArray *retval = [NSMutableArray array];
	if (!word) word = [NSCharacterSet alphanumericCharacterSet]; // provide a default
	while (1) {
		NSRange range;
		while (1) {
			range = [self rangeOfString:startsWith options:mask range:selectedRange];
			if (range.location != NSNotFound && range.length) {
				// was this an identfier?
				BOOL wasIdent = YES;
				// first, check character before the range to make sure it wasn't in the character set
				if (range.location > 0 && [word characterIsMember: [self characterAtIndex: range.location-1]] == YES)
					wasIdent = NO;
				if (wasIdent) {
					// then expand to characters after the word
					while (range.location+range.length+1 < [self length] &&
						   [word characterIsMember: [self characterAtIndex: range.location+range.length]] == YES) {
						range.length++;
					}
					break; // we found it
				}
				// otherwise, keep searching, but adjust range
				if (mask & NSBackwardsSearch) {
					selectedRange.length = range.location + range.length - selectedRange.location - 1;
				} else {
					selectedRange.length -= range.location + 1 - selectedRange.location;
					selectedRange.location = range.location + 1;
				}
				if (selectedRange.length <= 0) {
					range.location = NSNotFound;
					range.length = 0;
					break;
				}
			} else
				break;
		}
		if (range.location != NSNotFound && range.length) {
			[retval addObject: [self substringWithRange:range]];
			// move selectedRange to end of range
			selectedRange.length = selectedRange.length + selectedRange.location - (range.location + range.length);
			selectedRange.location = range.location + range.length;
			if (selectedRange.length == 0)
				break; // exhaused the range
		} else {
			break; // didn't find any more
		}
	}
	return retval;
}

- (NSString *)makeReplacementString:(NSArray *)regexGroups
{
	if (!regexGroups || [regexGroups count] == 0)
		return self; // no replacement, leave as is
	NSMutableString *retval = [NSMutableString string];
	enum {
		noEscapeYet = -1,
		justEscape = -2
	};
	int numSoFar = noEscapeYet;
	for (NSUInteger i=0;i<[self length];i++) {
		unichar c = [self characterAtIndex:i];
		if (c == '\\') {
			if (numSoFar == justEscape) {
				// two backslashes cancel each other out
				numSoFar = noEscapeYet;
			} else if (numSoFar == noEscapeYet) {
				// start accumulating digits
				numSoFar = justEscape;
			} else {
				// end of one, start the next
				if (numSoFar < [regexGroups count]) {
					[retval appendString:regexGroups[numSoFar]];
				}
				numSoFar = justEscape;
			}
		} else if ('0' <= c && c <= '9' && numSoFar != noEscapeYet) {
			if (numSoFar == justEscape) numSoFar = 0;
			numSoFar = 10 * numSoFar + c - '0';
		} else {
			if (numSoFar == justEscape) {
				// just add in the escape (we could/should probably evaluate it)
				switch (c) {
					case 'n':
						[retval appendString: @"\n"];
						break;
					case 'r':
						[retval appendString: @"\r"];
						break;
					case 't':
						[retval appendString: @"\t"];
						break;
					default:
						[retval appendFormat: @"\\%C",c];
						break;
				}
				numSoFar = noEscapeYet;
				continue;
			} else if (numSoFar != noEscapeYet) {
				// we end the numeric escape
				if (numSoFar < [regexGroups count]) {
					[retval appendString:regexGroups[numSoFar]];
				}
				numSoFar = noEscapeYet; // and back to no escape
			}
			// otherwise just add it in
			[retval appendFormat: @"%C",c];
		}
	}
	if (numSoFar != noEscapeYet) {
		// we end the numeric escape
		if (numSoFar == justEscape) {
			[retval appendString: @"\\"];
		} else if (numSoFar < [regexGroups count]) {
			[retval appendString:regexGroups[numSoFar]];
		}
		numSoFar = noEscapeYet; // and back to no escape
	}
	//NSLog(@"Replacing %@ in %@ produces %@",regexGroups,self,retval);
	return retval;
}

@end
