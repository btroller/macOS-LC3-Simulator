//
//  Memory.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// TODO: on write to memory, check if messing w/ kbsr and kbdr
// TODO: see if writing to kbsr and dsr is allowed
// TODO: check what should happen on read from KBDR - should it 0 out?

// Preference: whether to automatically load in symbol files

import Cocoa
import Foundation

class Memory {
    private var entries: [Entry] = []

    static let KBSR: UInt16 = 0xFE00
    static let KBDR: UInt16 = 0xFE02
    static let DSR: UInt16 = 0xFE04
    static let DDR: UInt16 = 0xFE06
    static let MCR: UInt16 = 0xFFFE

    static let kLogCharacterMessageName = Notification.Name("logCharacter")

    var mainVC: MainViewController! // NSApp.mainWindow?.contentViewController! as! MainViewController

    func setMainVC(to vc: MainViewController) {
        mainVC = vc
    }

    var KBSRIsSet: Bool {
        return self[Memory.KBSR].value.getBit(at: 15) == 1
    }

    var KBIEIsSet: Bool {
        return self[Memory.KBSR].value.getBit(at: 14) == 1
    }

    var DSRIsSet: Bool {
        return self[Memory.DSR].value & 0x8000 == 0x8000
    }

    var runLatchIsSet: Bool {
        return self[Memory.MCR].value & 0x8000 == 0x8000
    }

    // TODO: make static singleton instead of passing in `entries`?
    class Entry {
        var value: UInt16 = 0
        var shouldBreak: Bool = false
        var label: String?

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

        init(value: UInt16) {
            self.value = value
        }

        // Used to initalize with default values only
        init() {}
    }

