cmake_minimum_required(VERSION 3.16)

project(KeyGenerator VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# SPP 源文件（从主项目复制）
set(SPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../src/SPP)

set(SPP_SOURCES
    ${SPP_DIR}/BigNumber.cpp
    ${SPP_DIR}/BaseConfiguration.cpp
    ${SPP_DIR}/MiscUtils.cpp
    ${SPP_DIR}/GenerateKey.cpp
    ${SPP_DIR}/ValidateKey.cpp
    ${SPP_DIR}/SerialKey.cpp
)

add_executable(keygen main.cpp ${SPP_SOURCES})

target_include_directories(keygen PRIVATE ${SPP_DIR})

if(WIN32)
    target_link_libraries(keygen)
else()
    target_link_libraries(keygen m)
endif()
