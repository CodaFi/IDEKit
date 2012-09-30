//
//  IDEKit_BreakpointInspector.h
//  IDEKit
//
//  Created by Glenn Andreas on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IDEKit_Breakpoint;

@interface IDEKit_BreakpointInspector : NSWindowController {
    IBOutlet id myEnabled;
    IBOutlet id myKind;
    IBOutlet id myKindData;
    IBOutlet id myTraceLog;
    IBOutlet id myCondition;
    IBOutlet id myPauseDelay;
    IBOutlet id mySound;
    
    IDEKit_Breakpoint *myCurrentBreakpoint;
}
+ (IDEKit_BreakpointInspector *) sharedBreakpointInspector;
- (IBAction) changeKind: (id) sender;
- (IBAction) toggleEnabled: (id) sender;
- (IBAction) changeTraceLog: (id) sender;
- (IBAction) changePauseDelay: (id) sender;
- (IBAction) changeCondition: (id) sender;
- (IBAction) changeSound: (id) sender;

- (void) setBreakpoint: (IDEKit_Breakpoint *)bp; // or NULL for none here (but could be)
- (void) setNoBreakpointPossible; // disables it
- (void) rebuildSounds;
- (void) resetDefaultValues;
- (void) setValuesFromBreakpoint: (IDEKit_Breakpoint *)bp;
- (void) saveValuesToBreakpoint: (IDEKit_Breakpoint *)bp;
@end
