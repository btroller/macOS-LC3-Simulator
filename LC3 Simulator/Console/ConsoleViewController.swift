//
//  ConsoleViewController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

// TODO: allow for clearing of input buffer and clearing of output screen
class ConsoleViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    
    var queue = ConsoleInputQueue<Character>()
    
    func log(_ string : String) {
        DispatchQueue.main.async {
            self.textView.string.append(string)
        }
    }
    
    func log(_ char : Character) {
        DispatchQueue.main.async {
            self.textView.string.append(char)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // a stupid and hacky way of getting ahold of the main view controller before NSApp.mainWindow is set
        for window in NSApp.windows where window.contentViewController !== self {
            if let mainVC = window.contentViewController as? MainViewController {
                mainVC.setConsoleVC(to: self)
                print("set consoleVC in main")
            }
            else {
                print("failed to setConsoleVC, things will fail soon")
            }
        }
        
        // use digits monospaced font
        // EVENTUALLY: make a standard monospaced font at least a choice - can't bundle SF Mono due to license
        //  don't want to have inconsistent font in app
        textView.font = NSFont.monospacedDigitSystemFont(ofSize: (textView.font?.pointSize)!, weight: NSFont.Weight.regular)

    }
    
}

// TODO: ensure backspace works? might run in to trouble here
extension ConsoleViewController : NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        // TODO: ignore non-ASCII characters?
        print("called with \(replacementString)")
        replacementString?.forEach({ (char) in
            if (char.isAscii) {
                queue.push(char)
                print("inserted \(char) (\(char.unicodeScalars.first))")
            }
            else {
                print("didn't insert \(char)")
            }
        })
        
        return false
    }
}

extension Character {
    var isAscii : Bool {
        return unicodeScalars.first?.isASCII ?? false
    }
}
