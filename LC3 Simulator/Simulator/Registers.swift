//
//  Registers.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

// TODO: somehow notify MainViewController of changed PC after finished running

struct Registers {
    var pc:  UInt16 = 0x3000
    var ir:  UInt16 = 0x0000
    var psr: UInt16 = 0x8002 // Sets CC to N = 0, Z = 1, P = 0 and privilege mode to user.

    enum CCType: String {
        case N
        case Z
        case P
        case Invalid = "?"
    }

    var cc: CCType {
        get {
            switch (N, Z, P) {
            case (true, false, false):
                return .N
            case (false, true, false):
                return .Z
            case (false, false, true):
                return .P
            default:
                return .Invalid
            }
        }
        set {
            switch newValue {
            case .N:
                N = true
            case .Z:
                Z = true
            case .P:
                P = true
            case .Invalid:
                preconditionFailure()
            }
        }
    }

    private var N: Bool {
        get {
            return psr.getBit(at: 2) == 1
        }
        set {
            precondition(newValue == true)
            psr.setBit(at: 2, to: 1)
            psr.setBit(at: 1, to: 0)
            psr.setBit(at: 0, to: 0)
        }
    }

    private var Z: Bool {
        get {
            return psr.getBit(at: 1) == 1
        }
        set {
            precondition(newValue == true)
            psr.setBit(at: 2, to: 0)
            psr.setBit(at: 1, to: 1)
            psr.setBit(at: 0, to: 0)
        }
    }

    private var P: Bool {
        get {
            return psr.getBit(at: 0) == 1
        }
        set {
            precondition(newValue == true)
            psr.setBit(at: 2, to: 0)
            psr.setBit(at: 1, to: 0)
            psr.setBit(at: 0, to: 1)
        }
    }

    var r: [UInt16] = [UInt16].init(repeating: 0, count: 8)
    // See book page 260 for rundown of these. They bascially just store the unused stack pointer when a permission level changes, which is used to restore it later
    var savedSSP: UInt16 = 0x2FFF // at 0x2FFF and not 0x3000 b/c the label for SS_START will now appear outside of user memory. Possibly a bit confusing, though.
    var savedUSP: UInt16 = 0

    enum PrivilegeMode {
        case Supervisor
        case User
    }

    var privilegeMode: PrivilegeMode {
        get {
            if psr.getBit(at: 15) == 1 {
                return .User
            } else {
                return .Supervisor
            }
        }
        set {
            switch newValue {
            case .User:
                psr.setBit(at: 15, to: 1)
            case .Supervisor:
                psr.setBit(at: 15, to: 0)
            }
        }
    }

    var priorityLevel: UInt16 {
        get {
            return psr.getBits(high: 10, low: 8)
        }
        set {
            // Assumes that bits to replace with are in only the lowest 3 bits of the passed-in UInt16.
            assert(newValue & 0b1111_1111_1111_1000 == 0)
            
            psr.setBit(at:  8, to: newValue.getBit(at: 0))
            psr.setBit(at:  9, to: newValue.getBit(at: 1))
            psr.setBit(at: 10, to: newValue.getBit(at: 2))
        }
    }

    subscript(index: UInt16) -> UInt16 {
        get {
            return r[Int(index)]
        }
        // NOTE: sets only the value of the memory entry
        set {
            r[Int(index)] = newValue
        }
    }

    mutating func setCC(basedOn value: UInt16) {
        let signedValue = Int16(bitPattern: value)
        
        if signedValue < 0 {
            N = true
        } else if signedValue == 0 {
            Z = true
        } else {
            P = true
        }
    }

}
