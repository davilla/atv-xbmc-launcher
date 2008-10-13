/*
 *  xbmcclient.cpp
 *  xbmclauncher
 *
 *  Created by Stephan Diederich on 17.09.08.
 *  Copyright 2008 University Heidelberg. All rights reserved.
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

#include "xbmcclientwrapper.h"
#include "xbmcclient.h"
#include "XBMCDebugHelpers.h"
#include <map>

//typedef is here, as is seems that I can't put it into iterface declaration
//CPacketBUTTON is a pointer, as I'm not sure how well it's copy constructor is implemented
typedef std::map<eATVClientEvent, CPacketBUTTON*> tEventMap;

@interface  XBMCClientWrapperImpl : NSObject{
	tEventMap* mp_event_map;
	int					m_socket;	
	NSString*		mp_adress;
}
- (id) initWithServerAdress:(NSString*) fp_adress;
- (void) handleEvent:(eATVClientEvent) f_event;
- (void) populateEventMap;
@end;

@implementation XBMCClientWrapperImpl

-(id) init{
	return [self initWithServerAdress:@"localhost"];
}

-(id) initWithServerAdress:(NSString*) fp_adress{
	PRINT_SIGNATURE();
	if ( ![super init] )
		return nil;
	
	mp_adress = [fp_adress retain];
	mp_event_map = new tEventMap;
	[self populateEventMap];
	//open udp port etc
	m_socket = socket(AF_INET, SOCK_DGRAM, 0);
	if (m_socket < 0)
	{
		ELOG(@"Error opening UDP socket! error: ", errno);
		//TODO What to do?
	}
	return self;
}

-(void) dealloc{
	PRINT_SIGNATURE();
	[mp_adress release];
	delete mp_event_map;
	[super dealloc];
}

-(void) handleEvent:(eATVClientEvent) f_event{	
	tEventMap::iterator it = mp_event_map->find(f_event);
	if(it == mp_event_map->end()){
		ELOG(@"XBMCClientWrapperImpl::handleEvent: No mapping defined for event %i", f_event);	
		return;
	}
	CPacketBUTTON& packet = *(it->second);
	CAddress addr([mp_adress cString]);
	packet.Send(m_socket, addr);
	
}

- (void) populateEventMap{
	tEventMap& lr_map = *mp_event_map;
  
	lr_map.insert(std::make_pair(ATV_BUTTON_PLAY,          new CPacketBUTTON(5, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_RIGHT,         new CPacketBUTTON(4, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_RIGHT_RELEASE, new CPacketBUTTON(4, "JS0:AppleRemote", BTN_UP | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_LEFT,          new CPacketBUTTON(3, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT| BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_LEFT_RELEASE,  new CPacketBUTTON(3, "JS0:AppleRemote", BTN_UP | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_MENU,          new CPacketBUTTON(6, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_MENU_H,        new CPacketBUTTON(8, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_UP,            new CPacketBUTTON(1, "JS0:AppleRemote", BTN_DOWN  | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_UP_RELEASE,    new CPacketBUTTON(1, "JS0:AppleRemote", BTN_UP  | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_DOWN,          new CPacketBUTTON(2, "JS0:AppleRemote", BTN_DOWN | BTN_QUEUE)));
	lr_map.insert(std::make_pair(ATV_BUTTON_DOWN_RELEASE,  new CPacketBUTTON(2, "JS0:AppleRemote", BTN_UP | BTN_QUEUE)));
	
	// only present on ATV <= 2.1
	lr_map.insert(std::make_pair(ATV_BUTTON_RIGHT_H, new CPacketBUTTON(10, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));	
	lr_map.insert(std::make_pair(ATV_BUTTON_LEFT_H,  new CPacketBUTTON(11, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
	
	// only present on atv >= 2.2
	lr_map.insert(std::make_pair(ATV_BUTTON_PLAY_H,  new CPacketBUTTON(7, "JS0:AppleRemote", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE)));
}
@end;


@implementation XBMCClientWrapper
-(id) init{
	PRINT_SIGNATURE();
	if( ![super init] )
		return nil; 
	mp_impl = [[XBMCClientWrapperImpl alloc] initWithServerAdress:@"localhost"];
	return self;
}

- (void)dealloc{
	PRINT_SIGNATURE();
	[mp_impl release];
	[super dealloc];
}

-(void) handleEvent:(eATVClientEvent) f_event{
	[mp_impl handleEvent:f_event];
}
@end
