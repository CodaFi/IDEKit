//
//  IDEKit_Snippets.mm
//  IDEKit
//
//  Created by Glenn Andreas on Mon Jul 26 2004.
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


#import "IDEKit_Snippets.h"
#import "IDEKit.h"
#import "IDEKit_SrcEditViewStatusBar.h"
#import "NSString102.h"
#import "IDEKit_TextView.h"

NSString *IDEKit_TemplateInternalAttributeName = @"IDEKit_SrcTemplate";
NSString *IDEKit_TemplateVisualAttributeName = NSBackgroundColorAttributeName;
static BOOL gAutoCompletedFromMenu = NO;

@interface IDEKit_TemplateSheet : NSObject {
    NSPanel *mySheet;
    NSForm *myForm;
    IDEKit_SrcEditView *mySrcView;
    NSView *myView;
    id myTemplate;
    int myButtonCount;
}
- (id) initAndRunTemplate: (id) templ forView: (IDEKit_SrcEditView *)view;
@end;

#define kBUTTONWIDTH    96.0
#define kBUTTONHEIGHT   24.0
#define kBUTTONROW      (kBUTTONHEIGHT + kBOTTOMMARGIN + kBOTTOMMARGIN)
#define kSIDEMARGINS    8.0
#define kBOTTOMMARGIN   4.0
#define kBUTTONHGAP     16.0
#define kFORMROWITEM  24.0
#define kFORMROWGAP     2.0
#define kFORMROWHEIGHT  (kFORMROWITEM + kFORMROWGAP)
#define kTITLEHEIGHT    24.0
#define kTOPMARGIN      2.02
#define kTITLEROW       (kTITLEHEIGHT + kTOPMARGIN)

@implementation IDEKit_TemplateSheet

-(void) finishTemplateParameters: (NSWindow *)sheet returnCode: (NSInteger) returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSRunStoppedResponse) {
		// do it
		NSMutableArray *params = [NSMutableArray arrayWithCapacity: [myForm numberOfRows]];
		for (int i=0;i<[myForm numberOfRows];i++) {
			[params addObject: [[myForm cellAtIndex: i] stringValue]];
		}
		NSRange range = [mySrcView performMacro: [[(__bridge id)contextInfo objectForKey: @"template"] objectForKey: @"template"] withParams: params];
		//	if (range.length >= 0)
		//	    [mySrcView setSelectedRange: range];
    }
    [sheet orderOut:self];
    [self release]; // we retained it when we came in here
}
-(void) templateSheetButton: (id) sender
{
    [NSApp endSheet:mySheet returnCode:[sender tag]];
}
- (void) dealloc
{
    [myView release];
    [mySrcView release];
    [mySheet release];
    [myForm release];
    [myTemplate release];
}
- (void) addButton: (NSString *)title equiv: (NSString *)equiv command: (NSInteger) command
{
    NSRect bframe;
    bframe.size.height = kBUTTONHEIGHT;
    bframe.size.width = kBUTTONWIDTH;
    bframe.origin.x = NSMaxX([mySheet frame]) - kBUTTONWIDTH - kSIDEMARGINS - myButtonCount * (kBUTTONWIDTH+kBUTTONHGAP);
    bframe.origin.y = kBOTTOMMARGIN;
    NSButton *button = [[[NSButton alloc] initWithFrame:bframe] autorelease];
    [button setTag:command];
    [button setTarget:self];
    [button setAction:@selector(templateSheetButton:)];
    [button setTitle: title];
    [button setKeyEquivalent:equiv];
    if ([equiv isEqualToString:@"\n"]) {
		[mySheet setDefaultButtonCell:[button cell]];
    }
    [button setButtonType:NSMomentaryLightButton];
    [button setBezelStyle:NSRoundedBezelStyle];
    [myView addSubview:button];
    myButtonCount++;
}

