//
//  XCTestAsync.m
//  XCTestAsync
//
//  Created by James Hu on 2/16/14.
//  Copyright (c) 2014 Touchable Ideas. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "XCTestAsync.h"

NSString * const XCAsyncSuccessDescription = @"__async__success";

static char completionHandlerKey;
static char testRunKey;

typedef void(^XCTestCompletionHandler)(XCTestRun *run);

@interface XCTest (Async)
- (void)runWithCompletionHandler:(XCTestCompletionHandler)aCompletionHandler;
- (void)performTest:(XCTestRun *)aTestRun withCompletionHandler:(XCTestCompletionHandler)aCompletionHandler;
@end

@interface XCTestCase (Async)
- (void)performTest:(XCTestRun *)aTestRun withCompletionHandler:(XCTestCompletionHandler)aCompletionHandler;
@end

@interface XCTestCase (AsyncPrivate)
- (void)sync_recordFailureWithDescription:(NSString *)description inFile:(NSString *)filename atLine:(NSUInteger)lineNumber expected:(BOOL)expected;
@end

@interface XCTestCase ()
- (void)_recordUnexpectedFailureWithDescription:(NSString *)description exception:(NSException *)exception;
@end

@interface XCTestSuite (Async)
@end

@interface XCTestProbe (Async)
@end

@interface XCTestProbe ()
+ (id <NSObject>)suspendAppSleep;
+ (void)resumeAppSleep:(id <NSObject>)activity;
+ (XCTestSuite *)specifiedTestSuite;
@end

@interface XCTestObserver ()
+ (void)resumeObservation;
+ (void)setUpTestObservers;
+ (void)suspendObservation;
+ (void)tearDownTestObservers;
@end

@implementation XCTestCase (AsyncExtension)

- (void)setUpAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    handler();
}

- (void)tearDownAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    handler();
}

@end

@implementation XCTestSuite (AsyncExtension)

//- (void)setUpAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
//{
//    handler();
//}
//
//- (void)tearDownAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
//{
//    handler();
//}

@end


@implementation XCTest (Async)

- (void)runWithCompletionHandler:(XCTestCompletionHandler)aCompletionHandler
{
    Class testRunClass = [self testRunClass];
    XCTestRun *testRun = [testRunClass testRunWithTest:self];
    [self performTest:testRun withCompletionHandler:^(XCTestRun *run) {
        aCompletionHandler(testRun);
    }];
}

- (void)performTest:(XCTestRun *)aRun withCompletionHandler:(XCTestCompletionHandler)aCompletionHandler
{
    [self performTest:aRun];
    aCompletionHandler(aRun);
}

@end

@implementation XCTestCase (Async)

+ (void)load
{
    Method oldMethod = class_getInstanceMethod([self class], @selector(recordFailureWithDescription:inFile:atLine:expected:));
    if (oldMethod) {
        class_addMethod(objc_getClass(class_getName(self)),
                        @selector(sync_recordFailureWithDescription:inFile:atLine:expected:),
                        method_getImplementation(oldMethod),
                        method_getTypeEncoding(oldMethod));
    }
    
    Method newMethod = class_getInstanceMethod([self class], @selector(async_recordFailureWithDescription:inFile:atLine:expected:));
    if (newMethod) {
        class_replaceMethod(objc_getClass(class_getName(self)),
                            @selector(recordFailureWithDescription:inFile:atLine:expected:),
                            method_getImplementation(newMethod),
                            method_getTypeEncoding(newMethod));
    }
}

- (void)performTest:(XCTestRun *)aRun withCompletionHandler:(XCTestCompletionHandler)aCompletionHandler
{
    __block NSException *exception = nil;
    
    [self setValue:aRun forKey:@"testCaseRun"];
    
    __weak XCTestCase *weak = self;
    [weak setUp];
    [weak setUpAsyncWithCompletionHandler:^{
        [aRun start];
        
        if ([NSStringFromSelector([weak selector]) hasSuffix:@"Async"]) {
            weak.testRun = aRun;
            weak.completionHandler = aCompletionHandler;
            
            @try {
                [[weak invocation] invoke];
            }
            @catch (NSException *anException) {
                exception = anException;
            }
            
            if (exception) {
                [aRun stop];
                [weak tearDownAsyncWithCompletionHandler:^{
                    [weak tearDown];
                    
                    NSString *description = [NSString stringWithFormat:@"%@\n%@", [exception reason], [exception callStackSymbols]];
                    [weak _recordUnexpectedFailureWithDescription:description exception:exception];
                    
                    [weak setValue:nil forKey:@"testCaseRun"];
                    weak.testRun = nil;
                    weak.completionHandler = nil;
                    aCompletionHandler(aRun);
                }];
            }
        } else {
            @try {
                [[weak invocation] invoke];
            }
            @catch (NSException *anException) {
                exception = anException;
            }

            [aRun stop];
            [weak tearDownAsyncWithCompletionHandler:^{
                [weak tearDown];
                if (exception) {
                    NSString *description = [NSString stringWithFormat:@"%@\n%@", [exception reason], [exception callStackSymbols]];
                    [self _recordUnexpectedFailureWithDescription:description exception:exception];
                }
                
                [self setValue:nil forKey:@"testCaseRun"];
                aCompletionHandler(aRun);
            }];
        }
        
    }];

}

