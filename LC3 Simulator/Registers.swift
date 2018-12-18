//
//  Registers.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

class Registers : NSObject {
    var pc : UInt16 = 0
    var ir: UInt16 = 0
    var psr : UInt16 = 0
    var cc : UInt16 = 0
    var r : [UInt16] = [UInt16].init(repeating: 0, count: 8)
    
    override init() {
        super.init()
    }
}