- (id) initAndRunTemplate: (id) templ forView: (IDEKit_SrcEditView *)srcView
{
    self = [super init];
    mySrcView = [srcView retain];
    myTemplate = [templ retain];
    
    float width = 300.0;
    if ([templ objectForKey: @"sheetWidth"])
		width = [[templ objectForKey: @"sheetWidth"] floatValue];
    NSRect bounds = NSMakeRect(0.0,0.0,width,[[templ objectForKey: @"parameters"] count] * kFORMROWHEIGHT + kBUTTONROW + kTITLEROW);
    mySheet = [[NSPanel alloc] initWithContentRect:bounds styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    myView = [[NSView alloc] initWithFrame:bounds];
    // start at the bottom
    [self addButton: @"OK" equiv: @"\n" command: NSRunStoppedResponse];
    [self addButton: @"Cancel" equiv: @"\b" command: NSRunAbortedResponse];
    // now the form
    NSRect fframe = NSInsetRect(bounds,kSIDEMARGINS,0.0); // give a little border
    fframe.size.height -= kBUTTONROW + kTITLEROW; // buttons on bottom, title on top
    fframe.origin.y += kBUTTONROW;
    myForm = [[NSForm alloc] initWithFrame:fframe mode:NSTrackModeMatrix cellClass:[NSFormCell class] numberOfRows:0 numberOfColumns:1];
    for (NSUInteger i=0;i<[[templ objectForKey: @"parameters"] count];i++) {
		id param = [[templ objectForKey: @"parameters"] objectAtIndex: i];
		if ([param objectForKey: @"prompt"]) {
			[myForm addEntry: [param objectForKey: @"prompt"]];
		} else {
			[myForm addEntry: [NSString stringWithFormat:@"Parameter %d",i]];
		}
		if ([param objectForKey: @"default"]) {
			[[myForm cellAtIndex: i] setStringValue: [param objectForKey: @"default"]];
		}
    }
    [myForm selectTextAtIndex: 0];
    [myForm setCellSize:NSMakeSize(fframe.size.width,kFORMROWITEM)];
    [myForm setIntercellSpacing:NSMakeSize(kFORMROWGAP,kFORMROWGAP)];
    [myView addSubview: myForm];
    
    // finally, the title
    NSRect tframe = NSInsetRect(bounds,kSIDEMARGINS,kTOPMARGIN);
    tframe.origin.y = tframe.size.height - kTITLEHEIGHT;
    tframe.size.height = kTITLEHEIGHT;
    NSText *title = [[[NSText alloc] initWithFrame:tframe] autorelease];
    [title setFont: [NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [title setEditable: NO];
    if ([templ objectForKey: @"prompt"])
		[title setString:[templ objectForKey: @"prompt"]];
    else if ([templ objectForKey: @"tip"])
		[title setString:[templ objectForKey: @"tip"]];
    else
		[title setString:[NSString stringWithFormat: @"%@ Parameters:",[[templ objectForKey: @"title"] lastPathComponent]]];
    [title setDrawsBackground: NO];
    [myView addSubview:title];
    
    [mySheet setContentView: myView];
    
    [NSApp beginSheet:mySheet modalForWindow:[srcView window] modalDelegate:[self retain] didEndSelector:@selector(finishTemplateParameters:returnCode:contextInfo:) contextInfo:NULL];
    return self;
}
@end
@implementation IDEKit_SrcEditView(Snippets)
- (NSDictionary *) snippetsFromPath: (NSString *)path
{
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSEnumerator *fileEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *file;
    while ((file = [fileEnum nextObject]) != NULL) {
		if ([file hasPrefix:@"."])
			continue; // skip dot files
		BOOL isDir;
		if ([[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:file] isDirectory: &isDir] == NO || isDir)
			continue; // skip directories and missing files
		NSString *defaultName = [file stringByDeletingPathExtension];
		if ([[file pathExtension] isEqualToString:@"iksnip"]) {
			NSArray *snippets = [NSArray arrayWithContentsOfFile:[path stringByAppendingPathComponent:file]];
			if (snippets) {
				// a list of snippets
				for (NSUInteger i=0;i<[snippets count];i++) {
					NSDictionary *snippet= [snippets objectAtIndex: i];
					if ([snippet objectForKey: @"language"] && ![[snippet objectForKey: @"language"] isEqualToString: [myCurrentLanguage languageName]]) {
						continue; // not for the current language
					}
					if  ([snippet objectForKey: @"title"])
						[retval setObject: snippet forKey: [snippet objectForKey: @"title"]];
					else
						[retval setObject: snippet forKey: defaultName];
				}
			} else {
				NSDictionary *snippet = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:file]];
				if (snippet) {
					if ([snippet objectForKey: @"language"] && ![[snippet objectForKey: @"language"] isEqualToString: [myCurrentLanguage languageName]]) {
						continue; // not for the current language
					}
					if  ([snippet objectForKey: @"title"])
						[retval setObject: snippet forKey: [snippet objectForKey: @"title"]];
					else
						[retval setObject: snippet forKey: defaultName];
				}
			}
		} else if ([[file pathExtension] isEqualToString:@"iktmpl"]) {
			NSString *templ = [NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:file]];
			[retval setObject: [NSDictionary dictionaryWithObjectsAndKeys:
								templ,@"template",
								defaultName, @"title",
								NULL] forKey: defaultName];
		} else {
			[retval setObject: [NSDictionary dictionaryWithObject:[path stringByAppendingPathComponent:file] forKey:@"file"] forKey: file];
		}
    }
    return retval;
}

