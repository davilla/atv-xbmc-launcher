PROJECT(xbmchelper)

SET(XBMCHELPER_SRCS 
	main.mm
	xbmcclientwrapper.h 
	xbmcclientwrapper.mm 
	xbmcclient.h
	XBMCDebugHelpers.h
	XBMCHelper.h
	XBMCHelper.m
	remotecontrolwrapper/AppleRemote.h
	remotecontrolwrapper/AppleRemote.m
	remotecontrolwrapper/HIDRemoteControlDevice.h
	remotecontrolwrapper/HIDRemoteControlDevice.m
	remotecontrolwrapper/RemoteControl.h
	remotecontrolwrapper/RemoteControl.m
	)

INCLUDE_DIRECTORIES(../xbmclauncher/src/remote ../xbmclauncher/src/helpers)

FIND_LIBRARY(FOUNDATION_LIBRARY Foundation)
IF(NOT FOUNDATION_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch Foundation not found. Bailing out...")
ENDIF(NOT FOUNDATION_LIBRARY)
FIND_LIBRARY(IOKIT_LIBRARY IOKit)
IF(NOT IOKIT_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch IOKit not found. Bailing out...")
ENDIF(NOT IOKIT_LIBRARY)
FIND_LIBRARY(COCOA_LIBRARY Cocoa)
IF(NOT COCOA_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch Cocoa not found. Bailing out...")
ENDIF(NOT COCOA_LIBRARY)
FIND_LIBRARY(CARBON_LIBRARY Carbon)
IF(NOT CARBON_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch Carbon not found. Bailing out...")
ENDIF(NOT CARBON_LIBRARY)
FIND_LIBRARY(BACKROW_LIBRARY BackRow ../)
IF(NOT BACKROW_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch BackRow not found. Bailing out...")
ENDIF(NOT BACKROW_LIBRARY)
add_executable(xbmchelper ${XBMCHELPER_SRCS})
TARGET_LINK_LIBRARIES(xbmchelper ${FOUNDATION_LIBRARY} ${IOKIT_LIBRARY} ${COCOA_LIBRARY} ${CARBON_LIBRARY})
