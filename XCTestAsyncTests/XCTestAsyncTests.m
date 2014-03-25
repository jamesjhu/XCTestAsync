//
//  XCTestAsyncTests.m
//  XCTestAsyncTests
//
//  Created by James Hu on 2/16/14.
//  Copyright (c) 2014 Touchable Ideas. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestAsync.h"

@interface XCTestAsyncTests : XCTestCase
@property BOOL asyncSetUpRan;
@property BOOL asyncTearDownRan;
@property BOOL setUpRan;
@property BOOL tearDownRan;
@end

@implementation XCTestAsyncTests

- (void)setUp
{
    [super setUp];
    self.setUpRan = YES;
}

- (void)setUpAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    __weak XCTestAsyncTests *weak = self;
    [super setUpAsyncWithCompletionHandler:^{
        weak.asyncSetUpRan = YES;
        handler();
    }];
}

- (void)tearDownAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    __weak XCTestAsyncTests *weak = self;
    [super tearDownAsyncWithCompletionHandler:^{
        weak.asyncTearDownRan = YES;
        handler();
    }];
}

- (void)tearDown
{
    [super tearDown];
    self.tearDownRan = YES;
    
    NSAssert(self.setUpRan, @"setup did not run");
    NSAssert(self.asyncSetUpRan, @"async setup did not run");
    NSAssert(self.tearDownRan, @"tear down did not run");
    NSAssert(self.asyncTearDownRan, @"async teardown did not run");
}

#pragma mark - Tests

- (void)testTimeoutAsync
{
    XCAsyncFailAfter(3, @"\"%s\" timed out", __PRETTY_FUNCTION__);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        XCAsyncSuccess();
    });
}

- (void)testSetupsRunAsync {
    XCTAssert(self.asyncSetUpRan, @"async setup did not run");
    XCTAssert(self.setUpRan, @"sync setup did not run");
    XCAsyncSuccess();
}

- (void)testAsyncSetupRunsForSyncTest {
    XCTAssert(self.asyncSetUpRan, @"async setup did not run");
    XCTAssert(self.setUpRan, @"sync setup did not run");
}

//- (void)testFails {
//    XCTFail(@"expected");
//}
//
//- (void)testFailsAsync {
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        XCTFail(@"expected");
//        XCAsyncSuccess();
//    });
//}

@end
