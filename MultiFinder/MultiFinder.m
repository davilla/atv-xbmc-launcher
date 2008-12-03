//
//  MultiFinder.m
//  atv-xbmc-tools
//
//

#import "MultiFinder.h"
#import "Preferences.h"
#import <XBMCDebugHelpers.h>

@interface MultiFinder (private) 
  - (void) switchStateTo:(eMFState) f_state;
  - (BOOL) launchApplication;
  - (void) startApplicationRequest:(NSNotification *)notification;
@end


@implementation MultiFinder
+ (void) initialize{
  PRINT_SIGNATURE();
  NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
  //set the default app
  [defaultValues setObject:@"/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder" forKey:kMFDefaultApp];
  //and it's IR mode
  [defaultValues setObject:[NSNumber numberWithInt:MFAPP_IR_MODE_NONE] forKey:kMFDefaultAppIRMode];
  //maximum app startup retry count
  [defaultValues setObject:[NSNumber numberWithInt:3] forKey:kMFAppLaunchMaxRetryCount];

  //register the dictionary of defaults
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
  ILOG(@"registered defaults: %@", defaultValues);
}

//--------------------------------------------------------------
- (id) init{
  PRINT_SIGNATURE();
  if( ![super init] )
    return nil;

  //get ir_helper path
  mp_ir_helper_path = [[[NSBundle bundleForClass:[self class]] pathForResource:@"xbmchelper" ofType:@""] retain];
  
  //register cross-app-notification listeners
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startApplicationRequest:) name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  
  //switch to unitialized state
  [self switchStateTo:MF_STATE_UNINITIALIZED];
  return self;
}

//--------------------------------------------------------------
- (void) dealloc{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  [mp_ir_helper_path release];
  [super dealloc];
}

//--------------------------------------------------------------
- (void)checkTaskStatus:(NSNotification *)note
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  PRINT_SIGNATURE();
  if( mp_task && ![mp_task isRunning] ){
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:mp_task];
    //kill helper and release task object
    [mp_ir_helper terminate];
    [mp_ir_helper release];
    mp_ir_helper = nil;
    
    //print some status and release task object
    int status = [[note object] terminationStatus];
    ILOG(@"App exited with status %i", status);
    //depending on current state and exit status we may launch different stuff
    [mp_task release];
		mp_task = nil;
    
    if(m_state == MF_STATE_DEFAULT_APP || m_state == MF_STATE_USER_APP){
      switch(status){
        case 0:
          [self switchStateTo:MF_STATE_DEFAULT_APP];
          break;
        case 66:
          DLOG(@"App wants us to restart ATV. Don't do this for now, but start Finder");
          [self switchStateTo:MF_STATE_SAFE_MODE];
          break;
        case 65:
          //TODO: need to set mp_next_app_to_launch before switching back to current state
          //[self switchStateTo:m_state];
          DLOG(@"App wants to be restarted. Implement me!");
          break;
        default:
          ELOG(@"App exited with status: %i", status);
      }
    } else {
      [self switchStateTo:MF_STATE_DEFAULT_APP];
    }
  }
  [pool release];
}

//--------------------------------------------------------------
- (BOOL) launchApplication {
  PRINT_SIGNATURE();
  DLOG(@"Trying to launch app %@ with IRMode: %i", mp_next_app_to_launch, m_next_app_ir_mode);
  if(!mp_next_app_to_launch){
    ELOG(@"launchApplication called without setting mp_next_app_to_launch first");
    return FALSE;
  }
	mp_task = [[NSTask alloc] init];
	@try {
		[mp_task setLaunchPath: mp_next_app_to_launch];
    [mp_task setCurrentDirectoryPath:@"/Applications"];
		[mp_task launch];
	} 
	@catch (NSException* e) {
    ELOG(@"Could not launch application %@", mp_next_app_to_launch);
    [mp_task release];
    mp_task = nil;
    return FALSE;
	}
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
  //check if app needs IR helper and maybe start it
  if(m_next_app_ir_mode != MFAPP_IR_MODE_NONE){
    NSMutableArray* args = [NSMutableArray array];
#ifdef DEBUG
    [args addObject:@"-v"];
#endif
    bool ir_launch_success = true;
    if(m_next_app_ir_mode == MFAPP_IR_MODE_UNIVERSAL)
      [args addObject:@"-u"];
  	@try {
      mp_ir_helper = [[NSTask launchedTaskWithLaunchPath:mp_ir_helper_path arguments: args] retain];
    } @catch (NSException* e) {
      ir_launch_success = false;
    }   
    if(!ir_launch_success || !mp_ir_helper){
      ELOG(@"Could not launch IR-Helper %@", mp_ir_helper_path);
      [mp_task terminate];
      [mp_task release];
      mp_task = nil;
      [mp_ir_helper release];
      mp_ir_helper = nil;
      return FALSE;      
    }
  }
  //attach our listener
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkTaskStatus:)
                                               name:NSTaskDidTerminateNotification
                                             object:mp_task];
  //now reset the variables
  [mp_next_app_to_launch release];
  mp_next_app_to_launch = nil;
  m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
  return TRUE;
}

