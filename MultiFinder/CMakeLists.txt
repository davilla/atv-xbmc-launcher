PROJECT(MultiFinder)

SET(MULTIFINDER_SRCS 
	multifinder_main.mm
	MultiFinder.h
	MultiFinder.m
	Preferences.h
	Preferences.m
	../common/atvxbmccommon.h
	../common/atvxbmccommon.m
	../common/XBMCDebugHelpers.h
)

#collect needed libs
FIND_LIBRARY(FOUNDATION_LIBRARY Foundation)
IF(NOT FOUNDATION_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch Foundation not found. Bailing out...")
ENDIF(NOT FOUNDATION_LIBRARY)
FIND_LIBRARY(APPLETV_LIBRARY AppleTV ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks ../)
IF(NOT APPLETV_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch AppleTV not found. Bailing out...")
ENDIF(NOT APPLETV_LIBRARY)
FIND_LIBRARY(BACKROW_LIBRARY BackRow ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks ../)
IF(NOT BACKROW_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch BackRow not found. Bailing out...")
ENDIF(NOT BACKROW_LIBRARY)
FIND_LIBRARY(IPHOTOACESS_LIBRARY iPhotoAccess ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks ../)
IF(NOT IPHOTOACESS_LIBRARY)
 MESSAGE(FATAL_ERROR "Ouch iPhotoAccess not found. Bailing out...")
ENDIF(NOT IPHOTOACESS_LIBRARY)

#finally build the executable
add_executable(MultiFinder MACOSX_BUNDLE ${MULTIFINDER_SRCS} )
SET_TARGET_PROPERTIES(MultiFinder PROPERTIES 
	COMPILE_DEFINITIONS_DEBUG "${COMPILE_DEFINITIONS_DEBUG}"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.teamxbmc.multifinder"
	)

#link it
TARGET_LINK_LIBRARIES(MultiFinder ${FOUNDATION_LIBRARY} ${APPLETV_LIBRARY} ${BACKROW_LIBRARY} ${IPHOTOACESS_LIBRARY})

#and copy xbmchelper into it. For now by hand.
#see http://www.cmake.org/pipermail/cmake/2008-November/025455.html if this can be done better
get_target_property(MF_LOCATION MultiFinder LOCATION) 
get_target_property(HELPER_LOCATION xbmchelper LOCATION) 
ADD_DEPENDENCIES(MultiFinder xbmchelper)
add_custom_command(TARGET MultiFinder
                     POST_BUILD
                     COMMAND mkdir -p ${MF_LOCATION}.app/Contents/Resources/
                     COMMAND cp ${HELPER_LOCATION} ${MF_LOCATION}.app/Contents/Resources/
                     COMMENT "add xbmchelper" VERBATIM)
#and copy SettingsHelper into it. For now by hand.
#see http://www.cmake.org/pipermail/cmake/2008-November/025455.html if this can be done better
get_target_property(SETTINGSHELPER_LOCATION SettingsHelper LOCATION) 
ADD_DEPENDENCIES(MultiFinder SettingsHelper)
add_custom_command(TARGET MultiFinder
                     POST_BUILD
                     COMMAND mkdir -p ${MF_LOCATION}.app/Contents/Resources/
                     COMMAND cp ${SETTINGSHELPER_LOCATION} ${MF_LOCATION}.app/Contents/Resources/
                     COMMENT "add SettingsHelper" VERBATIM)

#-------
# add convenience target which copies to ATV
# needs following script in path:
#
##!/bin/bash
##restart finder
#kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
#kill `ps awwx | grep [F]inder | awk '{print $1}'`
#-------
SET(MULTIFINDER_ATV_LOCATION "" CACHE STRING "Path on ATV to place Multifinder.app; if empty home directory is used")
#TODO: need to implement mv on ATV if Multifinder_ATV_LOCATION is given
get_target_property(MF_LOCATION MultiFinder LOCATION) 
add_custom_target(MFBuildAndCopyToATV 
		COMMAND	scp -r ${MF_LOCATION}.app frontrow@${APPLETV_IP}:
		COMMAND ssh frontrow@${APPLETV_IP} "echo \"frontrow\" | sudo -S /bin/rm -rf /Applications/MultiFinder.app"
		COMMAND ssh frontrow@${APPLETV_IP} "echo \"frontrow\" | sudo -S /bin/mv ~/MultiFinder.app /Applications"
		COMMAND ssh frontrow@${APPLETV_IP} "echo \"frontrow\" | sudo -S /usr/sbin/chown root /Applications/MultiFinder.app/Contents/Resources/SettingsHelper"
		COMMAND ssh frontrow@${APPLETV_IP} "echo \"frontrow\" | sudo -S /bin/chmod +s /Applications/MultiFinder.app/Contents/Resources/SettingsHelper"
		COMMAND ssh frontrow@${APPLETV_IP} "restartLogin"
        COMMENT "covenience copy to ATV" VERBATIM)
ADD_DEPENDENCIES(MFBuildAndCopyToATV MultiFinder)
