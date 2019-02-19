//
//  Simulator.swift
//  Delete
//
//  Created by Benjamin Troller on 12/13/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

// Q: should I include a "step" button to only execute 1 instruction? A: I think so
// what should do if non-implemented/reserved instruction? send to exception handler? see current spot in book
// have way to manage files to be assembled and loaded each time so you can avoid loading from previously chosen ones
//  should I support C-file compiling as well? probably not necessary
// try using NSTask to support lc3as functionality
// clarify with Bellardo what behavior he wants if an instruction is invalid -- I think he said it should trigger an exception for bad instructions
// consider making everything rewindable like Time Machine so you can easily undo some number of past actions -- could be simple and just have a copy of registers/simulator (use struct so that it's very easy) or intelligently make note of everything that's changed and rewind from there
// figure out when to stop executing for each case of step in, step out, etc -- should it be based on returning to an address (easy enough to store a copy w/ a let constant) or do I wait until a specific return happens? should notice after instruciton executes and PC is updated -- but it's not as simple as seeing that the PC is where it would've been otherwise, b/c that's not necessarily returning with RET or similar. You could just wind up there serendipitously through a mistake if somehting like JMP to lower-number address, keep executing and don't return until go through original code and hit original jump, htne pause. That's not really the same as a normal RET

class Simulator {
    
    // MARK: state-keeping
    var registers = Registers()
    var memory = Memory()
    
    var nextInstructionEntry : Memory.Entry {
        return memory[registers.pc]
    }
    
    enum ExceptionType : UInt16 {
        case privilegeModeViolation = 0x00
        case illegalOpcode = 0x01
    }
    
    func executeException(_ exceptionType : ExceptionType) {
        // 1: set privilege mode to supervisor
        registers.privilegeMode = .Supervisor
        // TODO 2: R6 is loaded with the Supervisor Stack Pointer if it does not already contain it
        // TODO 3: The PSR and PC of the interrupted process are pushed onto the Supervisor Stack.
        // 4: The exception supplies its 8-bit vector. In the case of the Privilege mode violation, that vector is xOO. In the case of the illegal opcode, that vector is xOl.
        let vector = exceptionType.rawValue
        // 5: The processor expands that vector to xOlOO or xOlOl, the corresponding 16-bit address in the interrupt vector table
        let expandedVector = vector + 0x0100
        // 6: The PC is loaded with the contents of memory location xOlOO or xOlOl, the address of the first instruction in the corresponding exception service routine.
        registers.pc = memory[expandedVector].value
    }
    
    func executeNextInstruction() {
        // TODO: check if interrupt to be dealt with
        
        
        // execute instruction normally
        print("executing at \(String.init(format: "0x%04X", registers.pc))")
        let entryToExecute = nextInstructionEntry
        let value = entryToExecute.value
        registers.pc += 1
//        print("R4 = \(registers[4])")
        
        print(value.instructionType)
        print(value)
        switch (value.instructionType) {
            
        case .ADDR:
            registers[value.SR_DR] = registers[value.SR1] &+ registers[value.SR2]
            registers.setCC(basedOn: registers[value.SR_DR])
//            print("was add r")
        case .ADDI:
            registers[value.SR_DR] = registers[value.SR1] &+ UInt16(bitPattern: value.sextImm5)
            registers.setCC(basedOn: registers[value.SR_DR])
//            registers[value.SR_DR] = UInt16(bitPattern: Int16(bitPattern: registers[value.SR1]) + value.sextImm5)
        case .ANDR:
            registers[value.SR_DR] = registers[value.SR1] & registers[value.SR2]
            registers.setCC(basedOn: registers[value.SR_DR])
        case .ANDI:
            registers[value.SR_DR] = registers[value.SR1] &+ UInt16(bitPattern: value.sextImm5)
            registers.setCC(basedOn: registers[value.SR_DR])
//            registers[value.SR_DR] = UInt16(bitPattern: Int16(bitPattern: registers[value.SR1]) & value.sextImm5)
        case .BR:
            if ((registers.N && value.N) || (registers.Z && value.Z) || (registers.P && value.P)) {
                // 2 (hopefully) equivalent ways of doing this
                registers.pc = registers.pc &+ UInt16(bitPattern: value.sextPCoffset9)
//                registers.pc = UInt16(bitPattern: Int16(bitPattern: registers.pc) + value.sextPCoffset9)
            }
        case .JMP:
            registers.pc = registers[value.BaseR]
        case .JSR:
            registers.pc = registers.pc &+ UInt16(bitPattern: value.sextPCoffset11)
        case .JSRR:
            registers[7] = registers.pc
            registers.pc = registers[value.BaseR]
        case .LD:
            registers[value.SR_DR] = memory[registers.pc &+ UInt16(bitPattern: value.sextPCoffset9)].value
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDI:
            registers[value.SR_DR] = memory[memory[registers.pc &+ UInt16(bitPattern: value.sextPCoffset9)].value].value
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDR:
            registers[value.SR_DR] = memory[value.BaseR &+ UInt16(bitPattern: value.sextOffset6)].value
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LEA:
            registers[value.SR_DR] = registers.pc &+ UInt16(bitPattern: value.sextPCoffset9)
            registers.setCC(basedOn: registers[value.SR_DR])
        case .NOT:
            // TODO: create computed property in Memory to perform getSR functionality done manually here
            registers[value.SR_DR] = ~(registers[value.getBits(high: 8, low: 6)])
            registers.setCC(basedOn: registers[value.SR_DR])
        case .RET:
            registers.pc = registers[7]
        case .RTI:
            if (registers.psr.getBit(at: 15) == 0) {
                registers.pc = memory[registers.r[6]].value
                registers.r[6] += 1
                let temp = memory[registers.r[6]].value
                registers.r[6] += 1
                registers.psr = temp
            }
            else {
                // initiate privalege mode exception
                executeException(.privilegeModeViolation)
            }
        case .ST:
            memory[registers.pc + UInt16(bitPattern: value.sextPCoffset9)].value = registers[value.SR_DR]
        case .STI:
            memory[memory[registers.pc + UInt16(bitPattern: value.sextPCoffset9)].value].value = registers[value.SR_DR]
        case .STR:
            memory[registers[value.BaseR] + UInt16(bitPattern: value.sextPCoffset9)].value = registers[value.SR_DR]
        case .TRAP:
            registers[7] = registers.pc
            registers.pc = memory[value.trapVect8].value
        case .NOT_IMPLEMENTED:
            // trigger illegal opcode exception
            executeException(.illegalOpcode)
//        default:
//            print("didn't match instruction type in Simulator")
        }
        
        print(entryToExecute.value)
    }
    
    // run until have returned to same level as started at?
    func stepOver() {
//        while ()
    }
    
    // run until have
    func stepIn() {
        
    }
    
    func stepOut() {
        
    }
    
    func runForever() {
        
    }
    
    func stopExecution() {
        
    }
}
