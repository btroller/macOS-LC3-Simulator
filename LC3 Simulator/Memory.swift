//
//  Memory.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

class Memory {
//    typealias Instruction = UInt16
//    var memory : [UInt16] = [UInt16].init(repeating: 0, count: 0xFFFF + 1)
    var memory : [Entry] = []
    let lc3OS : [UInt16 : UInt16] = [
        // Trap vector table (valid entries)
        0x0020: 0x0400,
        0x0021: 0x0430,
        0x0022: 0x0450,
        0x0023: 0x04A0,
        0x0024: 0x04E0,
        0x0025: 0xFD70,
        // Implementation of GETC
        0x0400: 0x3E07,
        0x0401: 0xA004,
        0x0402: 0x07FE,
        0x0403: 0xA003,
        0x0404: 0x2E03,
        0x0405: 0xC1C0,
        0x0406: 0xFE00,
        0x0407: 0xFE02,
        // Implementation of OUT
        0x0430: 0x3E0A,
        0x0431: 0x3208,
        0x0432: 0xA205,
        0x0433: 0x07FE,
        0x0434: 0xB004,
        0x0435: 0x2204,
        0x0436: 0x2E04,
        0x0437: 0xC1C0,
        0x0438: 0xFE04,
        0x0439: 0xFE06,
        // Implementation of PUTS
        0x0450: 0x3E16,
        0x0451: 0x3012,
        0x0452: 0x3212,
        0x0453: 0x3412,
        0x0454: 0x6200,
        0x0455: 0x0405,
        0x0456: 0xA409,
        0x0457: 0x07FE,
        0x0458: 0xB208,
        0x0459: 0x1021,
        0x045A: 0x0FF9,
        0x045B: 0x2008,
        0x045C: 0x2208,
        0x045D: 0x2408,
        0x045E: 0x2E08,
        0x045F: 0xC1C0,
        0x0460: 0xFE04,
        0x0461: 0xFE06,
        0x0462: 0xF3FD,
        0x0463: 0xF3FE,
        // Implementation of IN
        0x04A0: 0x3E06,     // ST R7, SaveR7
        0x04A1: 0xE006,     // LEA R0, Message
        0x04A2: 0xF022,     // PUTS
        0x04A3: 0xF020,     // GETC
        0x04A4: 0xF021,     // OUT
        0x04A5: 0x2E01,     // LD R7, SaveR7
        0x04A6: 0xC1C0,     // RET
        0x04A7: 0x3001,     // SaveR7 (.BLKW #1)
        /* the "Input a character> " message goes here */
        // Implementation of PUTSP
        0x04E0: 0x3E27,
        0x04E1: 0x3022,
        0x04E2: 0x3222,
        0x04E3: 0x3422,
        0x04E4: 0x3622,
        0x04E5: 0x1220,
        0x04E6: 0x6040,
        0x04E7: 0x0406,
        0x04E8: 0x480D,
        0x04E9: 0x2418,
        0x04EA: 0x5002,
        0x04EB: 0x0402,
        0x04EC: 0x1261,
        0x04ED: 0x0FF8,
        0x04EE: 0x2014,
        0x04EF: 0x4806,
        0x04F0: 0x2013,
        0x04F1: 0x2213,
        0x04F2: 0x2413,
        0x04F3: 0x2613,
        0x04F4: 0x2E13,
        0x04F5: 0xC1C0,
        0x04F6: 0x3E06,
        0x04F7: 0xA607,
        0x04F8: 0x0801,
        0x04F9: 0x0FFC,
        0x04FA: 0xB003,
        0x04FB: 0x2E01,
        0x04FC: 0xC1C0,
        0x04FE: 0xFE06,
        0x04FF: 0xFE04,
        0x0500: 0xF3FD,
        0x0501: 0xF3FE,
        0x0502: 0xFF00,
        // Implementation of HALT
        0xFD00: 0x3E3E,
        0xFD01: 0x303C,
        0xFD02: 0x2007,
        0xFD03: 0xF021,
        0xFD04: 0xE006,
        0xFD05: 0xF022,
        0xFD06: 0xF025,
        0xFD07: 0x2036,
        0xFD08: 0x2E36,
        0xFD09: 0xC1C0,
        0xFD70: 0x3E0E,
        0xFD71: 0x320C,
        0xFD72: 0x300A,
        0xFD73: 0xE00C,
        0xFD74: 0xF022,
        0xFD75: 0xA22F,
        0xFD76: 0x202F,
        0xFD77: 0x5040,
        0xFD78: 0xB02C,
        0xFD79: 0x2003,
        0xFD7A: 0x2203,
        0xFD7B: 0x2E03,
        0xFD7C: 0xC1C0,
        /* the "halting the processor" message goes here */
        0xFDA5: 0xFFFE,
        0xFDA6: 0x7FFF,
        // Display status register
        0xFE04: 0x8000,
        // Machine control register
        0xFFFE: 0xFFFF
    ]
    
