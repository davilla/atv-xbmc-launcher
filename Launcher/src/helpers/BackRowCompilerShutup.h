/*
 *  BackRowCompilerShutup.h
 *  xbmclauncher
 *
 *  Created by Stephan Diederich on 30.09.08.
 *  Copyright 2008 University Heidelberg. All rights reserved.
 *
 *  File is here to keep compiler happy. Those methods exist, but don't show up in class dump. How come?
 *
 */
#import <BackRow/BackRow.h>

@interface BRControl (compat)

-(void) setFrame:(NSRect) f_rect;
-(NSRect)frame;

@end

@interface BRTextControl (compat)

-(id) text;
-(void) setFrame:(CGRect) f_rect;

@end

@interface BRSettingsFacade (compat)
- (int) screenSaverTimeout;
- (void) setScreenSaverTimeout:(int) f_timeout;
@end

@interface BREvent (compat)
- (unsigned short)page;
- (unsigned short)usage;
@end