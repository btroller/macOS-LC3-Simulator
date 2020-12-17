//
//  MainWindowController.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/28/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var addressSearchField:   NSSearchField!
    @IBOutlet var addressSearchBarItem: NSToolbarItem!
    
    // Close the app when the main window is closed.
    func windowShouldClose(_: NSWindow) -> Bool {
        NSApp.terminate(self)
        return true
    }
}

// Allow MainViewController to make the search field the first responder.
extension MainWindowController {
    func makeAddressSearchFieldFirstResponder() {
        self.window?.makeFirstResponder(self.addressSearchField)
    }
}
