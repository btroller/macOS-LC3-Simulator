//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// TODO: decide register UI
// TODO:   disable editing of registers while running continuously
// TODO: add "Reset" option to Simulator menu to reload all files loaded previously (and assemble all assembly files)
// TODO: automatic assembling and loading
// TODO: add list of previously-searched-for addresses
// TODO: add count of how many characters are buffered and button to clear buffered characters in Console window
// TODO: come up with something cleaner than `rowBeingEdited`
// TODO: use notifications and callbacks to talk between model and controller classes (as opposed to keeping references to controller classes around)
// TODO: have fancier instruction string descriptions? maybe include ascii representation or numerical representation of what's there, too (possibly in separate columns)
// TODO: remove watching for and handlers for unused Notifications

// MAYBE: maybe have different formatting in search bar to indicate it's a hex search
// MAYBE: precompute instruction strings to make scrolling faster if necessary - could also do caching so they're only computed once?
// MABYE: allow scaling of simulator horizontally, scaling only the label column (or allowing to change size of label/instruciton columns to accomidate longer instructions or labels)
// MAYBE: add "Set PC" option in context menu - I'm starting to think this is less useful as time goes on

// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk
// EVENTUALLY : move logic that should be run on simulator reinitialization to separate function from viewDidLoad() so I can call it separately and also from viewDidLoad()

// ASK: how does he like position of searched-for address?
// ASK: should I use his OS?

import Foundation
import Cocoa

class MainViewController: NSViewController {
    
    var rowBeingEdited : Int?
    private var shouldStopExecuting : Bool = false
    private var simulatorIsRunning : Bool = false
    
    // MARK: Constants
    let kStatusNoneImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)
    
    let kPCIndicatorColor : NSColor = NSColor(named: NSColor.Name("PCIndicatorColor"))!
    
    let kValueBinaryColumnIdentifier : NSUserInterfaceItemIdentifier = "valueBinaryColumnID"
    let kValueBinaryCellIdentifier: NSUserInterfaceItemIdentifier = "valueBinaryCellID"
    let kValueBinaryTextFieldIdentifier : NSUserInterfaceItemIdentifier = "valueBinaryTextFieldID"
    let kValueHexColumnIdentifier : NSUserInterfaceItemIdentifier = "valueHexColumnID"
    let kValueHexCellIdentifier : NSUserInterfaceItemIdentifier = "valueHexCellID"
    let kValueHexTextFieldIdentifier : NSUserInterfaceItemIdentifier = "valueHexTextFieldID"
    let kStatusColumnIdentifier : NSUserInterfaceItemIdentifier = "statusColumnID"
    let kStatusCellIdentifier : NSUserInterfaceItemIdentifier = "statusCellID"
    let kAddressColumnIdentifier : NSUserInterfaceItemIdentifier = "addressColumnID"
    let kAddressCellIdentifier : NSUserInterfaceItemIdentifier = "addressCellID"
    let kLabelColumnIdentifier : NSUserInterfaceItemIdentifier = "labelColumnID"
    let kLabelCellIdentifier : NSUserInterfaceItemIdentifier = "labelCellID"
    let kInstructionColumnIdentifier : NSUserInterfaceItemIdentifier = "instructionColumnID"
    let kInstructionCellIdentifier : NSUserInterfaceItemIdentifier = "instructionCellID"
    
    // MARK: Variables
    typealias Instruction = UInt16
    var simulator = Simulator()
    var memory : Memory!
    var consoleVC : ConsoleViewController?
    
    let backgroundQueue = DispatchQueue.global(qos: .userInteractive)
    
    // MARK: IB elements
    @IBOutlet weak var memoryTableView: NSTableView!
    @IBOutlet weak var registersTableView: NSTableView!
    
    func updateUIAfterSimulatorRun(modifiedRows: IndexSet) {
        simulatorIsRunning = false
        memoryTableView.reloadModifedRows(modifiedRows)
        pcChanged()
    }
    
    // TODO: change to computed property
    func shouldStopProgramExecution() -> Bool {
        return shouldStopExecuting
    }
    
    func pcChanged() {
        DispatchQueue.main.async {
            // if row of PC is visible, change its color to indicate that the PC is set to it
            self.memoryTableView.rowView(atRow: Int(self.simulator.registers.pc), makeIfNecessary: false)?.backgroundColor = self.kPCIndicatorColor
        }
    }
    
    // MARK: IB actions
    @IBAction func runClickedWithSender(_ sender: AnyObject) {
        print("run clicked")
        shouldStopExecuting = false
        simulatorIsRunning = true
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
//        memoryTableView.abortEditing()
        backgroundQueue.async {
            self.simulator.runForever(then: self.updateUIAfterSimulatorRun, shouldStopExecuting: self.shouldStopProgramExecution)
        }
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }
    
    @IBAction func stepInClickedWithSender(_ sender: AnyObject) {
        print("step clicked")
        shouldStopExecuting = false
        simulatorIsRunning = true
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
//        memoryTableView.abortEditing()
        simulator.stepIn(then: self.updateUIAfterSimulatorRun)
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }
    
    @IBAction func stepOutClickedWithSender(_ sender : AnyObject) {
        print("step out clicked")
        preconditionFailure("not implemented yet")
    }
    
    @IBAction func stepOverClickedWithSender(_ sender : AnyObject) {
        print("step over clicked")
        preconditionFailure("not implemented yet")
    }
    
    // TODO: stop running execution with (STOPPED THINKING HERE)
    // TODO: try sticking shouldStopExecuting in Simulator class
    @IBAction func stopClickedWithSender(_ sender: AnyObject) {
        shouldStopExecuting = true
        NSApp.mainWindow?.toolbar?.validateVisibleItems()

    }
    
    // when requested to jump to the PC, insert the PC as a string into the search bar and search for it
    @IBAction func scrollToPCClickedWithSender(_ sender: AnyObject) {
        DispatchQueue.main.async {
            if let windowController = NSApp.mainWindow?.windowController as? MainWindowController {
                let pcRow = self.simulator.registers.pc
                let str = String(format: "%X", pcRow)
                
                windowController.makeAddressSearchFieldFirstResponderWithStringAndSearch(str)
            }
        }
    }
    
    // reset machine state
    @IBAction func resetSimulatorPressedWithSender(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.simulator = Simulator()
            self.consoleVC?.resetConsole()
            self.viewDidLoad()
        }
    }
    
    @IBAction func setPCPressedWithSender(_ sender: AnyObject) {
        assert(!simulatorIsRunning && memoryTableView.selectedRowIndexes.count == 1)
        
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        let selectedRow = memoryTableView.selectedRowIndexes.first!
        simulator.registers.pc = UInt16(selectedRow)
        pcChanged()
    }
    
    func setConsoleVC(to vc : ConsoleViewController) {
        self.consoleVC = vc
    }

}

