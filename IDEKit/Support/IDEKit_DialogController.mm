//
//  IDEKit_DialogController.mm
//  IDEKit
//
//  Created by Glenn Andreas on Tue Jan 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "IDEKit_DialogController.h"
#import "IDEKit_PathUtils.h"

@implementation IDEKit_DialogController
+ (IDEKit_DialogController *) dialogControllerForNib: (NSString *)nibName
{
    IDEKit_DialogController *retval = [[IDEKit_DialogController alloc] init];
    if ([NSBundle loadOverridenNibNamed: nibName owner: retval]) {
	return retval; // we don't autorelease until sheet is done [retval autorelease];
    } else {
	[retval release];
	return NULL;
    }
}
- (id) init
{
    self = [super init];
    if (self) {
	myFields = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void) dealloc
{
    [myFields release];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSRunStoppedResponse) {
	if (myModalDelegate) {
	    [myModalDelegate performSelector:myDidEndSelector withObject:self];
	}
    }
    [myWindow orderOut:self];
    [self release];
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;
{
    myModalDelegate = [delegate retain];
    myDidEndSelector = didEndSelector;
    [NSApp beginSheet: myWindow modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void) handleOK: (id) sender
{
    [NSApp endSheet:myWindow returnCode:NSRunStoppedResponse];
}
- (void) handleCancel: (id) sender
{
    [NSApp endSheet:myWindow returnCode:NSRunAbortedResponse];
}
// both the pre 10.3 versions
- (void)handleTakeValue:(id)value forUnboundKey:(NSString *)key
{
    [myFields setObject: value forKey: key];
}
- (id)handleQueryWithUnboundKey:(NSString *)key;
{
    return [myFields objectForKey:key];
}

// and the 10.3 and later version
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [myFields setObject: value forKey: key];
}
- (id)valueForUndefinedKey:(NSString *)key
{
    return [myFields objectForKey:key];
}

// the problem, however, is that NIB loading doesn't directly call the same KVC routines we override here
// so instead, fake out the various "set" selectors
- (BOOL) respondsToSelector: (SEL) sel
{
    const char *selName = sel_getName(sel);
    if (strncmp(selName,"set",3) == 0 && selName[strlen(selName)-1] == ':') {
	return YES;
    }
    return [super respondsToSelector: sel];
}
- (id)performSelector:(SEL)aSelector withObject:(id)object
{
    const char *selName = sel_getName(aSelector);
    if (strncmp(selName,"set",3) == 0 && selName[strlen(selName)-1] == ':') {
	char varName[32];
	strncpy(varName,selName+3,32);
	varName[strlen(varName)-1] = 0; // remove trailing colon
	if ('A' <= varName[0] && varName[0] <= 'Z')
	    varName[0] = varName[0] + 'a' - 'A'; // make it lower case
	NSString *name = [NSString stringWithCString:varName];
	//NSLog(@"Performing 'set' on %@",name);
	if ([name isEqualToString: @"myWindow"])
	    myWindow = object;
	else
	    [myFields setObject: object forKey: name];
	return NULL;
    }
    return [super performSelector: aSelector withObject:(id)object];
}

- (void) setMyGoto: (id) value
{
    NSLog(@"SetMyGoto %@",value);
    [self setValue: value forKey: @"myGoto"];
}
@end
