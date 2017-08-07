//
//  OSScrollViewScrollIndicatoTests.m
//  OSScrollViewScrollIndicatoTests
//
//  Created by Ossey on 05/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIScrollView+OSScrollIndicatoExtend.h"

@interface OSScrollViewScrollIndicatoTests : XCTestCase

@end

@implementation OSScrollViewScrollIndicatoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.os_scrollIndicatoStyle = OSScrollIndicatoStyleCustom;
    //    [scrollView removeScrollIndicatoView];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
