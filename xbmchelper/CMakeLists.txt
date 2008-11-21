cmake_minimum_required(VERSION 2.6)

PROJECT(xbmchelper)
set(CMAKE_OSX_SYSROOT /Developer/SDKs/MacOSX10.4u.sdk)

SET(XBMCHELPER_SRCS 
	main.mm
	../xbmclauncher/src/remote/xbmcclientwrapper.h 
	../xbmclauncher/src/remote/xbmcclientwrapper.mm 
	../xbmclauncher/src/remote/xbmcclient.h
	../xbmclauncher/src/helpers/XBMCDebugHelpers.h
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
FIND_LIBRARY(IOKIT_LIBRARY IOKit)
FIND_LIBRARY(COCOA_LIBRARY Cocoa)
FIND_LIBRARY(CARBON_LIBRARY Carbon)
add_executable(xbmchelper ${XBMCHELPER_SRCS})
TARGET_LINK_LIBRARIES(xbmchelper ${FOUNDATION_LIBRARY} ${IOKIT_LIBRARY} ${COCOA_LIBRARY} ${CARBON_LIBRARY})