-(void) insertTemplateString: (NSString *)string
{
    NSRange range = [self performMacro: string withParams: NULL];
    if (range.length >= 0)
		[myTextView setSelectedRange: range];
}

-(void) insertTemplate: (id) sender
{
    [self insertSnippet: [sender representedObject]];
}

-(void) insertSnippet: (id)templ;
{
    if ([templ isKindOfClass:[NSString class]]) {
		NSRange range = [self performMacro: templ withParams: NULL];
		if (range.length >= 0)
			[myTextView setSelectedRange: range];
    } else if ([templ isKindOfClass:[NSDictionary class]]) {
		if ([templ objectForKey: @"file"]) {
			// file contents
			NSString *contents = [NSString stringWithContentsOfFile:[templ objectForKey: @"file"]];
			contents = [self massageInsertableText: contents];
			[myTextView insertText: contents];
		} else if ([templ objectForKey: @"literal"]) {
			[myTextView insertText: [templ objectForKey: @"literal"]];
		} else if ([templ objectForKey: @"url"]) {
			BOOL hide = [self setStatusBar: [NSString stringWithFormat: @"Downloading %@",[templ objectForKey: @"url"]]];
			[myTextView insertText: [self massageInsertableText:[NSString stringWithContentsOfURL:[[[NSURL alloc] initWithString:[templ objectForKey: @"url"]] autorelease]]]];
			[self clearStatusBar: hide];
		} else if ([templ objectForKey: @"template"]) {
			// check for prompted template values
			if ([templ objectForKey: @"parameters"]) {
				// we've got a set of parameter, need to run UI
				[[IDEKit_TemplateSheet alloc] initAndRunTemplate: templ forView: self];
			} else {
				NSRange range = [self performMacro: [templ objectForKey: @"template"] withParams: NULL];
				if (range.length >= 0)
					[myTextView setSelectedRange: range];
			}
		} else if ([templ objectForKey: @"title"]){
			[myTextView insertText: [[templ objectForKey: @"title"] lastPathComponent]];
		}
    } else {
		//[myTextView insertText: [sender title]];
    }
}

- (NSDate *)newestSnippetInPath: (NSString *)path
{
    // start with dir entry
    NSDate *bestSnippet = [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES] fileModificationDate]; //[NSDate distantPast];
    NSEnumerator *fileEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *file;
    while ((file = [fileEnum nextObject]) != NULL) {
		if ([file hasPrefix:@"."])
			continue; // skip dot files
		NSDate *nextDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[path stringByAppendingPathComponent:file] traverseLink:YES] fileModificationDate];
		if ([bestSnippet compare:nextDate ] == NSOrderedAscending)
			bestSnippet = nextDate;
    }
    return bestSnippet;
}

- (NSDate *)newestSnippet: (NSString *)firstPath, ...
{
    va_list paths;
    va_start(paths, firstPath);
    NSString *path = firstPath;
    NSDate *bestSnippet = [NSDate distantPast];
    while (path) {
		NSDate *nextDate = [self newestSnippetInPath: path];
		if ([bestSnippet compare:nextDate ] == NSOrderedAscending)
			bestSnippet = nextDate;
		path = va_arg(paths, NSString *);
    }
    va_end(paths);
    return bestSnippet;
}

- (void) updateSnippets
{
    // add in the new
    NSMutableDictionary *templates = [NSMutableDictionary dictionary];
    NSDictionary *moreTemplates = [[myCurrentLanguage insertionTemplates] mutableCopy];
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [IDEKit appSnippets];
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [self snippetsFromPath: [[NSBundle bundleForClass: [self class]] pathForResource:@"Snippets" ofType:@""]]; // check Snippets in IDEKit resources
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [self snippetsFromPath: [[NSBundle mainBundle] pathForResource:@"Snippets" ofType:@""]]; // check Snippets in embedding resources
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [[NSUserDefaults standardUserDefaults] objectForKey: @"snippets"]; // check for preference snippets
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [self snippetsFromPath: [@"~/Library/Application Support/IDEKit/Snippets" stringByExpandingTildeInPath]];
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    moreTemplates = [self snippetsFromPath: [[NSString stringWithFormat: @"~/Library/Application Support/@%/Snippets",[[[NSBundle mainBundle] bundlePath]stringByDeletingLastPathComponent]] stringByExpandingTildeInPath]];
    if (moreTemplates) [templates addEntriesFromDictionary:moreTemplates];
    
    [[IDEKit_SnippetManager sharedSnippetManager] setSnippet:templates];
}

- (IBAction) showSnippets: (id) sender
{
    [[IDEKit_SnippetManager sharedSnippetManager] showWindow:sender];
    [self updateSnippets];
}


