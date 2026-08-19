cmake_minimum_required(VERSION 3.20)
project(NppFinder VERSION 1.3.1 LANGUAGES OBJCXX CXX)

# -----------------------------------------------------------------------------
# Nextpad++ "NppFinder" plugin
#
# Ports the Windows npp-explorer-plugin concept (folder tree + file list
# sidebar, Explorer/Finder integration) to the macOS host, using the
# NppPluginInterfaceMac.h ABI (vendored under vendor/, see vendor/README.md).
#
# No third-party dependencies: only Apple system frameworks (Cocoa,
# Foundation) plus the C++/Foundation standard library. Same toolchain
# conventions as the host app (CMake, ObjC++, ARC on .mm files).
# -----------------------------------------------------------------------------

if(NOT APPLE)
    message(FATAL_ERROR "The NppFinder plugin only builds on macOS (uses Cocoa/AppKit).")
endif()

set(CMAKE_AR /usr/bin/ar)
set(CMAKE_RANLIB /usr/bin/ranlib)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_OBJCXX_STANDARD 17)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
if(NOT CMAKE_OSX_ARCHITECTURES)
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
endif()

set(FINDER_SRCS
    src/FinderPlugin.mm
    src/FinderPanelView.mm
    src/FinderFileOperations.mm
    src/FinderPreferences.mm
    src/FinderLocalization.mm
)

set(FINDER_HDRS
    vendor/NppPluginInterfaceMac.h
    src/FinderPanelView.h
    src/FinderFileOperations.h
    src/FinderPreferences.h
    src/FinderLocalization.h
)

# SHARED (not MODULE), matching every released Nextpad++ plugin: the host
# dlopen()s it either way, but only an MH_DYLIB carries LC_ID_DYLIB, whose
# current_version Plugins Admin reads to show the installed version.
add_library(NppFinder SHARED ${FINDER_SRCS} ${FINDER_HDRS})

set_target_properties(NppFinder PROPERTIES
    OUTPUT_NAME "NppFinder"
    PREFIX ""
    SUFFIX ".dylib"
)

target_include_directories(NppFinder PRIVATE
    "${CMAKE_SOURCE_DIR}/vendor"
    "${CMAKE_SOURCE_DIR}/src"
)

target_compile_options(NppFinder PRIVATE -fobjc-arc -Wall -Wextra)

target_link_libraries(NppFinder PRIVATE
    "-framework Cocoa"
    "-framework Foundation"
)

# Stamp version into the dylib Mach-O current_version (Plugins Admin reads it).
target_link_options(NppFinder PRIVATE "-Wl,-current_version,${PROJECT_VERSION}")

# Plugins are dlopen()'d, not linked against a fixed absolute path.
set_target_properties(NppFinder PROPERTIES
    LINK_FLAGS "-Wl,-undefined,dynamic_lookup"
)

# -----------------------------------------------------------------------------
# Convenience "install" step: copies the built dylib into the same
# <PluginName>/<PluginName>.dylib layout the host's NppPluginManager expects
# under ~/Library/Application Support/Nextpad++/plugins/.
# Usage: cmake --build build --target install_plugin
# -----------------------------------------------------------------------------
set(NPP_PLUGINS_DIR "$ENV{HOME}/Library/Application Support/Nextpad++/plugins")

add_custom_target(install_plugin
    COMMAND ${CMAKE_COMMAND} -E make_directory "${NPP_PLUGINS_DIR}/NppFinder"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:NppFinder>" "${NPP_PLUGINS_DIR}/NppFinder/NppFinder.dylib"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/resources" "${NPP_PLUGINS_DIR}/NppFinder/resources"
    DEPENDS NppFinder
    COMMENT "Installing NppFinder.dylib and toolbar icons into ${NPP_PLUGINS_DIR}/NppFinder/"
)
