//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// Question: Should I allow poorly-formatted instructions - ex. 0b1100_111_000_111111
// Question: should I include NOP? (all 0s)
// TODO: set up search for / jump to addresses
// TODO: decide what PC indicator is
// TODO: decide register UI

// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk

import Foundation
import Cocoa

class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var rowBeingEdited : Int?
    
    let backgroundQueue = DispatchQueue.global(qos: .userInteractive)
    
    // MARK: IB elements
    @IBOutlet weak var memoryTableView: NSTableView!
    @IBOutlet weak var registersTableView: NSTableView!
    
    var allColumnIndices : IndexSet {
        var allColumns : IndexSet = []
        for (index, _) in self.memoryTableView.tableColumns.enumerated() {
            allColumns.insert(index)
        }
        return allColumns
    }
    
    func refreshTableView(modifiedRow: Int) {
        DispatchQueue.main.async {
            // DOWNSIDE always grab correct number of columns, but might present a plenty of overhead
            let modifiedRowSet : IndexSet = [modifiedRow]
            self.memoryTableView.reloadData(forRowIndexes: modifiedRowSet, columnIndexes: self.allColumnIndices)
        }
    }
    
    func shouldStopProgramExecution() -> Bool {
        return shouldStopExecuting
    }
    
    func pcChanged() {
        DispatchQueue.main.async {
            self.memoryTableView.selectRowIndexes([Int(self.simulator.registers.pc)], byExtendingSelection: false)
        }
    }
    
    // MARK: IB actions
    @IBAction func runClickedWithSender(_ sender: AnyObject) {
        print("run clicked")
        shouldStopExecuting = false
        backgroundQueue.async {
            self.simulator.runForever(then: self.refreshTableView, shouldStopExecuting: self.shouldStopProgramExecution)
        }
        
//        memoryTableView.reloadData()
    }
    
    // TODO: insert step button? ACTUALY NO, USE STEP INTO
    @IBAction func stepInClickedWithSender(_ sender: AnyObject) {
        print("step clicked")
        shouldStopExecuting = false
        simulator.executeNextInstruction(afterMemoryModification: refreshTableView)
//        memoryTableView.reloadData()
    }
    
    @IBAction func stepOutClickedWithSender(_ sender : AnyObject) {
        print("step out clicked")
        
    }
    
    var shouldStopExecuting : Bool = false
    
    // TODO: stop running execution with
    @IBAction func stopClickedWithSender(_ sender: AnyObject) {
        shouldStopExecuting = true
    }
    
    // MARK: Constants
    let kStatusNoneImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)
    
    // MARK: Variables
    typealias Instruction = UInt16
    let simulator = Simulator()
    var memory : Memory!
    var consoleVC : ConsoleViewController?
    
    func setConsoleVC(to vc : ConsoleViewController) {
        self.consoleVC = vc
    }
    
    @objc func onItemClicked() {
        print("row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn) clicked")
        if memoryTableView.clickedColumn == 0 && memoryTableView.clickedRow >= 0 {
            memory[UInt16(memoryTableView.clickedRow)].shouldBreak.toggle()
            memoryTableView.reloadData(forRowIndexes: [memoryTableView.clickedRow], columnIndexes: [memoryTableView.clickedColumn])
        }
    }
