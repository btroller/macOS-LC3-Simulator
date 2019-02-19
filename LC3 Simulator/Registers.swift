//
//  Registers.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

class Registers {
    var pc : UInt16 = 0x3000
    var ir: UInt16 = 0
    var psr : UInt16 = 0x2 // set CC to N = 0, Z = 1, P = 0
//    var cc : UInt16 = 0
    var N : Bool {
        get {
            return psr.getBit(at: 2) == 1
        }
        set {
            psr.setBit(at: 2, to: newValue ? 1 : 0)
        }
    }
    var Z : Bool {
        get {
            return psr.getBit(at: 1) == 1
        }
        set {
            psr.setBit(at: 1, to: newValue ? 1 : 0)
        }
    }
    var P : Bool {
        get {
            return psr.getBit(at: 0) == 1
        }
        set {
            psr.setBit(at: 0, to: newValue ? 1 : 0)
        }
    }
    var r : [UInt16] = [UInt16].init(repeating: 0, count: 8)
    
    enum PrivilegeMode {
        case Supervisor
        case User
    }
    
    var privilegeMode : PrivilegeMode {
        get {
            if (psr.getBit(at: 15) == 1) {
                return .User
            }
            else {
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
    
    var priorityLevel : UInt16 {
        return psr.getBits(high: 10, low: 8)
    }
    
    subscript(index: UInt16) -> UInt16 {
        
        get {
            precondition(0...7 ~= index, "Attempt to access illegal register no. \(index)")
            
            return r[Int(index)]
        }
        // NOTE: sets only the value of the memory entry
        set {
            precondition(0...7 ~= index, "Attempt to access illegal register no. \(index)")
            
            r[Int(index)] = newValue
        }
    }
    
    func setCC(basedOn value: UInt16) {
        N = false
        Z = false
        P = false
        
        let signedValue = Int16(bitPattern: value)
        if signedValue < 0 {
            N = true
        }
        else if value == 0 {
            Z = true
        }
        else {
            P = true
        }
    }
    
    // Could use scheme like this to access each register individually and safely, but will take more room
    // definitely convenient to have an array for main registers
//    var r0 : UInt16 {
//        get {
//            return r[0]
//        }
//        set {
//            r[0] = newValue
//        }
//    }
    
//    override init() {
//        super.init()
//    }
}
