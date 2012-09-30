//
//  IDEKit_Autocompletion.h
//  IDEKit
//
//  Created by Glenn Andreas on Sat Mar 20 2004.
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

#import <AppKit/AppKit.h>


@interface IDEKit_Autocompletion : NSWindowController {
    NSArray *myCompletions;
    NSMutableString *myCommonPrefix;
    NSMutableString *myCurrentTypeAhead;
    IBOutlet id myList;
    IBOutlet id myTextView;
    IBOutlet id myScrollView;
    IBOutlet id myView;
}
- (id) initWithCompletions: (NSArray *)completions;
- (id) popupAssistantAt: (NSPoint)where forView: (NSTextView *)view;
- (void) endSessionWithCompletedString:(id)sender;
@end

@interface NSArray(IDEKit_Autocompletion)
- (NSArray *) sortedUniqueArray;
@end


