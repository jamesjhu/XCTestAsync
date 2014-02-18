//
//  XCTestAsync.h
//  XCTestAsync
//
//  Created by James Hu on 2/16/14.
//  Copyright (c) 2014 Touchable Ideas. All rights reserved.
//

#import <XCTest/XCTest.h>

extern NSString * const XCAsyncSuccessDescription;

#define XCAsyncSuccess() [self recordFailureWithDescription:XCAsyncSuccessDescription inFile:[NSString stringWithUTF8String:__FILE__] atLine:__LINE__ expected:YES]

#define XCAsyncFailAfter(timeout, format...) \
do { \
    int64_t delayInSeconds = timeout; \
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC); \
    dispatch_after(popTime, dispatch_get_main_queue(), ^{ \
        _XCAsyncPrimitiveTimeout(format); \
    }); \
} while(0)

#define _XCAsyncPrimitiveTimeout(format...) \
({ \
    _XCTRegisterFailure(@"timed out",format); \
})