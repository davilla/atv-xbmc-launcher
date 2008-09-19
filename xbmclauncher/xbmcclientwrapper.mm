/*
 *  xbmcclient.cpp
 *  xbmclauncher
 *
 *  Created by Stephan Diederich on 17.09.08.
 *  Copyright 2008 University Heidelberg. All rights reserved.
 *
 */

#include "xbmcclientwrapper.h"
#include "xbmcclient.h"
#include <iostream>
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
	NSLog(@"XBMCClientImpl initWithServerAdress");
	if ( ![super init] )
		return nil;
		
	mp_adress = fp_adress;
	mp_event_map = new tEventMap;
	[self populateEventMap];
	[fp_adress retain];		
	//open udp port etc
	m_socket = socket(AF_INET, SOCK_DGRAM, 0);
	if (m_socket < 0)
	{
		std::cerr << "Error opening UDP socket! error: " <<  errno << std::endl;
		//TODO What to do?
	}
	return self;
}

-(void) dealloc{
	NSLog(@"XBMCClientImpl dealloc");
	[mp_adress retain];
	delete mp_event_map;
	[super dealloc];
}

-(void) handleEvent:(eATVClientEvent) f_event{	
	tEventMap::iterator it = mp_event_map->find(f_event);
	if(it == mp_event_map->end()){
		NSLog(@"XBMCClientWrapperImpl::handleEvent: Unknown event!");	
		return;
	}
	CPacketBUTTON& packet = *(it->second);
	CAddress addr([mp_adress cString]);
	packet.Send(m_socket, addr);

}

- (void) populateEventMap{
	tEventMap& lr_map = *mp_event_map;
	lr_map[ATV_BUTTON_PLAY] = new CPacketBUTTON("Select", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_RIGHT] = new CPacketBUTTON("Right", "R1", BTN_DOWN  | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_RIGHT_H] = new CPacketBUTTON("Right", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_LEFT] = new CPacketBUTTON("Left",  "R1", BTN_DOWN  | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_LEFT_H] = new CPacketBUTTON("Left", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_MENU] = new CPacketBUTTON("Menu", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
	// Menu Hold will be used both for sending "Back" and for starting universal remote combinations (if universal mode is on)
	lr_map[ATV_BUTTON_MENU_H] = new CPacketBUTTON("Back", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_UP_PRESS] = new CPacketBUTTON("Up", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
//	lr_map[ATV_BUTTON_UP_RELEASE] = new CPacketBUTTON("Up", "R1", BTN_UP | BTN_NO_REPEAT | BTN_QUEUE);
	lr_map[ATV_BUTTON_DOWN_PRESS] = new CPacketBUTTON("Down", "R1", BTN_DOWN | BTN_NO_REPEAT | BTN_QUEUE);
//	lr_map[ATV_BUTTON_DOWN_RELEASE] = new CPacketBUTTON("Down", "R1", BTN_UP | BTN_NO_REPEAT | BTN_QUEUE);
	//TODO
	//ATV_BUTTON_PLAY_H, //atm it looks like we can't intercept that button/event
	
}
@end;


@implementation XBMCClientWrapper
-(id) init{
	NSLog(@"XBMCClient init...");
	if( ![super init] )
		return nil; 
	mp_impl = [[XBMCClientWrapperImpl alloc] initWithServerAdress:@"localhost"];
	return self;
}

- (void)dealloc{
	NSLog(@"XBMCClient deallocating...");
	[mp_impl release];
	[super dealloc];
}

-(void) handleEvent:(eATVClientEvent) f_event{
	[mp_impl handleEvent:f_event];
}
@end