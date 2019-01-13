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
    var cc : UInt16 = 0
    var r : [UInt16] = [UInt16].init(repeating: 0, count: 8)
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
