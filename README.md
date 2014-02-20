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

## Additional Reading

* [Testing Concurrent Applications](http://www.objc.io/issue-2/async-testing.html) - Written for [SenTestingKitAsync](https://github.com/nxtbgthng/SenTestingKitAsync) but applies to XCTestAsync as well.
