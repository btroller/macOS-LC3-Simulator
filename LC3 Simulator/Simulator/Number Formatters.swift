//
//  BinaryNumberFormatter.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/28/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

// TODO: change isPartialStringValid() in BinaryNumberFormatter to use spaces in formatting - taken out presently to simplify
// MAYBE: change way BinaryNumberFormatter give editingString to just have spaces in it for simplicity's sake, which can be stripped out easily

import Foundation

class BinaryNumberFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let inUInt16 = obj as? UInt16 else {
            return nil
        }

        var formattedBinaryString = String(inUInt16, radix: 2, paddedTo: UInt16.bitWidth)
        formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 12, in: formattedBinaryString))
        formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 8, in: formattedBinaryString))
        formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 4, in: formattedBinaryString))

        return formattedBinaryString
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        var strippedString = string
        strippedString.removeAll { $0 != "0" && $0 != "1" }

        if string.count < 1 {
            error?.pointee = "Input of length 0" as NSString
            return false
        }

        let result = UInt16(strtoul(strippedString, nil, 2))

        obj?.pointee = result as AnyObject
        return true
    }

    override func editingString(for obj: Any) -> String? {
        guard let inUInt16 = obj as? UInt16 else {
            return nil
        }

        return String(inUInt16, radix: 2, paddedTo: UInt16.bitWidth)
    }

    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange _: NSRangePointer?, originalString _: String, originalSelectedRange _: NSRange, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "10 ")
        
        var strippedString = partialStringPtr.pointee as String
        strippedString.removeAll {  $0 != "0" && $0 != "1" }

        if strippedString.count <= 16 && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: partialStringPtr.pointee as String)) {
            partialStringPtr.pointee = strippedString as NSString
            return true
        } else {
            return false
        }
    }
}

class HexNumberFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let inUInt16 = obj as? UInt16 else {
            return nil
        }

        return String(format: "x%04X", inUInt16)
    }

    // gives string without starting `x`
    // TODO: preserve editing position if possible
    override func editingString(for obj: Any) -> String? {
        guard let inUInt16 = obj as? UInt16 else {
            return nil
        }

        return String(format: "%04X", inUInt16)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let scanner = Scanner(string: string)
        var result: UInt64 = 0
        // TODO: might have issue with overflow here
        if !scanner.scanHexInt64(&result) {
            // scanner failed to scan from `string`
            error?.pointee = "bad input - failed to scan" as NSString
            return false
        } else if scanner.currentIndex != string.endIndex {
            // scanner didn't scan all of `string` - must be bad characters in it somewhere
            error?.pointee = "bad input - disallowed characters present" as NSString
            return false
        }

        let shortenedResult = UInt16(result & 0x0FFFF)
        if shortenedResult != result {
            // overflow
            error?.pointee = "bad input - too large" as NSString
            return false
        }

        obj?.pointee = shortenedResult as AnyObject
        return true
    }

    // check whether a partial string is valid, also preserve cursor position
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange _: NSRangePointer?, originalString _: String, originalSelectedRange _: NSRange, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits.union(["A", "B", "C", "D", "E", "F"])

        return /* partialString.count > 0 && */ partialStringPtr.pointee.length <= 4 && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: partialStringPtr.pointee.uppercased))
    }
}

// TODO: at least mostly combine with HexNumberFormatter
class SearchBarHexNumberFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        if obj == nil || obj as? String == "" {
            return ""
        }

        guard let inUInt16 = obj as? UInt16 else {
            assertionFailure("shouldn't get here, obj = \(String(describing: obj))")
            return nil
        }

        return String(format: "%X", inUInt16)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let scanner = Scanner(string: string)
        var result: UInt64 = 0

        // case of empty search - do nothing, but allow user to exit search box by returning true
        if string.isEmpty {
            obj?.pointee = nil
            return true
        }
        if !scanner.scanHexInt64(&result) {
            // scanner failed to scan from `string`
            error?.pointee = "bad input - failed to scan" as NSString
            return false
        } else if scanner.currentIndex != string.endIndex {
//        } else if scanner.currentIndex != string.endIndex {
            // scanner didn't scan all of `string` - must be bad characters in it somewhere
            error?.pointee = "bad input - disallowed characters present" as NSString
            return false
        }

        let shortenedResult = UInt16(result & 0x0FFFF)
        if shortenedResult != result {
            // overflow
            error?.pointee = "bad input - too large" as NSString
            return false
        }

        obj?.pointee = shortenedResult as AnyObject
        return true
    }

    // check whether a partial string is valid, also preserve cursor position
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange _: NSRangePointer?, originalString _: String, originalSelectedRange _: NSRange, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits.union(["A", "B", "C", "D", "E", "F"])

        return /* partialString.count > 0 && */ partialStringPtr.pointee.length <= 4 && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: partialStringPtr.pointee.uppercased))
    }
}

class Base10NumberFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let inUInt16 = obj as? UInt16 else {
            return nil
        }

        return String(format: "%hu", inUInt16)
    }

    /*
     // gives string without starting `x`
     // TODO: preserve editing position if possible
     override func editingString(for obj: Any) -> String? {
         guard let inUInt16 = obj as? UInt16 else {
             return nil
         }

         return String(format: "%04X", inUInt16)
     }
     */

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let scanner = Scanner(string: string)
        var result: Int64 = 0
        // BEWARE: might have issue with overflow here
        if !scanner.scanInt64(&result) {
            // scanner failed to scan from `string`
            error?.pointee = "bad input - failed to scan" as NSString
            return false
        } else if scanner.currentIndex != string.endIndex {
            // scanner didn't scan all of `string` - must be bad characters in it somewhere
            error?.pointee = "bad input - disallowed characters present" as NSString
            return false
        }

        let shortenedResult = UInt16(result & 0x0FFFF)
        if shortenedResult != result {
            // overflow
            error?.pointee = "bad input - too large" as NSString
            return false
        }

        obj?.pointee = shortenedResult as AnyObject
        return true
    }

    // check whether a partial string is valid, also preserve cursor position
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange _: NSRangePointer?, originalString _: String, originalSelectedRange _: NSRange, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits

        return /* partialString.count > 0 && */ partialStringPtr.pointee.length <= 5 && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: partialStringPtr.pointee.uppercased))
    }
}

class CCFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let ccType = obj as? Registers.CCType else {
            return nil
        }

        switch ccType {
        case .N:
            return "N"
        case .Z:
            return "Z"
        case .P:
            return "P"
        case .Invalid:
            return "?"
        }
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if let value = Registers.CCType(rawValue: string.uppercased()) {
            obj?.pointee = value as AnyObject
            
            return true
        } else {
            return false
        }
    }

    // check whether a partial string is valid, also preserve cursor position
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange _: NSRangePointer?, originalString _: String, originalSelectedRange _: NSRange, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let allowedCharacters: CharacterSet = ["N", "Z", "P"]

        return /* partialString.count > 0 && */ partialStringPtr.pointee.length <= 1 && allowedCharacters.isSuperset(of: CharacterSet(charactersIn: partialStringPtr.pointee.uppercased))
    }
}

extension String {
    init(_ val: UInt16, radix: Int, paddedTo width: Int) {
        let tempVal = String(val, radix: radix)
        let pad = String(repeating: "0", count: width - tempVal.count)
        self = pad + tempVal
        assert(count == width)
    }
}
