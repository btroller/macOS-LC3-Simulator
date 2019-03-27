//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// TODO: decide what PC indicator is - try changing color of row to green, also allow selecting of lines separately
//   also figure out what to do if selected row is also PC - probably mix colors somehow
// TODO: decide register UI
// TODO: only enable buttons when they make sense
// TODO: add "Jump to PC" menu option
// TODO: make search for address show result as selected and in middle of page if possible
// TODO: disable editing of registers/memory (but still allow setting breakpoints) while running continuously
// TODO: add "Set PC" option in context menu and menu bar (probably once selection of rows is available)


// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk

import Foundation
import Cocoa

class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var rowBeingEdited : Int?
    var shouldStopExecuting : Bool = false
    
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
        assertionFailure("not implemented yet")
    }
    
    // TODO: stop running execution with
    @IBAction func stopClickedWithSender(_ sender: AnyObject) {
        shouldStopExecuting = true
    }
    
    @IBAction func scrollToPCClickedWithSender(_ sender: AnyObject) {
        DispatchQueue.main.async {
            let pcRow = Int(self.simulator.registers.pc)
//            self.memoryTableView.scrollRowToVisible(pcRow)
            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(pcRow)
        }
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
    
    // NOTE: might also trigger for registers table view for now
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
            rowBeingEdited = memoryTableView.clickedRow
            memoryTableView.editColumn(2, row: memoryTableView.clickedRow, with: nil, select: false)
            break
        case 3:
            // value (hex) column
            rowBeingEdited = memoryTableView.clickedRow
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
        
        // TODO: change to be dynamic
        // scroll to place PC in middle of memory table view
//        memoryTableView.scrollRowToVisible(0x3020)
        DispatchQueue.main.async {
            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(Int(self.simulator.registers.pc))
        }
        // show PC appropriately
        pcChanged()
//        memoryTableView.selectRowIndexes([Int(simulator.registers.pc)], byExtendingSelection: false)
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
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 12, in: formattedBinaryString))
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 8, in: formattedBinaryString))
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 4, in: formattedBinaryString))
            cellView.textField?.stringValue = formattedBinaryString
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: (cellView.textField?.font?.pointSize)!, weight: NSFont.Weight.regular)
            return cellView
        case "valueHexColumnID":
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "valueHexCellID"), owner: self) as! NSTableCellView
            cellView.textField?.stringValue = String(format: "%04X", memory[UInt16(row)].value)
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

    // disable selection of all rows
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        switch tableColumn?.identifier.rawValue {
        case "valueHexColumnID":
            return memory[UInt16(row)].value
        case "valueBinaryCellID":
            return memory[UInt16(row)].value
        default:
            return nil
        }
        
    }

}

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
        let formatter = BinaryNumberFormatter()
        var obj : AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if !formatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return nil
        }
        
        return obj as? UInt16
    }
    
    func scanHexStringToUInt16(_ string : String) -> UInt16? {
        let formatter = HexNumberFormatter()
        var obj : AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if formatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        }
        else {
            return nil
        }
    }
    
    // if text makes sense, set memory, then reload table view
    // if it doesn't, just reload table view
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // put new value into memory
        // reload table view
        DispatchQueue.main.async {
            switch control.identifier?.rawValue {
            case "hexValueCellID":
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                }
            case "binaryValueCellID":
                if let parsedString = self.scanBinaryStringToUInt16(fieldEditor.string) {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                }
            default:
                assertionFailure("Failed to match identifier of control in control()")
            }

            self.memoryTableView.reloadData(forRowIndexes: [self.rowBeingEdited!], columnIndexes: self.allColumnIndices)
        }
        
        print("in control function, new string value \(fieldEditor.string)")
        
        return true
    }
}

// MARK: search bar stuff
extension MainViewController {
    
    // TODO: implement better version
    @IBAction func searchingFinished(_ sender: NSSearchField) {
        if let scannedValue = scanHexStringToUInt16(sender.stringValue) {
            DispatchQueue.main.async {
                self.memoryTableView.scrollToMakeRowVisibleWithSpacing(Int(scannedValue))
            }
        }
    }
    
    @IBAction func findMenuItemClickedWithSender(_ sender: Any) {
        if let mainWindowController = NSApp.mainWindow?.windowController as? MainWindowController {
            mainWindowController.makeAddressSearchFieldFirstResponder()
        }
    }
    
}

extension NSTableView {
    
    // TODO: implement correctly
    // NOTE: relies on caller executing this on main thread
    func scrollToMakeRowVisibleWithSpacing(_ row: Int) {
        let visibleRect = self.visibleRect
        let visibleRange = self.rows(in: visibleRect)
        
        self.scrollRowToVisible(min(row - 3 + visibleRange.length - 3, self.numberOfRows - 1))
        self.scrollRowToVisible(max(row - 3, 0))
        
        /*
        let scrollTo : Int
         
        if row >= self.numberOfRows {
            scrollTo = self.numberOfRows - 1
        }
        else if row <= 1 {
            scrollTo = row
        }
        else if row < visibleRange.lowerBound {
            scrollTo = max(row - 3, 0)
        }
        else /* if row > visibleRange.upperBound */ {
            scrollTo = row - 3
            self.scrollRowToVisible(min(row - 3 + visibleRange.length - 3, self.numberOfRows - 1))
        }
//        else /* if row > visibleRange.lowerBound + (visibleRange.length / 2) */ { // in bottom half of table
//            scrollTo = row - 3
//            self.scrollRowToVisible(min(row - 3 + visibleRange.length - 3, self.numberOfRows - 1))
//        }
//        else {
//            scrollTo = max(row - 1, 0)
//        }
        self.scrollRowToVisible(scrollTo)
        
        /*
        // a stupidly complicated way to keep offsets constistent for a given screen
        let visibleRect = self.visibleRect
        var visibleRange = self.rows(in: visibleRect)
        struct Holder {
            static var oldVisibleRect : NSRect? = nil
            static var oldVisibleRange : NSRange? = nil
        }
        
        if Holder.oldVisibleRect == nil {
            Holder.oldVisibleRect = visibleRect
        }
        if Holder.oldVisibleRange == nil {
            Holder.oldVisibleRange = visibleRange
        }
        
        print("old: \(Holder.oldVisibleRect?.size.height), new: \(visibleRect.height)")
        if (Holder.oldVisibleRect?.size.height)! == visibleRect.height {
            visibleRange.length = Holder.oldVisibleRange!.length
        }
        else {
            Holder.oldVisibleRect = visibleRect
            Holder.oldVisibleRange = visibleRange
        }
        
//        let visibleRect = self.visibleRect
//        let visibleRange = self.rows(in: visibleRect)
        let offset = max((visibleRange.length) / 4, 0)
        let scrollTo : Int
        // last row
        if row + offset >= self.numberOfRows {
            scrollTo = self.numberOfRows - 1
        }
        // one of the first rows
        else if row < offset /* visibleRange.length / 2 */ {
            scrollTo = row
        }
        // row is before first half of visible stuff
        else if row <= visibleRange.lowerBound + offset + 2 /*visibleRange.length*/ {
            scrollTo = max(row - offset + 2, 0)
        }
        // row is at or after first half of visible stuff
        else {
//            scrollTo = max(row - offset, 0)
            scrollTo = row + (offset * 3) - 2
        }
        self.scrollRowToVisible(scrollTo)
        */
        
//        self.scrollRowToVisible(row)
    
         */
    }
    
}
