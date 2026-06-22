//
//  Elite-Bridging-Header.h
//  Elite
//
//  Exposes the Objective-C++ zsign bridge to Swift. Add the zsign C++
//  sources to the target and this header makes `ZSign` callable from
//  ZSignWrapper.swift.
//

#if __has_include("ZSign.h")
#import "ZSign.h"
#define ZSIGN_AVAILABLE 1
#endif
