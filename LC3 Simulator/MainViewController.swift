//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// Today: register UI, use IR?, interrupts/exceptions

// TODO: decide register UI
// TODO:   disable editing of registers while running continuously
// TODO: add "Reset" option to Simulator menu to reload all files loaded previously (and assemble all assembly files)
// TODO: add list of previously-searched-for addresses
// TODO: add count of how many characters are buffered and button to clear buffered characters in Console window
// TODO: come up with something cleaner than `rowBeingEdited`
// TODO: use notifications and callbacks to talk between model and controller classes (as opposed to keeping references to controller classes around)
// TODO: have fancier instruction string descriptions? maybe include ascii representation or numerical representation of what's there, too (possibly in separate columns)
// TODO: remove watching for and handlers for unused Notifications
// TODO: thoroughly test of Simulator
// TODO: try using IB to connect and have identifiers done w/ bindings

// MAYBE: allow editing of labels?
// MAYBE: maybe have different formatting in search bar to indicate it's a hex search
// MAYBE: precompute instruction strings to make scrolling faster if necessary - could also do caching so they're only computed once?
// MABYE: allow scaling of simulator horizontally, scaling only the label column (or allowing to change size of label/instruciton columns to accomidate longer instructions or labels)
// MAYBE: add "Set PC" option in context menu - I'm starting to think this is less useful as time goes on
// MAYBE: set selection indicator color to grey when simulator is running

// EVENTUALLY: disable ⌘F shortuct when the address search bar isn't in view. This doesn't currenlty break anything, but I'd guess it's misleading. Maybe make the search bar permanent somehow
// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk
// EVENTUALLY : move logic that should be run on simulator reinitialization to separate function from viewDidLoad() so I can call it separately and also from viewDidLoad()
// EVENTUALLY: make preference for choosing an OS (maybe some provided ones and then they can also have custom ones)
// EVENTUALLY: could have log of executed instructions w/ calculated values for debugging
// EVENTUALLY: give list of previously searched for addresses in search bar
// MAYBE EVENTUALLY: add preference for slow output printing to emphasize characters being outputted? Doesn't seem to useful to me.

import Foundation
import Cocoa

class MainViewController: NSViewController {

    var rowBeingEdited: Int?

