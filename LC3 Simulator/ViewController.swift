//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// Question: Should I allow poorly-formatted instructions - ex. 0b1100_111_000_111111
// Question: should I include NOP? (all 0s)

import Foundation
import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: IB elements
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: Constants
    let kStatusNoneImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)
    
    // MARK: Variables
    typealias Instruction = UInt16
    let simulator = Simulator()
    var memory : Memory!
    
    func onItemClicked() {
        print("row \(tableView.clickedRow), col \(tableView.clickedColumn) clicked")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        memory = simulator.memory
        print("viewloaded")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 0xFFFF + 1
    }
    
    // TODO: set font only once, hopefully in Interface Builder
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier.rawValue {
        case "statusColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "statusCellID"), owner: self) as! NSTableCellView
            if row == 1 {
                cellView.imageView?.image = NSImage(imageLiteralResourceName: NSImage.goRightTemplateName)
            } else if row == 3 {
                cellView.imageView?.image = kStatusUnavailableIMage
            } else {
                cellView.imageView?.image = kStatusNoneImage
            }
            return cellView
        case "addressColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addressCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueBinaryColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            let unformattedBinaryString = String(memory[row].value, radix: 2)
            var formattedBinaryString = String(repeating: "0", count: 16 - unformattedBinaryString.count) + unformattedBinaryString
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 12))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 8))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 4))
            cellView.textField?.stringValue = formattedBinaryString
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueHexColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", memory[row].value)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "labelColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory.getEntryLabel(of: row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "instructionColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "instructionCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory.instructionString(at: row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        default:
            let newTextField = NSTextField(string: "\(row)")
            newTextField.isBezeled = false
            newTextField.drawsBackground = false
            return newTextField
        }
    }


}


//
//extension ViewController: NSSearchFieldDelegate {
//
//    func searchFieldDidEndSearching(_ sender: NSSearchField) {
//        if let cell = sender.cell as? NSSearchFieldCell {
//            print("hello")
//        }
//        print("hi")
//    }
//
//}

// MARK: NSOpenSavePanelDelegate methods
extension ViewController : NSOpenSavePanelDelegate {

    // NOTE: not a part of the delegate
    @IBAction func openDocument(_ sender: NSMenuItem) {
        print("called openDocument() in VC")
        let window = NSApp.mainWindow!
        let panel = NSOpenPanel()
        panel.delegate = self
        panel.message = "Import an assembled file"
        panel.beginSheetModal(for: window) { (response) in
            switch (response) {
            case .OK:
                print("selected the files \(panel.urls)")
                self.memory.loadProgramsFromFiles(at: panel.urls)
                self.tableView.reloadData()
            default:
                print("didn't select something")
            }
        }
    }
    
    // TODO: eventually allow .asm files and do the whole automatic assembling and loading thing
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        return url.pathExtension == "obj"
    }
    
}
