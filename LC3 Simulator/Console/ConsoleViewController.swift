//
//  ConsoleViewController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

// TODO: figure out what to do about printing non-ASCII characters. Probably compare to ouput of command-line and Windows simulators.
class ConsoleViewController: NSViewController {
    
    // MARK: Notification name constants
    
    static let kShouldReset                   = Notification.Name("resetConsoleNotificationName")
    static let kNewStringTyped                = Notification.Name("newStringTypedNotificationName")
    static let kClearConsoleInputClicked      = Notification.Name("clearConsoleInputClickedNotificationName")
    static let kConsoleInputQueueCountChanged = Notification.Name("consoleInputQueueCountChanged")
    
    // MARK: IBOutlets
    
    @IBOutlet private var textView:                    NSTextView!
    @IBOutlet private var consoleInputQueueCountLabel: NSTextField!

    // MARK: IBActions
    
    @IBAction func clearConsoleDisplayClicked(with _: AnyObject) {
        textView.string = ""
        self.numCharsInTextView = 0
    }
    
    @IBAction func clearConsoleInputBufferClicked(with _: AnyObject) {
        NotificationCenter.default.post(name: ConsoleViewController.kClearConsoleInputClicked, object: nil)
    }

    // MARK: Notification handlers
    
    @objc func shouldResetConsole(_ notification: Notification) {
        textView.string = ""
        self.numCharsInTextView = 0
    }
    
    @objc func consoleInputQueueCountChanged(_ notification: Notification) {
        guard let newCount = notification.userInfo?["newCount"] as? Int else { preconditionFailure() }
        
        DispatchQueue.main.async {
            self.consoleInputQueueCountLabel.stringValue = "\(newCount) buffered character\(newCount == 1 ? "" : "s")"
        }
    }
    
    var numCharsInTextView = 0
    @objc private func logCharactersInNotification(_ notification: Notification) {
        guard let characterToLog = notification.object as? Character else {
            preconditionFailure()
        }
        
        DispatchQueue.main.async {

            let oldMaxY       = self.textView.bounds.maxY
            let wasNearBottom = oldMaxY - self.textView.visibleRect.maxY <= 20

            self.textView.replaceCharacters(in: NSMakeRange(self.numCharsInTextView, 0), with: String(characterToLog))

            // Scrolls to the bottom of the text view if a new character is added if the bottom of the view was already visible.
            if wasNearBottom/*, oldMaxY < self.textView.bounds.maxY*/ {
                self.textView.scrollRangeToVisible(NSRange(location: self.numCharsInTextView, length: 0))
            }
            
            self.numCharsInTextView += 1
        }
    }
    
    // MARK: Class methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: try removing and base on IB settings
        // Use digits monospaced font.
        if let fontSize = textView.font?.pointSize, let font = NSFont.userFixedPitchFont(ofSize: fontSize) {
            textView.font = font
        }

        self.consoleInputQueueCountLabel.stringValue = "0 buffered characters"
        
        NotificationCenter.default.addObserver(self, selector: #selector(logCharactersInNotification(  _:)), name: Memory.kLogCharacterMessageName,                      object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(consoleInputQueueCountChanged(_:)), name: ConsoleViewController.kConsoleInputQueueCountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldResetConsole(           _:)), name: ConsoleViewController.kShouldReset,                   object: nil)
    }
}

// TODO: ensure backspace works? might run in to trouble here
// TODO: give some sort of error notifiaction when non-ASCII character is pasted?
extension ConsoleViewController: NSTextViewDelegate {
    // insert each ASCII character typed into the queue without altering the string in the NSTextView
    func textView(_: NSTextView, shouldChangeTextIn _: NSRange, replacementString: String?) -> Bool {
        if let replacementString = replacementString {
            NotificationCenter.default.post(name: ConsoleViewController.kNewStringTyped, object: nil, userInfo: ["newString" : replacementString])
        }

        return false
    }
}

extension Character {
    var isASCII: Bool {
        return unicodeScalars.first!.isASCII
    }
}
