//
//  debug.h
//  Firmware
//

#import <Foundation/Foundation.h>

#ifndef debug_h
#define debug_h

#if (DEBUG)
#define DEBUGLOG(str, ...) do { \
NSLog(@str, ##__VA_ARGS__); \
} while(0)
#else
#define DEBUGLOG(str, ...)
#endif

#endif /* debug_h */
