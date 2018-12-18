//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// Question: Should I allow poorly-formatted instructions - ex. 0b1100_111_000_111111
// Question: should I include NOP? (all 0s)

import Foundation
import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: IB elements
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: Constants
    let kStatusNoneImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)
    
    // MARK: Variables
    typealias Instruction = UInt16
    var memory : [UInt16] = [UInt16].init(repeating: 0, count: 0xFFFF + 1)
    
    func onItemClicked() {
        print("row \(tableView.clickedRow), col \(tableView.clickedColumn) clicked")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // TODO: remove
        // Randomly fills memory with junk (for testing purposes)
        for address in 0...0xFFFF {
            memory[address] = UInt16.random(in: UInt16.min...UInt16.max)
        }
        memory[0x3000] = 0b0001000111000110
        memory[0x3001] = 0b0000_111_111111111
//        tableView.
        tableView.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        // Note -- might be 0xFFFF, but online simulator has 0 through 0xFFFF
        return 0xFFFF + 1
    }
    
    // TODO: set font only once, hopefully in Interface Builder
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        switch tableColumn?.identifier.rawValue {
//        case "statusColumnID":
//            let tmp =
//            tmp.imageView = NSImageView(image: NSImage(imageLiteralResourceName: NSImage.goRightTemplateName))
//            return tmp
//        default:
//            let tmp = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addressCellID"), owner: self) as! NSTableCellView
//            tmp.textField = NSTextField(string: String(format: "x%04X", row))
//            return tmp
//        }
        switch tableColumn?.identifier.rawValue {
        case "statusColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "statusCellID"), owner: self) as! NSTableCellView
            if row == 1 {
                cellView.imageView?.image = NSImage(imageLiteralResourceName: NSImage.goRightTemplateName)
            } else if row == 3 {
                cellView.imageView?.image = kStatusUnavailableIMage
            } else {
                cellView.imageView?.image = kStatusNoneImage
            }
            return cellView
        case "addressColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addressCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: String(format: "x%04X", row))
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueBinaryColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            let unformattedBinaryString = String(memory[row], radix: 2)
            var formattedBinaryString = String(repeating: "0", count: 16 - unformattedBinaryString.count) + unformattedBinaryString
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 12))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 8))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 4))
            cellView.textField?.stringValue = formattedBinaryString
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: formattedBinaryString)
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
//            return newTextField
            return cellView
        case "valueHexColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", memory[row])
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: String(format: "x%04X", row))
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
//            return newTextField
            return cellView
        case "instructionColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "instructionCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory[row].stringFromInstruction
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: "NOT      R0, R0")
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            return newTextField
            return cellView
        default:
            let newTextField = NSTextField(string: "\(row)")
            newTextField.isBezeled = false
            newTextField.drawsBackground = false
            return newTextField
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
    
    // NOTE: called SR_DR because it's sometimes SR and sometimes DR
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
//
//extension ViewController: NSSearchFieldDelegate {
//
//    func searchFieldDidEndSearching(_ sender: NSSearchField) {
//        if let cell = sender.cell as? NSSearchFieldCell {
//            print("hello")
//        }
//        print("hi")
//    }
//
//}
