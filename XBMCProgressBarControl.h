//
//  XBMCProgressBarControl.h
//  XBMCDownloader
//  based on QuDownloader
//  Created by Alan Quatermain on 19/04/07.
//  Copyright 2007 AwkwardTV. All rights reserved.
//
// Updated by nito 08-20-08 - works in 2.x

#import <Foundation/Foundation.h>
#import <BackRow/BRControl.h>
#import <BackRowCompilerShutup.h>

@class BRRenderLayer, BRProgressBarWidget;

@interface XBMCProgressBarControl : BRControl
{
	int padding[16];
	//BRRenderLayer *         _layer;
	BRProgressBarWidget *   _widget;
	float                   _maxValue;
	float                   _minValue;
}

- (id) init;
- (void) dealloc;

- (void) setFrame: (NSRect) frame;
//- (BRRenderLayer *) layer;

- (void) setMaxValue: (float) maxValue;
- (float) maxValue;

- (void) setMinValue: (float) minValue;
- (float) minValue;

- (void) setCurrentValue: (float) currentValue;
- (float) currentValue;

- (void) setPercentage: (float) percentage;
- (float) percentage;

@end