    class Entry {
        var value : UInt16 = 0
        var shouldBreak : Bool = false
        var label : String?
        
        init(value : UInt16) {
            self.value = value
        }
        
        // Used to initalize with default values only
        init() {}
    }
    
    // reloads memory to inital state with only OS present
    // NOTE: not nessecary, can just initialize whole new unit of Memory when making new Simulator
//    func resetMemory() {
//
//    }
    
    // MARK: Initializer
    // NOTE: follows design of online simulator
    init() {
        
        // Initialize rest of memory to all 0s and no breakpoints
        for _ in 0...0xFFFF {
            memory.append(Entry())
        }
        
        // fill in bad traps
        // NOTE: Windows sim fills in xFF, online one doesn't
        for i in 0...0xFF {
            self[i] = 0xFD00
        }
        
        // fill in input prompt
        let inputPromptAsUInt16 = "Input a character> \0".utf8.map{ UInt16($0) }
        let promptStartAddress = 0x04A8
        for i in 0..<inputPromptAsUInt16.count {
            self[promptStartAddress + i] = inputPromptAsUInt16[i]
        }
        
        // fill in halt message
        let haltMessageAsUInt16 = "\n----- Halting the processor ----- \n\0".utf8.map{ UInt16($0) }
        let haltStartAddress = 0xFD80
        for i in 0..<haltMessageAsUInt16.count {
            self[haltStartAddress + i] = haltMessageAsUInt16[i]
        }
        
        // load traps and interrupts
        for (address, value) in lc3OS {
            self[Int(address)] = value
        }
    
    }
    
    func loadProgramsFromFiles(at urls: [URL]) {
        for url in urls {
            loadProgramFromFile(at: url)
        }
    }
    
    // TODO: FIX -- I don't think this works as is
    func loadProgramFromFile(at url: URL) {
//        let path = "/Users/Ben/Downloads/lc3tools/lc3os.obj"
//        let fileData = NSData(contentsOfFile: path)!
        let fileData = NSData(contentsOf: url)!
        let fileLength = fileData.length
//        let dataRange = NSRange(location: 0, length: 10 * 2) // TODO: change from 10
        let dataRange = NSRange(location: 0, length: fileLength / 2)
        var bigEndienValues = [UInt16].init(repeating: 0, count: fileLength / 2)
        fileData.getBytes(&bigEndienValues, range: dataRange)
        
        guard bigEndienValues.count > 0 else { return }
        
        let values : [UInt16] = bigEndienValues.map { CFSwapInt16($0) }
        
        let orig = Int(values[0])
        print("orig = " + String(format: "%04X", orig))
        let programData = values[1...]
//        var modifiedMemoryLocations : [Int] = []
        for (index, value) in programData.enumerated() {
            print("val[\(index)] = " + String(format: "%04X", value))
            self[orig + index] = value
//            modifiedMemoryLocations.appe
        }
        
//        for i in Int(values[1])..<(values)(fileLength / 2) {
//            print(values[i])
//            self[i] = values[i]
//        }
    }
    
}

extension Memory {
    
    subscript(index: Int) -> UInt16 {
        get {
            return memory[index].value
        }
        // NOTE: sets only the value of the memory entry
        set {
            memory[index].value = newValue
        }
    }
    
}

// MARK: Instruction extensions to make parsing easier
extension UInt16 {
    
    enum InstructionType {
        case ADDR
        case ADDI
        case ANDR
        case ANDI
        case BR
        case JMP
        case JSR
        case JSRR
        case LD
        case LDI
        case LDR
        case LEA
        case NOT
        case RET
        case RTI
        case ST
        case STI
        case STR
        case TRAP
        case NOT_IMPLEMENTED
    }
    
    func getBit(at pos : Int) -> UInt16 {
        return (self >> pos) & 1
    }
    
    var instructionType : InstructionType {
        let instructionBits = self >> 12
        switch instructionBits {
        case 0b0001:
            if getBit(at: 5) == 0 {
                return .ADDR
            } else {
                return .ADDI
            }
        case 0b0101:
            if getBit(at: 5) == 0 {
                return .ANDR
            } else {
                return .ANDI
            }
        case 0b0000:
            return .BR
        case 0b1100:
            if getBit(at: 8) == 1 && getBit(at: 7) == 1 && getBit(at: 6) == 1 {
                return .RET
            } else {
                return .JMP
            }
        case 0b0100:
            if getBit(at: 11) == 1 {
                return .JSR
            } else {
                return .JSRR
            }
        case 0b0010:
            return .LD
        case 0b1010:
            return .LDI
        case 0b0110:
            return .LDR
        case 0b1110:
            return .LEA
        case 0b1001:
            return .NOT
        case 0b1000:
            return .RTI
        case 0b0011:
            return .ST
        case 0b1011:
            return .STI
        case 0b0111:
            return .STR
        case 0b1111:
            return .TRAP
        default:
            return .NOT_IMPLEMENTED
        }
    }
    
