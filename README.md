# XCTestAsync

XCTestAsync is an extension to XCTest for asynchronous testing, and is based on [SenTestingKitAsync](https://github.com/nxtbgthng/SenTestingKitAsync).

## Installation

There are currently two ways to add XCTestAsync to your project:
* Install with [CocoaPods](http://cocoapods.org) __(recommended)__
* Manually copying the source files

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C. To include XCTestAsync into your project with CocoaPods, edit your project's `podfile` as follows:
<pre>
target :test, :exclusive => true do
    pod 'XCTestAsync', '~> 1.0'
end</pre>

### Manually

If you are not using CocoaPods, you can copy over `XCTestAsync.h` and `XCTestAsync.m` into your test target. In addition, you will need to add `-ObjC` to your test target linker flags.

## Usage 

To use XCTestAsync in your tests, do the following:

1. Import the header:
    <pre>#import &lt;XCTestAsync/XCTestAsync.h&gt;</pre>

2. Add your test method that ends with the suffix `Async`:
    <pre>- (void)testMethodAsync
    {
        // your async code here
    }</pre>

3. Tell XCTestAsync when the test succeeds:
    <pre>
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        XCAsyncSuccess();
    });</pre>

Once your async tests start, XCTestAsync will wait until either a failure occurs (by calling assertions such as `XCTFail(…)` or `XCTAssert(…)`) or a success is signalled (by calling `XCAsyncSuccess()`). If neither of these happen, XCTestAsync will wait indefinitely.

### Timeouts

If you expect your async test to run within a specified amount of time, you can specify a time limit by calling `XCAsyncFailAfter(timeout, description, …)`. If a success is not signalled within the time limit, the test will fail after `timeout` number of seconds.

## Asynchronous set up and tear down of test cases

If the setup needed by you test is also handled asynchronous, you can now do this with the extension to XCTestCase. Simply implement `-[XCTestCase setUpAsyncWithCompletionHandler:]` or `-[XCTestCase tearDownAsyncWithCompletionHandler:]` in you test case and do the setup (or tear down). If you are done with that, call the completion handler (and do not forget to call the setup or tear down of super).

```
- (void)setUpAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    [super setUpAsyncWithCompletionHandler:^{
        // Your set up
        handler();
    }];
}

- (void)tearDownAsyncWithCompletionHandler:(XCAsyncCompletionBlock)handler
{
    [super tearDownAsyncWithCompletionHandler:^{
        // Your tear down
        handler();
    }];
}
```

Because there is no timeout or error catching, you have to be sure, that your implementation that is used for set up and tear down is well tested. In case of an error exit the test with an assertion. 


## Additional Reading

* [Testing Concurrent Applications](http://www.objc.io/issue-2/async-testing.html) - Written for [SenTestingKitAsync](https://github.com/nxtbgthng/SenTestingKitAsync) but applies to XCTestAsync as well.
