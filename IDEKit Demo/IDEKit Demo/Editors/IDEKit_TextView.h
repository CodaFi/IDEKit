//
//  IDEKit_TextView.h
//  IDEKit
//
//  Created by Glenn Andreas on Mon Oct 20 2003.
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

#import <AppKit/AppKit.h>
#import "IDEKit_TextViewExtensions.h"
// For a couple of things, we need to subclass NSTextView (such as dynamically built
// contextual menus).


@interface IDEKit_TextView : NSTextView {

}
@property (nonatomic, unsafe_unretained) id <IDEKit_NSTextViewExtendedDelegate> delegate;

- (NSInteger) foldableIndentOfRange: (NSRange) range hasFold: (BOOL *)fold atOffset: (NSUInteger *)offset;
- (NSInteger) foldabilityAtOffset: (NSUInteger) offset foldedAtOffset: (NSUInteger *)foldOffset; // return 1 if already folded, -1 if can be folded, 0 if not
@end
