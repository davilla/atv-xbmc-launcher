#ifndef ATVXBMCCOMMON_H
#define ATVXBMCCOMMON_H
#import <Foundation/Foundation.h>

extern NSString* MULTIFINDER_START_APPLICATION_NOTIFICATION;
extern NSString* MULTIFINDER_CHANGE_DEFAULT_APPLICATION_NOTIFICATION;
extern NSString* kApplicationPath;
extern NSString* kApplicationArguments;
extern NSString* kApplicationNeedsIR;
extern NSString* kApplicationWantsUniversalIRMode;
extern NSString* FINDER_PATH; //path to Finder's executable used throughout this project

typedef enum{
  MFAPP_IR_MODE_NONE = 0,
  MFAPP_IR_MODE_NORMAL,
  MFAPP_IR_MODE_UNIVERSAL
} eMultiFinderAppIRMode;

#endif