extension MainViewController : NSTableViewDataSource, NSTableViewDelegate {
    
    // TODO: rename to something better
    // NOTE: relies on static ordering of columns
    // TODO: abstact away from specific column like done in other cases (onItemDoubleClicked) - replace 0
    @IBAction func onItemClicked(_ sender: AnyObject) {
        print("row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn) clicked")
        let breakpointColumnIndex = memoryTableView.column(withIdentifier: kStatusColumnIdentifier)
        
        if memoryTableView.clickedColumn == breakpointColumnIndex && memoryTableView.clickedRow >= 0 {
            memory[UInt16(memoryTableView.clickedRow)].shouldBreak.toggle()
            // only need to reload the view containing the breakpoint icon
            memoryTableView.reloadData(forRowIndexes: [memoryTableView.clickedRow], columnIndexes: [memoryTableView.clickedColumn])
        }
    }
    
    // TODO: rename to something better
    // NOTE: might also trigger for registers table view for now
    // NOTE: relies on static ordering of columns
    @IBAction func onItemDoubleClicked(_ sender: AnyObject) {
        guard memoryTableView.clickedRow >= 0 else { return }
        print("double clicked on row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn)")
        let breakpointColumnIndex = memoryTableView.column(withIdentifier: kStatusColumnIdentifier)
        let binaryValueColumnIndex = memoryTableView.column(withIdentifier: kValueBinaryColumnIdentifier)
        let hexValueColumnIndex = memoryTableView.column(withIdentifier: kValueHexColumnIdentifier)
        
        switch memoryTableView.clickedColumn {
        case breakpointColumnIndex:
            // just run the same logic for toggling a breakpoint as if it were clicked once
            onItemClicked(self)
        case binaryValueColumnIndex:
            // value (binary) column
            guard !simulatorIsRunning else { return }
            
            let rowToEdit = self.memoryTableView.clickedRow
            let columnToEdit = self.memoryTableView.column(withIdentifier: kValueBinaryColumnIdentifier)
            
            rowBeingEdited = rowToEdit
            
            (self.memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            self.memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        case hexValueColumnIndex:
            // value (hex) column
            guard !simulatorIsRunning else { return }
            
            let rowToEdit = self.memoryTableView.clickedRow
            let columnToEdit = self.memoryTableView.column(withIdentifier: kValueHexColumnIdentifier)
            
            rowBeingEdited = rowToEdit
            
            (self.memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            self.memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        default:
            break
        }
    }
    
    // TODO: hook up to menu item and toolbar button, then make sure those are only enabled if it makes sense (same logic as used for setting pc to selected row)
    @IBAction func toggleBreakpointClickedWithSender(_ sender: AnyObject) {
        assert(memoryTableView.selectedRowIndexes.count == 1)
        // MAYBE perform check for valid row here
        
        guard let selectedRowIndex = memoryTableView.selectedRowIndexes.first else { return }
        
        memory[UInt16(selectedRowIndex)].shouldBreak.toggle()
        memoryTableView.reloadData(forRowIndexes: [selectedRowIndex], columnIndexes: [memoryTableView.column(withIdentifier: kStatusColumnIdentifier)])
        
        
        //        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        //        let selectedRow = memoryTableView.selectedRowIndexes.first!
        //        simulator.registers.pc = UInt16(selectedRow)
        //        pcChanged()
        
        //        if memoryTableView.clickedColumn == 0 && memoryTableView.clickedRow >= 0 {
        //            memory[UInt16(memoryTableView.clickedRow)].shouldBreak.toggle()
        //            memoryTableView.reloadData(forRowIndexes: [memoryTableView.clickedRow], columnIndexes: [memoryTableView.clickedColumn])
        //        }
        
    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        return !simulatorIsRunning
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display the console window when this VC loads
        // TODO: maybe use this sender instead of NSApp.mainWindow... in Console stuff
        performSegue(withIdentifier: "showConsoleWindow", sender: self)
        
        memory = simulator.memory
        simulator.setMainVC(to: self)
        
        // show memory table view appropriately
        DispatchQueue.main.async {
            self.memoryTableView.reloadData()
            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(Int(self.simulator.registers.pc))
        }
        // show PC appropriately
        pcChanged()
        
        // NOTE: I attempted to specify `object` as simulator.memory, but it didn't work.
        //        NotificationCenter.default.addObserver(self, selector: #selector(logCharactersInNotification), name: MainViewController.kLogCharacterMessageName, object: nil)
        //        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }
    
    // MARK: NSTableView stuff
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === memoryTableView {
            return 0x10000
        }
        else {
            return 3
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier {
        case kStatusColumnIdentifier:
            switch memory[UInt16(row)].shouldBreak {
            case true:
                return tableView.createNSTableCellViewWithStringIdentifier(kStatusCellIdentifier, imageValue: kStatusUnavailableIMage)
            case false:
                return tableView.createNSTableCellViewWithStringIdentifier(kStatusCellIdentifier, imageValue: kStatusNoneImage)
            }
        case kAddressColumnIdentifier:
            return tableView.createNSTableCellViewWithStringIdentifier(kAddressCellIdentifier, stringValue: String(format: "x%04X", row))
        case kValueBinaryColumnIdentifier:
            // attempt to avoid unneccessary computation and speed up table view loading process, pt. 1
            if memory[UInt16(row)].value == 0 {
                return tableView.createNSTableCellViewWithStringIdentifier(kValueBinaryCellIdentifier, stringValue: "0000 0000 0000 0000")
            }
            
            let unformattedBinaryString = String(memory[UInt16(row)].value, radix: 2)
            var formattedBinaryString = String(repeating: "0", count: 16 - unformattedBinaryString.count) + unformattedBinaryString
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 12, in: formattedBinaryString))
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 8, in: formattedBinaryString))
            formattedBinaryString.insert(" ", at: String.Index(utf16Offset: 4, in: formattedBinaryString))
            
            return tableView.createNSTableCellViewWithStringIdentifier(kValueBinaryCellIdentifier, stringValue: formattedBinaryString)
        case kValueHexColumnIdentifier:
            // attempt to avoid unneccessary computation and speed up table view loading process, pt. 2
            if memory[UInt16(row)].value == 0 {
                return tableView.createNSTableCellViewWithStringIdentifier(kValueHexCellIdentifier, stringValue: "0000")
            }
            
            return tableView.createNSTableCellViewWithStringIdentifier(kValueHexCellIdentifier, stringValue: String(format: "%04X", memory[UInt16(row)].value))
        case kLabelColumnIdentifier:
            return tableView.createNSTableCellViewWithStringIdentifier(kLabelCellIdentifier, stringValue: memory.getEntryLabel(of: row))
        case kInstructionColumnIdentifier:
            // attempt to avoid unneccessary computation and speed up table view loading process, pt. 3
            if memory[UInt16(row)].value == 0 {
                return tableView.createNSTableCellViewWithStringIdentifier(kInstructionCellIdentifier, stringValue: "NOP")
            }
            
            return tableView.createNSTableCellViewWithStringIdentifier(kInstructionCellIdentifier, stringValue: memory.instructionString(at: row))
            
        // MARK: cases having to do with second table
        case "registerNameCol1":
            let cellView = tableView.makeView(withIdentifier: "registerNameCol1", owner: self) as! NSTableCellView
            cellView.textField?.stringValue = "R\(row)"
            return cellView
        case "registerNameCol2":
            let cellView = tableView.makeView(withIdentifier: "registerNameCol1", owner: self) as! NSTableCellView
            cellView.textField?.stringValue = "R\(row + 3)"
            return cellView
        case "registerNameCol3":
            let cellView = tableView.makeView(withIdentifier: "registerNameCol1", owner: self) as! NSTableCellView
            if (row == 2) {
                cellView.textField?.stringValue = "CC"
            }
            else {
                cellView.textField?.stringValue = "R\(row + 6)"
            }
            return cellView
        case "registerNameCol4":
            let cellView = tableView.makeView(withIdentifier: "registerNameCol1", owner: self) as! NSTableCellView
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
    
    //    // disable selection of all rows
    //    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    //        return false
    //    }
    
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
    
    // color newly-appearing rows green iff the simulator isn't running instructions and the row is of the PC
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if !simulatorIsRunning && row == simulator.registers.pc {
            rowView.backgroundColor = kPCIndicatorColor
        }
    }
    