- (IBAction) expandMacro: (id) sender
{
    //[self getFocusedView];
    gAutoCompletedFromMenu = NO;
    NSString *name;
    NSArray *params;
    NSRange range = [self buildMacro: &name params: &params];
    if (range.length) {
		NSString *complete = [self expandMacro: name withParams: params];
		if (complete) {
			//			[[myTextView textStorage] beginEditing];
			[myTextView setSelectedRange: range];
			// if we expand a selection, make sure to remove the template here
			[[myTextView textStorage] removeAttribute: IDEKit_TemplateInternalAttributeName range: range];
			[[myTextView textStorage] removeAttribute: IDEKit_TemplateVisualAttributeName range: range];
			
			range = [self performMacro: complete withParams: params];
			if (range.length >= 0)
				[myTextView setSelectedRange: range];
		} else {
			if (gAutoCompletedFromMenu == NO)
				NSBeep();
		}
    }
}

- (IBAction) evaluate: (id) sender
{
    NSString *name;
    NSArray *params;
    NSRange range = [self buildMacro: &name params: &params];
    if (range.length) {
		NSString *complete = [self expandMacro: name withParams: params];
		if (complete) {
			range.location += range.length;
			range.length = 0;
			[myTextView setSelectedRange: range];
			[myTextView insertText: complete];
		} else {
			NSBeep();
		}
    }
}

- (NSArray *) extractParameters: (NSRange) paramRange
{
    if (paramRange.length) {
		// there are params, instead of an empty list
		// This isn't perfect, since we should properly be able to nest parameters
		//return [[[myTextView string] substringWithRange: paramRange] componentsSeparatedByString: @","];
		NSMutableArray *retval = [NSMutableArray array];
		NSUInteger index = paramRange.location;
		NSRange lastRange = NSMakeRange(index,0);
		while (index < paramRange.location + paramRange.length) {
			if ([[myTextView string] characterAtIndex: index] == '(') {
				// include entire parens
				NSRange subRange = [myTextView balanceFrom: index+1 startCharacter:'(' endCharacter:')'];
				index += subRange.length;
				lastRange.length += subRange.length;
			} else if ([[myTextView string] characterAtIndex: index] == '{') {
				// include entire parens
				NSRange subRange = [myTextView balanceFrom: index+1 startCharacter:'{' endCharacter:'}'];
				index += subRange.length;
				lastRange.length += subRange.length;
			} else if ([[myTextView string] characterAtIndex: index] == '[') {
				// include entire parens
				NSRange subRange = [myTextView balanceFrom: index+1 startCharacter:'[' endCharacter:']'];
				index += subRange.length;
				lastRange.length += subRange.length;
			} else if ([[myTextView string] characterAtIndex: index] == ',') {
				[retval addObject: [[myTextView string] substringWithRange: lastRange]];
				// go to next, after comma
				index++;
				lastRange.location = index;
				lastRange.length = 0;
			} else {
				index++;
				lastRange.length++; // include this in the last parameter
			}
		}
		// get last parameter
		[retval addObject: [[myTextView string] substringWithRange: lastRange]];
		return retval;
    } else
		return [NSArray array];
}

