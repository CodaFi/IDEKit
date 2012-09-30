//
//  IDEKit_PreferenceController.h
//
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

@interface IDEKit_PreferenceController : NSObject
{
    IBOutlet id myPreferenceList;
    IBOutlet id myPreferencePane;
    IBOutlet id myPreferenceWindow;
    IBOutlet id myPreferenceHeader;
    id myCurrentPreferencePanel;
    NSMutableArray *myPanels;
    NSMutableArray *myCategories;
    NSMutableDictionary *myCategoryMap;
    NSUserDefaults *myDefaults;
    BOOL isSheet;
}
+ (IDEKit_PreferenceController *)applicationPreferences;
- (id) initWithDefaults: (NSUserDefaults *)defaults;
- (void) switchPanel: (id) sender;
// subclasses can determine how to find out what the category and name is for this preference panel to be shown in the list
// Returning NULL from categoryKeyFromBundle means don't show.  By default, we just look for one specific thing, but a
// subclass could use multiple keys
- (NSString *)categoryKeyFromBundle: (NSBundle *) prefBundle;
- (NSString *)nameKeyFromBundle: (NSBundle *) prefBundle;
- (void) preferences;
- (void) beginSheetModalForWindow:(NSWindow *)docWindow modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;

+ (NSDictionary *)pathVars;
+ (NSString *)pathWithVars: (NSString *)path;

- (void) exportPanel: (id) sender;
- (void) importPanel: (id) sender;
- (NSDictionary *)getPathVars;
@end
@interface IDEKit_AppPreferenceController : IDEKit_PreferenceController
{
}
@end
@interface IDEKit_LayeredPreferenceController : IDEKit_PreferenceController	// in this case, "defaults" is actually a layered defaults
{
}
@end
@interface IDEKit_ProjectPreferenceController : IDEKit_LayeredPreferenceController
{
    id myProject;
}
- (id) initWithDefaults: (NSUserDefaults *)defaults forProject: (id) project;
@end
@interface IDEKit_SrcPreferenceController : IDEKit_LayeredPreferenceController
{
}
@end
