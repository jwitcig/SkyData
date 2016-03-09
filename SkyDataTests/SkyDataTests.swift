//
//  SkyDataTests.swift
//  SkyDataTests
//
//  Created by Developer on 3/9/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import XCTest

@testable import SkyData

class SkyDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDelayOperation() {
        let expectation = expectationWithDescription("")

        let delayOperation = SDDelayOperation(delayDuration: 0.2)
        delayOperation.completionBlock = {
            expectation.fulfill()
        }
        
        NSOperationQueue().addOperation(delayOperation)
        
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
}
