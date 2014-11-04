//
//  APSwiftEncryptQueryTests.swift
//  APSwiftEncrypt
//
//  Created by Juan Alvarez on 11/4/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

import UIKit
import XCTest

class APSwiftEncryptQueryTests: XCTestCase {
    
    let genericPasswordTestLabel = "com.genericpassword.test"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let query = APKeychainQuery(key: APSecClassKey.GenericPassword)
        query.label = genericPasswordTestLabel
        
        let key = APKeychainService.performKeyQuery(query) as SecKeyRef
        
        XCTAssertNotNil(key, "should return a key")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
