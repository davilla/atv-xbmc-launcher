/*
 *  BoxeeClient.cpp
 *  BoxeeLauncher
 *
 *  Created by Stephan Diederich on 17.09.08.
 *  Copyright 2008 Stephan Diederich. All rights reserved.
 *
 */
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

typedef enum{
	ATV_BUTTON_PLAY=0,
	ATV_BUTTON_PLAY_H, //atm it looks like we can't intercept that button/event
	ATV_BUTTON_RIGHT,
	ATV_BUTTON_RIGHT_H,
	ATV_BUTTON_LEFT,
	ATV_BUTTON_LEFT_H,
	ATV_BUTTON_UP_PRESS,
	ATV_BUTTON_UP_RELEASE,
	ATV_BUTTON_DOWN_PRESS,
	ATV_BUTTON_DOWN_RELEASE,
	ATV_BUTTON_MENU,
	ATV_BUTTON_MENU_H
} eATVClientEvent;

@class BoxeeClientWrapperImpl;

@interface BoxeeClientWrapper : NSObject{
	BoxeeClientWrapperImpl* mp_impl;
}

-(void) handleEvent:(eATVClientEvent) f_event;

@end