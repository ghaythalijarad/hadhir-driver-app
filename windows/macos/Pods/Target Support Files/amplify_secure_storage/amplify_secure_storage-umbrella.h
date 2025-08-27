#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "amplify_secure_storage.h"

FOUNDATION_EXPORT double amplify_secure_storageVersionNumber;
FOUNDATION_EXPORT const unsigned char amplify_secure_storageVersionString[];

