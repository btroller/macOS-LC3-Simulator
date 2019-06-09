//
//  MainWindowController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/28/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var addressSearchField: NSSearchField!
    @IBOutlet var addressSearchBarItem: NSToolbarItem!

    // close app when simulator's close button is pressed
    func windowShouldClose(_: NSWindow) -> Bool {
        NSApp.terminate(self)
        return true
    }
}

// MARK: make address search field the first responder after menu "find" item clicked

extension MainWindowController {
    func makeAddressSearchFieldFirstResponder() {
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(self.addressSearchField)
        }
    }
}
