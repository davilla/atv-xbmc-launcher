#ifndef __OSDETECTION_H__
#define __OSDETECTION_H__

typedef enum _HW_Vers {
  kHWUnknown = 0,
  kOSXversion,
  kATVversion
} HW_Vers;

typedef enum _OS_Vers {
  kOSUnknown  = 0,
	kOSX_10_5 = 1050,
	kOSX_10_4 = 1040,
	kATV_1_00 =  100,
	kATV_1_10 =  101,
	kATV_2_00 =  200,
	kATV_2_01 =  201,
	kATV_2_02 =  202,
	kATV_2_10 =  210,
	kATV_2_20 =  220,
	kATV_2_30 =  230,
} OS_Vers;

OS_Vers getOSVersion();
HW_Vers getHWVersion();

#endif
