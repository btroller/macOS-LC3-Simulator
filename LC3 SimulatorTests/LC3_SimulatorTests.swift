//
//  LC3_SimulatorTests.swift
//  LC3 SimulatorTests
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

// TODO: add CC checks where applicable
// TODO: test exceptions and interrupts

@testable import LC3_Simulator
import XCTest

class LC3SimulatorTests: XCTestCase {
    // NOTE: this
    func execute(instructions: [UInt16], in simulator: Simulator = Simulator()) -> Simulator {
//        let simulator = Simulator()
        for insn in instructions {
            simulator.memory[simulator.registers.pc].value = insn
            simulator.executeNextInstruction()
        }
        return simulator
    }

    func testADDR() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b1110_0010_0000_0000, // load 0x3002 into R1
            0b0001_0100_0000_0001, // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[1] == 0x3002)
        XCTAssert(simulator.registers.r[2] == 0x6003)
        XCTAssert(simulator.registers.cc == .P)
    }

    func testADDRWithOverflow() {
        let simulator = Simulator()
        simulator.registers.r[0] = 0xFFFF
        simulator.registers.r[1] = 0xFFFF
        simulator.memory[simulator.registers.pc].value = 0b0001_0100_0000_0001
        simulator.executeNextInstruction()

        XCTAssert(simulator.registers.r[0] == 0xFFFF)
        XCTAssert(simulator.registers.r[1] == 0xFFFF)
        XCTAssert(simulator.registers.r[2] == 0xFFFE)
        XCTAssert(simulator.registers.cc == .N)
    }

    func testADDI() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b0001_0100_0010_1111, // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[2] == 0x3010)
        XCTAssert(simulator.registers.cc == .P)
    }

    func testADDIWithNegativeImm5() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b0001_0100_0011_1111, // add the two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3001)
        XCTAssert(simulator.registers.r[2] == 0x3000)
        XCTAssert(simulator.registers.cc == .P)
    }

    func testADDIWithOverflow() {
        let insns: [UInt16] = [
            0b0001_0100_0011_1111, // add 0 and -1 two into R2
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == 0xFFFF)
        XCTAssert(simulator.registers.cc == .N)
    }

    func testANDR() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b0101_0100_0000_0001, // R2 = R0 & R1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == 0x0000)
    }

    func testANDINoSignExtend() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b0101_0100_0010_1111, // R2 = R0 & R1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == (0x3001 & 0b01111))
    }

    func testANDIWithSignExtend() {
        let insns: [UInt16] = [
            0b1110_0000_0000_0000, // load 0x3001 into R0
            0b0101_0100_0011_1111, // R2 = R0 & R1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == 0x3001)
    }

    func testBRNoSignExtend() {
        let insns: [UInt16] = [
            0b0000_1110_1111_1111, // BR #255
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == (0x3001 + 0b0_1111_1111))
    }

    func testBRWithSignExtend() {
        let insns: [UInt16] = [
            0b0000_1111_1111_1111, // BR #-1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x3000)
    }

    func testJMP() {
        let insns: [UInt16] = [
            0b1110_0010_0000_1001, // load 0x300A into R1
            0b1100_0000_0100_0000, // JMP R1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x300A)
    }

    // TODO: test supervisor stack
    func testJSRINoSignExtend() {
        let insns: [UInt16] = [
            0b0100_1000_0000_0111, // JSR #7
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x3008)
        XCTAssert(simulator.registers.r[7] == 0x3001)
    }

    // TODO: test supervisor stack
    func testJSRIWithSignExtend() {
        let insns: [UInt16] = [
            0b0100_1111_1111_1111, // JSR #7
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x3000)
        XCTAssert(simulator.registers.r[7] == 0x3001)
    }

    // TODO: test supervisor stack
    func testJSRR() {
        let insns: [UInt16] = [
            0b1110_0010_0000_1001, // load 0x300A into R1
            0b0100_0000_0100_0000, // JSR R1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x300A)
        XCTAssert(simulator.registers.r[7] == 0x3002)
    }

    func testLD() {
        let insns: [UInt16] = [
            0b0000_0001_1111_1111, // NOP
            0b0010_1001_1111_1110, // LD R4, 0x3000
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[4] == 0b0000_0001_1111_1111)
        XCTAssert(simulator.registers.pc == 0x3002)
    }

    func testLDINoSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x300A].value = 0x1234
        simulator.memory[0x1234].value = 0x2345
        let insns: [UInt16] = [
            0b1010_0010_0000_1001,
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.registers.r[1] == 0x2345)
    }

    // TODO: make sure I'm doing sign extension correctly
    func testLDIWithSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x2FF9].value = 0x1234
        simulator.memory[0x1234].value = 0x2345
        let insns: [UInt16] = [
            0b1010_0011_1111_1000,
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.registers.r[1] == 0x2345)
    }

    func testLDRNoSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x300D].value = 0x2345
        let insns: [UInt16] = [
            0b1110_0000_0000_1001, // load 0x300A into R0
            0b0110_0010_0000_0011, // LDR R1, R0, #3
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.registers.r[1] == 0x2345)
    }

    func testLDRWithSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x3009].value = 0x2345
        let insns: [UInt16] = [
            0b1110_0000_0000_1001, // load 0x300A into R0
            0b0110_0010_0011_1111, // LDR R1, R0, #-1
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.registers.r[1] == 0x2345)
    }

    func testLEANoSignExtend() {
        let insns: [UInt16] = [
            0b1110_0000_0000_1001, // LEA R0, 0x300A
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x300A)
    }

    func testLEAWithSignExtend() {
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[0] == 0x3000)
    }

    func testNOT() {
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
            0b1001_0100_0011_1111, // NOT R2, R0
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.r[2] == ~0x3000)
    }

    // NOTE: test for RET not included because it's just another JMP instruction

    func testRTI() {
        let simulator = Simulator()
        simulator.memory[simulator.registers.r[6]].value = 0x1234
        simulator.memory[simulator.registers.r[6] + 1].value = 0x2345
        simulator.registers.psr &= 0x7FFF
        let insns: [UInt16] = [
            0b1000_0000_0000_0000, // RTI
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.registers.pc == 0x1234)
        XCTAssert(simulator.registers.psr == 0x2345)
    }

    func testSTNoSignExtend() {
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
            0b0011_0000_0000_0011, // ST R0, #3
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.memory[0x3005].value == 0x3000)
    }

    func testSTWithSignExtend() {
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
            0b0011_0001_1111_1111, // ST R0, #-1
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.memory[0x3001].value == 0x3000)
    }

    func testSTIWithoutSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x3003].value = 0x2000
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
            0b1011_0000_0000_0001, // STI R0, #-3
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.memory[0x2000].value == 0x3000)
    }

    func testSTIWithSignExtend() {
        let simulator = Simulator()
        simulator.memory[0x2FFF].value = 0x2000
        let insns: [UInt16] = [
            0b1110_0001_1111_1111, // LEA R0, 0x3000
            0b1011_0001_1111_1101, // STI R0, #-3
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.memory[0x2000].value == 0x3000)
    }

    func testSTRWithoutSignExtend() {
        let simulator = Simulator()
        simulator.registers.r[1] = 0x1234
        let insns: [UInt16] = [
            0b1110_0001_1111_0110, // LEA R0, #-10
            0b0111_0010_0000_0001, // STR R1, R0, #1
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.memory[0x2FF8].value == 0x1234)
    }

    func testSTRWithSignExtend() {
        let simulator = Simulator()
        simulator.registers.r[1] = 0x1234
        let insns: [UInt16] = [
            0b1110_0001_1111_0110, // LEA R0, #-10
            0b0111_0010_0011_1111, // STR R1, R0, #-1
        ]
        _ = execute(instructions: insns, in: simulator)
        XCTAssert(simulator.memory[0x2FF6].value == 0x1234)
    }

    func testTRAP() {
        let insns: [UInt16] = [
            0b1111_0000_0010_0011,
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x04A0)
    }

    func testUnusedOpcode() {
        // expect illegal opcode exception
        let insns: [UInt16] = [
            0b1101_0000_0000_0000, // unused opcode
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x0540)
        XCTAssert(simulator.memory[0x2FFE].value == 0x8002)
        XCTAssert(simulator.memory[0x2FFD].value == 0x3000)
    }

    func testPrivelegeModeException() {
        let insns: [UInt16] = [
            0b1000_0000_0000_0000, // RTI
        ]
        let simulator = execute(instructions: insns)
        XCTAssert(simulator.registers.pc == 0x0510)
        XCTAssert(simulator.memory[0x2FFE].value == 0x8002)
        XCTAssert(simulator.memory[0x2FFD].value == 0x3000)
    }
}
