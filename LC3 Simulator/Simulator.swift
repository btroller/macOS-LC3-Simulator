//
//  Simulator.swift
//  Delete
//
//  Created by Benjamin Troller on 12/13/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

// Q: should I include a "step" button to only execute 1 instruction? A: I think so

// TODO: setcc()

class Simulator {
    
    // MARK: state-keeping
    var registers = Registers()
    var memory = Memory()
    
    func executeNextInstruction() {
        print("executing at \(String.init(format: "0x%04X", registers.pc))")
        let entryToExecute = memory[Int(registers.pc)]
        let value = entryToExecute.value
        registers.pc += 1
        print("R4 = \(registers[4])")
        
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
            registers[value.SR_DR] = memory[Int(registers.pc &+ UInt16(bitPattern: value.sextPCoffset9))].value
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDI:
            registers[value.SR_DR] = memory[ Int(memory[ Int(registers.pc &+ UInt16(bitPattern: value.sextPCoffset9)) ].value) ].value
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDR:
            registers[value.SR_DR] = memory[Int(value.BaseR &+ UInt16(bitPattern: value.sextOffset6))].value
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
//        case .RTI:
//            <#code#>
        case .ST:
            memory[Int(registers.pc + UInt16(bitPattern: value.sextPCoffset9))].value = registers[value.SR_DR]
        case .STI:
            memory[Int(memory[Int(registers.pc + UInt16(bitPattern: value.sextPCoffset9))].value)].value = registers[value.SR_DR]
        case .STR:
            memory[Int(registers[value.BaseR] + UInt16(bitPattern: value.sextPCoffset9))].value = registers[value.SR_DR]
        case .TRAP:
            registers[7] = registers.pc
            registers.pc = memory[Int(value.trapVect8)].value
//        case .NOT_IMPLEMENTED:
//            <#code#>
        default:
            print("didn't match instruction type in Simulator")
        }
        
        print(entryToExecute.value)
    }
    
    func stepOver() {
        
    }
    
    func stepIn() {
        
    }
    
    func stepOut() {
        
    }
    
    func runForever() {
        
    }
    
    func stopExecution() {
        
    }
}