- (void)async_recordFailureWithDescription:(NSString *)description inFile:(NSString *)filename atLine:(NSUInteger)lineNumber expected:(BOOL)expected
{
    if (self.completionHandler == nil) {
        if (![XCAsyncSuccessDescription isEqualToString:description]) {
            [self sync_recordFailureWithDescription:description inFile:filename atLine:lineNumber expected:expected];
        }
    } else {
        __weak XCTestCase *weak = self;
        XCTestCompletionHandler aCompletionHandler = self.completionHandler;
        self.completionHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            XCTestRun *aRun = weak.testRun;
            weak.testRun = nil;
            
            if (![XCAsyncSuccessDescription isEqualToString:description]) {
                [self sync_recordFailureWithDescription:description inFile:filename atLine:lineNumber expected:expected];
            }
            
            [self tearDownAsyncWithCompletionHandler:^{
                [weak tearDown];
                [aRun stop];
                [weak setValue:nil forKey:@"testCaseRun"];
                aCompletionHandler(aRun);
            }];
        });
    }
}

- (void)setCompletionHandler:(XCTestCompletionHandler)completionHandler
{
    objc_setAssociatedObject(self, &completionHandlerKey, completionHandler, OBJC_ASSOCIATION_RETAIN);
}

- (XCTestCompletionHandler)completionHandler
{
    return objc_getAssociatedObject(self, &completionHandlerKey);
}

- (void)setTestRun:(XCTestRun *)testRun
{
    objc_setAssociatedObject(self, &testRunKey, testRun, OBJC_ASSOCIATION_RETAIN);
}

- (XCTestRun *)testRun
{
    return objc_getAssociatedObject(self, &testRunKey);
}

@end

@implementation XCTestSuite (Async)

- (void)performTest:(XCTestRun *)aTestRun withCompletionHandler:(XCTestCompletionHandler)aCompletionHandler
{
    __weak XCTestSuite *weak = self;
    [weak setUp];
    [aTestRun start];
    
    NSEnumerator *testEnumerator = [[self tests] objectEnumerator];
    
    [self performTestRun:aTestRun
      withTestEnumerator:testEnumerator
       completionHandler:aCompletionHandler];
}

- (void)performTestRun:(XCTestRun *)aTestRun
    withTestEnumerator:(NSEnumerator *)aTestEnumerator
     completionHandler:(XCTestCompletionHandler)aCompletionHandler
{
    __weak XCTestSuite *weak = self;
    XCTest *aTest = [aTestEnumerator nextObject];
    
    if (aTest) {
        [aTest runWithCompletionHandler:^(XCTestRun *run) {
            [(XCTestSuiteRun *)aTestRun addTestRun:run];
            [weak performTestRun:aTestRun
              withTestEnumerator:aTestEnumerator
               completionHandler:aCompletionHandler];
        }];
    } else {
        [aTestRun stop];
        [self tearDown];
        aCompletionHandler(aTestRun);
    }
}

@end

@implementation XCTestProbe (Async)

+ (void)load
{
    Method newMethod = nil;
    newMethod = class_getClassMethod([self class], @selector(runTestsAsync:));
    if (newMethod) {
        class_replaceMethod(objc_getMetaClass(class_getName([self class])),
                            @selector(runTests:),
                            method_getImplementation(newMethod),
                            method_getTypeEncoding(newMethod));
    }
}

+ (void)runTestsAsync:(id)ignored
{
    @autoreleasepool {
        [[NSBundle allFrameworks] makeObjectsPerformSelector:@selector(principalClass)];
        id <NSObject> activity = [self suspendAppSleep];
        [XCTestObserver setUpTestObservers];
        [XCTestObserver resumeObservation];
        
        NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self specifiedTestSuite] runWithCompletionHandler:^(XCTestRun *run) {
                BOOL hasFailed = [run hasSucceeded];
                
                [XCTestObserver suspendObservation];
                [XCTestObserver tearDownTestObservers];
                [self resumeAppSleep:activity];
                exit((int)hasFailed);
            }];
        });
        
        [mainRunLoop run];
    }
}

@end
