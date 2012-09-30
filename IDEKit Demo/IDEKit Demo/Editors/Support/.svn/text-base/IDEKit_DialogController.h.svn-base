//
//  IDEKit_DialogController.h
//  IDEKit
//
//  Created by Glenn Andreas on Tue Jan 27 2004.
//  Copyright (c) 2004 Glenn Andreas
//
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


@interface IDEKit_DialogController : NSObject {
    IBOutlet id myWindow;
    NSMutableDictionary *myFields; // we don't have any real ivars other than this, and we use KVC to make them as needed
    id myModalDelegate;
    SEL myDidEndSelector;
}
+ (IDEKit_DialogController *) dialogControllerForNib: (NSString *)nibName;
// and this is how it is activated, similar to an NSAlert, but we only handle "OK" cases (as a single message, with this as the sender)
- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;



// wire up OK and cancel to these
- (void) handleOK: (id) sender;
- (void) handleCancel: (id) sender;

// our KVC hooks (both the new and old versions)
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (id)valueForUndefinedKey:(NSString *)key;
- (void)handleTakeValue:(id)value forUnboundKey:(NSString *)key;
- (id)handleQueryWithUnboundKey:(NSString *)key;
@end