- (NSRange) buildMacro: (NSString **)name params: (NSArray **)params
{
    //NSLog(@"textView: %@ doCommandBySelector: %s",aTextView,aSelector);
    // get the last word before the cursor
    NSRange selectedRange = [myTextView selectedRange]; // figure out the start of this line
    NSString *selection = nil;
    NSString *text = [myTextView string];
    
    *params = NULL;
    *name = NULL;
    if (selectedRange.location == 0 && selectedRange.length == 0)
		return selectedRange;
    if (selectedRange.length == 0) {
		NSRange totalRange = selectedRange;
		NSRange paramsRange = NSMakeRange(0,0);
		// first, see if we've got params
		if ([text characterAtIndex: selectedRange.location - 1] == ')') {
			paramsRange = [myTextView balanceFrom: selectedRange.location - 1 startCharacter:'(' endCharacter:')'];
			if (paramsRange.length == 0)
				return paramsRange; // invalid
			totalRange = NSMakeRange(paramsRange.location,0); // and move back
			NSRange paramsContents = paramsRange;
			paramsContents.location+=1;
			paramsContents.length-=2;
			if (paramsContents.length) {
				// there are params, instead of an empty list
				*params = [self extractParameters: paramsContents];
			}
		}
		NSMutableCharacterSet *set = [[[NSMutableCharacterSet alloc] init] autorelease];
		[set formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
		[set addCharactersInRange: NSMakeRange('_',1)];
		while (1) {
			selectedRange = [text rangeOfCharacterFromSet:set
												  options: NSBackwardsSearch|NSAnchoredSearch range: NSMakeRange(0,totalRange.location)];
			if (selectedRange.length == 1) {
				totalRange.location -= 1;
				totalRange.length += 1;
			} else
				break;
		}
		selectedRange = totalRange;
		if (totalRange.length == 0)
			return totalRange;
		selection = [text substringWithRange: selectedRange];
		if (paramsRange.length) {
			selectedRange = NSUnionRange(selectedRange, paramsRange);
		}
    } else {
		NSRange paramsRange = NSMakeRange(0,0);
		if ([text characterAtIndex: selectedRange.location + selectedRange.length - 1] == ')') {
			paramsRange = [myTextView balanceFrom: selectedRange.location + selectedRange.length - 1 startCharacter:'(' endCharacter:')'];
			if (paramsRange.length == 0)
				return paramsRange; // invalid
			selectedRange.length = paramsRange.location - selectedRange.location; // and move back
			NSRange paramsContents = paramsRange;
			paramsContents.location+=1;
			paramsContents.length-=2;
			if (paramsContents.length) {
				// there are params, instead of an empty list
				*params = [self extractParameters: paramsContents];
			}
		}
		selection = [text substringWithRange: selectedRange];
		if (paramsRange.length) {
			selectedRange = NSUnionRange(selectedRange, paramsRange);
		}
    }
    *name = selection;
    return selectedRange;
}



- (IBAction) autoCompleteFromMenu: (id)  sender
{
    //[self getFocusedView];
    NSString *name;
    NSArray *params;
    NSRange range = [self buildMacro: &name params: &params];
    if (range.length) {
		// just fill in the sender rep object
		NSString *complete = [sender representedObject];
		if (complete) {
			BOOL completeThis = NO;
			if ([complete characterAtIndex: 0] == '$') {
				completeThis = YES;
				complete = [complete substringFromIndex: 1];
			}
			//			[[myTextView textStorage] beginEditing];
			[myTextView setSelectedRange: range];
			// if we expand a selection, make sure to remove the template here
			[[myTextView textStorage] removeAttribute: IDEKit_TemplateInternalAttributeName range: range];
			[[myTextView textStorage] removeAttribute: IDEKit_TemplateVisualAttributeName range: range];
			
			if (completeThis) {
				range = [self performMacro: complete withParams: params];
				if (range.length >= 0)
					[myTextView setSelectedRange: range];
			} else {
				[myTextView insertText: complete];
			}
			gAutoCompletedFromMenu = YES;
		} else {
			NSBeep();
		}
    }
}
- (NSString *) expandMacro: (NSString *)name withParams: (NSArray *)array
{
    NSString *retval;
    //NSLog(@"Complete the term <%@>",name);
    if ([name isEqualToString: @"_UUID"]) {
		// for now, just dump in a uuid
		CFUUIDRef myUUID;
		CFStringRef myUUIDString;
		myUUID = CFUUIDCreate(kCFAllocatorDefault);
		myUUIDString = CFUUIDCreateString(kCFAllocatorDefault, myUUID);
		NSString *retval = [NSString stringWithString: (__bridge id) myUUIDString];
		CFRelease(myUUIDString);
		CFRelease(myUUID);
		return retval;
    } else if ([name isEqualToString: @"_USER"]) {
		return NSFullUserName();
    } else if ([name isEqualToString: @"_FILENAME"]) {
		//NSLog(@"Getting filename");
		if ([myContext fileNameForSrcEditView: self]) {
			return [[myContext fileNameForSrcEditView: self] lastPathComponent];
		} else
			return @"(File Name)";
    } else if ([name isEqualToString: @"_PROJECT"]) {
		//NSLog(@"Getting filename");
		if ([myContext owningProjectForSrcEditView: self]) {
			return [[[myContext owningProjectForSrcEditView: self] fileName] lastPathComponent];
		} else
			return @"(Project Name)";
    } else if ([name isEqualToString: @"_DATE"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat: @"%x"];
    } else if ([name isEqualToString: @"_YEAR"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat: @"%Y"];
    } else if ([name isEqualToString: @"_MONTH"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat: @"%B"];
    } else if ([name isEqualToString: @"_TIME"]) {
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat: @"%I:%M %p"];
    } else if ([name isEqualToString: @"_CALENDARFMT"]) {
		NSString *fmt;
		if ([array count] == 0)
			fmt = @"%x";
		else
			fmt = [array componentsJoinedByString: @","];
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		return [date descriptionWithCalendarFormat: fmt];
    } else if ([name isEqualToString: @"_DEFINE"] && [array count] >= 2) {
		NSString *name = [array objectAtIndex: 0];
		NSString *value = [[array subarrayWithRange: NSMakeRange(1,[array count]-1)] componentsJoinedByString: @","];
		NSUserDefaults *defaults = myContext ? [myContext defaultsForSrcEditView: self] : [NSUserDefaults standardUserDefaults];
		NSDictionary *currentTemplates = [defaults dictionaryForKey: IDEKit_TemplatesKey];
		NSMutableDictionary *newTemplates = [NSMutableDictionary dictionaryWithDictionary: currentTemplates];
		[newTemplates setObject: value forKey: name];
		[defaults setObject: newTemplates forKey: IDEKit_TemplatesKey];
		return name;
    } else if ([name isEqualToString: @"_COND"] && [array count] >= 2) {
		NSString *name = [array objectAtIndex: 0];
		NSString *value = [[array subarrayWithRange: NSMakeRange(1,[array count]-1)] componentsJoinedByString: @","];
		if ([name length])
			return name;
		else
			return value;
    } else if ([name isEqualToString: @"_EVAL"]) {
		if ([array count] == 0)
			return @"";
		return [array componentsJoinedByString: @","];
    } else if (myCurrentLanguage && [myCurrentLanguage respondsToSelector: @selector(expandMacro:withParams:)]) {
		retval = [myCurrentLanguage expandMacro: name withParams: array];
		if (retval)
			return retval;
    }
    NSUserDefaults *defaults = myContext ? [myContext defaultsForSrcEditView: self] : [NSUserDefaults standardUserDefaults];
    NSDictionary *prefTemplates = [defaults dictionaryForKey: IDEKit_TemplatesKey];
    retval = [prefTemplates objectForKey: name];
    //NSLog(@"Looking for %@ in %@, found %@",name,[prefTemplates description],retval);
    if (retval)
		return retval;
    if (!retval) {
		id project = [myContext owningProjectForSrcEditView: self];
		if (project && [project respondsToSelector: @selector(autoCompleteIdentifier:max:)]) {
			//retval = [project expandMacro: name withParams: array forDocument: myDocument];
			NSArray *completes = [project srcEditView: self autoCompleteIdentifier: name max: 50];
			if (completes && [completes count]) {
				if ([completes count] == 1) {
					// just one, it is easy
					return [completes objectAtIndex: 0];
				}
				//NSLog(@"Pick completion from %@",[completes description]);
				NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Completion"] autorelease];
				for (NSUInteger i=0;i<[completes count];i++) {
					id completion = [completes objectAtIndex: i];
					id title = completion;
					if ([completion characterAtIndex: 0] == '$') {
						title = [completion substringFromIndex: 1]; // drop leading $
						// next item is actual completion
						completion = [completes objectAtIndex: i+1];
						i++;
					}
					id item = [menu addItemWithTitle: title action: @selector(autoCompleteFromMenu:) keyEquivalent: @""];
					[item setRepresentedObject: completion];
					[item setTarget: self];
				}
				[myTextView popupSmallMenuAtInsertion: menu];
				return NULL;
			}
		}
    }
    return retval;
}

