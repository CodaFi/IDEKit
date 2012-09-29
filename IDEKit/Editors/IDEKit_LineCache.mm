//
//  IDEKit_LineCache.cpp
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



#include "IDEKit_LineCache.h"
#include <algorithm>

IDEKit_LineCache::IDEKit_LineCache() : fTotalUnfoldedSize(0), fTotalFoldedSize(0)
{
    fUnfoldedLineStarts.push_back(0); // first line start at 0, simple
    fUnfoldedLineData.push_back(NULL);
    fFoldedLineStarts.push_back(0); // first line start at 0, simple
}

IDEKit_LineCache::~IDEKit_LineCache()
{
    ReleaseLineData();
}

void IDEKit_LineCache::ReleaseLineData()
{
    for (std::deque<NSMutableDictionary *>::iterator i = fUnfoldedLineData.begin(); i != fUnfoldedLineData.end(); i++) {
		[(*i) release]; // release any line data
		(*i) = NULL;
    }
}

void IDEKit_LineCache::DumpLineCache()
{
    NSLog(@"Unfolded cache");
    NSInteger num = 1;
    for (std::deque<NSUInteger>::iterator i = fUnfoldedLineStarts.begin(); i != fUnfoldedLineStarts.end(); i++) {
		NSLog(@"Line %ld: %ld %@",num,*i,fUnfoldedLineData[num]);
		num++;
    }
    NSLog(@"Folded cache");
    num = 1;
    for (std::deque<NSUInteger>::iterator i = fFoldedLineStarts.begin(); i != fFoldedLineStarts.end(); i++) {
		NSLog(@"Line %ld: %ld",num++,*i);
    }
    NSLog(@"Folding");
    for (std::deque<FoldingInfo>::iterator i = fFoldingInfo.begin(); i != fFoldingInfo.end(); i++) {
		NSLog(@"%ld, contains %ld",(*i).foldingStart, (*i).contentsSize);
    }
    NSLog(@"Total size: Folded = %ld, Unfolded = %ld", fTotalFoldedSize,fTotalUnfoldedSize);
}

void IDEKit_LineCache::RebuildFromString(NSString *string)
{
    fFoldingInfo.clear();
    fFoldedLineStarts.clear();
    fUnfoldedLineStarts.clear();
    ReleaseLineData();
    fUnfoldedLineData.clear();
    
    fUnfoldedLineStarts.push_back(0); // first line start at 0, simple
    fUnfoldedLineData.push_back(NULL);
    NSUInteger curStart = 0;
    for (curStart=0;curStart<[string length];) {
		curStart = NSMaxRange([string lineRangeForRange: NSMakeRange(curStart,0)]);
		fUnfoldedLineStarts.push_back(curStart); // start of next line
		fUnfoldedLineData.push_back(NULL);
    }
    // and since it is unfolded, these two are the same
    fFoldedLineStarts = fUnfoldedLineStarts;
    fTotalFoldedSize = fTotalUnfoldedSize = [string length];
}

// given a line start array which is sorted, find the first element <= offset
static std::deque<NSUInteger>::iterator FindLineStartFromOffset(std::deque<NSUInteger>::iterator begin, std::deque<NSUInteger>::iterator end, NSUInteger offset)
{
    std::deque<NSUInteger>::iterator retval = std::lower_bound(begin, end, offset);
    // this will find the next one up, if we aren't exact
    while (retval == end || (retval != begin && (*retval) > offset)) retval--;
    // you'd think there'd be an easy way to combine lower_bound or upper_bound with offset+1 or offset-1 and
    // increment/decrement the result.
#ifdef nodef
    NSLog(@"Looking for %d",offset);
    int index = 1;
    for (std::deque<NSUInteger>::iterator i = begin; i != end; i++) {
		if (i == retval)
			NSLog(@"=> %d:%d",index,(*i));
		else
			NSLog(@"   %d:%d",index,(*i));
		index++;
    }
#endif
    return retval;
}

NSInteger IDEKit_LineCache::FoldedLineNumberFromOffset(NSUInteger offset)
{
    return FindLineStartFromOffset(fFoldedLineStarts.begin(), fFoldedLineStarts.end(), offset) - fFoldedLineStarts.begin();
}

NSRange IDEKit_LineCache::FoldedNthLineRange(NSInteger n)
{
    if (n <= 0) return NSMakeRange(0,0);
    if (n >= fFoldedLineStarts.size()) n = fFoldedLineStarts.size() - 1;
    NSUInteger start = fFoldedLineStarts[n];
    NSUInteger end = (n+1 < fFoldedLineStarts.size()) ? fFoldedLineStarts[n+1] : fTotalFoldedSize;
    return NSMakeRange(start, end-start);
}

