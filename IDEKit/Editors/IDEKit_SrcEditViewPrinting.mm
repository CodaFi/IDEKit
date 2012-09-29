//
//  IDEKit_SrcEditViewPrinting.mm
//  IDEKit
//
//  Created by Glenn Andreas on Tue Aug 26 2003.
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

#import "IDEKit_SrcEditViewPrinting.h"


@implementation IDEKit_SrcEditView(Printing)

- (NSView *) viewForPrinting: (NSPrintInfo *)printInfo
{
    // for now just use a regular text view, and let it
    // print.  Later we'll have headers, and more interesting
    // things
    return [[self allTextViews] objectAtIndex: 0];
}

@end
