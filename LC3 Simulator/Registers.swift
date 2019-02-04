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
    var psr : UInt16 = 0
    // I don't think there's actually a CC register, I'm pretty sure it's all in the PSR.
//    var cc : UInt16 = 0
    var N : Bool = false
    var Z : Bool = true
    var P : Bool = false
    var r : [UInt16] = [UInt16].init(repeating: 0, count: 8)
    
    subscript(index: UInt16) -> UInt16 {
//        precond
        get {
            return r[Int(index)]
        }
        // NOTE: sets only the value of the memory entry
        set {
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