NSInteger IDEKit_LineCache::FoldedLineCount()
{
    return fUnfoldedLineStarts.size();
}

NSInteger IDEKit_LineCache::UnfoldedLineNumberFromOffset(NSUInteger offset)
{
    return FindLineStartFromOffset(fUnfoldedLineStarts.begin(), fUnfoldedLineStarts.end(), offset) - fUnfoldedLineStarts.begin() + 1;
}

NSRange IDEKit_LineCache::UnfoldedNthLineRange(NSInteger n)
{
    if (n <= 0) return NSMakeRange(0,0);
    n--; // convert from 1 based to 0 based
    if (n >= fUnfoldedLineStarts.size()) n = fUnfoldedLineStarts.size() - 1;
    NSUInteger start = fUnfoldedLineStarts[n];
    NSUInteger end = (n+1 < fUnfoldedLineStarts.size()) ? fUnfoldedLineStarts[n+1] : fTotalUnfoldedSize;
    return NSMakeRange(start, end-start);
}

NSInteger IDEKit_LineCache::UnfoldedLineCount()
{
    return fUnfoldedLineStarts.size();
}

void IDEKit_LineCache::NextTopLevelFold(std::deque<FoldingInfo>::iterator &i)
{
    NSUInteger nextAtThisLevel = (*i).foldingStart + (*i).contentsSize;
    while (i != fFoldingInfo.end()) {
		i++;
		if ((*i).foldingStart >= nextAtThisLevel)
			break;
    }
}

NSUInteger IDEKit_LineCache::UnfoldedLocation(NSUInteger offset) // convert from unfolded to folded location
{
    // short cut if not folded, or before fold
    if (fFoldingInfo.empty() || offset <= fFoldingInfo[0].foldingStart)
		return offset;
    // OK, we need to break it down
    NSUInteger retval = offset;
    for (std::deque<FoldingInfo>::iterator i = fFoldingInfo.begin(); i != fFoldingInfo.end();) {
		if (retval <= (*i).foldingStart) {
			// we are before this fold, so we are done (we don't care about downstream folds
			break;
		} else if (retval > (*i).foldingStart) {
			// offset is after this entire folding
			retval += (*i).contentsSize-1; // we hid N characters inside 1 character
			// skip to next fold at this level
			NextTopLevelFold(i);
		}
    }
    //NSLog(@"Unfolded %d as %d",offset,retval);
    return retval;
}

NSUInteger IDEKit_LineCache::FoldedLocation(NSUInteger offset) // convert from folded to unfolded
{
    // short cut if not folded, or before fold
    if (fFoldingInfo.empty() || offset <= fFoldingInfo[0].foldingStart)
		return offset;
    // getting the folded location is fairly simple - we only have to walk the "top level" folds
    // If the fold is before here, we subtract the size of that fold.  If the fold is after, we're
    // done, and otherwise we are in that fold so use the start of the fold (we don't care about
    // subfolded locations)
    NSUInteger retval = offset;
    for (std::deque<FoldingInfo>::iterator i = fFoldingInfo.begin(); i != fFoldingInfo.end();) {
		if (offset <= (*i).foldingStart) {
			// we are before this fold, so we are done (we don't care about downstream folds
			break;
		} else if (offset >= (*i).foldingStart + (*i).contentsSize) {
			// offset is after this entire folding
			retval -= (*i).contentsSize-1; // we hid N characters inside 1 character
			// skip to next fold at this level
			NextTopLevelFold(i);
		} else {
			// we are in this fold, somewhere
			retval = (*i).foldingStart - (offset - retval);
			break; // and also done
		}
    }
    //NSLog(@"Folded %d as %d",offset,retval);
    return retval;
}

NSRange IDEKit_LineCache::FoldedRange(NSRange range)
{
    NSRange foldedLoc;
    foldedLoc.location = FoldedLocation(range.location);
    foldedLoc.length = FoldedLocation(range.location + range.length) - foldedLoc.location;
    return foldedLoc;
}

NSRange IDEKit_LineCache::UnfoldedRange(NSRange range)
{
    NSRange unfoldedLoc;
    unfoldedLoc.location = UnfoldedLocation(range.location);
    unfoldedLoc.length = UnfoldedLocation(range.location + range.length) - unfoldedLoc.location;
    return unfoldedLoc;
}

