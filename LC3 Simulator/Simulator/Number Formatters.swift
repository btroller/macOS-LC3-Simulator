//
//  BinaryNumberFormatter.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/28/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

// NOTES: I tried going this route but it's not working well because (I think) the type of element in the table view cells are strings, not numbers. I probably need to rearchitect the thing to get this to work, so I think I'll continue on the hack-it-together path by directly looking at what a cell is changed to

import Foundation

//class BinaryNumberFormatter: Formatter {
//    override func string(for obj: Any?) -> String? {
//        guard let inString = obj as? String else {
//            return nil
//        }
//        print("here")
//        return nil
//    }
//
//    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
//        <#code#>
//    }
//
//    // string without
//    override func editingString(for obj: Any) -> String? {
//        <#code#>
//    }
//}

class HexNumberFormatter: Formatter {
    
    func getUInt16FromString(_ string : String) -> UInt16? {
        let scanner = Scanner(string: string)
        var result : UInt32 = 0
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "x"))
        // BEWARE: might have issue with overflow here
        if (!scanner.scanHexInt32(&result)) {
            return nil
        }
        let shortenedResult = UInt16(result & 0x0FFFF)
        if (shortenedResult != result) {
            // overflow
            return nil
        }
        
        print("in getUInt16FromString")
        return shortenedResult
    }
    
    override func string(for obj: Any?) -> String? {
        print("in string")
        
        guard let inString = obj as? String else {
            return nil
        }
        
        return inString
    }
    
    // string without starting `0x`
    override func editingString(for obj: Any) -> String? {
        print("in editingString")
        
        guard let inString = obj as? String else {
            return nil
        }
        
        if let underlyingNumber = getUInt16FromString(inString) {
            return String(format: "%04X", underlyingNumber)
        }
        
        return nil
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        let scanner = Scanner(string: string)
        var result : UInt32 = 0
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "x"))
        // BEWARE: might have issue with overflow here
        if (!scanner.scanHexInt32(&result)) {
            return false
        }
        let shortenedResult = UInt16(result & 0x0FFFF)
        if (shortenedResult != result) {
            // overflow
            return false
        }
        
        print("in object value")
        return true
    }
}
