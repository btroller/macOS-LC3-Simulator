//
//  Memory.swift
//  Delete
//
//  Created by Benjamin Troller on 12/17/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Foundation

class Memory : NSObject {
    typealias Instruction = UInt16
    var memory : [UInt16] = [UInt16].init(repeating: 0, count: 0xFFFF + 1)
}
