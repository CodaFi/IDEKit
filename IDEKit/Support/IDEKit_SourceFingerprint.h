//
//  IDEKit_SourceFingerprint.h
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

#import <Cocoa/Cocoa.h>
#import "IDEKit_SrcEditView.h"

// This is how we map between files that may have changed - we "fingerprint" the file (take a crc of
// each line) and then we can compare them "easily".
unsigned short IDEKit_Fingerprint(const unsigned char * data, int length); // generate a CRC for this
unsigned short IDEKit_FingerprintText(const unichar * data, int length); // will white-strip head & tail

@interface IDEKit_SrcEditView(Fingerprint)
- (NSData *)fingerprint;
@end

@interface NSString(Fingerprint)
- (unsigned short) fingerprint;
- (unsigned short) trimmedFingerprint;
@end


@interface IDEKit_SourceMapping : NSObject {
    int *myForwardMap;
    int *myReverseMap;
}
- (id) initMappingFrom: (NSData *)srcFingerprint to: (NSData *)dstFingerprint;
- (BOOL) isTrivial; // 1<->1
- (NSInteger) mapForward: (NSInteger) srcLineNumber;
- (NSInteger) mapBackward: (NSInteger) dstLineNumber;
- (NSInteger) mapForwardStrict: (NSInteger) srcLineNumber;
- (NSInteger) mapBackwardStrict: (NSInteger) dstLineNumber;
- (NSDictionary *) mapDictionaryForward: (NSDictionary *)dictionary;
- (NSDictionary *) mapDictionaryBackward: (NSDictionary *)dictionary;
@end