//
//  IDEKit_SrcEditViewStatusBar.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/6/04.
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


#import "IDEKit_SrcEditViewStatusBar.h"


@implementation IDEKit_SrcEditView(StatusBar)
- (IBAction) showStatusBar: (id) sender;
{
    if (![myStatusBar superview]) {
	// show it
	id viewToResize = mySplitView ? mySplitView : myScrollView;
	NSRect frame = [viewToResize frame];
	NSRect statusFrame;
	NSDivideRect(frame, &statusFrame, &frame, [myStatusBar frame].size.height, NSMaxYEdge);
	[viewToResize setFrame: frame];
	[myStatusBar setFrame: statusFrame];
	[self addSubview:myStatusBar];
    }
    // force a redraw
    [self display];
}
- (BOOL) statusBarShown
{
    return [myStatusBar superview] == self;
}
- (BOOL) setStatusBar: (NSString *)string
{
    BOOL retval = [self statusBarShown];
    [myStatusBarText setStringValue:string];
    [self showStatusBar: self];
    return !retval; // if already shown before, don't hide
}
- (void) clearStatusBar: (BOOL) hide
{
    [myStatusBarText setStringValue:@""];
    if (hide) {
	[self hideStatusBar: self];
    }
}

- (IBAction) hideStatusBar: (id) sender
{
    id viewToResize = mySplitView ? mySplitView : myScrollView;
    NSRect frame = [viewToResize frame];
    frame = NSUnionRect(frame,[myStatusBar frame]);
    [myStatusBar removeFromSuperview];
    [viewToResize setFrame: frame];
}

@end
