/*
 *  FakeTCLBridge.c
 *  IDEKit
 *
 *  Created by Glenn Andreas on Sat May 15 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "FakeTCLBridge.h"
//#import <Foundation/Foundation.h>

void Tcl_DStringInit(Tcl_DString *ds)
{
    *ds = NULL;
}

const char *Tcl_UniCharToUtfDString(Tcl_UniChar *characters, size_t length, Tcl_DString *ds)
{
    CFStringRef str = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault,characters, length, kCFAllocatorNull);
    CFRange range = {0,length}; // all the characters
    CFIndex bufLen = 0;
    CFStringGetBytes(str, range, kCFStringEncodingUTF8, true, false, NULL, 0, &bufLen);
    *ds = (malloc(bufLen));
    CFStringGetBytes(str, range, kCFStringEncodingUTF8, true, false, *ds, bufLen, &bufLen);
    CFRelease(str);
    return (const char *)*ds;
}
void Tcl_DStringFree(Tcl_DString *ds)
{
    if (*ds)
	free(*ds);
}



Tcl_UniChar Tcl_UniCharToLower(Tcl_UniChar c)
{
    if (c < 0x7f)
	return tolower(c);
    CFMutableStringRef str = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault,&c, 1,0, kCFAllocatorNull);
    CFStringLowercase(str,NULL);
    Tcl_UniChar retval = c;
    if (CFStringGetLength(str)) { // make sure one exists
	retval = CFStringGetCharacterAtIndex(str, 0);
    }
    CFRelease(str);
    return retval;
}
Tcl_UniChar Tcl_UniCharToUpper(Tcl_UniChar c)
{
    if (c < 0x7f)
	return toupper(c);
    CFMutableStringRef str = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault,&c, 1,0, kCFAllocatorNull);
    CFStringUppercase(str,NULL);
    Tcl_UniChar retval = c;
    if (CFStringGetLength(str)) { // make sure one exists
	retval = CFStringGetCharacterAtIndex(str, 0);
    }
    CFRelease(str);
    return retval;
}
Tcl_UniChar Tcl_UniCharToTitle(Tcl_UniChar c)
{
    if (c < 0x7f)
	return toupper(c);
    CFMutableStringRef str = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault,&c, 1,0, kCFAllocatorNull);
    CFStringCapitalize(str,NULL);
    Tcl_UniChar retval = c;
    if (CFStringGetLength(str)) { // make sure one exists
	retval = CFStringGetCharacterAtIndex(str, 0);
    }
    CFRelease(str);
    return retval;
}

bool Tcl_UniCharIsAlpha(Tcl_UniChar c)
{
    if (c < 0x7f)
	return isalpha(c);
    CFCharacterSetRef set = CFCharacterSetGetPredefined(kCFCharacterSetLetter);
    return CFCharacterSetIsCharacterMember(set, c);
}

bool Tcl_UniCharIsDigit(Tcl_UniChar c)
{
    if (c < 0x7f)
	return isdigit(c);
    CFCharacterSetRef set = CFCharacterSetGetPredefined(kCFCharacterSetDecimalDigit);
    return CFCharacterSetIsCharacterMember(set, c);
}

bool Tcl_UniCharIsAlnum(Tcl_UniChar c)
{
    if (c < 0x7f)
	return isalnum(c);
    CFCharacterSetRef set = CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric);
    return CFCharacterSetIsCharacterMember(set, c);
}

bool Tcl_UniCharIsSpace(Tcl_UniChar c)
{
    if (c < 0x7f)
	return isspace(c);
    CFCharacterSetRef set = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
    return CFCharacterSetIsCharacterMember(set, c);
}
