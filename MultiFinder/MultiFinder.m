//
//  MultiFinder.m
//  atv-xbmc-tools
//
//

#import "MultiFinder.h"

//--------------------------------------------------------------
@implementation MultiFinder

- (id) init{
  if( ![super init] )
    return nil;
  mp_next_app_to_launch = nil;
  m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
  mp_default_app = @"/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder";
  m_default_app_ir_mode = MFAPP_IR_MODE_NONE;
  
  mp_ir_helper_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"xbmchelper" ofType:@""];
  NSLog(@"App status callback %@", mp_ir_helper_path);
  //register cross-app-notification listeners
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startApplicationRequest:) name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  //by default launch Finder
  [self launchApplication:mp_default_app];
  return self;
}

//--------------------------------------------------------------
- (void) dealloc{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  [super dealloc];
}

//--------------------------------------------------------------
- (void)checkTaskStatus:(NSNotification *)note
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:mp_task];
  NSLog(@"App status callback");
  if( ! [mp_task isRunning] ){
    //kill helper and release task object
    [mp_ir_helper terminate];
    [mp_ir_helper release];
    mp_ir_helper = nil;
    
    //print some status and release task object
    int status = [[note object] terminationStatus];
    NSLog(@"App exited with status %i", status);
		[mp_task release];
		mp_task = nil;
    
    if( mp_next_app_to_launch ){
      NSLog(@"Looks like killed by request. Starting app %@ with IR:%i", mp_next_app_to_launch, m_next_app_ir_mode);
      [self launchApplication:mp_next_app_to_launch];
    }
    else {
      NSLog(@"No app given. Starting default app %@ with IR:%i", mp_default_app, m_default_app_ir_mode);
      m_next_app_ir_mode = m_default_app_ir_mode;
      [self launchApplication:mp_default_app];    
    }
  }
  [pool release];
}

//--------------------------------------------------------------
- (BOOL) launchApplication:(NSString*) f_app_path {
	mp_task = [[NSTask alloc] init];
	@try {
		[mp_task setLaunchPath: f_app_path];
    [mp_task setCurrentDirectoryPath:@"/Applications"];
		[mp_task launch];
	} 
	@catch (NSException* e) {
    NSLog(@"Could not launch application %@", f_app_path);
    return FALSE;
	}
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:mp_task];
  if(m_next_app_ir_mode != MFAPP_IR_MODE_NONE){
    NSMutableArray* args = [NSMutableArray array];
#ifdef DEBUG
    [args addObject:@"-v"];
#endif
    if(m_next_app_ir_mode == MFAPP_IR_MODE_UNIVERSAL)
      [args addObject:@"-u"];
    mp_ir_helper = [[NSTask launchedTaskWithLaunchPath:mp_ir_helper_path arguments: args] retain];    
  }
  //now reset the variables
  [mp_next_app_to_launch release];
  mp_next_app_to_launch = nil;
  m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
  return TRUE;
}

//--------------------------------------------------------------
- (void) startApplicationRequest:(NSNotification *)notification {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"Got an start application request");
  NSDictionary* userInfo = [notification userInfo];
  //set next app to launch
  mp_next_app_to_launch = [[userInfo objectForKey:kApplicationPath] retain];
  if( !mp_next_app_to_launch)
    NSLog(@"Ouch something went wrong. Got a request to start an app, but no app was given!");
  //does it need IR?
  if( [[userInfo objectForKey:kApplicationNeedsIR] boolValue] ){
    if([userInfo objectForKey:kApplicationWantsUniversalIRMode] && [[userInfo objectForKey:kApplicationWantsUniversalIRMode] boolValue])
      m_next_app_ir_mode = MFAPP_IR_MODE_UNIVERSAL;
    else 
      m_next_app_ir_mode = MFAPP_IR_MODE_NORMAL;
  } else {
    m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
  }
  NSLog(@"Request for app %@ withRemote:%i", mp_next_app_to_launch, m_next_app_ir_mode);
  //kill current app
  [mp_task terminate];
  [pool release];
}
@end
