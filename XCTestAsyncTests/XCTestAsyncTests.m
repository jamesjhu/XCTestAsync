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

@end

@implementation XCTestAsyncTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTimeoutAsync
{
    XCAsyncFailAfter(3, @"\"%s\" timed out", __PRETTY_FUNCTION__);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        XCAsyncSuccess();
    });
}

@end