//--------------------------------------------------------------
- (void) startApplicationRequest:(NSNotification *)notification {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSDictionary* userInfo = [notification userInfo];
  //set next app to launch
  mp_next_app_to_launch = [[userInfo objectForKey:kApplicationPath] retain];
  if( !mp_next_app_to_launch)
    ELOG(@"Ouch something went wrong. Got a request to start an app, but no app was given!");
  //does it need IR?
  if( [[userInfo objectForKey:kApplicationNeedsIR] boolValue] ){
    if([userInfo objectForKey:kApplicationWantsUniversalIRMode] && [[userInfo objectForKey:kApplicationWantsUniversalIRMode] boolValue])
      m_next_app_ir_mode = MFAPP_IR_MODE_UNIVERSAL;
    else 
      m_next_app_ir_mode = MFAPP_IR_MODE_NORMAL;
  } else {
    m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
  }
  DLOG(@"Got an start application request for app %@ withRemote:%i", mp_next_app_to_launch, m_next_app_ir_mode);
  [self switchStateTo:MF_STATE_USER_APP];
  [pool release];
}

//--------------------------------------------------------------
- (void) switchStateTo:(eMFState) f_state {
  DLOG(@"Request to change state from %i to %i", m_state, f_state);
  //first do stuff for state exit 
  switch(m_state){
    case MF_STATE_UNINITIALIZED:
      //nothing todo on state exit
      break;
    case MF_STATE_SAFE_MODE:
    case MF_STATE_DEFAULT_APP:      
    case MF_STATE_USER_APP:
      [mp_task terminate];
      [mp_task release];
      mp_task = nil;
      [mp_ir_helper terminate];
      [mp_ir_helper release];
      mp_ir_helper = nil;
      break;
  }
  //switch state
  m_state = f_state;
  // do stuff needed onEntry of this state
  switch(m_state){
    case MF_STATE_UNINITIALIZED:
      //kill all running stuff
      //switch to default_app-state
      [self switchStateTo:MF_STATE_DEFAULT_APP];
      break;
    case MF_STATE_SAFE_MODE:
    {
      //try forever to launch finder 
      mp_next_app_to_launch = @"/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder";
      m_next_app_ir_mode = MFAPP_IR_MODE_NONE;
      while(![self launchApplication]){}
      break;
    } //case MF_STATE_SAFE_MODE
    case MF_STATE_DEFAULT_APP:
    {
      //get needed stuff for app launching
      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
      mp_next_app_to_launch = [[defaults objectForKey:kMFDefaultApp] retain];
      m_next_app_ir_mode = [defaults integerForKey:kMFDefaultAppIRMode] ;
      const int MAX_RETRIES = [defaults integerForKey:kMFAppLaunchMaxRetryCount];
      
      //try to launch the app
      int retry_count;
      bool success;
      for(retry_count = 0; retry_count < MAX_RETRIES; ++retry_count){
        success = [self launchApplication];
        if(success)
          break;
      }
      if(!success){
        [self switchStateTo:MF_STATE_SAFE_MODE];
      }
      break;
    } //case MF_STATE_DEFAULT_APP
    case MF_STATE_USER_APP:
    {
      //get needed stuff for app launching
      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
      const int MAX_RETRIES = [defaults integerForKey:kMFAppLaunchMaxRetryCount];
      //try to launch user application
      assert(mp_next_app_to_launch);
      int retry_count;
      bool success;
      for(retry_count = 0; retry_count < MAX_RETRIES; ++retry_count){
        success = [self launchApplication];
        if(success)
          break;
      }
      if(!success){
        [self switchStateTo:MF_STATE_SAFE_MODE];
      }
      break;
    } //case MF_STATE_USER_APP
  }
}
@end
