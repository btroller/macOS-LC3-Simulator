//
//  Memory.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

class Memory {
    private var entries : [Entry] = []
    
    class Entry {
        var value : UInt16 = 0
        var shouldBreak : Bool = false
        var label : String?
//        var instructionType : InstructionType {
//            value.instructionType
//        }
        
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
        
        init(value : UInt16) {
            self.value = value
        }
        
        // Used to initalize with default values only
        init() {}
    }
    
    func instructionString(at address: Int) -> String {
        
        func getEffectiveAddrLabel(instructionAddr: Int, offset: Int16) -> String {
            // remember the PC increment
            let effectiveAddress = UInt16(bitPattern: Int16(bitPattern: UInt16(instructionAddr)) + 1 + offset)
            
            return entries[Int(effectiveAddress)].label ?? "#\(offset)"
        }
        
        let entry = entries[address]
        let val = entry.value
        
        switch entry.value.instructionType {
        case .ADDR:
            return "ADD R\(val.SR_DR), R\(val.SR1), R\(val.SR2)"
        case .ADDI:
            return "ADD R\(val.SR_DR), R\(val.SR1), #\(val.sextImm5)"
        case .ANDR:
            return "AND R\(val.SR_DR), R\(val.SR1), R\(val.SR2)"
        case .ANDI:
            return "AND R\(val.SR_DR), R\(val.SR1), #\(val.sextImm5)"
        // TODO: use labels when available
        case .BR:
            // Return NOP if branching nowhere or all 0s
            if ((val & 0x0E00) == 0 || val == 0) {
                return "NOP";
            }
            
            var branchStr = "BR"
            if val.getBit(at: 11) == 1 {
                branchStr.append("n")
            }
            if val.getBit(at: 10) == 1 {
                branchStr.append("z")
            }
            if val.getBit(at: 9) == 1 {
                branchStr.append("p")
            }
            branchStr.append(String.init(repeating: " ", count: (6 - branchStr.count)))
            branchStr.append(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9)) //  "#\(val.sextPCoffset9)")
            return branchStr
        case .JMP:
            return "JMP R\(val.BaseR)"
        // TODO: use labels when available
        case .JSR:
            return "JSR \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset11))" //"#\(val.sextPCoffset11)"
        // TODO: test from here on down in function
        case .JSRR:
            // TODO: test
            return "JSRR R\(val.BaseR)"
        case .LD:
            return "LD R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" //#\(val.sextPCoffset9)"
        case .LDI:
            return "LDI R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" //#\(val.sextPCoffset9)"
        case .LDR:
            return "LDR R\(val.SR_DR), R\(val.BaseR), #\(val.sextOffset6)"
        case .LEA:
            return "LEA R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" //#\(val.sextPCoffset9)"
        case .NOT:
            return "NOT R\(val.SR_DR), R\(val.getBits(high: 8, low: 6))"
        case .RET:
            return "RET"
        case .RTI:
            return "RTI"
        case .ST:
            return "ST R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" //#\(val.sextPCoffset9)"
        case .STI:
            return "STI R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" //#\(val.sextPCoffset9)"
        case .STR:
            return "STR R\(val.SR_DR), R\(val.BaseR), #\(val.sextOffset6)"
        case .TRAP:
            let actualTrapAddress = entries[Int(val.zextTrapVect8)].value
            if let trapLabel = entries[Int(actualTrapAddress)].label {
                return "TRAP \(trapLabel)"
            }
            return "TRAP x\(val.zextTrapVect8)"
        case .NOT_IMPLEMENTED:
            return "RESERVED INSTRUCTION"
        }
    }
    
    func getEntryLabel(of entry: Int) -> String {
        return entries[entry].label ?? ""
    }
    
    // MARK: Initializer
    // NOTE: follows design of online simulator
    init() {
        
        // Initialize rest of memory to all 0s and no breakpoints
        for _ in 0...0xFFFF {
            entries.append(Entry())
        }
        
        // fill in bad traps
        // NOTE: Windows sim fills in xFF, online one doesn't
        for i in 0...0xFF {
            self[i].value = 0xFD00
        }
        
        // fill in input prompt
        let inputPromptAsUInt16 = "Input a character> \0".utf8.map{ UInt16($0) }
        let promptStartAddress = 0x04A8
        for i in 0..<inputPromptAsUInt16.count {
            self[promptStartAddress + i].value = inputPromptAsUInt16[i]
        }
        
        // fill in halt message
        let haltMessageAsUInt16 = "\n----- Halting the processor ----- \n\0".utf8.map{ UInt16($0) }
        let haltStartAddress = 0xFD80
        for i in 0..<haltMessageAsUInt16.count {
            self[haltStartAddress + i].value = haltMessageAsUInt16[i]
        }
        
        // load traps and interrupts
        for (address, value) in LC3OS.nonZeroValues {
            self[Int(address)].value = value
        }
        
        // load OS symbols
        for (label, address) in LC3OS.osSymbols {
            entries[address].label = label
        }
    
    }
    
    // Loads multiple programs in
    func loadProgramsFromFiles(at urls: [URL]) {
        for url in urls {
            loadProgramFromFile(at: url)
        }
    }
    
    // Loads in a single program
    func loadProgramFromFile(at url: URL) {
        let fileData = NSData(contentsOf: url)!
        guard fileData.length % 2 == 0 else { print("uneven length input file") ; return }
        let numUInt16sInFile = fileData.length / 2
        print("numUInt16sInFile = \(numUInt16sInFile)")
        let dataRange = NSMakeRange(0, fileData.length)
        var bigEndienValues = [UInt16].init(repeating: 0, count: numUInt16sInFile)
        fileData.getBytes(&bigEndienValues, range: dataRange)
        
        guard bigEndienValues.count > 0 else { return }
        
        print(bigEndienValues)
        
        let values : [UInt16] = bigEndienValues.map { CFSwapInt16($0) }
        
        let orig = Int(values[0])
        print("orig = " + String(format: "%04X", orig))
        let programData = values[1...]
//        var modifiedMemoryLocations : [Int] = []
        // might be able to do this without recording all separately just by reloading range from start to (start + length)
        for (index, value) in programData.enumerated() {
            print("val[\(index)] = " + String(format: "0x%04X", value))
            self[orig + index].value = value
//            modifiedMemoryLocations.appe
        }
        
        // try opening corresponding symbol file
        let symURL = url.deletingPathExtension().appendingPathExtension("sym")
        do {
            let symFileContents = try String(contentsOf: symURL)
            print("found sym file at \(symURL)")
            // get each line of symbol file with
            let symFileLines = symFileContents.components(separatedBy: .newlines)[4...]
            for line in symFileLines {
                print(line)
                var label : NSString?
                var addressStr : NSString?
                let scanner = Scanner(string: line)
                // ignore `/` characters at beginning of line
                let charsToSkip = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/"))
                scanner.charactersToBeSkipped = charsToSkip
                guard scanner.scanUpToCharacters(from: charsToSkip, into: &label) == true && label != nil else { return }
                guard scanner.scanUpToCharacters(from: charsToSkip, into: &addressStr) == true && addressStr != nil else { return }
                guard let address = UInt16(addressStr! as String, radix: 16) else { return }
                entries[Int(address)].label = label as String?
                print("new label: \(String(describing: label)) at address: \(address)")
            }
        } catch {
            print("Failed to open matching symbol file with error: \(error)")
            return
        }
        
//        for i in Int(values[1])..<(values)(fileLength / 2) {
//            print(values[i])
//            self[i] = values[i]
//        }
    }
    
}


extension Memory {
    
    subscript(index: Int) -> Entry {
        get {
            return entries[index]
        }
        // NOTE: sets only the value of the memory entry
        set {
            entries[index] = newValue
        }
    }
    
}

// MARK: Instruction extensions to make parsing easier
extension UInt16 {
    
    
    
    func getBit(at pos : Int) -> UInt16 {
        return (self >> pos) & 1
    }
    
    var instructionType : Memory.Entry.InstructionType {
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
    
    var N : Bool {
        return getBit(at: 11) == 1
    }
    
    var Z : Bool {
        return getBit(at: 10) == 1
    }
    
    var P : Bool {
        return getBit(at: 9) == 1
    }
}
