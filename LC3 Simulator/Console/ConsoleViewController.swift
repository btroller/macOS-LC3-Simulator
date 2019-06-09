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
    @IBOutlet var consoleInputQueueCountLabel: NSTextField!

    @IBAction func clearConsoleDisplayClicked(with _: AnyObject) {
        textView.string = ""
    }

    @IBAction func clearConsoleInputBufferClicked(with _: AnyObject) {
        queue = ConsoleInputQueue()
        updateInputQueueCountLabel()
    }

    var queueHasNext: Bool {
        return queue.hasNext
    }

    func popFromQueue() -> Character? {
        return queue.pop()
    }

    // TODO: make all pops decreate the no. of characters registered in the queue according to string
    private var queue = ConsoleInputQueue()

    func resetConsole() {
        queue = ConsoleInputQueue()
        textView.string = ""
        updateInputQueueCountLabel()
    }

    func updateInputQueueCountLabel() {
        let newString = "\(queue.count) buffered characters"
        DispatchQueue.main.async {
            self.consoleInputQueueCountLabel.stringValue = newString
        }
    }

    private func log(_ char: Character) {
        DispatchQueue.main.sync {
            let shouldScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY
                
            self.textView.string.append(char)
            
            // scrolls to the bottom of the text view if a new character is added iff the bottom of the view was already visible
            if shouldScroll {
                self.textView.scrollToEndOfDocument(nil)
            }
        }
    }

    // MARK: methods dealing with notifications

    @objc private func logCharactersInNotification(_ notification: Notification) {
        if let characterToLog = notification.object as? Character {
            log(characterToLog)
        }
    }

    static let kConsoleInputQueueCountChanged = Notification.Name("consoleInputQueueCountChanged")

    // called when Memory wants another character from the console
    @objc private func consoleInputQueueCountChanged(_: Notification) {
        updateInputQueueCountLabel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // a stupid and hacky way of getting ahold of the main view controller before NSApp.mainWindow is set
        for window in NSApp.windows where window.contentViewController !== self {
            if let mainVC = window.contentViewController as? MainViewController {
                mainVC.setConsoleVC(to: self)
                print("set consoleVC in main")
            } else {
                preconditionFailure("failed to setConsoleVC")
            }
        }

        // use digits monospaced font
        if let fontSize = textView.font?.pointSize, let font = NSFont.userFixedPitchFont(ofSize: fontSize) {
            textView.font = font
        }

        NotificationCenter.default.addObserver(self, selector: #selector(logCharactersInNotification), name: Memory.kLogCharacterMessageName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(consoleInputQueueCountChanged (_:)), name: ConsoleViewController.kConsoleInputQueueCountChanged, object: nil)

        updateInputQueueCountLabel()
    }
}

// TODO: ensure backspace works? might run in to trouble here
// TODO: give some sort of error notifiaction when non-ASCII character is pasted?
extension ConsoleViewController: NSTextViewDelegate {
    // insert each ASCII character typed into the queue without altering the string in the NSTextView
    func textView(_: NSTextView, shouldChangeTextIn _: NSRange, replacementString: String?) -> Bool {
        DispatchQueue.global(qos: .userInitiated).async {
            if let replacementString = replacementString {
                self.queue.push(replacementString)
            }
        }

        return false
    }
}

extension Character {
    var isASCII: Bool {
        return unicodeScalars.first?.isASCII ?? false
    }
}