    //    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    ////        tableview
    //        if let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "memoryTableRowViewIdentifier"), owner: self) as? NSTableRowView {
    ////            rowView.wantsLayer = true
    ////            rowView.layer?.backgroundColor = CGColor(red: 0, green: 255, blue: 255, alpha: 0.5);
    //
    //            rowView.backgroundColor = .green
    // //            rowView.drawBackground(in: rowView.visibleRect)
    //            return rowView
    //        }
    //
    //        // required b/c registers table view is still around
    //        return nil
    ////        assertionFailure()
    //
    //    }
    
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
                
//                func reloadRowsInIndexSetInsideMemoryTableView(_ indexSet: IndexSet) {
//                    DispatchQueue.main.async {
//                        self.memoryTableView.reloadData(forRowIndexes: indexSet, columnIndexes: self.memoryTableView.allColumnIndexes)
//                    }
//                }
                
                self.memory.loadProgramsFromFiles(at: panel.urls, then: self.memoryTableView.reloadModifedRows)
            default:
                print("didn't select something")
            }
        }
    }
    
    // EVENTUALLY: allow .asm files and do the whole automatic assembling and loading thing
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        return url.pathExtension == "obj" || url.hasDirectoryPath
    }
    
}

// TODO: put scanning functions inside of control()
extension MainViewController : NSTextFieldDelegate {
    
