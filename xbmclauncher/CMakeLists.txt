PROJECT(XBMCLauncher)

#
# TODO
# -create a proper Bundle (not a framework, but a module in bundle structure). This doesn't seem to be supported yet
# -put files into it (scripts, etc)
MESSAGE(FATAL_ERROR "XBMCLauncher cmake build not working yet")


#setup build requirements
FIND_LIBRARY(BACKROW_LIBRARY BackRow ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks ../)
IF(NOT BACKROW_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch BackRow not found. Bailing out...")
ENDIF(NOT BACKROW_LIBRARY)
#FIND_LIBRARY(APPKIT_LIBRARY AppKit)
#IF(NOT COCOA_LIBRARY)
# MESSAGE(FATAL_ERROR "Ouch COCOA_LIBRARY not found. Bailing out...")
#ENDIF(NOT COCOA_LIBRARY)

FIND_LIBRARY(BACKROW_LIBRARY BackRow ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks ../)
IF(NOT BACKROW_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch BackRow not found. Bailing out...")
ENDIF(NOT BACKROW_LIBRARY)

#collect sources
SET(XBMCLAUNCHER_SRCS 
	src/XBMCAppliance.m
	src/XBMCAppliance.h
	src/XBMCController.h
	src/XBMCController.m
	src/XBMCPreferencesController.h
	src/XBMCPreferencesController.m
	src/XBMCUserDefaults.h
	src/XBMCUserDefaults.m
	src/helpers/DebugController.h
	src/helpers/DebugController.m
	src/helpers/BackRowCompilerShutup.h
	src/updater/XBMCSimpleDownloader.h
	src/updater/XBMCSimpleDownloader.m
	src/updater/XBMCUpdateBlockingController.h
	src/updater/XBMCUpdateBlockingController.m
	src/updater/XBMCUpdateController.h
	src/updater/XBMCUpdateController.m
	../common/XBMCDebugHelpers.h
	../common/atvxbmccommon.h
	../common/atvxbmccommon.m
)
include_directories(src)

add_library(XBMCLauncher SHARED ${XBMCLAUNCHER_SRCS})
#set various target properties
set_target_properties(XBMCLauncher PROPERTIES 
	FRAMEWORK ON
	SUFFIX	frappliance
	MACOSX_FRAMEWORK_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
	)

		
TARGET_LINK_LIBRARIES(XBMCLauncher ${BACKROW_LIBRARY} ${COCOA_LIBRARY})

#scp to ATV
get_target_property(LAUNCHER_LOCATION XBMCLauncher LOCATION) 
add_custom_target(LauncherBuildAndCopyToATV 
		COMMAND scp -r ${LAUNCHER_LOCATION}.frappliance frontrow@$APPLETV_IP:
		COMMAND ssh frontrow@$APPLETV_IP "echo frontrow | sudo -S /bin/rm -rf /System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance"
		COMMAND ssh frontrow@$APPLETV_IP "echo frontrow | sudo -S /bin/mv /Users/frontrow/XBMCLauncher.frappliance /System/Library/CoreServices/Finder.app/Contents/PlugIns/"
		COMMAND ssh frontrow@$APPLETV_IP restartFinder
        COMMENT "Conveniece scp XBMCLauncher to ATV. See APPLETV_IP cache variable" VERBATIM)
ADD_DEPENDENCIES(LauncherBuildAndCopyToATV XBMCLauncher)
