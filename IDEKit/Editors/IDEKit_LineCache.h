//
//  IDEKit_LineCache.h
//  IDEKit
//
//  Created by Glenn Andreas on Sun Feb 08 2004.
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
//
#include <Foundation/Foundation.h>
#include <deque>
// IDEKit_LineCache isn't declared a class because we want to reference it from Objective-C
// headers - while we compile IDEKit as ObjectiveC++, we don't want to force that on all of our
// clients
typedef struct IDEKit_LineCache {
public:
    IDEKit_LineCache();
    ~IDEKit_LineCache();
    void RebuildFromString(NSString *string);
    // queury the information
    NSInteger FoldedLineNumberFromOffset(NSUInteger offset);
    NSRange FoldedNthLineRange(NSInteger n);
    NSInteger FoldedLineCount();
    NSInteger UnfoldedLineNumberFromOffset(NSUInteger offset);
    NSRange UnfoldedNthLineRange(NSInteger n);
    NSInteger  UnfoldedLineCount();
    // conversion
    NSUInteger UnfoldedLocation(NSUInteger offset); // convert from unfolded to folded location
    NSUInteger FoldedLocation(NSUInteger offset); // convert from folded to unfolded
    NSRange FoldedRange(NSRange range);
    NSRange UnfoldedRange(NSRange range);
    
    NSMutableDictionary *UnfoldedLineData(NSInteger lineNum, bool create = NO);
    NSDictionary *GetLineData();
    void SetLineData(NSDictionary *data);
    bool ValidLineNum(NSInteger lineNum); // these are 1 based
    // update our cache, expressed with folded coordinate space
    void ReplaceRangeWithString(NSRange src, NSString *string);
    // folding information
    void FoldRange(NSRange fold);
    void UnfoldLocation(NSUInteger offset);
    
    // for debugging
    void DumpLineCache();
protected:
    std::deque<NSUInteger> fUnfoldedLineStarts;
    std::deque<NSMutableDictionary *> fUnfoldedLineData;
    std::deque<NSUInteger> fFoldedLineStarts;
    NSUInteger fTotalUnfoldedSize;
    NSUInteger fTotalFoldedSize;
    typedef struct FoldingInfo {
	NSUInteger foldingStart;
	NSUInteger contentsSize; // the contents, unfolded
	bool operator < (const FoldingInfo &other) const;
    };
    std::deque<FoldingInfo> fFoldingInfo;
    
    void RemoveRange(NSRange src);
    void InsertString(NSUInteger offset, NSString *string);
    void RebuildFoldedFromUnfolded();
    void NextTopLevelFold(std::deque<FoldingInfo>::iterator &i);
    void MoveFoldings(NSRange src, NSInteger replaceSize);
    void ReleaseLineData();
};