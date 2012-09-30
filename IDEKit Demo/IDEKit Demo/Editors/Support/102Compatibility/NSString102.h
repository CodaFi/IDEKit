//
//  NSString102.h
//  IDEKit
//
//  Created by Glenn Andreas on Tue Jul 27 2004.
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

#import <Foundation/Foundation.h>

// Provide 10.3 features on 10.2 systems (so we can just call 10.3 routines regardless)

@interface NSString(NSURLUtilities_102)
/* Adds all percent escapes necessary to convert the receiver in to a legal URL string.  Uses the given encoding to determine the correct percent escapes (returning nil if the given encoding cannot encode a particular character).  See CFURLCreateStringByAddingPercentEscapes in CFURL.h for more complex transformations */
- (NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)enc;

    /* Replaces all percent escapes with the matching characters as determined by the given encoding.  Returns nil if the transformation is not possible (i.e. the percent escapes give a byte sequence not legal in the given encoding).  See CFURLCreateStringByReplacingPercentEscapes in CFURL.h for more complex transformations */
- (NSString *)stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)enc;
@end