void IDEKit_LineCache::ReplaceRangeWithString(NSRange src, NSString *string)
{
    if (src.length)
		RemoveRange(src);
    InsertString(src.location, string);
    MoveFoldings(src, [string length]);
    RebuildFoldedFromUnfolded();
}

void IDEKit_LineCache::RemoveRange(NSRange src)
{
    // these operations update both folded and unfolded, but start by just doing unfolded and rebuild
    if (src.length == 0)
		return;
    if (src.location == 0 && src.length == fTotalFoldedSize) {
		// clear everything shortcut
		fTotalFoldedSize = 0;
		fTotalUnfoldedSize = 0;
		fFoldedLineStarts.clear();
		fFoldedLineStarts.push_back(0);
		fUnfoldedLineStarts.clear();
		fUnfoldedLineStarts.push_back(0);
		ReleaseLineData();
		fUnfoldedLineData.clear();
		fUnfoldedLineData.push_back(0);
		fFoldingInfo.clear();
		return;
    }
    //NSLog(@"Removing range %d-%d",src.location,src.location + src.length);
    src = UnfoldedRange(src);
    // start with first line that begins here
    std::deque<NSUInteger>::iterator p = FindLineStartFromOffset(fUnfoldedLineStarts.begin(), fUnfoldedLineStarts.end(), src.location)+1; // we don't start messing with line starts until the _next_ line
    std::deque<NSMutableDictionary *>::iterator pData = fUnfoldedLineData.begin() + (p - fUnfoldedLineStarts.begin());
    std::deque<NSMutableDictionary *>::iterator iData = pData;
    for (std::deque<NSUInteger>::iterator i = p; i != fUnfoldedLineStarts.end(); i++,iData++) {
		if ((*i) <= src.location) {
			// before what we want to mess with (shouldn't happen if our lower_bound  logic worked correctly)
			p++; // advance p in sync
			pData++;
			//NSLog(@"Line #%d unchanged (shouldn't see this)",i - fUnfoldedLineStarts.begin()+1);
		} else if ((*i) <= src.location + src.length) {
			[(*iData) release];
			(*iData) = NULL;
			// this thing will go away - do nothing with it yet
			//NSLog(@"Line #%d will be removed",i - fUnfoldedLineStarts.begin()+1);
		} else {
			// we are after the deletion point, so start adjusting the coordinates, moving them back
			//NSLog(@"Line #%d moved back by %d",i - fUnfoldedLineStarts.begin()+1,src.length);
			(*p) = (*i) - src.length;
			(*pData) = (*iData); // copy over pdata
			(*iData) = NULL; // this is now empty
			p++; // and advance our "put them here"
			pData++;
		}
    }
    // p is now where we want the new end of the array to be
    fUnfoldedLineStarts.erase(p,fUnfoldedLineStarts.end());
    fUnfoldedLineData.erase(pData,fUnfoldedLineData.end()); // we already released everything that got deleted
    NSCAssert(fUnfoldedLineStarts.size() == fUnfoldedLineData.size(),@"Inconsistent line count (RemoveRange)");
    // update size of both
    fTotalFoldedSize -= src.length;
    fTotalUnfoldedSize -= src.length;
    
}
void IDEKit_LineCache::MoveFoldings(NSRange src, NSInteger replaceSize)
{
    src = UnfoldedRange(src);
    // update the folding info
    std::deque<FoldingInfo>::iterator p = fFoldingInfo.begin(); // we don't start messing with line starts until the _next_ line
    for (std::deque<FoldingInfo>::iterator i = fFoldingInfo.begin(); i != fFoldingInfo.end(); i++) {
		// the fold can either be before the changes (do nothing)
		// entirely after the change (update by delta)
		// entirely within the change (delete)
		// change is entirely within fold (change length) - hopefully never happens
		// overlap the beginning - shouldn't happens (since you can't edit inside the fold)
		// overlap the ending - shouldn't happens (since you can't edit inside the fold)
		if ((*i).foldingStart + (*i).contentsSize <= src.location) {
			// before what we want to mess with
			p++;
		} else if (src.location + src.length <= (*i).foldingStart) {
			// entirely after the change - copy it back and update delta
			(*p) = (*i);
			(*p).foldingStart += replaceSize - src.length;
			p++;
		} else if (src.location <= (*i).foldingStart && (*i).foldingStart + (*i).contentsSize <= src.location + src.length) {
			// delete this (do nothing)
		} else if ((*i).foldingStart <= src.location && src.location + src.length <= (*i).foldingStart + (*i).contentsSize) {
			// change is within fold - normally shouldn't happen (since you can't edit inside a fold yet)
			(*p) = (*i);
			(*p).contentsSize += replaceSize - src.length;
			p++;
		} else {
			NSLog(@"Fold and edit overlap but not nested - how did we edit inside the fold?");
		}
    }
    // p is now where we want the new end of the array to be
    fFoldingInfo.erase(p,fFoldingInfo.end());
}

