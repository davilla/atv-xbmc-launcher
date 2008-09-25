//
//  XBMCUpdateController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCUpdateController : BRCenteredMenuController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	NSURL * mp_url; //url where to get udaters plist from
	NSMutableArray* mp_items; //list items
	NSMutableArray*	mp_updates; //list with entries what updates/downloads we offer 
}
- (id) initWithURL:(NSURL*) fp_url;
@end
