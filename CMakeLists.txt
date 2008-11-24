cmake_minimum_required(VERSION 2.6)

PROJECT(atv-xbmc-tools)
#this is a nice feature to make a distribution
#FIND_PACKAGE(Subversion)
#IF(Subversion_FOUND)
# Subversion_WC_INFO("${CMAKE_CURRENT_SOURCE_DIR}" myproj)
# MESSAGE(STATUS "myproj_WC_REVISION='${myproj_WC_REVISION}'")
#ENDIF(Subversion_FOUND)

#colored makefiles are nice
set(CMAKE_COLOR_MAKEFILE ON)

# Always include srcdir and builddir in include path
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_OSX_SYSROOT /Developer/SDKs/MacOSX10.4u.sdk)
SET(CMAKE_OSX_ARCHITECTURES "i386" CACHE STRING "Build architectures for OSX" FORCE)
SET(COMPILE_DEFINITIONS_DEBUG "DEBUG ${COMPILE_DEFINITIONS_DEBUG}")

SET(APPLETV_IP "192.168.0.90" CACHE STRING "IP address of atv for build&copy targets")

include_directories(common)


#the IR helper
add_subdirectory(xbmchelper)

#ATV FrontRow Frappliance
#doesn't work with cmake yet :/
#add_subdirectory(xbmclauncher)

#Finder replacement
add_subdirectory(MultiFinder)
