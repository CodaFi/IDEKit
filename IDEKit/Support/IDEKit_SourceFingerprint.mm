//
//  IDEKit_SourceFingerprint.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/18/04.
//  Copyright 2004 by Glenn Andreas.
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

#import "IDEKit_SourceFingerprint.h"
#import "IDEKit_LineCache.h"

NSUInteger short IDEKit_Fingerprint(const NSUInteger char * data, int length) // simple crc-16
{
    static NSUInteger short table[256] = {
	0x0000, 0x1189, 0x2312, 0x329B, 0x4624, 0x57AD, 0x6536, 0x74BF,
	0x8C48, 0x9DC1, 0xAF5A, 0xBED3, 0xCA6C, 0xDBE5, 0xE97E, 0xF8F7,
	0x1081, 0x0108, 0x3393, 0x221A, 0x56A5, 0x472C, 0x75B7, 0x643E,
	0x9CC9, 0x8D40, 0xBFDB, 0xAE52, 0xDAED, 0xCB64, 0xF9FF, 0xE876,
	0x2102, 0x308B, 0x0210, 0x1399, 0x6726, 0x76AF, 0x4434, 0x55BD,
	0xAD4A, 0xBCC3, 0x8E58, 0x9FD1, 0xEB6E, 0xFAE7, 0xC87C, 0xD9F5,
	0x3183, 0x200A, 0x1291, 0x0318, 0x77A7, 0x662E, 0x54B5, 0x453C,
	0xBDCB, 0xAC42, 0x9ED9, 0x8F50, 0xFBEF, 0xEA66, 0xD8FD, 0xC974,
	0x4204, 0x538D, 0x6116, 0x709F, 0x0420, 0x15A9, 0x2732, 0x36BB,
	0xCE4C, 0xDFC5, 0xED5E, 0xFCD7, 0x8868, 0x99E1, 0xAB7A, 0xBAF3,
	0x5285, 0x430C, 0x7197, 0x601E, 0x14A1, 0x0528, 0x37B3, 0x263A,
	0xDECD, 0xCF44, 0xFDDF, 0xEC56, 0x98E9, 0x8960, 0xBBFB, 0xAA72,
	0x6306, 0x728F, 0x4014, 0x519D, 0x2522, 0x34AB, 0x0630, 0x17B9,
	0xEF4E, 0xFEC7, 0xCC5C, 0xDDD5, 0xA96A, 0xB8E3, 0x8A78, 0x9BF1,
	0x7387, 0x620E, 0x5095, 0x411C, 0x35A3, 0x242A, 0x16B1, 0x0738,
	0xFFCF, 0xEE46, 0xDCDD, 0xCD54, 0xB9EB, 0xA862, 0x9AF9, 0x8B70,
	0x8408, 0x9581, 0xA71A, 0xB693, 0xC22C, 0xD3A5, 0xE13E, 0xF0B7,
	0x0840, 0x19C9, 0x2B52, 0x3ADB, 0x4E64, 0x5FED, 0x6D76, 0x7CFF,
	0x9489, 0x8500, 0xB79B, 0xA612, 0xD2AD, 0xC324, 0xF1BF, 0xE036,
	0x18C1, 0x0948, 0x3BD3, 0x2A5A, 0x5EE5, 0x4F6C, 0x7DF7, 0x6C7E,
	0xA50A, 0xB483, 0x8618, 0x9791, 0xE32E, 0xF2A7, 0xC03C, 0xD1B5,
	0x2942, 0x38CB, 0x0A50, 0x1BD9, 0x6F66, 0x7EEF, 0x4C74, 0x5DFD,
	0xB58B, 0xA402, 0x9699, 0x8710, 0xF3AF, 0xE226, 0xD0BD, 0xC134,
	0x39C3, 0x284A, 0x1AD1, 0x0B58, 0x7FE7, 0x6E6E, 0x5CF5, 0x4D7C,
	0xC60C, 0xD785, 0xE51E, 0xF497, 0x8028, 0x91A1, 0xA33A, 0xB2B3,
	0x4A44, 0x5BCD, 0x6956, 0x78DF, 0x0C60, 0x1DE9, 0x2F72, 0x3EFB,
	0xD68D, 0xC704, 0xF59F, 0xE416, 0x90A9, 0x8120, 0xB3BB, 0xA232,
	0x5AC5, 0x4B4C, 0x79D7, 0x685E, 0x1CE1, 0x0D68, 0x3FF3, 0x2E7A,
	0xE70E, 0xF687, 0xC41C, 0xD595, 0xA12A, 0xB0A3, 0x8238, 0x93B1,
	0x6B46, 0x7ACF, 0x4854, 0x59DD, 0x2D62, 0x3CEB, 0x0E70, 0x1FF9,
	0xF78F, 0xE606, 0xD49D, 0xC514, 0xB1AB, 0xA022, 0x92B9, 0x8330,
	0x7BC7, 0x6A4E, 0x58D5, 0x495C, 0x3DE3, 0x2C6A, 0x1EF1, 0x0F78
    };
    NSUInteger short retval = 0;
    while ((length--) > 0) {
	retval = table[(retval ^ (*data++)) & 0x0ff] ^ (retval >> 8);
    }
    return retval;
}

