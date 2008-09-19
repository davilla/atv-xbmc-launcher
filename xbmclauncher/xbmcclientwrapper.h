/*
 *  xbmcclient.cpp
 *  xbmclauncher
 *
 *  Created by Stephan Diederich on 17.09.08.
 *  Copyright 2008 University Heidelberg. All rights reserved.
 *
 */

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

@class XBMCClientWrapperImpl;

@interface XBMCClientWrapper : NSObject{
	XBMCClientWrapperImpl* mp_impl;
}

-(void) handleEvent:(eATVClientEvent) f_event;

@end