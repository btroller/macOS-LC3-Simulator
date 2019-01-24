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
    
    // TODO: implement NSOpenSavePanelDelegate to only allow loading of appropriate files
    @IBAction func openDocument(_ sender: NSMenuItem) {
        print("here in VC")
        let window = NSApp.mainWindow!
        let panel = NSOpenPanel()
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
//        print("openDocument ViewController")
//        if let url = NSOpenPanel().selectUrl {
//            imageView.image = NSImage(contentsOf: url)
//            print("file selected:", url.path)
//        } else {
//            print("file selection was canceled")
//        }
    }
    
//    func openDocument() {
//        let window = NSApp.mainWindow!
//        let panel = NSOpenPanel()
//        panel.message = "Import an assembled file"
//        panel.beginSheetModal(for: window) { (response) in
//            switch (response) {
//            case .OK:
//                print("selected the files \(panel.urls)")
//            default:
//                print("didn't select somethign")
//            }
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        memory = simulator.memory
        // TODO: remove
        // Randomly fills memory with junk (for testing purposes)
//        for address in 0...0xFFFF {
//            memory[address] = UInt16.random(in: UInt16.min...UInt16.max)
//        }
//        memory[0x3000] = 0b0001000111000110
//        memory[0x3001] = 0b0000_111_111111111
//        tableView.
//        tableView.reloadData()
        print("viewloaded")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        // Note -- might be 0xFFFF, but online simulator has 0 through 0xFFFF
        return 0xFFFF + 1
    }
    
    // TODO: set font only once, hopefully in Interface Builder
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        switch tableColumn?.identifier.rawValue {
//        case "statusColumnID":
//            let tmp =
//            tmp.imageView = NSImageView(image: NSImage(imageLiteralResourceName: NSImage.goRightTemplateName))
//            return tmp
//        default:
//            let tmp = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addressCellID"), owner: self) as! NSTableCellView
//            tmp.textField = NSTextField(string: String(format: "x%04X", row))
//            return tmp
//        }
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
//            let newTextField = NSTextField(string: String(format: "x%04X", row))
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueBinaryColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            let unformattedBinaryString = String(memory[row], radix: 2)
            var formattedBinaryString = String(repeating: "0", count: 16 - unformattedBinaryString.count) + unformattedBinaryString
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 12))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 8))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 4))
            cellView.textField?.stringValue = formattedBinaryString
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: formattedBinaryString)
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
//            return newTextField
            return cellView
        case "valueHexColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", memory[row])
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: String(format: "x%04X", row))
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            newTextField.font = NSFont.monospacedDigitSystemFont(ofSize: (newTextField.font?.pointSize)!, weight: NSFont.Weight.regular)
//            return newTextField
            return cellView
        case "instructionColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "instructionCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory[row].stringFromInstruction
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
//            let newTextField = NSTextField(string: "NOT      R0, R0")
//            newTextField.isBezeled = false
//            newTextField.drawsBackground = false
//            return newTextField
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