- (NSRange) performMacro: (NSString *)macro withParams: (NSArray *)params
{
    int newCursorPos = -1;
    NSRange range = [myTextView selectedRange];
    NSDictionary *nonTemplateAttributes = [[NSDictionary alloc] initWithDictionary: [myTextView typingAttributes]];
    [myTextView setTypingAttributes: nonTemplateAttributes];
    NSMutableDictionary *templateAttributes = [[NSMutableDictionary alloc] initWithDictionary: [myTextView typingAttributes]]; //[[view textStorage] fontAttributesInRange: NSMakeRange(0, 0)];
    [templateAttributes setObject: [NSNumber numberWithInt: 1] forKey: IDEKit_TemplateInternalAttributeName];
    //			[templateAttributes setObject: [NSNumber numberWithInt: NSSingleUnderlineStyle] forKey: NSUnderlineStyleAttributeName];
    [templateAttributes setObject: IDEKit_TextColorForColor(IDEKit_kLangColor_FieldsBG) forKey: IDEKit_TemplateVisualAttributeName];
    BOOL gotTemplate = NO;
    NSRange firstTemplateRange = NSMakeRange(0,0);
    NSRange lastTemplateRange = NSMakeRange(0,0);
    for (NSUInteger i=0;i<[macro length];i++) {
		if ([macro characterAtIndex: i] == '$') {
			i++;
			if (i<[macro length]) {
				switch ([macro characterAtIndex: i]) {
					case '+':
						[myTextView insertNewlineAndIndent: self];
						break;
					case '-':
						[myTextView insertNewlineAndDedent: self];
						break;
					case '=':
						[myTextView insertNewlineAndDent: self];
						break;
					case '|':
						newCursorPos = [myTextView selectedRange].location;
						break;
					case '!':
						// recursive explansion of template
						if (myIsMakingTemplate < 20) {
							//[myTextView setSelectedRange: NSMakeRange([myTextView selectedRange].location + [myTextView selectedRange].length,0)];
							[myTextView setSelectedRange: lastTemplateRange];
							lastTemplateRange = NSMakeRange(0,0);
							if ([myTextView selectedRange].length) {
								gotTemplate = YES;
								firstTemplateRange = [myTextView selectedRange]; // use whatever we had expanded here, if anything
							}
							[self expandMacro: self];
						} else {
							[myTextView insertText: @"[Template Recursing Limit Reached]"];
							// avoid recursing too much
						}
						break;
					case '<':
						myIsMakingTemplate++;
						if (!gotTemplate) {
							gotTemplate = YES;
							firstTemplateRange.location = [myTextView selectedRange].location;
							firstTemplateRange.length = 0;
						}
						lastTemplateRange.location = [myTextView selectedRange].location;
						lastTemplateRange.length = 0;
						[myTextView setTypingAttributes: templateAttributes];
						break;
					case '>':
						if (firstTemplateRange.length == 0) {
							firstTemplateRange.length = [myTextView selectedRange].location - firstTemplateRange.location;
						}
						lastTemplateRange.length = [myTextView selectedRange].location - lastTemplateRange.location;
						[myTextView setTypingAttributes: nonTemplateAttributes];
						myIsMakingTemplate--;
						break;
					case '$':
						[myTextView insertText: @"$"];
						break;
					case '0':
						if ([params count] != 0)
							[myTextView insertText:[params componentsJoinedByString: @","]];
						break;
					case '1':
						if ([params count] >= 1)
							[myTextView insertText:[params objectAtIndex: 0]];
						break;
					case '2':
						if ([params count] >= 2)
							[myTextView insertText:[params objectAtIndex: 1]];
						break;
					case '3':
						if ([params count] >= 3)
							[myTextView insertText:[params objectAtIndex: 2]];
						break;
					case '4':
						if ([params count] >= 4)
							[myTextView insertText:[params objectAtIndex: 3]];
						break;
					case '5':
						if ([params count] >= 5)
							[myTextView insertText:[params objectAtIndex: 4]];
						break;
					case '6':
						if ([params count] >= 6)
							[myTextView insertText:[params objectAtIndex: 5]];
						break;
					case '7':
						if ([params count] >= 7)
							[myTextView insertText:[params objectAtIndex: 6]];
						break;
					case '8':
						if ([params count] >= 8)
							[myTextView insertText:[params objectAtIndex: 7]];
						break;
					case '9':
						if ([params count] >= 9)
							[myTextView insertText:[params objectAtIndex: 8]];
						break;
					case ':':
						if ([params count] >= 2) {
							[myTextView insertText:[[params subarrayWithRange: NSMakeRange(1,[params count]-1)] componentsJoinedByString: @","]];
						}
						break;
					default:
						[myTextView insertText: [NSString stringWithFormat: @"%c%c",'$',[macro characterAtIndex: i]]];
						break;
				}
			} else {
				[myTextView insertText: @"$"];
			}
		} else {
			[myTextView insertText: [NSString stringWithFormat: @"%c",[macro characterAtIndex: i]]];
		}
    }
    if (newCursorPos != -1) {
		return NSMakeRange(newCursorPos,0);
    } else if (firstTemplateRange.length != 0) {
		return firstTemplateRange;
    } else {
		return [myTextView selectedRange]; //NSMakeRange(0,-1);
    }
}