void IDEKit_LineCache::InsertString(NSUInteger offset, NSString *string)
{
    // these operations update both folded and unfolded, but start by just doing unfolded and rebuild
    if ([string length] == 0)
		return; // nothing to insert
    // again, work in unfolded space
    offset = UnfoldedLocation(offset);
    //NSLog(@"Inserting %d character string at %d",[string length],offset);
    // find the line that starts the same place as where we are inserting
    std::deque<NSUInteger>::iterator p = FindLineStartFromOffset(fUnfoldedLineStarts.begin(), fUnfoldedLineStarts.end(), offset);
    // p is the line that is after the line we insert this string at (since the line start doesn't
    // change until this line)
    // can't use NSAssert from here
    //NSLog(@"Inserts at line %d",p - fUnfoldedLineStarts.begin() + 1);
    // everything after p is offset by stringLength
    NSUInteger stringLength = [string length];
    for (std::deque<NSUInteger>::iterator i = p+1;i!= fUnfoldedLineStarts.end();i++) {
		//NSLog(@"Updating line %d",i - fUnfoldedLineStarts.begin() + 1);
		(*i) += stringLength;
    }
    // at p we will start inserting the lines - for each line, we add another entry with that offset
    if ([string rangeOfString:@"\n"].location != NSNotFound) {
		//NSLog(@"Inserting new line(s)");
		NSUInteger curStart = 0;
		for (curStart=0;curStart<stringLength;) {
			NSUInteger  contentsEnd;
			[string getLineStart: NULL end: &curStart contentsEnd: &contentsEnd forRange:NSMakeRange(curStart,0)];
			if (contentsEnd != curStart) { // we had some sort of termination, so we need to add this line
				NSInteger lineNum = p - fUnfoldedLineStarts.begin();
				fUnfoldedLineStarts.insert(p+1,curStart + offset); // start of next line
				NSDictionary *nullDict = NULL;
				fUnfoldedLineData.insert(fUnfoldedLineData.begin()+lineNum+1,nullDict); // add a blank data here
				//NSLog(@"Insert at line %d (string subpos %d)",lineNum + 1,curStart);
				p = fUnfoldedLineStarts.begin() + lineNum + 1;
			}
		}
    }
    // update size of both
    fTotalFoldedSize += stringLength;
    fTotalUnfoldedSize += stringLength;
    NSCAssert(fUnfoldedLineStarts.size() == fUnfoldedLineData.size(),@"Inconsistent line count (InsertString)");
}

bool IDEKit_LineCache::FoldingInfo::operator < (const IDEKit_LineCache::FoldingInfo &other) const
{
    if (other.foldingStart < foldingStart)
		return false;
    if (other.foldingStart > foldingStart)
		return true;
    // same start, smaller one is "inside" (and this "later")
    return other.contentsSize  > contentsSize;
}
void IDEKit_LineCache::FoldRange(NSRange fold)
{
    // this fold is in folded coordinate space - convert to unfolded
    NSRange unfoldedFold = UnfoldedRange(fold);
    // insert where appropriate
    FoldingInfo newFold = { unfoldedFold.location, unfoldedFold.length };
    std::deque<FoldingInfo>::iterator nextFold = std::lower_bound(fFoldingInfo.begin(), fFoldingInfo.end(), newFold);
    fFoldingInfo.insert(nextFold, newFold);
    fTotalFoldedSize -= fold.length + 1; // replaced the range (in folded space) with a single characer
    RebuildFoldedFromUnfolded(); // and just rebuild
}

void IDEKit_LineCache::UnfoldLocation(NSUInteger offset)
{
    //NSLog(@"Unfold at offset %d (folded coordinate)",offset);
    // this fold is in folded coordinate space - convert to unfolded
    offset = UnfoldedLocation(offset);
    // find the thing, if possible
    FoldingInfo oldFold = { offset, 0 }; // this will be the outermost fold here
    std::deque<FoldingInfo>::iterator oldFoldLoc = std::lower_bound(fFoldingInfo.begin(), fFoldingInfo.end(), oldFold);
    if (oldFoldLoc == fFoldingInfo.end() || (*oldFoldLoc).foldingStart != offset) {
		// not found
		NSLog(@"Couldn't find fold at offset %ld (unfolded coordinate)",offset);
    } else {
		//NSLog(@"Removing fold #%d (loc %d, size %d)",oldFoldLoc - fFoldingInfo.begin(), (*oldFoldLoc).foldingStart, (*oldFoldLoc).contentsSize);
		fTotalFoldedSize += oldFold.contentsSize - 1; // replaced the range with a single characer
		fFoldingInfo.erase(oldFoldLoc);
		RebuildFoldedFromUnfolded(); // and just rebuild
    }
}

