cmake_minimum_required(VERSION 3.16)

project(AtChat VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(FLUENTUI_BUILD_EXAMPLES OFF)
set(FLUENTUI_BUILD_FRAMELESSHEPLER OFF)

find_package(FluentUI)
find_package(Qt6 REQUIRED COMPONENTS Quick Network WebSockets)

qt_standard_project_setup(REQUIRES 6.8)

# SPP 模块源文件
set(SPP_SOURCES
    src/SPP/BigNumber.cpp
    src/SPP/BaseConfiguration.cpp
    src/SPP/MiscUtils.cpp
    src/SPP/GenerateKey.cpp
    src/SPP/ValidateKey.cpp
    src/SPP/SerialKey.cpp
)

set(SPP_HEADERS
    src/SPP/BigNumber.h
    src/SPP/BaseConfiguration.h
    src/SPP/MiscUtils.h
    src/SPP/GenerateKey.h
    src/SPP/ValidateKey.h
    src/SPP/SerialKey.h
    src/SPP/SKU.h

)

# TimeBomb 模块源文件
set(TIMEBOMB_SOURCES
    src/TimeBomb/TimeBomb.cpp
)

set(TIMEBOMB_HEADERS
    src/TimeBomb/TimeBomb.h
)

# LicenseManager
set(LICENSE_SOURCES
    src/LicenseManager.cpp
)

set(LICENSE_HEADERS
    src/LicenseManager.h
)

# NetworkManager
set(NETWORK_SOURCES
    src/NetworkManager.cpp
)

set(NETWORK_HEADERS
    src/NetworkManager.h
)

qt_add_executable(appAtChat
    main.cpp
    ${SPP_SOURCES}
    ${SPP_HEADERS}
    ${TIMEBOMB_SOURCES}
    ${TIMEBOMB_HEADERS}
    ${LICENSE_SOURCES}
    ${LICENSE_HEADERS}
    ${NETWORK_SOURCES}
    ${NETWORK_HEADERS}
)

target_include_directories(appAtChat PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/SPP
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeBomb
)

qt_add_qml_module(appAtChat
    URI AtChat
    QML_FILES
        Main.qml
        RESOURCES resource.qrc
        QML_FILES
        RESOURCES res/fav.png res/favicon.ico res/logo.png
        SOURCES src/AppInfo.h src/AppInfo.cpp
        SOURCES src/Version.h
)

set_target_properties(appAtChat PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appAtChat
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Network
    PRIVATE Qt6::WebSockets
)

include(GNUInstallDirs)
install(TARGETS appAtChat
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
add_subdirectory(tools/KeyGenerator)