NSUInteger short IDEKit_FingerprintText(const unichar * data, int length) // will white-strip head & tail
{
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    // strip leading
    while (length && [ws characterIsMember: data[0]]) {
	data++;
	length--;
    }
    // strip tailing
    while (length && [ws characterIsMember: data[length-1]]) {
	length--;
    }
    if (length) {
	return IDEKit_Fingerprint((const NSUInteger char *)data, length * sizeof(unichar));
    } else {
	return 0; // return 0 for blank lines
    }
}

@implementation NSString(Fingerprint)
- (NSUInteger short) fingerprint
{
    int length = [self length];
    unichar *buffer = (unichar *)malloc(length * sizeof(unichar));
    [self getCharacters:buffer];
    NSUInteger short retval = IDEKit_Fingerprint((const NSUInteger char *)buffer, length * sizeof(unichar));
    free(buffer);
    return retval;
}
- (NSUInteger short) trimmedFingerprint
{
    int length = [self length];
    unichar *buffer = (unichar *)malloc(length * sizeof(unichar));
    [self getCharacters:buffer];
    NSUInteger short retval = IDEKit_FingerprintText(buffer, length);
    free(buffer);
    return retval;
}
@end

@implementation IDEKit_SrcEditView(Fingerprint)
- (NSData *)fingerprint
{
    int numLines = myLineCache->UnfoldedLineCount();
    NSMutableData *retval = [NSMutableData dataWithLength: sizeof(NSUInteger short) * (numLines + 1)];
    // we make an array of crcs for each line (with a crc for the entire data at the start)
    NSUInteger short *buffer = (NSUInteger short *)[retval mutableBytes];
    NSString *source = [self string];
    for (int line=1;line <= numLines; line++) {
	buffer[line] = [[source substringWithRange: myLineCache->UnfoldedNthLineRange(line)] trimmedFingerprint];
    }
    // and put a crc at the start to make it easy to compare
    buffer[0] = IDEKit_Fingerprint((const NSUInteger char *)(buffer+1),numLines * sizeof(NSUInteger short));
    return retval;
}
@end

static void FillInMapping(int *map, int count)
{
    // now, at this point there are going to be some gaps where the maps are set to zero
    for (int i=0;i<count;i++) {
	if (map[i] == 0) {
	    if (i==0)
		map[i] = -1;
	    else {
		map[i] = -abs(map[i-1]);
	    }
	}
    }
}

