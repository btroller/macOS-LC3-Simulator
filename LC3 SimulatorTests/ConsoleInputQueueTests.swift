//
//  ConsoleInputQueueTests.swift
//  LC3 SimulatorTests
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import XCTest
@testable import LC3_Simulator

class ConsoleInputQueueTests: XCTestCase {
    var queue: ConsoleInputQueue<Character>!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        queue = ConsoleInputQueue<Character>()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        queue.push("a")
        XCTAssert(queue.hasNext && queue.pop() == "a")
        queue.push("a")
        queue.push("b")
        queue.push("c")
        XCTAssert(queue.hasNext && queue.pop() == "a")
        XCTAssert(queue.hasNext && queue.pop() == "b")
        XCTAssert(queue.hasNext && queue.pop() == "c")
        XCTAssert(!queue.hasNext && queue.pop() == nil)
        queue.push("a")
        queue.push("c")
        queue.push("b")
        queue.push("d")
        XCTAssert(queue.hasNext && queue.pop() == "a")
        XCTAssert(queue.hasNext && queue.pop() == "c")
        XCTAssert(queue.hasNext && queue.pop() == "b")
        XCTAssert(queue.hasNext && queue.pop() == "d")
    }
}