    func scanBinaryStringToUInt16(_ string : String) -> UInt16? {
        let formatter = BinaryNumberFormatter()
        var obj : AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if formatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        }
        else {
            return nil
        }
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
        
        // always make the text field non-editable again after finished editing
        defer {
            (control as? NSTextField)?.isEditable = false
        }
        
        // don't allow edit to go through if simulator is running
        guard !simulatorIsRunning else {
            control.abortEditing()
            return true
        }
        
        // put new value into memory, then reload table view
        DispatchQueue.main.async {
            switch control.identifier {
            case self.kValueHexTextFieldIdentifier:
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                }
            case self.kValueBinaryTextFieldIdentifier:
                if let parsedString = self.scanBinaryStringToUInt16(fieldEditor.string) {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                }
            default:
                preconditionFailure("Failed to match identifier of control in control()")
            }

            self.memoryTableView.reloadModifedRows([self.rowBeingEdited!])
        }
        
        return true
    }
}

// MARK: search bar stuff
extension MainViewController {
    
    @IBAction func searchingFinished(_ sender: NSSearchField) {
        if let scannedValue = scanHexStringToUInt16(sender.stringValue) {
            DispatchQueue.main.async {
                self.memoryTableView.scrollToMakeRowVisibleWithSpacing(Int(scannedValue))
            }
        }
    }
    
    // makes ⌘F shortcut or click of menu item trigger search bar
    @IBAction func findMenuItemClickedWithSender(_ sender: Any) {
        if let mainWindowController = NSApp.mainWindow?.windowController as? MainWindowController {
            mainWindowController.makeAddressSearchFieldFirstResponder()
        }
    }
    
}

// MARK: utility method extensions to NSTableView
extension NSTableView {
    