@implementation IDEKit_SourceMapping
- (id) initMappingFrom: (NSData *)srcFingerprint to: (NSData *)dstFingerprint
{
    self = [super init];
    if (self) {
	if ([srcFingerprint isEqualToData:dstFingerprint]) { // same, so we do trivial mapping
	    myForwardMap = myReverseMap = NULL;
	} else {
	    int srcCount = [srcFingerprint length] / sizeof(NSUInteger short) - 1;
	    int dstCount = [dstFingerprint length] / sizeof(NSUInteger short) - 1;
	    myForwardMap = new int[srcCount]; for (int i=0;i<srcCount;i++) myForwardMap[i] = 0;
	    myReverseMap = new int[dstCount]; for (int i=0;i<dstCount;i++) myReverseMap[i] = 0;
	    NSUInteger short *srcPrint = ((NSUInteger short *)[srcFingerprint bytes]);
	    NSUInteger short *dstPrint = ((NSUInteger short *)[dstFingerprint bytes]);
	    // ok, try to keep them in sync (we don't handle text being moved, just added/deleted
	    int srcLine = 1; // 0 is the composite crc
	    int dstLine = 1;
	    while (srcLine <= srcCount && dstLine <= dstCount) {
		if (srcPrint[srcLine] == dstPrint[dstLine]) {
		    // the two match
		    myForwardMap[srcLine-1] = dstLine;
		    myReverseMap[dstLine-1] = srcLine;
		    srcLine++;
		    dstLine++;
		} else {
		    // we are out of sync - ugh.  Start searching out for a resync
		    int delta;
		    for (delta = 1;delta>0 && delta < (srcCount - srcLine + 1) + (dstCount - dstLine + 1); delta++) { // set delta=-1 once we've found it
			// and we search "delta" lines forward in either direction
			for (int srcDelta=0;srcDelta<=delta;srcDelta++) {
			    int dstDelta = delta - srcDelta;
			    if (srcLine+srcDelta <= srcCount && dstLine+dstDelta <= dstCount && srcPrint[srcLine+srcDelta] == dstPrint[dstLine+dstDelta]) {
				// synced!
				srcLine += srcDelta;
				dstLine += dstDelta;
				myForwardMap[srcLine-1] = dstLine;
				myReverseMap[dstLine-1] = srcLine;
				srcLine++;
				dstLine++;
				delta = -1; // we're done
				break; // this only breaks our inter looop
			    }
			}
		    }
		    if (delta > 0) {
			// never found a resync, so we're done
			break;
		    }
		}
	    }
	    // now, at this point there are going to be some gaps where the maps are set to zero
	    FillInMapping(myForwardMap, srcCount);
	    FillInMapping(myReverseMap, dstCount);
	}
    }
    return self;
}
- (void) dealloc
{
    delete []myForwardMap;
    delete []myReverseMap;
}
- (NSInteger) mapForward: (NSInteger) srcLineNumber
{
    if (myForwardMap)
	return abs(myForwardMap[srcLineNumber-1]);
    else
	return srcLineNumber;
}
- (NSInteger) mapBackward: (NSInteger) dstLineNumber
{
    if (myReverseMap)
	return abs(myReverseMap[dstLineNumber-1]);
    else
	return dstLineNumber;
}
- (NSInteger) mapForwardStrict: (NSInteger) srcLineNumber
{
    if (myForwardMap)
	if (myForwardMap[srcLineNumber-1] > 0)
	    return myForwardMap[srcLineNumber-1];
	else
	    return 0; // no strict mapping
    else
	return srcLineNumber;
}
- (NSInteger) mapBackwardStrict: (NSInteger) dstLineNumber
{
    if (myReverseMap)
	if (myReverseMap[dstLineNumber-1] > 0)
	    return myForwardMap[dstLineNumber-1];
	else
	    return 0; // no strict mapping
    else
	return dstLineNumber;
}
- (BOOL) isTrivial // 1<->1
{
    return myForwardMap == NULL;
}
- (NSDictionary *) mapDictionaryForward: (NSDictionary *)dict
{
    if (myForwardMap == NULL) return dict; // trivial
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSEnumerator *e = [dict keyEnumerator];
    NSString *key;
    while ((key = [e nextObject]) != NULL) {
	int dstLine = [key intValue];
	if ([key isEqualToString: [NSString stringWithFormat: @"%d", dstLine]]) {
	    int srcLine = [self mapForward: dstLine];
	    [retval setObject: [dict objectForKey: key] forKey: [NSString stringWithFormat: @"%d", srcLine]];
	} else {
	    // not a numeric key
	    [retval setObject: [dict objectForKey: key] forKey: key];
	}
    }
    return retval;
}

- (NSDictionary *) mapDictionaryBackward: (NSDictionary *)dict
{
    if (myReverseMap == NULL) return dict;
    NSMutableDictionary *retval = [NSMutableDictionary dictionary];
    NSEnumerator *e = [dict keyEnumerator];
    NSString *key;
    while ((key = [e nextObject]) != NULL) {
	int dstLine = [key intValue];
	if ([key isEqualToString: [NSString stringWithFormat: @"%d", dstLine]]) {
	    int srcLine = [self mapBackward: dstLine];
	    [retval setObject: [dict objectForKey: key] forKey: [NSString stringWithFormat: @"%d", srcLine]];
	} else {
	    // not a numeric key
	    [retval setObject: [dict objectForKey: key] forKey: key];
	}
    }
    return retval;
}

@end