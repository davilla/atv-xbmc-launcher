//
//  DebugController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 23.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "DebugController.h"


//stuff from  CGSPrivate.h 
typedef UInt32 CGSConnectionRef;
typedef UInt32 CGSWindowRef;
typedef int    CGSWindow;
typedef enum _CGSWindowOrderingMode {
	kCGSOrderAbove                =  1, // Window is ordered above target.
	kCGSOrderBelow                = -1, // Window is ordered below target.
	kCGSOrderOut                  =  0  // Window is removed from the on-screen window list.
} CGSWindowOrderingMode;
CG_EXTERN CGError CGSGetConnectionIDForPSN(UInt32 inParam1,
																					 ProcessSerialNumber* inPSN, CGSConnectionRef* outConnectionRef);

CG_EXTERN CGError CGSGetOnScreenWindowCount(CGSConnectionRef
																						inCurrentConnectionRef, CGSConnectionRef inTargetConnectionRef, UInt32*
																						outWindowCount);

CG_EXTERN CGError CGSGetOnScreenWindowList(CGSConnectionRef
																					 inCurrentConnectionRef, CGSConnectionRef inTargetConnectionRef, UInt32
																					 inMaxWindowRefs, CGSWindowRef* outWindowRefList, UInt32*
																					 outWindowRefListCount);
CG_EXTERN OSStatus CGSGetWindowAlpha(CGSConnectionRef cid, const CGSWindow wid, float* alpha);
CG_EXTERN OSStatus CGSSetWindowAlpha(CGSConnectionRef cid, const CGSWindow wid, float alpha);
extern OSStatus CGSOrderWindow(CGSConnectionRef cid, const CGSWindow wid, 
															 CGSWindowOrderingMode place, CGSWindow relativeToWindowID /* can be NULL */);   
extern OSStatus CGSGetWindowLevel(CGSConnectionRef cid, CGSWindow wid, 
																	int *level);
																	
																	
@implementation DebugController



-(void) wasPushed
{
	CGError err = 0;
	UInt32 count = 0;
	UInt32 connectionID = 0;
	ProcessSerialNumber psn = {kNoProcess, kNoProcess};
	UInt32 myConnectionID = 0;
	ProcessSerialNumber myPSN = {kNoProcess, kNoProcess};
	
	// get our connection id.  From looking at other hacks
	//  I believe you can do this part another way.
	GetCurrentProcess(&myPSN);
	err = CGSGetConnectionIDForPSN(0, &myPSN, &myConnectionID);
	
	// walk the process list
	err = GetNextProcess(&psn);
	//	myConnectionID = connectionID = _CGSDefaultConnection();
	while( err == noErr ) {
		err = CGSGetConnectionIDForPSN(0, &psn, &connectionID);
		NSLog(@"psid %i", psn);	
		if( err == noErr ) {
			err = CGSGetOnScreenWindowCount( myConnectionID, connectionID, &count);
			NSLog(@"found %o windows", count);
			if( (err == noErr) && (count > 0) ) {
				UInt32* ids = (UInt32*)calloc(count, sizeof(UInt32));
				UInt32 actualIDs = 0;
				UInt32 i = 0;
				err = CGSGetOnScreenWindowList(myConnectionID, connectionID, count, ids, &actualIDs);
				
				for(i = 0; i < actualIDs; i++) {
					NSLog(@"windowid: %i", ids[i]);
					float alpha;
					err = CGSGetWindowAlpha(myConnectionID, ids[i], &alpha);
					if( err != noErr){
						NSLog(@"erred getting windows alpha");
					}
					NSLog(@"hasAlpha: %i", alpha);
					err = CGSSetWindowAlpha(myConnectionID, ids[i], 1.);
					if( err != noErr){
						NSLog(@"erred setting windows alpha");
					}
					err = CGSGetWindowAlpha(myConnectionID, ids[i], &alpha);
					if( err != noErr){
						NSLog(@"erred getting windows alpha");
					}
					NSLog(@"nowHasAlpha: %i", alpha);										
					int level;
					err = CGSGetWindowLevel(myConnectionID, ids[i], &level);
					if( err != noErr){
						NSLog(@"erred getting windows level");
					}					
					NSLog(@"hasWindowLevel: %i", level);
					err = CGSOrderWindow(myConnectionID, ids[i],kCGSOrderOut , 0);   
					if( err != noErr){
						NSLog(@"erred setting window order");
					}					
				}
				free(ids);
			}
		}
		err = GetNextProcess(&psn);
	}
}

-(BOOL) recreateOnReselect
{
	return TRUE;
}

@end