//    var window : NSWindow!
    
    @objc func onItemDoubleClicked() {
        guard memoryTableView.clickedRow > 0 else { return }
        print("double clicked on row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn)")
        switch memoryTableView.clickedColumn {
        case 0:
            // just run the same logic for toggling a breakpoint
            onItemClicked()
        case 1:
            // address column
            // do nothing
            break
        case 2:
            // value (binary) column
            memoryTableView.editColumn(2, row: memoryTableView.clickedRow, with: nil, select: false)
            break
        case 3:
            // value (hex) column
            memoryTableView.editColumn(3, row: memoryTableView.clickedRow, with: nil, select: false)
        default:
            print("default")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display the console window when this VC loads
        // TODO: maybe use this sender instead of NSApp.mainWindow... in Console stuff
        performSegue(withIdentifier: "showConsoleWindow", sender: self)
        
        memory = simulator.memory
        print("viewloaded")
        simulator.setMainVC(to: self)
//        memoryTableView.rowView(atRow: 0x3000, makeIfNecessary: false)?.backgroundColor = .red
//        memoryTableView.highlightSelection(inClipRect: memoryTableView.rect(ofRow: 0x3000))
//        memoryTableView.reloadData()
//        window = NSWindow(contentViewController: ConsoleViewController())
//        window.windowController?.showWindow(self)
        memoryTableView.action = #selector(onItemClicked)
        memoryTableView.doubleAction = #selector(onItemDoubleClicked)
        
        memoryTableView.scrollRowToVisible(0x3020)
        memoryTableView.selectRowIndexes([Int(simulator.registers.pc)], byExtendingSelection: false)
//        memoryTableView.
    }

//    override var representedObject: Any? {
//        didSet {
//        // Update the view, if already loaded.
//        }
//    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === memoryTableView {
            return 0x10000
        }
        else {
            return 3
        }
    }
    
    // TODO: set font only once, hopefully in Interface Builder
    // TODO: refactor so I don't have to do a bunch of junk like "NSUserInter..." each time I run it
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        switch tableColumn?.identifier.rawValue {
        case "statusColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "statusCellID"), owner: self) as! NSTableCellView
            
            switch memory[UInt16(row)].shouldBreak {
                case true:
                cellView.imageView?.image = kStatusUnavailableIMage
                case false:
                cellView.imageView?.image = kStatusNoneImage
            }
            
//            if row == 1 {
//                cellView.imageView?.image = NSImage(imageLiteralResourceName: NSImage.goRightTemplateName)
//            } else if row == 3 {
//                cellView.imageView?.image = kStatusUnavailableIMage
//            } else {
//                cellView.imageView?.image = kStatusNoneImage
//            }
            return cellView
        case "addressColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addressCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueBinaryColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueBinaryCellID"), owner: self) as! NSTableCellView
            let unformattedBinaryString = String(memory[UInt16(row)].value, radix: 2)
            var formattedBinaryString = String(repeating: "0", count: 16 - unformattedBinaryString.count) + unformattedBinaryString
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 12))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 8))
            formattedBinaryString.insert(" ", at: String.Index(encodedOffset: 4))
            cellView.textField?.stringValue = formattedBinaryString
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueHexColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueHexCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "x%04X", memory[UInt16(row)].value)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "labelColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "labelCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory.getEntryLabel(of: row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "instructionColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "instructionCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = memory.instructionString(at: row)
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
            
        // MARK: cases having to do with second table
        case "registerNameCol1":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "registerNameCol1"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = "R\(row)"
            return cellView
        case "registerNameCol2":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "registerNameCol1"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = "R\(row + 3)"
            return cellView
        case "registerNameCol3":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "registerNameCol1"), owner: self) as! NSTableCellView
            if (row == 2) {
                cellView.textField?.stringValue = "CC"
            }
            else {
                cellView.textField?.stringValue = "R\(row + 6)"
            }
            return cellView
        case "registerNameCol4":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "registerNameCol1"), owner: self) as! NSTableCellView
            switch row {
            case 0:
                cellView.textField?.stringValue = "PC"
            case 1:
                cellView.textField?.stringValue = "IR"
            case 2:
                cellView.textField?.stringValue = "PSR"
            default:
                preconditionFailure("bad row")
            }
            return cellView
            
        default:
            let newTextField = NSTextField(string: "x\(row)")
            newTextField.isBezeled = false
            newTextField.drawsBackground = false
            return newTextField
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
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
extension MainViewController : NSOpenSavePanelDelegate {

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
                // less efficient (I think) than only loading modified rows
                // EVENTUALLY: create set of modified rows to pass into other type of reloadData()
                self.memoryTableView.reloadData()
            default:
                print("didn't select something")
            }
        }
    }
    
    // TODO: eventually allow .asm files and do the whole automatic assembling and loading thing
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        return url.pathExtension == "obj" || url.hasDirectoryPath
    }
    
}

extension MainViewController : NSTextFieldDelegate {
    
    func scanBinaryStringToUInt16(_ string : String) -> UInt16? {
        return 0
    }
    
    func scanHexStringToUInt16(_ string : String) -> UInt16? {
        return 0
    }
    
    // NOTE: Might need to change if IB settings don't keep to disallow editing of other columns
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        rowBeingEdited = row
        return true
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("here")
    }
    
    // if text makes sense, set memory, then reload table view
    // if it doesn't, just reload table view
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // if text makes sense
        //  put new value into memory
        // reload table view
        if let parsedString = scanBinaryStringToUInt16(fieldEditor.string) {
            self.memory?[UInt16(rowBeingEdited!)].value = parsedString
        }
        else if let parsedString = scanBinaryStringToUInt16(fieldEditor.string) {
            self.memory?[UInt16(rowBeingEdited!)].value = parsedString
        }
        memoryTableView.reloadData(forRowIndexes: [rowBeingEdited!], columnIndexes: allColumnIndices)
        
        return true
    }
}