@end


@implementation IDEKit_SnippetManager
+ (IDEKit_SnippetManager *) sharedSnippetManager
{
    static IDEKit_SnippetManager *snippet = NULL;
    if (!snippet) {
		snippet = [[IDEKit_SnippetManager alloc] init];
    }
    return snippet;
}
- (IDEKit_SrcEditView *)srcEditView {
    id obj = [[NSApp mainWindow] firstResponder];
    if (obj) {
		if ([obj isKindOfClass:[IDEKit_TextView class]])
			return [obj delegate]; // return the IDEKit_SrcView so we are synced correctly
    }
    return nil;
}
- (void) targetWindowBecame: (NSNotification *)notification
{
    IDEKit_SrcEditView *srcEditView = [self srcEditView];
    if (srcEditView) {
		[srcEditView updateSnippets];
    } else {
		[self setSnippet: [NSDictionary dictionary]]; // use empty dictionary
    }
}
- (void) targetWindowResign: (NSNotification *)notification
{
    if ([NSApp mainWindow] == NULL)
		[self setSnippet: [NSDictionary dictionary]]; // use empty dictionary
}

- (id) init
{
    self = [super init];
    if (self) {
		[NSBundle loadOverridenNibNamed:@"IDEKit_Snippets" owner:self];
		[myOutline setDoubleAction:@selector(insertSnippet:)];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetWindowBecame:) name: NSWindowDidBecomeMainNotification object: NULL];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetWindowResign:) name: NSWindowDidResignMainNotification object: NULL];
		myExpandedNodes = [[NSMutableSet set] retain];
    }
    return self;
}
- (void) insertSnippet: (id) sender
{
    id snippet = [[myOutline itemAtRow: [myOutline selectedRow]] objectForKey: @"snippet"];
    if (snippet) {
		id obj = [[NSApp mainWindow] firstResponder];
		if (obj) {
			if ([obj isKindOfClass:[IDEKit_TextView class]]) {
				IDEKit_SrcEditView *src = [obj delegate];
				[src insertSnippet: snippet];
			}
		}
    }
}
- (void) showTip: (id) sender
{
    id item = [myOutline itemAtRow: [myOutline selectedRow]];
    if ([item objectForKey: @"tip"])
		[myTip setStringValue:[item objectForKey: @"tip"]];
    else
		[myTip setStringValue:@""];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == NULL)
		return [mySnippetRoot objectAtIndex: index];
    return [[item objectForKey: @"children"] objectAtIndex: index];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == NULL) return YES;
    return [item objectForKey: @"children"] != NULL;
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == NULL)
		return [mySnippetRoot count];
    return [[item objectForKey: @"children"] count];
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[item objectForKey: @"snippet"] objectForKey: @"url"])
		return [NSString stringWithFormat: @"[URL] %@",[item objectForKey: @"title"]];
    if ([[item objectForKey: @"snippet"] objectForKey: @"file"])
		return [NSString stringWithFormat: @"[FILE] %@",[item objectForKey: @"title"]];
    //if ([[item objectForKey: @"snippet"] objectForKey: @"template"])
	//return [NSString stringWithFormat: @"[TEMPLATE] %@",[item objectForKey: @"title"]];
    return [item objectForKey: @"title"];
}
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    // keep track of it by the key (full path)
    [myExpandedNodes addObject: [[[notification userInfo] objectForKey: @"NSObject"] objectForKey: @"key"]];
}
- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    // keep track of it by the key (full path)
    [myExpandedNodes removeObject: [[[notification userInfo] objectForKey: @"NSObject"] objectForKey: @"key"]];
}
- (void) expandItemsIn: (NSArray *)children
{
    NSEnumerator *e = [children objectEnumerator];
    NSDictionary *child;
    while ((child = [e nextObject]) != NULL) {
		if ([myExpandedNodes containsObject: [child objectForKey: @"key"]]) {
			[myOutline expandItem:child];
			[self expandItemsIn: [child objectForKey: @"children"]]; // only recurse the ones that are open already
		}
    }
}

