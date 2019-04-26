//
//  MainWindowController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/28/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var addressSearchField: NSSearchField!
    @IBOutlet weak var addressSearchBarItem: NSToolbarItem!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    // close app when simulator's close button is pressed
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.terminate(self)
        return true
    }

}

// MARK: make address search field the first responder after menu "find" item clicked
extension MainWindowController {

    func makeAddressSearchFieldFirstResponder() {
        DispatchQueue.main.async {
//            self.addressSearchBarItem.
            self.window?.makeFirstResponder(self.addressSearchField)
        }
    }

    func makeAddressSearchFieldFirstResponderWithStringAndSearch(_ string: String) {
        DispatchQueue.main.async {
            self.addressSearchField.stringValue = string
            self.makeAddressSearchFieldFirstResponder()
            if let addressSearchFieldCell = self.addressSearchField.cell as? NSSearchFieldCell {
                addressSearchFieldCell.searchButtonCell?.performClick(nil)
            }
        }
    }

}

//extension MainWindowController: NSSearchFieldDelegate {
//
//    func searchFieldDidStartSearching(_ sender: NSSearchField) {
//        print("started")
//    }
//
//    func searchFieldDidEndSearching(_ sender: NSSearchField) {
//        print("ended")
//    }
//
//}
