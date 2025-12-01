#ifndef __VERSION_H
#define __VERSION_H

#define SOFTNAME    "AtChat"
#define COPYRIGHT_YEAR      "2024-2025"

#define VER_PRODUCTMAJORVERSION     0
#define VER_PRODUCTMINORVERSION     1
#define VER_PRODUCTBUILD            6
#define VER_PRODUCTBUILD_QFE        0

#define VER_PRODUCT2(w,x,y,z)       #w "." #x "." #y "." #z
#define VER_PRODUCT1(w,x,y,z) VER_PRODUCT2(w,x,y,z)
#define VERSION_PRODUCT VER_PRODUCT1(VER_PRODUCTMAJORVERSION, VER_PRODUCTMINORVERSION, VER_PRODUCTBUILD, VER_PRODUCTBUILD_QFE)

#define VER_PRODUCT4(w,x)           #w "." #x
#define VER_PRODUCT3(w,x) VER_PRODUCT4(w,x)
#define KERNEL_VERSION VER_PRODUCT3(VER_PRODUCTMAJORVERSION, VER_PRODUCTMINORVERSION)

#define VER_PRODUCTBUILD_TYPE       "atchat_main"

#ifdef _WIN32
    #define SYSTEM_NAME "Windows"
#elif __linux__
    #define SYSTEM_NAME "Linux"
#else
    #define SYSTEM_NAME "MacOS"
#endif

#define _VER_FLAGS_(a,b,c)          a "-" b "-" c
#define _VER_FLAGS(a,b,c)           _VER_FLAGS_(a,b,c)
#define VER_FLAGS                   _VER_FLAGS(VERSION_PRODUCT, VER_PRODUCTBUILD_TYPE, SYSTEM_NAME)

#define BUILD_YEAR     ((((__DATE__ [7] - '0') * 10 + (__DATE__ [8] - '0')) * 10 \
                                     + (__DATE__ [9] - '0')) * 10 + (__DATE__ [10] - '0'))

#define BUILD_MONTH    (__DATE__ [2] == 'n' ? (__DATE__ [1] == 'a' ? 1 : 6) \
                                 : __DATE__ [2] == 'b' ? 2 \
                                 : __DATE__ [2] == 'r' ? (__DATE__ [0] == 'M' ? 3 : 4) \
                                 : __DATE__ [2] == 'y' ? 5 \
                                 : __DATE__ [2] == 'l' ? 7 \
                                 : __DATE__ [2] == 'g' ? 8 \
                                 : __DATE__ [2] == 'p' ? 9 \
                                 : __DATE__ [2] == 't' ? 10 \
                                 : __DATE__ [2] == 'v' ? 11 : 12)

#define BUILD_DAY      ((__DATE__ [4] == ' ' ? 0 : __DATE__ [4] - '0') * 10 \
                                 + (__DATE__ [5] - '0'))

#define BUILD_HOUR     ((__TIME__ [0] - '0') * 10 + (__TIME__ [1] - '0'))
#define BUILD_MINUTE   ((__TIME__ [3] - '0') * 10 + (__TIME__ [4] - '0'))
#define BUILD_SECOND   ((__TIME__ [6] - '0') * 10 + (__TIME__ [7] - '0'))

#endif