    func instructionString(at address: Int) -> String {
        func getEffectiveAddrLabel(instructionAddr: Int, offset: Int16) -> String {
            // remember the PC increment
            // TODO: maybe use &+ operator instead? won't get overflow this way if that's what I'm going for
            //   just left this comment as passing by, but this setup seems a bit weird
            let effectiveAddress = UInt16(bitPattern: Int16(bitPattern: UInt16(instructionAddr)) &+ 1 &+ offset)

            return entries[Int(effectiveAddress)].label ?? "#\(offset)"
        }

        let val = entries[address].value

        switch val.instructionType {
        case .ADDR:
            return "ADD R\(val.SR_DR), R\(val.SR1), R\(val.SR2)"
        case .ADDI:
            return "ADD R\(val.SR_DR), R\(val.SR1), #\(val.sextImm5)"
        case .ANDR:
            return "AND R\(val.SR_DR), R\(val.SR1), R\(val.SR2)"
        case .ANDI:
            return "AND R\(val.SR_DR), R\(val.SR1), #\(val.sextImm5)"
        case .BR:
            // Return NOP if branching nowhere or all 0s
            if (val & 0x0E00) == 0 || val == 0 {
                if isascii(Int32(val)) != 0 {
                    return "'\(val.ascii.literalRepresentation)'"
                } else {
                    return "NOP"
                }
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
            branchStr.append(String(repeating: " ", count: 6 - branchStr.count))
            branchStr.append(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9)) //  "#\(val.sextPCoffset9)")
            return branchStr
        case .JMP:
            return "JMP R\(val.BaseR)"
        // TODO: use labels when available
        case .JSR:
            return "JSR \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset11))" // "#\(val.sextPCoffset11)"
        // TODO: test from here on down in function
        case .JSRR:
            // TODO: test
            return "JSRR R\(val.BaseR)"
        case .LD:
            return "LD R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" // #\(val.sextPCoffset9)"
        case .LDI:
            return "LDI R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" // #\(val.sextPCoffset9)"
        case .LDR:
            return "LDR R\(val.SR_DR), R\(val.BaseR), #\(val.sextOffset6)"
        case .LEA:
            return "LEA R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" // #\(val.sextPCoffset9)"
        case .NOT:
            return "NOT R\(val.SR_DR), R\(val.getBits(high: 8, low: 6))"
        case .RET:
            return "RET"
        case .RTI:
            return "RTI"
        case .ST:
            return "ST R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" // #\(val.sextPCoffset9)"
        case .STI:
            return "STI R\(val.SR_DR), \(getEffectiveAddrLabel(instructionAddr: address, offset: val.sextPCoffset9))" // #\(val.sextPCoffset9)"
        case .STR:
            return "STR R\(val.SR_DR), R\(val.BaseR), #\(val.sextOffset6)"
        case .TRAP:
            let actualTrapAddress = entries[Int(val.zextTrapVect8)].value
            if let trapLabel = entries[Int(actualTrapAddress)].label {
                return "TRAP \(trapLabel)"
            }
            return "TRAP x\(String(val.zextTrapVect8, radix: 16))"
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
        for _ in 0 ... 0xFFFF {
            entries.append(Entry())
        }

        // fill in bad traps
        // NOTE: Windows sim fills in xFF, online one doesn't
        for i in 0 ... (0xFF as UInt16) {
            self[i].value = 0xFD00
        }

        // fill in input prompt
        let inputPromptAsUInt16 = "Input a character> \0".utf8.map { UInt16($0) }
        let promptStartAddress = 0x04A8
        for i in 0 ..< inputPromptAsUInt16.count {
            self[UInt16(promptStartAddress + i)].value = inputPromptAsUInt16[i]
        }

        // fill in halt message
        let haltMessageAsUInt16 = "\n----- Halting the processor ----- \n\0".utf8.map { UInt16($0) }
        let haltStartAddress = 0xFD80
        for i in 0 ..< haltMessageAsUInt16.count {
            self[UInt16(haltStartAddress + i)].value = haltMessageAsUInt16[i]
        }

        // load traps and interrupts
        for (address, value) in LC3OS.nonZeroValues {
            self[address].value = value
        }

        // load OS symbols
        for (label, address) in LC3OS.osSymbols {
            entries[address].label = label
        }
    }

    // Loads multiple programs in
    func loadProgramsFromFiles(at urls: [URL], then reloadTableViewRowsInSet: (IndexSet) -> Void) {
        for url in urls {
            loadProgramFromFile(at: url, then: reloadTableViewRowsInSet)
        }
    }

    // TODO: deal with bad data gracefully, probably display error dialogue
    // Loads in a single program
    func loadProgramFromFile(at url: URL, then reloadTableViewRowsInSet: (IndexSet) -> Void) {
        let fileData = NSData(contentsOf: url)!
        guard fileData.length % 2 == 0 else { print("uneven length input file"); return }
        let numUInt16sInFile = fileData.length / 2
        print("numUInt16sInFile = \(numUInt16sInFile)")
        let dataRange = NSRange(location: 0, length: fileData.length)
        var bigEndienValues = [UInt16].init(repeating: 0, count: numUInt16sInFile)
        fileData.getBytes(&bigEndienValues, range: dataRange)

        guard bigEndienValues.count > 0 else { return }

        print(bigEndienValues)

        let values: [UInt16] = bigEndienValues.map { CFSwapInt16($0) }

        let orig = Int(values[0])
        print("orig = " + String(format: "%04X", orig))
        // get rid of origin, the first 16 bits (aka first UInt16) of the file
        let programData = values[1...]

        var modifiedMemoryLocations = IndexSet()
        defer {
            // whenever this function ends (through error, like if the symbols file can't be found, or otherwise), reload all table views
            reloadTableViewRowsInSet(modifiedMemoryLocations)
        }

        // might be able to do this without recording all separately just by reloading range from start to (start + length)
        for (index, value) in programData.enumerated() {
            print("val[\(index)] = " + String(format: "0x%04X", value))
            let addressToInsertAt = UInt16(orig + index)
            self[addressToInsertAt].value = value
            modifiedMemoryLocations.insert(Int(addressToInsertAt))
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
                var label: NSString?
                var addressStr: NSString?
                let scanner = Scanner(string: line)
                // ignore `/` characters at beginning of line
                let charsToSkip = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/"))
                scanner.charactersToBeSkipped = charsToSkip
                guard scanner.scanUpToCharacters(from: charsToSkip, into: &label) == true, label != nil else { return }
                guard scanner.scanUpToCharacters(from: charsToSkip, into: &addressStr) == true, addressStr != nil else { return }
                guard let address = UInt16(addressStr! as String, radix: 16) else { return }
                entries[Int(address)].label = label as String?
                // add the entries with labels attached to modifiedMemoryLocations in case a label is added for an address not in the program itself
                modifiedMemoryLocations.insert(Int(address))
                print("new label: \(String(describing: label)) at address: \(address)")
            }
        } catch {
            print("Failed to open matching symbol file with error: \(error)")
            return
        }
    }
}