    // utility method used to scroll to a row with spacing around it
    // NOTE: relies on caller executing this on main thread
    func scrollToMakeRowVisibleWithSpacing(_ row: Int) {
//        let visibleRect = self.visibleRect
//        let visibleRange = self.rows(in: visibleRect)
        
        // two scrolls are used to make spacing easier - otherwise there's some annoyingly complex logic here
//        self.scrollRowToVisible(min(row - 3 + visibleRange.length - 3, self.numberOfRows - 1))
        self.scrollRowToVisible(self.numberOfRows - 1)
        self.scrollRowToVisible(max(row /* - 3 */, 0))
    }
    
    // gets all column indexes in a NSTableView
    var allColumnIndexes : IndexSet {
        return IndexSet(integersIn: self.tableColumns.indices)
    }
    
    // NOTE: createNSTableCellViewWithStringIdentifier() is implemented as 2 separate functions for (hopeful) speed's sake, but could (and was previously) implemented as a single function with nil as default value for stringValue and imageValue
    
    func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, stringValue: String) -> NSTableCellView {
        let cellView = self.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.textField?.stringValue = stringValue
        if let fontSize = cellView.textField?.font?.pointSize, let font = NSFont.userFixedPitchFont(ofSize: fontSize) {
            cellView.textField?.font = font
        }

        return cellView
    }

    func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, imageValue: NSImage) -> NSTableCellView {
        let cellView = self.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.imageView?.image = imageValue

        return cellView
    }
    
    // reset color of specific row in table view to original color
    func resetRowColorOf(row: Int) {
        if let originalColor = self.rowView(atRow: row - 2, makeIfNecessary: false)?.backgroundColor {
            self.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
        }
        else if let originalColor = self.rowView(atRow: row + 2, makeIfNecessary: false)?.backgroundColor {
            self.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
        }
    }
    
    func reloadModifedRows(_ modifiedRows: IndexSet) {
        DispatchQueue.main.async {
            self.reloadData(forRowIndexes: modifiedRows, columnIndexes: self.allColumnIndexes)
        }
    }

}

// allows me to pass strings as arguments which expect NSUserInterfaceItemIdentifiers, avoiding bloat from explicit calls to the NSUserInterfaceItemIdentifier constructor
extension NSUserInterfaceItemIdentifier : ExpressibleByStringLiteral {
    
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
    
}


extension MainViewController : NSMenuItemValidation, NSToolbarItemValidation {
    
    var shouldEnableSetPCToSelectedRow : Bool {
        return !simulatorIsRunning && memoryTableView.selectedRowIndexes.count == 1
    }
    
    var shouldEnableToggleBreakpoint : Bool {
        return memoryTableView.selectedRowIndexes.count == 1
    }
    
    var shouldEnableControlWhichStartsSimulator : Bool {
        return !simulatorIsRunning
    }
    
    var shouldEnableStopSimulator : Bool {
        return simulatorIsRunning
    }
    
    // validation of menu items
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier {
        case "setPCToSelectedRowMenuItemID":
            return shouldEnableSetPCToSelectedRow
        case "toggleBreakpointMenuItemID":
            return shouldEnableToggleBreakpoint
        case "runMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stopMenuItemID":
            return shouldEnableStopSimulator
        case "stepInMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOutMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOverMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        default:
            return true
        }
    }
    
    // validation of toolbar items
    @objc func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "toggleBreakpointToolbarItemID":
            return shouldEnableToggleBreakpoint
        case "runToolbarItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOutToolbarItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepInToolbarItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOverToolbarItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stopToolbarItemID":
            return shouldEnableStopSimulator
        default:
            return true
        }
    }
    
}

// trick non-image NSToolbarItems into calling validate() anyway, enabling or disabling them as desired
// NOTE: must use this subclass of NSToolbarItem for it to work. I tried extending NSToolbarItem, but it fought me
class MyNSToolbarItem : NSToolbarItem {

    override func validate() {
        if let control = self.view as? NSControl, let action = self.action, let validator = NSApp.target(forAction: action, to: self.target, from: self) {
            // safe to do because I checked for nil using if let
            control.isEnabled = (validator as AnyObject).validateToolbarItem(self)
        }
        else {
            super.validate()
        }
    }

}

//extension NSToolbarItem {
//
//    override func validate() {
//        preconditionFailure()
//    }
//
//}

// TODO: remove
//extension NSTableView {
//
//    open override func keyDown(with event: NSEvent) {
//        print(event)
//        super.keyDown(with: event)
//    }
//    
//    open override func keyUp(with event: NSEvent) {
//        print(event)
//        super.keyUp(with: event)
//    }
//
//}
