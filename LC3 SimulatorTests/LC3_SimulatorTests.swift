//
//  LC3_SimulatorTests.swift
//  LC3 SimulatorTests
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import XCTest
@testable import LC3_Simulator

class LC3SimulatorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    // NOTE: this
    func execute(instructions: [UInt16]) -> Simulator {
        let simulator = Simulator()
        for insn in instructions {
            simulator.memory[simulator.registers.pc].value = insn
            simulator.executeNextInstruction()
        }
        return simulator
    }
    
    func testADDR() {
        let insns: [UInt16] = [
            0b1110_000_000000000,   // load 0x3001 into R0
            0b1110_001_000000000,   // load 0x3002 into R1
            0b0001_010_000_0_00_001 // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[1] == 0x3002)
        XCTAssert(simulator.registers.r[2] == 0x6003)
        XCTAssert(simulator.registers.cc == .P)
    }
    
    func testADDRWithOverflow() {
        let simulator = Simulator()
        simulator.registers.r[0] = 0xffff
        simulator.registers.r[1] = 0xffff
        simulator.memory[simulator.registers.pc].value = 0b0001_010_000_0_00_001
        simulator.executeNextInstruction()
        
        XCTAssert(simulator.registers.r[0] == 0xFFFF)
        XCTAssert(simulator.registers.r[1] == 0xFFFF)
        XCTAssert(simulator.registers.r[2] == 0xFFFE)
        XCTAssert(simulator.registers.cc == .N)
    }
    
    // TODO: also with SextImm5
    func testADDI() {
        let insns: [UInt16] = [
            0b1110_000_000000000,   // load 0x3001 into R0
            0b0001_010_000_1_01111 // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[2] == 0x3010)
        XCTAssert(simulator.registers.cc == .P)
    }
    
    func testADDIWithNegativeImm5() {
        let insns: [UInt16] = [
            0b1110_000_000000000,   // load 0x3001 into R0
            0b0001_010_000_1_11111 // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[2] == 0x3000)
        XCTAssert(simulator.registers.cc == .P)
    }
    
    func testADDIWithOverflow() {
        let insns: [UInt16] = [
            0b0001_010_000_1_11111 // add 0 and -1 two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == 0xFFFF)
        XCTAssert(simulator.registers.cc == .N)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
