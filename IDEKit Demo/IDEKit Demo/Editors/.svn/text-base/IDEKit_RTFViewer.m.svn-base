//
//  IDEKit_RTFViewer.m
//  IDEKit
//
//  Created by Glenn Andreas on Sun Aug 17 2003.
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

#import "IDEKit_RTFViewer.h"


@implementation IDEKit_RTFViewer

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"IDEKit_RTFViewer";
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    // Implement to provide a persistent data representation of your document OR remove this and implement the file-wrapper or file path based save methods.
    return nil;
}

-(void) loadDocWithData: (id) data
{
    //NSLog(@"Trying to load RTF data %@",[data description]);
    [myTextView replaceCharactersInRange: NSMakeRange(0,0) withRTF: data];
}

-(void)windowControllerDidLoadNib: (NSWindowController *)controller
{
    if (myDataFromFile) {
	[self loadDocWithData: myDataFromFile];
	[myDataFromFile release];
	myDataFromFile = NULL;
    } else {
    }
    //[self setupToolbar: [controller window]];
}



- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    // Implement to load a persistent data representation of your document OR remove this and implement the file-wrapper or file path based load methods.
    //NSLog(@"LoadData Rep type %@",type);
    if (1 || [type isEqualToString: NSRTFTextDocumentType]) {
	if (myTextView) {
	    [self loadDocWithData: data];
	} else {
	    myDataFromFile = [data retain];
	}
	return YES;
    }
    return NO;
}

@end
