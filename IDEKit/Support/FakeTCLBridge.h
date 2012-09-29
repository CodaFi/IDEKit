/*
 *  FakeTCLBridge.h
 *  IDEKit
 *
 *  Created by Glenn Andreas on Sat May 15 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

// This provides a bridge between the Tcl routines that regex uses and CF/NS routines
typedef unsigned short unichar;
#import <limits.h>
#import <stdarg.h>
#include <sys/types.h>

typedef unichar Tcl_UniChar;
#define UCHAR(c)    ((unichar)(c))

typedef void *Tcl_DString;

void Tcl_DStringInit(Tcl_DString *ds);
const char *Tcl_UniCharToUtfDString(Tcl_UniChar *characters, size_t lenth, Tcl_DString *ds);
void Tcl_DStringFree(Tcl_DString *ds);
// these, of course, assume that upper & lower not only exist, but are also a single character
Tcl_UniChar Tcl_UniCharToLower(Tcl_UniChar c);
Tcl_UniChar Tcl_UniCharToUpper(Tcl_UniChar c);
Tcl_UniChar Tcl_UniCharToTitle(Tcl_UniChar c);

bool Tcl_UniCharIsAlpha(Tcl_UniChar c);
bool Tcl_UniCharIsDigit(Tcl_UniChar c);
bool Tcl_UniCharIsAlnum(Tcl_UniChar c);
bool Tcl_UniCharIsSpace(Tcl_UniChar c);
