//
//  IDEKit_Snippets.h
//  IDEKit
//
//  Created by Glenn Andreas on Mon Jul 26 2004.
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

#import <Foundation/Foundation.h>
#import "IDEKit_SrcEditView.h"

extern NSString *IDEKit_TemplateInternalAttributeName;
extern NSString *IDEKit_TemplateVisualAttributeName;

@interface IDEKit_SrcEditView(Snippets)
// Snippets/Templates
-(void) insertTemplate: (id) sender; // sender is menu item, rep obj is the template (string or dict)
-(void) insertSnippet: (id)snippet;
-(void) insertTemplateString: (NSString *)string;
//-(void) buildSnippetMenu: (NSMenu *)menu;
#ifdef nomore
-(NSMenu *) buildSnippetMenu: (NSMenu *)suggestedMenu;
#else
- (void) updateSnippets;
- (IBAction) showSnippets: (id) sender;
#endif
// macros
- (NSArray *) extractParameters: (NSRange) paramRange;
- (IBAction) expandMacro: (id) sender;
- (IBAction) evaluate: (id) sender;
- (NSRange) buildMacro: (NSString **)name params: (NSArray **)params;
- (NSString *) expandMacro: (NSString *)name withParams: (NSArray *)array;
- (NSRange) performMacro: (NSString *)macro withParams: (NSArray *)params;
@end


@interface IDEKit_SnippetManager : NSWindowController {
    NSMutableArray *mySnippetRoot;
    NSMutableSet *myExpandedNodes;
    IBOutlet NSOutlineView *myOutline;
    IBOutlet NSTextField *myTip;
}
+ (IDEKit_SnippetManager *) sharedSnippetManager;
- (void) setSnippet: (NSDictionary *)snippets;
@end