    func getBits(high : Int, low : Int) -> UInt16 {
        return (self >> low) & (0xFFFF >> (Int(16) - (high - low + 1)))
    }
    
    var imm5 : UInt16 {
        return getBits(high: 4, low: 0)
    }
    
    // NOTE: returns a signed result to make displaying and working with easier
    var sextImm5 : Int16 {
        if imm5.getBit(at: 4) == 1 {
            return Int16.init(bitPattern: (imm5 | 0b1111_1111_111_10000))
        } else {
            return Int16(imm5)
        }
    }
    
    // NOTE: I called it SR_DR because it's sometimes SR and sometimes DR
    var SR_DR : UInt16 {
        return getBits(high: 11, low: 9)
    }
    
    var SR1 : UInt16 {
        return getBits(high: 8, low: 6)
    }
    
    var SR2 : UInt16 {
        return getBits(high: 2, low: 0)
    }
    
    var PCoffset9 : UInt16 {
        return getBits(high: 8, low: 0)
    }
    
    var sextPCoffset9 : Int16 {
        if PCoffset9.getBit(at: 8) == 1 {
            return Int16.init(bitPattern: PCoffset9 | 0b1111_111_000000000)
        } else {
            return Int16(PCoffset9)
        }
    }
    
    var PCoffset11 : UInt16 {
        return getBits(high: 10, low: 0)
    }
    
    var sextPCoffset11 : Int16 {
        if PCoffset11.getBit(at: 10) == 1 {
            return Int16.init(bitPattern: PCoffset11 | 0b11111_00000000000)
        } else {
            return Int16(PCoffset11)
        }
    }
    
    var BaseR : UInt16 {
        return getBits(high: 8, low: 6)
    }
    
    var offset6 : UInt16 {
        return getBits(high: 5, low: 0)
    }
    
    var sextOffset6 : Int16 {
        if offset6.getBit(at: 5) == 1 {
            return Int16.init(bitPattern: offset6 | 0b1111111111_000000)
        } else {
            return Int16(offset6)
        }
    }
    
    var trapVect8 : UInt16 {
        return getBits(high: 7, low: 0)
    }
    
    var zextTrapVect8 : UInt16 {
        return trapVect8
    }
    
    var stringFromInstruction : String {
        switch self.instructionType {
        case .ADDR:
            return "ADD R\(SR_DR), R\(SR1), R\(SR2)"
        case .ADDI:
            return "ADD R\(SR_DR), R\(SR1), #\(sextImm5)"
        case .ANDR:
            return "AND R\(SR_DR), R\(SR1), R\(SR2)"
        case .ANDI:
            return "AND R\(SR_DR), R\(SR1), #\(sextImm5)"
        // TODO: use labels when available
        case .BR:
            var branchStr = "BR"
            if getBit(at: 11) == 1 {
                branchStr.append("n")
            }
            if getBit(at: 10) == 1 {
                branchStr.append("z")
            }
            if getBit(at: 9) == 1 {
                branchStr.append("p")
            }
            branchStr.append(String.init(repeating: " ", count: (6 - branchStr.count)))
            branchStr.append("#\(sextPCoffset9)")
            return branchStr
        case .JMP:
            return "JMP R\(BaseR)"
        // TODO: use labels when available
        case .JSR:
            return "JSR #\(sextPCoffset11)"
        // TODO: test from here on down in function
        case .JSRR:
            // TODO: test
            return "JSRR R\(BaseR)"
        case .LD:
            return "LD R\(SR_DR), #\(sextPCoffset9)"
        case .LDI:
            return "LDI R\(SR_DR), #\(sextPCoffset9)"
        case .LDR:
            return "LDR R\(SR_DR), R\(BaseR), #\(sextOffset6)"
        case .LEA:
            return "LEA R\(SR_DR), #\(sextPCoffset9)"
        case .NOT:
            return "NOT R\(SR_DR), R\(getBits(high: 8, low: 6))"
        case .RET:
            return "RET"
        case .RTI:
            return "RTI"
        case .ST:
            return "ST R\(SR_DR), #\(sextPCoffset9)"
        case .STI:
            return "STI R\(SR_DR), #\(sextPCoffset9)"
        case .STR:
            return "STR R\(SR_DR), R\(BaseR), #\(sextOffset6)"
        case .TRAP:
            return "TRAP x\(zextTrapVect8)"
        case .NOT_IMPLEMENTED:
            return "RESERVED INSTRUCTION"
        }
    }
}
