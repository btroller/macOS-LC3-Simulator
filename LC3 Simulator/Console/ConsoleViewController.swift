//
//  ConsoleViewController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

// TODO: allow for clearing of input buffer and clearing of output screen
// TODO: figure out what to do about printing non-ASCII characters - compare to ouput of command-line and Windows simulators
class ConsoleViewController: NSViewController {

    @IBOutlet private var textView: NSTextView!
    
    var queue = ConsoleInputQueue<Character>()
    
    func resetConsole() {
        queue = ConsoleInputQueue<Character>()
        textView.string = ""
    }
    
    // EVENTUALLY: remove the unused log() function
    private func log(_ string : String) {
        DispatchQueue.main.async {
            self.textView.string.append(string)
        }
    }
    
    private func log(_ char : Character) {
        DispatchQueue.main.async {
            self.textView.string.append(char)
        }
    }
    
    // MARK: methods dealing with notifications
    @objc private func logCharactersInNotification(_ notification: Notification) {
        if let characterToLog = notification.object as? Character {
            self.log(characterToLog)
        }
    }
    
    // called when Memory wants another character from the console
    @objc private func receiveRequestForNextConcoleCharacter(_ notification: Notification) {
        NotificationCenter.default.post(name: Memory.kReceiveNextConsoleCharacter, object: queue.pop())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // a stupid and hacky way of getting ahold of the main view controller before NSApp.mainWindow is set
        for window in NSApp.windows where window.contentViewController !== self {
            if let mainVC = window.contentViewController as? MainViewController {
                mainVC.setConsoleVC(to: self)
                print("set consoleVC in main")
                // needed to ...
//                window.orderBack(self)
//                window.resignKey()
//                NSApp.mainWindow?.orderFront(self)
//                NSApp.mainWindow?.makeKeyAndOrderFront(self)
//                if let mainVC = NSApp.mainWindow?.contentViewController as? MainViewController {
//                    print("worked")
//                }
            }
            else {
                preconditionFailure("failed to setConsoleVC")
            }
        }
        
        // use digits monospaced font
        // EVENTUALLY: make a standard monospaced font at least a choice - can't bundle SF Mono due to license
        //  and don't want to have inconsistent font in app
//        textView.font = NSFont.monospacedDigitSystemFont(ofSize: (textView.font?.pointSize)!, weight: NSFont.Weight.regular)
        if let fontSize = textView.font?.pointSize, let font = NSFont.userFixedPitchFont(ofSize: fontSize) {
            textView.font = font
        }

        NotificationCenter.default.addObserver(self, selector: #selector(logCharactersInNotification), name: Memory.kLogCharacterMessageName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveRequestForNextConcoleCharacter), name: Memory.kRequestNextConsoleCharacter, object: nil)
    }
    
}

// TODO: ensure backspace works? might run in to trouble here
// TODO: give some sort of error notifiaction when non-ASCII character is pasted?
extension ConsoleViewController : NSTextViewDelegate {
    
    // insert each ASCII character typed into the queue without altering the string in the NSTextView
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        replacementString?.forEach({ (char) in
            if (char.isASCII) {
                queue.push(char)
            }
        })
        
        return false
    }
    
}

extension Character {
    
    var isASCII : Bool {
        return unicodeScalars.first?.isASCII ?? false
    }
    
}