    // MARK: Constants
    let kStatusNoneImage = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)

    // TODO: try keeping this thing in interface builder
    let kPCIndicatorColor: NSColor = NSColor(named: NSColor.Name("PCIndicatorColor"))!
    
    let kValueBinaryColumnIdentifier: NSUserInterfaceItemIdentifier = "valueBinaryColumnID"
    let kValueBinaryCellIdentifier: NSUserInterfaceItemIdentifier = "valueBinaryCellID"
    let kValueBinaryTextFieldIdentifier: NSUserInterfaceItemIdentifier = "valueBinaryTextFieldID"
    let kValueHexColumnIdentifier: NSUserInterfaceItemIdentifier = "valueHexColumnID"
    let kValueHexCellIdentifier: NSUserInterfaceItemIdentifier = "valueHexCellID"
    let kValueHexTextFieldIdentifier: NSUserInterfaceItemIdentifier = "valueHexTextFieldID"
    let kStatusColumnIdentifier: NSUserInterfaceItemIdentifier = "statusColumnID"
    let kStatusCellIdentifier: NSUserInterfaceItemIdentifier = "statusCellID"
    let kAddressColumnIdentifier: NSUserInterfaceItemIdentifier = "addressColumnID"
    let kAddressCellIdentifier: NSUserInterfaceItemIdentifier = "addressCellID"
    let kLabelColumnIdentifier: NSUserInterfaceItemIdentifier = "labelColumnID"
    let kLabelCellIdentifier: NSUserInterfaceItemIdentifier = "labelCellID"
    let kInstructionColumnIdentifier: NSUserInterfaceItemIdentifier = "instructionColumnID"
    let kInstructionCellIdentifier: NSUserInterfaceItemIdentifier = "instructionCellID"

    // MARK: Variables
    typealias Instruction = UInt16
    var simulator = Simulator()
    var memory: Memory!
    var consoleVC: ConsoleViewController?

    let backgroundQueue = DispatchQueue.global(qos: .userInteractive)

    // MARK: IB outlets
    @IBOutlet var hexNumberFormatter: HexNumberFormatter!
    @IBOutlet var binaryNumberFormatter: BinaryNumberFormatter!
    @IBOutlet weak var memoryTableView: NSTableView!
    // specifically, for registers UI
    @IBOutlet weak var r0HexTextField: NSTextField!
    @IBOutlet weak var r0DecimalTextField: NSTextField!
    @IBOutlet weak var r1HexTextField: NSTextField!
    @IBOutlet weak var r1DecimalTextField: NSTextField!
    @IBOutlet weak var r2HexTextField: NSTextField!
    @IBOutlet weak var r2DecmialTextField: NSTextField!
    @IBOutlet weak var r3HexTextField: NSTextField!
    @IBOutlet weak var r3DecimalTextField: NSTextField!
    @IBOutlet weak var r4HexTextField: NSTextField!
    @IBOutlet weak var r4DecimalTextField: NSTextField!
    @IBOutlet weak var r5HexTextField: NSTextField!
    @IBOutlet weak var r5DecimalTextField: NSTextField!
    @IBOutlet weak var r6HexTextField: NSTextField!
    @IBOutlet weak var r6DecimalTextField: NSTextField!
    @IBOutlet weak var r7HexTextField: NSTextField!
    @IBOutlet weak var r7DecimalTextField: NSTextField!
    @IBOutlet weak var pcHexTextField: NSTextField!
    @IBOutlet weak var pcDecimalTextField: NSTextField!
    @IBOutlet weak var irHexTextField: NSTextField!
    @IBOutlet weak var irDecimalTextField: NSTextField!
    @IBOutlet weak var psrHexTextField: NSTextField!
    @IBOutlet weak var psrDecimalTextField: NSTextField!
    @IBOutlet weak var ccTextField: NSTextField!
    
    class RegistersUI {
        
        class DecimalHexTextFieldPair {
            
            var hexTextField : NSTextField
            var decimalTextField : NSTextField
            
            init(hexTextField : NSTextField, decimalTextField : NSTextField) {
                self.hexTextField = hexTextField
                self.decimalTextField = decimalTextField
            }
            
        }
        
        var regs : [DecimalHexTextFieldPair]
        var pc : DecimalHexTextFieldPair
        var ir : DecimalHexTextFieldPair
        var psr : DecimalHexTextFieldPair
        var cc : NSTextField
        
        init(r0: [NSTextField], r1: [NSTextField], r2: [NSTextField], r3: [NSTextField], r4: [NSTextField], r5: [NSTextField], r6: [NSTextField], r7: [NSTextField], pc: [NSTextField], ir: [NSTextField], psr: [NSTextField], cc: NSTextField) {
            self.regs = [DecimalHexTextFieldPair(hexTextField: r0[0], decimalTextField: r0[1]), DecimalHexTextFieldPair(hexTextField: r1[0], decimalTextField: r1[1]), DecimalHexTextFieldPair(hexTextField: r2[0], decimalTextField: r2[1]), DecimalHexTextFieldPair(hexTextField: r3[0], decimalTextField: r3[1]), DecimalHexTextFieldPair(hexTextField: r4[0], decimalTextField: r4[1]), DecimalHexTextFieldPair(hexTextField: r5[0], decimalTextField: r5[1]), DecimalHexTextFieldPair(hexTextField: r6[0], decimalTextField: r6[1]), DecimalHexTextFieldPair(hexTextField: r7[0], decimalTextField: r7[1])]
            self.pc = DecimalHexTextFieldPair(hexTextField: pc[0], decimalTextField: pc[1])
            self.ir = DecimalHexTextFieldPair(hexTextField: ir[0], decimalTextField: ir[1])
            self.psr = DecimalHexTextFieldPair(hexTextField: psr[0], decimalTextField: psr[1])
            self.cc = cc
        }
        
    }
    
    var registersUI : RegistersUI?
    
    func reloadRegisterUI() {
        DispatchQueue.main.async {
            for regNum in 0...7 {
                self.registersUI?.regs[regNum].hexTextField.intValue = Int32(self.simulator.registers.r[regNum])
                self.registersUI?.regs[regNum].decimalTextField.intValue = Int32(self.simulator.registers.r[regNum])
            }
            self.registersUI?.pc.hexTextField.intValue = Int32(self.simulator.registers.pc)
            self.registersUI?.pc.decimalTextField.intValue = Int32(self.simulator.registers.pc)
            self.registersUI?.ir.hexTextField.intValue = Int32(self.simulator.registers.ir)
            self.registersUI?.ir.decimalTextField.intValue = Int32(self.simulator.registers.ir)
            self.registersUI?.psr.hexTextField.intValue = Int32(self.simulator.registers.psr)
            self.registersUI?.psr.decimalTextField.intValue = Int32(self.simulator.registers.psr)
            
            let ccString = self.simulator.registers.cc.rawValue
//            switch self.simulator.registers.cc {
//            case .N:
//                ccString = "N"
//            case .Z:
//                ccString = "Z"
//            case .P:
//                ccString = "P"
//            }
            self.registersUI?.cc.stringValue = ccString
        }
    }
    
    func updateUIAfterSimulatorRun(modifiedRows: IndexSet) {
        memoryTableView.reloadModifedRows(modifiedRows)
        pcChanged()
    }

    func pcChanged() {
        DispatchQueue.main.async {
            // if row of PC is visible, change its color to indicate that the PC is set to it
            self.memoryTableView.rowView(atRow: Int(self.simulator.registers.pc), makeIfNecessary: false)?.backgroundColor = self.kPCIndicatorColor
            self.reloadRegisterUI()
        }
    }

    // MARK: IB actions
    @IBAction func runClickedWithSender(_ sender: AnyObject) {
        print("run clicked")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        backgroundQueue.async {
            self.simulator.runForever(finallyUpdateIndexes: self.updateUIAfterSimulatorRun)
        }
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }

    @IBAction func stepInClickedWithSender(_ sender: AnyObject) {
        print("step clicked")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        simulator.stepIn(finallyUpdateIndexes: self.updateUIAfterSimulatorRun)
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }

    @IBAction func stepOutClickedWithSender(_ sender: AnyObject) {
        print("step out clicked")
        preconditionFailure("not implemented yet")
    }

    @IBAction func stepOverClickedWithSender(_ sender: AnyObject) {
        print("step over clicked")
        preconditionFailure("not implemented yet")
    }

    @IBAction func stopClickedWithSender(_ sender: AnyObject) {
        simulator.stopRunning()
        NSApp.mainWindow?.toolbar?.validateVisibleItems()

    }

    // when requested to jump to the PC, insert the PC as a string into the search bar and search for it
    @IBAction func scrollToPCClickedWithSender(_ sender: AnyObject) {
        DispatchQueue.main.async {
            let pcAsInt = Int(self.simulator.registers.pc)
            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(pcAsInt)
            // selects row of PC for consistency with searching for address
            self.memoryTableView.selectRowIndexes([pcAsInt], byExtendingSelection: false)
        }
    }

    // reset machine state
    @IBAction func resetSimulatorPressedWithSender(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.simulator = Simulator()
            self.consoleVC?.resetConsole()
            self.viewDidLoad()

            // make the main window the key window again (otherwise, console window becomes key window)
            NSApp.getWindowWith(identifier: "MainWindowID")?.makeKeyAndOrderFront(self)
        }
    }

    @IBAction func setPCPressedWithSender(_ sender: AnyObject) {
        assert(!simulator.isRunning && memoryTableView.selectedRowIndexes.count == 1)

        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        let selectedRow = memoryTableView.selectedRowIndexes.first!
        simulator.registers.pc = UInt16(selectedRow)
        pcChanged()
    }

    func setConsoleVC(to vc: ConsoleViewController) {
        self.consoleVC = vc
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
        // initialize register UI
        registersUI = RegistersUI(r0: [r0HexTextField, r0DecimalTextField], r1: [r1HexTextField, r1DecimalTextField], r2: [r2HexTextField, r2DecmialTextField], r3: [r3HexTextField, r3DecimalTextField], r4: [r4HexTextField, r4DecimalTextField], r5: [r5HexTextField, r5DecimalTextField], r6: [r6HexTextField, r6DecimalTextField], r7: [r7HexTextField, r7DecimalTextField], pc: [pcHexTextField, pcDecimalTextField], ir: [irHexTextField, irDecimalTextField], psr: [psrHexTextField, psrDecimalTextField], cc: ccTextField)
        reloadRegisterUI()
        
        // NOTE: I attempted to specify `object` as simulator.memory, but it didn't work.
        //        NotificationCenter.default.addObserver(self, selector: #selector(logCharactersInNotification), name: MainViewController.kLogCharacterMessageName, object: nil)
        //        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }

}

extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {

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
            guard !simulator.isRunning else { return }

            let rowToEdit = self.memoryTableView.clickedRow
            let columnToEdit = self.memoryTableView.column(withIdentifier: kValueBinaryColumnIdentifier)

            rowBeingEdited = rowToEdit

            (self.memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            self.memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        case hexValueColumnIndex:
            // value (hex) column
            guard !simulator.isRunning else { return }

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
        return !simulator.isRunning
    }

    // MARK: NSTableView stuff
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === memoryTableView {
            return 0x10000
        } else {
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
            } else {
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

//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        switch tableColumn?.identifier.rawValue {
//        case "valueHexCellID":
//            return memory[UInt16(row)].value
//        case "valueBinaryCellID":
//            return memory[UInt16(row)].value
//        default:
//            return nil
//        }
//    }

    // color newly-appearing rows green iff the simulator isn't running instructions and the row is of the PC
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if !simulator.isRunning && row == simulator.registers.pc {
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
extension MainViewController: NSOpenSavePanelDelegate {

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

// parsing new values from memory table view
// TODO: put scanning functions inside of control()
extension MainViewController: NSTextFieldDelegate {

    func scanBinaryStringToUInt16(_ string: String) -> UInt16? {
        var obj: AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if binaryNumberFormatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        } else {
            return nil
        }
    }

    func scanHexStringToUInt16(_ string: String) -> UInt16? {
        var obj: AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if hexNumberFormatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        } else {
            return nil
        }
    }
    
    func scanBase10StringToUInt16(_ string: String) -> UInt16? {
        var obj: AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        let base10NumberFormatter = Base10NumberFormatter() // TODO: use IBOutlet to reference existing Base10NumberFormatter in storyboard
        if base10NumberFormatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        } else {
            return nil
        }
    }
    
    // TODO: figure out why CCFormatter was causing errors when run previously. The return value seemed fine -- I think the autoreleasing pointer junk is what killed it
    func scanCCStringToCCType(_ string: String) -> Registers.CCType? {
        switch string {
        case "N":
            return .N
        case "Z":
            return .Z
        case "P":
            return .P
        default:
            return nil
        }
//        var obj: AnyObject = 0 as AnyObject
//        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
//        let ccFormatter = CCFormatter() // TODO: use IBOutlet to reference existing Base10NumberFormatter in storyboard
//        if ccFormatter.getObjectValue(pointer, for: string, errorDescription: nil), let ccType = obj as? Registers.CCType {
//            switch ccType {
//            case .N:
//                return .N
//            case .Z:
//                return .Z
//            case .P:
//                return .P
//            }
//
////            return obj as? Registers.CCType
//        } else {
//            return nil
//        }
    }

    // if text makes sense, set memory, then reload table view
    // if it doesn't, just reload table view
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {

//        // always make the text field non-editable again after finished editing
//        defer {
//            // set isEditable to false if it's a text box from the table view
//            let memoryTableViewTextFieldIdentifiers: Set = [kValueHexTextFieldIdentifier, kValueBinaryTextFieldIdentifier]
//            if let controlIdentifier = control.identifier, memoryTableViewTextFieldIdentifiers.contains(controlIdentifier), let controlAsTextField = control as? NSTextField {
//                    controlAsTextField.isEditable = false
//            }
//        }

        // don't allow edit to go through if simulator is running
        guard !simulator.isRunning else {
            control.abortEditing()
            return true
        }

        // put new value into memory, then reload table view
        switch control.identifier {
        case self.kValueHexTextFieldIdentifier:
            if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                DispatchQueue.main.async {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                    self.memoryTableView.reloadModifedRows([self.rowBeingEdited!])
                }
                if let controlAsTextField = control as? NSTextField {
                    controlAsTextField.isEditable = false
                }
            }
        case self.kValueBinaryTextFieldIdentifier:
            if let parsedString = self.scanBinaryStringToUInt16(fieldEditor.string) {
                DispatchQueue.main.async {
                    self.memory?[UInt16(self.rowBeingEdited!)].value = parsedString
                    self.memoryTableView.reloadModifedRows([self.rowBeingEdited!])
                }
                if let controlAsTextField = control as? NSTextField {
                    controlAsTextField.isEditable = false
                }
            }
        default:
            // a text field from the registers
            if let decimalRegNum = registersUI?.regs.firstIndex(where: { $0.decimalTextField === control }) {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.r[decimalRegNum] = parsedString
//                        self.reloadRegisterUI()
                    }
                }
            }
            else if let hexRegNum = registersUI?.regs.firstIndex(where: { $0.hexTextField === control }) {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.r[hexRegNum] = parsedString
//                        self.reloadRegisterUI()
                    }
                }
            }
            else if control === registersUI?.pc.decimalTextField {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.memoryTableView.resetRowColorOf(row: Int(self.simulator.registers.pc))
                        self.simulator.registers.pc = parsedString
//                        self.reloadRegisterUI()
                    }
                }
            }
            else if control === registersUI?.pc.hexTextField {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.memoryTableView.resetRowColorOf(row: Int(self.simulator.registers.pc))
                        self.simulator.registers.pc = parsedString
//                        self.reloadRegisterUI()
                    }
                }
            }
            else if control === registersUI?.cc {
                if let parsedCCType = self.scanCCStringToCCType(fieldEditor.string) {
                    switch parsedCCType {
                    case .N:
                        self.simulator.registers.N = true
                    case .Z:
                        self.simulator.registers.Z = true
                    case .P:
                        self.simulator.registers.P = true
                    }
                }
            }
            // TODO: deal w/ IR, and PSR
