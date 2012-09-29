//
//  IDEKit_SrcScroller.h
//  IDEKit
//
//  Created by Glenn Andreas on Sun Feb 09 2003.
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

#import <Cocoa/Cocoa.h>

enum {
    IDEKit_kShowNavPopup = 0x0001,
    IDEKit_kShowFmtPopup = 0x0002,
    IDEKit_kShowSplitter = 0x0004,
    IDEKit_kShowUnsplitter = 0x0008,
    IDEKit_kShowBreakpoints = 0x0010,
    IDEKit_kShowLineNums = 0x0020,
    IDEKit_kShowFolding = 0x0040,
};

@interface IDEKit_SrcScroller : NSScrollView {
    IBOutlet id subView;
    IBOutlet id myNavPopup;
    IBOutlet id myFmtPopup;
    IBOutlet id mySplitter;
    IBOutlet id myUnsplitter;
    IBOutlet id myLineButton;
    int myShowFlags;
}
+ (id)lastHit; // used for split hit detection
- (id) initWithFrame: (NSRect) theFrame;
- (void) awakeFromNib;
- (void) tile;
- (IBAction) insertSplitView: (id) sender;
- (IBAction) closeSplitView: (id) sender;
- (void) setShowFlags: (NSInteger) flags;
- (NSInteger) showFlags;
- (void) setLine: (NSInteger) line col: (NSInteger) col;
- (void) setLineRange: (NSRange) lines colRange: (NSRange) cols;
@end

@interface IDEKit_BreakPointRuler : NSRulerView {
}
@end
