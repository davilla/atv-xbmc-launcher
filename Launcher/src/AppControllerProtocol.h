//
//  AppControllerProtocol.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 21.02.10.
//  Copyright 2010 Stephan Diederich. All rights reserved.
//


@protocol AppControllerProtocol

- (id) initWithAppPath:(NSString*) appPath   //path to app to launch
             arguments:(NSArray*) args        //arguments for that app
        userDictionary:(NSDictionary*) dict; //additional info's given

@end