//            if let registersUI = registersUI, registersUI.regs.contains(where: { (pair) -> Bool in
//                return pair.decimalTextField === control || pair.hexTextField === control
//            }) {
//                let regNum = registersUI.regs.index(where: { $0.decimalTextField === control || $0.hexTextField === control })
//            }
            reloadRegisterUI()
//            return true
//            preconditionFailure("Failed to match identifier of control in control()")
        }

        return true
    }
}

// MARK: search bar stuff
extension MainViewController {

    @IBAction func searchingFinished(_ sender: NSSearchField) {
        if let scannedValue = scanHexStringToUInt16(sender.stringValue) {
            let scannedValueAsInt = Int(scannedValue)
            DispatchQueue.main.async {
                self.memoryTableView.selectRowIndexes([scannedValueAsInt], byExtendingSelection: false)
                self.memoryTableView.scrollToMakeRowVisibleWithSpacing(scannedValueAsInt)
                // TODO: try making memory table view key view / first responder
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
    // two scrolls are used to make spacing easier - otherwise there's some annoyingly complex logic here
    func scrollToMakeRowVisibleWithSpacing(_ row: Int) {
        self.scrollRowToVisible(self.numberOfRows - 1)
        self.scrollRowToVisible(max(row, 0))
    }

    // gets all column indexes in a NSTableView
    var allColumnIndexes: IndexSet {
        return IndexSet(integersIn: self.tableColumns.indices)
    }

    // NOTE: createNSTableCellViewWithStringIdentifier() is implemented as 2 separate functions for (hopeful) speed's sake, but could (and was previously) implemented as a single function with nil as default value for stringValue and imageValue

    @inline(__always) func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, stringValue: String) -> NSTableCellView {
        let cellView = self.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.textField?.stringValue = stringValue

        return cellView
    }

    @inline(__always) func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, imageValue: NSImage) -> NSTableCellView {
        let cellView = self.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.imageView?.image = imageValue

        return cellView
    }

    // reset color of specific row in table view to original color
    func resetRowColorOf(row: Int) {
        if let originalColor = self.rowView(atRow: row - 2, makeIfNecessary: false)?.backgroundColor {
            self.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
        } else if let originalColor = self.rowView(atRow: row + 2, makeIfNecessary: false)?.backgroundColor {
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
extension NSUserInterfaceItemIdentifier: ExpressibleByStringLiteral {

    public typealias StringLiteralType = String

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

}

extension MainViewController: NSMenuItemValidation, NSToolbarItemValidation {

    var shouldEnableSetPCToSelectedRow: Bool {
        return !simulator.isRunning && memoryTableView.selectedRowIndexes.count == 1
    }

    var shouldEnableToggleBreakpoint: Bool {
        return memoryTableView.selectedRowIndexes.count == 1
    }

    var shouldEnableControlWhichStartsSimulator: Bool {
        return !simulator.isRunning
    }

    var shouldEnableStopSimulator: Bool {
        return simulator.isRunning
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
class MyNSToolbarItem: NSToolbarItem {

    override func validate() {
        if let control = self.view as? NSControl, let action = self.action, let validator = NSApp.target(forAction: action, to: self.target, from: self) {
            // safe to do because I checked for nil using if let
            control.isEnabled = (validator as AnyObject).validateToolbarItem(self)
        } else {
            super.validate()
        }
    }

}

extension NSApplication {

    func getWindowWith(identifier: NSUserInterfaceItemIdentifier) -> NSWindow? {
        let windowsWithIdentifier = self.windows.filter({$0.identifier == "MainWindowID"})
        assert(windowsWithIdentifier.count == 1)
        return windowsWithIdentifier.first
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