extension Memory {
    subscript(index: UInt16) -> Entry {
        get {
            return entries[Int(index)]
        }
        set {
            entries[Int(index)] = newValue
        }
    }

    func setValue(at row: UInt16, to newValue: UInt16, then: (Int) -> Void) {
        // can do this safely because DDR will always be ready to read because I clear it after each instruction is run
        if row == Memory.DDR {
            NotificationCenter.default.post(name: Memory.kLogCharacterMessageName, object: newValue.ascii)
            self[Memory.DSR].value.setBit(at: 15, to: 1)
        }
        self[row].value = newValue
        then(Int(row))
    }

    func getValue(at index: UInt16) -> UInt16 {
        let currentVal = self[index].value

        // update KBSR and KBDR if KBDR is read from to reflect current state
        if index == Memory.KBDR {
            self[Memory.KBSR].value.setBit(at: 15, to: 0)
        }

        return currentVal
    }
}

// MARK: Instruction extensions to make parsing easier

extension UInt16 {
    func getBit(at pos: Int) -> UInt16 {
        return (self >> pos) & 1
    }

    mutating func setBit(at pos: Int, to val: UInt16) {
        assert(val == 0 || val == 1)
        self = (self & ~(1 << pos)) | (val << pos)
    }

    var instructionType: Memory.Entry.InstructionType {
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
            if getBit(at: 8) == 1, getBit(at: 7) == 1, getBit(at: 6) == 1 {
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

    func getBits(high: Int, low: Int) -> UInt16 {
        return (self >> low) & (0xFFFF >> (Int(16) - (high - low + 1)))
    }

    var imm5: UInt16 {
        return getBits(high: 4, low: 0)
    }

    // NOTE: returns a signed result to make displaying and working with easier
    var sextImm5: Int16 {
        if imm5.getBit(at: 4) == 1 {
            return Int16(bitPattern: imm5 | 0b1111_1111_1111_0000)
        } else {
            return Int16(imm5)
        }
    }

    // NOTE: I called it SR_DR because it's sometimes SR and sometimes DR
    var SR_DR: UInt16 {
        return getBits(high: 11, low: 9)
    }

    var SR1: UInt16 {
        return getBits(high: 8, low: 6)
    }

    var SR2: UInt16 {
        return getBits(high: 2, low: 0)
    }

    var PCoffset9: UInt16 {
        return getBits(high: 8, low: 0)
    }

    var sextPCoffset9: Int16 {
        if PCoffset9.getBit(at: 8) == 1 {
            return Int16(bitPattern: PCoffset9 | 0b1111_1110_0000_0000)
        } else {
            return Int16(PCoffset9)
        }
    }

    var PCoffset11: UInt16 {
        return getBits(high: 10, low: 0)
    }

    var sextPCoffset11: Int16 {
        if PCoffset11.getBit(at: 10) == 1 {
            return Int16(bitPattern: PCoffset11 | 0b1111_1000_0000_0000)
        } else {
            return Int16(PCoffset11)
        }
    }

    var BaseR: UInt16 {
        return getBits(high: 8, low: 6)
    }

    var offset6: UInt16 {
        return getBits(high: 5, low: 0)
    }

    var sextOffset6: Int16 {
        if offset6.getBit(at: 5) == 1 {
            return Int16(bitPattern: offset6 | 0b1111_1111_1100_0000)
        } else {
            return Int16(offset6)
        }
    }

    var trapVect8: UInt16 {
        return getBits(high: 7, low: 0)
    }

    var zextTrapVect8: UInt16 {
        return trapVect8
    }

    var N: Bool {
        return getBit(at: 11) == 1
    }

    var Z: Bool {
        return getBit(at: 10) == 1
    }

    var P: Bool {
        return getBit(at: 9) == 1
    }

    var ascii: Character {
        return Character(UnicodeScalar(UInt8(getBits(high: 7, low: 0))))
    }
}

// gives literal representation in string like python __repr__
extension Character {
    var literalRepresentation: String {
        return debugDescription.trimmingCharacters(in: ["\""])
    }
}
