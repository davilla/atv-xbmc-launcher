#import <Cocoa/Cocoa.h>
#import <sys/types.h>
#import <sys/sysctl.h>

#import "osdetection.h"

bool g_initialized = false;
OS_Vers g_os_version = kOSUnknown;
HW_Vers g_hw_version = kHWUnknown;
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
static void initOSAndHWVersion() {
	// Runtime Version Check
  SInt32      MacVersion;
  
  Gestalt(gestaltSystemVersion, &MacVersion);
  if (MacVersion < 0x1050) {
    // OSX 10.4/AppleTV
    size_t      len = 512;
    char        hw_model[512] = "unknown";
    
    sysctlbyname("hw.model", &hw_model, &len, NULL, 0);

    if ( strstr(hw_model,"AppleTV1,1") ) {
      FILE        *inpipe;
      BOOL        atv_version_found = NO;
    
      g_hw_version = kATVversion;
      //Find the build version of the AppleTV OS
      inpipe = popen("sw_vers -buildVersion", "r");
      if (inpipe) {
          char linebuf[1000];
          //get output
          if(fgets(linebuf, sizeof(linebuf) - 1, inpipe)) {
              if( strstr(linebuf,"8N5107") ) {
                  g_os_version = kATV_1_00;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r1.0");
              } else if( strstr(linebuf,"8N5239") )  {
                  g_os_version = kATV_1_10;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r1.1");
              } else if ( strstr(linebuf,"8N5400") ) {
                  g_os_version = kATV_2_00;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.0");
              } else if ( strstr(linebuf,"8N5455") ) {
                  g_os_version = kATV_2_01;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.01");
              } else if ( strstr(linebuf,"8N5461") ) {
                  g_os_version = kATV_2_02;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.02");
                  atv_version_found = YES;
              } else if( strstr(linebuf,"8N5519")) {
                  g_os_version = kATV_2_10;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.10");
                  atv_version_found = YES;
              } else if( strstr(linebuf,"8N5622")) {
                  g_os_version = kATV_2_20;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.20");
                  atv_version_found = true;
              } else if( strstr(linebuf,"8N5722")) {
                  g_os_version = kATV_2_30;
                  atv_version_found = YES;
                  NSLog(@"Found AppletTV software version r2.30");
              }                    
          }
          pclose(inpipe); 
      }
      
      if(! atv_version_found) {
          // handle fallback or just exit
          g_os_version = kATV_2_30;
          NSLog(@"AppletTV software version could not be determined");
          NSLog(@"Defaulting to AppleTV r2.3");
      }
    } else {
      // OSX 10.4.x Tiger
      g_hw_version = kOSXversion;
      g_os_version = kOSX_10_4;
      NSLog(@"Found OSX 10.4 Tiger");
    }
  } else {
    g_hw_version = kOSXversion;
    g_os_version = kOSX_10_5;
    // OSX 10.5.x Leopard
    NSLog(@"Found OSX 10.5 Leopard");
  }
  
  g_initialized = true;
}

//----------------------------------------------------------------------------
OS_Vers getOSVersion() {
  if(! g_initialized) {
    initOSAndHWVersion();
  }
  
  return g_os_version;
}

//----------------------------------------------------------------------------
HW_Vers getHWVersion() {
  if(! g_initialized) {
    initOSAndHWVersion();
  }
  
	return g_hw_version;
}