- (void) setSnippet: (NSDictionary *)snippets
{
    [mySnippetRoot release];
    mySnippetRoot = [[NSMutableArray array] retain];
    NSEnumerator *e = [snippets keyEnumerator];
    NSString *key;
    while ((key = [e nextObject]) != NULL) {
		NSMutableArray *subMenu = mySnippetRoot;
		NSArray *subMenuNames = [key pathComponents];
		// if it is a path, build the path of menu items
		for (NSUInteger index=0;index+1<[subMenuNames count];index++) { // all but the last item
			// allow titles to include URL style % escapes
			NSString *title = [[subMenuNames objectAtIndex: index] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			NSDictionary *hItem = NULL;
			NSEnumerator *i = [subMenu objectEnumerator];
			while ((hItem = [i nextObject]) != NULL) {
				if ([[hItem objectForKey: @"title"] isEqualToString: title])
					break;
			}
			if (!hItem) {
				hItem = [NSDictionary dictionaryWithObjectsAndKeys:
						 title, @"title",
						 [NSMutableArray array], @"children",
						 [[subMenuNames subarrayWithRange: NSMakeRange(0,index+1)] componentsJoinedByString:@"\t"],@"key",
						 NULL];
				[subMenu addObject: hItem];
			}
			subMenu = [hItem objectForKey: @"children"];
		}
		id snip = [snippets objectForKey:key];
		id item = [NSDictionary dictionaryWithObjectsAndKeys:
				   [[key lastPathComponent] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"title",
				   snip, @"snippet",
				   ([snip isKindOfClass:[NSDictionary class]] && [snip objectForKey: @"tip"]) ? [snip objectForKey: @"tip"] : NULL, @"tip",
				   NULL];
		[subMenu addObject: item];
    }
    [myOutline reloadData];
    [self expandItemsIn: mySnippetRoot];
    [myTip setStringValue:@""];
}

@end