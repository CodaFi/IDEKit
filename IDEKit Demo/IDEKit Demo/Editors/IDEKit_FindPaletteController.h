//
//  IDEKit_FindPaletteController.h
//
//  Created by Glenn Andreas on Sun Feb 23 2003.
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
/*
 Reusable find panel functionality (find, replace).
 Need one shared instance of TextFinder to which the menu items and widgets in the find panel are connected.
 Loads UI lazily.
 Works on first responder, assumed to be an NSTextView.
 */
#import <Cocoa/Cocoa.h>
#define Forward YES
#define Backward NO
@interface IDEKit_TextFinder : NSObject {
    NSString *findString;
    NSString *replaceString;
    NSArray *regexGroups;
    NSRange regexGroupRange;
    id findTextField;
    id replaceTextField;
    id ignoreCaseButton;
    id wholeWordsButton;
    id stopAtEndOfFileButton;
    id regularExpressionButton;
    id findNextButton;
    id replaceAllScopeMatrix;
    id statusField;
    BOOL lastFindWasSuccessful;
    id findPopup;
    id replacePopup;
}
/* Common way to get a text finder. One instance of TextFinder per app is good enough. */
+ (id)sharedInstance;
/* Main method for external users; does a find in the first responder. Selects found range or beeps. */
- (BOOL)find:(BOOL)direction;
/* Loads UI lazily */
- (NSPanel *)findPanel;
/* Gets the first responder and returns it if it's an NSTextView */
- (NSTextView *)textObjectToSearchIn;
/* Get/set the current find string. Will update UI if UI is loaded */
- (NSString *)findString;
- (void)setFindString:(NSString *)string;
- (void)setFindString:(NSString *)string writeToPasteboard:(BOOL)flag;
- (NSString *)replaceString;
- (NSString *)fullReplaceString; // including regex
- (void)setReplaceString:(NSString *)string;
/* Misc internal methods */
- (void)appDidActivate:(NSNotification *)notification;
- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;
/* Action methods, sent from the find panel UI; can also be connected to menu items */
- (void)findNext:(id)sender;
- (void)findPrevious:(id)sender;
- (void)findNextAndOrderFindPanelOut:(id)sender;
- (void)findAll:(id)sender;
- (void)replace:(id)sender;
- (void)replaceAndFind:(id)sender;
- (void)replaceAndFindPrevious:(id)sender;
- (void)replaceAll:(id)sender;
- (void)orderFrontFindPanel:(id)sender;
- (void)takeFindStringFromSelection:(id)sender;
- (void)takeReplaceStringFromSelection:(id)sender;
- (void)jumpToSelection:(id)sender;
@end
@interface NSString (NSStringTextFinding)
- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrapFlag wordSet:(NSCharacterSet *)word;
- (NSRange)rangeOfString:(NSString *)aString options:(NSUInteger)mask range:(NSRange)searchRange boundBy:(NSCharacterSet *)word;
- (NSRange)findExpression:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrap  groups: (NSArray * __strong*)groups;
- (NSRange)rangeOfExpression:(NSString *)aString options:(NSUInteger)mask range:(NSRange)searchRange groups: (NSArray *__strong*)groups;
- (NSArray *)findAllExpressions:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask;
- (NSArray *)findAllIdentifiers:(NSString *)startsWith selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wordSet:(NSCharacterSet *)word;
- (NSString *)makeReplacementString:(NSArray *)regexGroups;
@end