void IDEKit_LineCache::RebuildFoldedFromUnfolded()
{
    // folding changed, so rebuild folded coordinate space
    // take shortcut
    if (fFoldingInfo.empty()) { // no folds
		fFoldedLineStarts = fUnfoldedLineStarts;
		fTotalFoldedSize = fTotalUnfoldedSize; // just in case
		return;
    }
    // we iterate through our unfolded line starts, keeping track of what folding we will hit next
    // So long as we haven't hit it, we copy it over (adjusted with the folding delta).
    // When we hit a fold, we skip ahead to the next top level fold, and don't do anything until we
    // get to a line that starts after the end of the current fold
    fFoldedLineStarts.clear();
    bool folded = false;
    std::deque<FoldingInfo>::iterator nextFold = fFoldingInfo.begin();
    NSUInteger skipUntilUnfoldedAt = 0;
    NSInteger foldedDelta = 0;
    // temporarily add in the end of the unfolded and then remove it to get the correct foled
    fUnfoldedLineStarts.push_back(fTotalUnfoldedSize);
    for (std::deque<NSUInteger>::iterator i = fUnfoldedLineStarts.begin(); i != fUnfoldedLineStarts.end(); i++) {
		if (!folded && nextFold != fFoldingInfo.end() && (*i) >= (*nextFold).foldingStart) {
			// we enter a fold
			foldedDelta += (*nextFold).contentsSize - 1;
			skipUntilUnfoldedAt = (*nextFold).foldingStart + (*nextFold).contentsSize;
			NextTopLevelFold(nextFold);
			folded = true;
			//NSLog(@"Starting skip of line at %d",(*i));
		} // we may unfold in the same line, so not "else if"
		if (folded && (*i) >= skipUntilUnfoldedAt) {
			// and here we are now unfolded again
			//NSLog(@"Ending skip of line at %d",(*i));
			folded = false;
		}
		if (!folded) {
			// we are currently unfolded
			fFoldedLineStarts.push_back((*i) - foldedDelta);
			//NSLog(@"Adding line at %d",(*i));
		} else {
			//NSLog(@"Starting skip of line at %d",(*i));
		}
    }
    // the last element of the folded version is the total length
    fTotalFoldedSize = *(fFoldedLineStarts.end()-1);
    // remove those markers
    fUnfoldedLineStarts.pop_back();
    fFoldedLineStarts.pop_back();
    // and that should be it
}

void IDEKit_LineCache::SetLineData(NSDictionary *data)
{
    NSInteger line=1;
    for (std::deque<NSMutableDictionary *>::iterator i = fUnfoldedLineData.begin(); i != fUnfoldedLineData.end(); i++) {
		id lineData = [data objectForKey:[NSNumber numberWithInteger: line]];
		if (lineData) {
			[(*i) release];
			(*i) = [lineData mutableCopy];
		} else {
			// clear it out
			if (*i) {
				[(*i) release];
				(*i) = nil;
			}
		}
		line++;
    }
}

NSMutableDictionary *IDEKit_LineCache::UnfoldedLineData(NSInteger n, bool create)
{
    if (n <= 0) return NULL;
    n--; // convert from 1 based to 0 based
    if (n >= fUnfoldedLineData.size()) return NULL; //n = fUnfoldedLineData.size() - 1;
    NSMutableDictionary *retval = fUnfoldedLineData[n];
    if (!retval && create) {
		fUnfoldedLineData[n] = retval = [[NSMutableDictionary dictionary] retain];
    }
    return retval;
}

NSDictionary *IDEKit_LineCache::GetLineData()
{
    NSInteger line=1;
    NSMutableDictionary * retval = [NSMutableDictionary dictionary];
    for (std::deque<NSMutableDictionary *>::iterator i = fUnfoldedLineData.begin(); i != fUnfoldedLineData.end(); i++) {
		if (*i) {
			[retval setObject:(*i) forKey:[NSNumber numberWithInteger: line]];
		}
		line++;
    }
    return retval;
}

bool IDEKit_LineCache::ValidLineNum(NSInteger lineNum) // these are 1 based
{
    return (1 <= lineNum && lineNum <= fUnfoldedLineStarts.size());
}
