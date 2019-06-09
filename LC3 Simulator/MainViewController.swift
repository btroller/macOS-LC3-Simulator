//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// TODO: thoroughly test Simulator
// TODO: find any leaks -- Instruments fails to check for leaks when I start to open files
// TODO: remove watching for and handlers for unused Notifications

// MAYBE: warn user when they load programs which overlap
// MAYBE: add button to clear console in console window itself
// MAYBE: disable text formatting options for text field in console window
// MAYBE: use notifications and callbacks to talk between model and controller classes (as opposed to keeping references to controller classes around)
// MAYBE: have fancier instruction string descriptions? maybe include ascii representation or numerical representation of what's there, too (possibly in separate columns)
// MAYBE: add list of previously-searched-for addresses
// MAYBE: have preference for showing 'NOP' vs 'BR #0'
// MAYBE: allow setting of memory to default values - ex. allows you to set 0x180 to point to the address of your intterupt. Approaches what Bellardo suggested in the way of creating memory snapshots which can be loaded, like custom OSs
// MAYBE: allow editing of labels?
// MAYBE: stop any editing sessions in the memory table view or registers when the simulator starts up - could send Notification from Simulator to main VC
// MAYBE: maybe have different formatting in search bar to indicate it's a hex search
// MAYBE: precompute instruction strings to make scrolling faster if necessary - could also do caching so they're only computed once?
// MABYE: allow scaling of simulator horizontally, scaling only the label column (or allowing to change size of label/instruciton columns to accomidate longer instructions or labels)
// MAYBE: add "Set PC" option in context menu - I'm starting to think this is less useful as time goes on
// MAYBE: set selection indicator color to grey when simulator is running
// MAYBE: make preference for having keyboard interrupts enabled by default
// MAYBE: could have a spare simulator sitting around & queued up to replace the current one in case that's what takes time to reset it. Maybe it's just UI junk, though
// MAYBE: make simulator window main window when breakpoint triggers

// EVENTUALLY: consider changing scroll to PC icon
// EVENTUALLY: disable ⌘F shortuct when the address search bar isn't in view. This doesn't currenlty break anything, but I'd guess it's misleading. Maybe make the search bar permanent somehow
// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk
// EVENTUALLY : move logic that should be run on simulator reinitialization to separate function from viewDidLoad() so I can call it separately and also from viewDidLoad()
// EVENTUALLY: make preference for choosing an OS (maybe some provided ones and then they can also have custom ones)
// EVENTUALLY: could have log of executed instructions w/ calculated values for debugging
// EVENTUALLY: give list of previously searched for addresses in search bar
// MAYBE EVENTUALLY: add preference for slow output printing to emphasize characters being outputted? Doesn't seem to useful to me.

import Cocoa
import Foundation

class MainViewController: NSViewController {
//    var rowBeingEdited: Int?

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
    @IBOutlet var base10NumberFormatter: Base10NumberFormatter!
    @IBOutlet var ccFormatter: CCFormatter!
    // memory UI
    @IBOutlet var memoryTableView: NSTableView!
    // registers UI
    @IBOutlet var r0HexTextField: NSTextField!
    @IBOutlet var r0DecimalTextField: NSTextField!
    @IBOutlet var r1HexTextField: NSTextField!
    @IBOutlet var r1DecimalTextField: NSTextField!
    @IBOutlet var r2HexTextField: NSTextField!
    @IBOutlet var r2DecmialTextField: NSTextField!
    @IBOutlet var r3HexTextField: NSTextField!
    @IBOutlet var r3DecimalTextField: NSTextField!
    @IBOutlet var r4HexTextField: NSTextField!
    @IBOutlet var r4DecimalTextField: NSTextField!
    @IBOutlet var r5HexTextField: NSTextField!
    @IBOutlet var r5DecimalTextField: NSTextField!
    @IBOutlet var r6HexTextField: NSTextField!
    @IBOutlet var r6DecimalTextField: NSTextField!
    @IBOutlet var r7HexTextField: NSTextField!
    @IBOutlet var r7DecimalTextField: NSTextField!
    @IBOutlet var pcHexTextField: NSTextField!
    @IBOutlet var pcDecimalTextField: NSTextField!
    @IBOutlet var irHexTextField: NSTextField!
    @IBOutlet var irDecimalTextField: NSTextField!
    @IBOutlet var psrHexTextField: NSTextField!
    @IBOutlet var psrDecimalTextField: NSTextField!
    @IBOutlet var ccTextField: NSTextField!

    class RegistersUI {
        class DecimalHexTextFieldPair {
            var hexTextField: NSTextField
            var decimalTextField: NSTextField

            init(hexTextField: NSTextField, decimalTextField: NSTextField) {
                self.hexTextField = hexTextField
                self.decimalTextField = decimalTextField
            }

            func setEnabled(to newVal: Bool) {
                hexTextField.isEnabled = newVal
                decimalTextField.isEnabled = newVal
            }
        }

        var regs: [DecimalHexTextFieldPair]
        var pc: DecimalHexTextFieldPair
        var ir: DecimalHexTextFieldPair
        var psr: DecimalHexTextFieldPair
        var cc: NSTextField

        init(r0: [NSTextField], r1: [NSTextField], r2: [NSTextField], r3: [NSTextField], r4: [NSTextField], r5: [NSTextField], r6: [NSTextField], r7: [NSTextField], pc: [NSTextField], ir: [NSTextField], psr: [NSTextField], cc: NSTextField) {
            regs = [DecimalHexTextFieldPair(hexTextField: r0[0], decimalTextField: r0[1]), DecimalHexTextFieldPair(hexTextField: r1[0], decimalTextField: r1[1]), DecimalHexTextFieldPair(hexTextField: r2[0], decimalTextField: r2[1]), DecimalHexTextFieldPair(hexTextField: r3[0], decimalTextField: r3[1]), DecimalHexTextFieldPair(hexTextField: r4[0], decimalTextField: r4[1]), DecimalHexTextFieldPair(hexTextField: r5[0], decimalTextField: r5[1]), DecimalHexTextFieldPair(hexTextField: r6[0], decimalTextField: r6[1]), DecimalHexTextFieldPair(hexTextField: r7[0], decimalTextField: r7[1])]
            self.pc = DecimalHexTextFieldPair(hexTextField: pc[0], decimalTextField: pc[1])
            self.ir = DecimalHexTextFieldPair(hexTextField: ir[0], decimalTextField: ir[1])
            self.psr = DecimalHexTextFieldPair(hexTextField: psr[0], decimalTextField: psr[1])
            self.cc = cc
        }

        func setEnabled(to newVal: Bool) {
            DispatchQueue.main.async {
                for reg in self.regs {
                    reg.setEnabled(to: newVal)
                }
                self.pc.setEnabled(to: newVal)
                self.ir.setEnabled(to: newVal)
                self.psr.setEnabled(to: newVal)
                self.cc.isEnabled = newVal
            }
        }
    }

    var registersUI: RegistersUI?

    func reloadRegisterUI() {
        DispatchQueue.main.async {
            for regNum in 0 ... 7 {
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
            self.registersUI?.cc.stringValue = ccString
        }
    }

    static let kSimulatorChangedRunStatus = Notification.Name("simulatorChangedRunStatus")

    @objc private func simulatorChangedRunningStatus(_: Notification) {
        updateRegistersAndToolbarUIEnabledness()
    }

    func updateRegistersAndToolbarUIEnabledness() {
        registersUI?.setEnabled(to: !simulator.isRunning)
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }

    func updateUIAfterSimulatorRun(modifiedRows: IndexSet) {
        memoryTableView.reloadModifedRows(modifiedRows)
        pcChanged()
        updateRegistersAndToolbarUIEnabledness()
    }

    func pcChanged() {
        DispatchQueue.main.async {
            // if row of PC is visible, change its color to indicate that the PC is set to it
            self.memoryTableView.rowView(atRow: Int(self.simulator.registers.pc), makeIfNecessary: false)?.backgroundColor = self.kPCIndicatorColor
            self.reloadRegisterUI()
        }
    }

    // MARK: IB actions

    @IBAction func runClickedWithSender(_: AnyObject) {
        print("run clicked")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        backgroundQueue.async {
            self.simulator.runForever(finallyUpdateIndexes: self.updateUIAfterSimulatorRun)
        }
        updateRegistersAndToolbarUIEnabledness()
    }

    @IBAction func stepInClickedWithSender(_: AnyObject) {
        print("step clicked")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        simulator.stepIn(finallyUpdateIndexes: updateUIAfterSimulatorRun)
        updateRegistersAndToolbarUIEnabledness()
    }

    @IBAction func stepOutClickedWithSender(_: AnyObject) {
        print("step out clicked")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        backgroundQueue.async {
            self.simulator.stepOut(finallyUpdateIndexes: self.updateUIAfterSimulatorRun(modifiedRows:))
        }
        updateRegistersAndToolbarUIEnabledness()
    }

    @IBAction func stepOverClickedWithSender(_: AnyObject) {
        print("step over clicked")
//        preconditionFailure("not implemented yet")
        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        backgroundQueue.async {
            self.simulator.stepOver(finallyUpdateIndexes: self.updateUIAfterSimulatorRun(modifiedRows:))
        }
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
    }

    @IBAction func stopClickedWithSender(_: AnyObject) {
        simulator.stopRunning()
        updateRegistersAndToolbarUIEnabledness()
    }

    // when requested to jump to the PC, insert the PC as a string into the search bar and search for it
    @IBAction func scrollToPCClickedWithSender(_: AnyObject) {
        DispatchQueue.main.async {
            let pcAsInt = Int(self.simulator.registers.pc)
            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(pcAsInt)
            // selects row of PC for consistency with searching for address
            // I don't really like this behavior, so I've commented it out for now and will deal with it later
//            self.memoryTableView.selectRowIndexes([pcAsInt], byExtendingSelection: false)
        }
    }

    // reset machine state
    @IBAction func resetSimulatorPressedWithSender(_: AnyObject) {
        DispatchQueue.main.async {
            self.simulator.stopRunning() // required because it's running in a dispatch queue, so it'll keep execuing unless I kill it directly -- ARC doesn't do this for me
            self.simulator = Simulator()
            self.consoleVC?.resetConsole()
            self.viewDidLoad()

            // make the main window the key window again (otherwise, console window becomes key window)
            NSApp.getWindowWith(identifier: "MainWindowID")?.makeKeyAndOrderFront(self)
        }
    }

    @IBAction func setPCPressedWithSender(_: AnyObject) {
        assert(!simulator.isRunning && memoryTableView.selectedRowIndexes.count == 1)

        memoryTableView.resetRowColorOf(row: Int(simulator.registers.pc))
        let selectedRow = memoryTableView.selectedRowIndexes.first!
        simulator.registers.pc = UInt16(selectedRow)
        pcChanged()
    }

    func setConsoleVC(to vc: ConsoleViewController) {
        consoleVC = vc
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
        NotificationCenter.default.addObserver(self, selector: #selector(simulatorChangedRunningStatus(_:)), name: MainViewController.kSimulatorChangedRunStatus, object: nil)
    }
}

extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {
    // TODO: rename to something better
    // TODO: abstact away from specific column like done in other cases (onItemDoubleClicked) - replace 0
    @IBAction func onItemClicked(_: AnyObject) {
//        print("row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn) clicked")
        let breakpointColumnIndex = memoryTableView.column(withIdentifier: kStatusColumnIdentifier)

        if memoryTableView.clickedColumn == breakpointColumnIndex, memoryTableView.clickedRow >= 0 {
            memory[UInt16(memoryTableView.clickedRow)].shouldBreak.toggle()
            // only need to reload the view containing the breakpoint icon
            memoryTableView.reloadData(forRowIndexes: [memoryTableView.clickedRow], columnIndexes: [memoryTableView.clickedColumn])
        }
    }

    // TODO: rename to something better
    // NOTE: might also trigger for registers table view for now
    @IBAction func onItemDoubleClicked(_: AnyObject) {
        guard memoryTableView.clickedRow >= 0 else { return }
//        print("double clicked on row \(memoryTableView.clickedRow), col \(memoryTableView.clickedColumn)")
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

            let rowToEdit = memoryTableView.clickedRow
            let columnToEdit = memoryTableView.column(withIdentifier: kValueBinaryColumnIdentifier)

//            rowBeingEdited = rowToEdit

            (memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        case hexValueColumnIndex:
            // value (hex) column
            guard !simulator.isRunning else { return }

            let rowToEdit = memoryTableView.clickedRow
            let columnToEdit = memoryTableView.column(withIdentifier: kValueHexColumnIdentifier)

//            rowBeingEdited = rowToEdit

            (memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        default:
            break
        }
    }

    // TODO: hook up to menu item and toolbar button, then make sure those are only enabled if it makes sense (same logic as used for setting pc to selected row)
    @IBAction func toggleBreakpointClickedWithSender(_: AnyObject) {
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

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
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
            if row == 2 {
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
    func tableView(_: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if !simulator.isRunning, row == simulator.registers.pc {
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
    @IBAction func openDocument(_: NSMenuItem) {
        print("called openDocument() in VC")
        let window = NSApp.mainWindow!
        let panel = NSOpenPanel()
        panel.delegate = self
        panel.message = "Import an assembled file"
        panel.allowsMultipleSelection = true
        panel.beginSheetModal(for: window) { response in
            switch response {
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
    func panel(_: Any, shouldEnable url: URL) -> Bool {
        return url.pathExtension == "obj" || url.hasDirectoryPath
    }
}

// parsing new values from memory table view
// TODO: put scanning functions inside of control()
extension MainViewController: NSTextFieldDelegate {
    @inline(__always) func scanStringToUInt16WithFormatter(string: String, formatter: Formatter) -> UInt16? {
        var obj: AnyObject = 0 as AnyObject
        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&obj)
        if formatter.getObjectValue(pointer, for: string, errorDescription: nil) {
            return obj as? UInt16
        } else {
            return nil
        }
    }

    func scanBinaryStringToUInt16(_ string: String) -> UInt16? {
        return scanStringToUInt16WithFormatter(string: string, formatter: binaryNumberFormatter)
    }

    func scanHexStringToUInt16(_ string: String) -> UInt16? {
        return scanStringToUInt16WithFormatter(string: string, formatter: hexNumberFormatter)
    }

    func scanBase10StringToUInt16(_ string: String) -> UInt16? {
        return scanStringToUInt16WithFormatter(string: string, formatter: base10NumberFormatter)
    }

    // TODO: figure out why CCFormatter was causing errors when run previously. The return value seemed fine -- I think the autoreleasing pointer junk is what killed it
    func scanCCStringToCCType(_ string: String) -> Registers.CCType? {
        switch string.uppercased() {
        case "N":
            return .N
        case "Z":
            return .Z
        case "P":
            return .P
        default:
            return nil
        }
    }

    func updateMemoryTableView(control: NSControl, fieldEditor: NSText, scanner: (String) -> UInt16?) {
        let rowBeingEdited = memoryTableView.row(for: control)

        if rowBeingEdited >= 0, let parsedString = scanner(fieldEditor.string) {
            DispatchQueue.main.async {
                self.memory?[UInt16(rowBeingEdited)].value = parsedString
                self.memoryTableView.reloadModifedRows([rowBeingEdited])
            }
            if let controlAsTextField = control as? NSTextField {
                controlAsTextField.isEditable = false
            }
        }
    }

    // if text makes sense, set memory, then reload table view
    // if it doesn't, just reload table view
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // make sure we update UI based on anything changed (primarily set of MCR)
        defer {
            updateRegistersAndToolbarUIEnabledness()
            reloadRegisterUI()
        }

        // don't allow edit to go through if simulator is running
        guard !simulator.isRunning else {
            control.abortEditing()
            return true
        }

        // put new value into memory, then reload table view
        switch control.identifier {
        case kValueHexTextFieldIdentifier:
            updateMemoryTableView(control: control, fieldEditor: fieldEditor, scanner: scanHexStringToUInt16(_:))
        case kValueBinaryTextFieldIdentifier:
            updateMemoryTableView(control: control, fieldEditor: fieldEditor, scanner: scanBinaryStringToUInt16(_:))
        default:

//            defer {
//                self.reloadRegisterUI()
//            }

            // a text field from the registers
            if let decimalRegNum = registersUI?.regs.firstIndex(where: { $0.decimalTextField === control }) {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.r[decimalRegNum] = parsedString
                    }
                }
            } else if let hexRegNum = registersUI?.regs.firstIndex(where: { $0.hexTextField === control }) {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.r[hexRegNum] = parsedString
                    }
                }
            } else if control === registersUI?.pc.decimalTextField {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.memoryTableView.resetRowColorOf(row: Int(self.simulator.registers.pc))
                        self.simulator.registers.pc = parsedString
                    }
                }
            } else if control === registersUI?.pc.hexTextField {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.memoryTableView.resetRowColorOf(row: Int(self.simulator.registers.pc))
                        self.simulator.registers.pc = parsedString
                    }
                }
            } else if control === registersUI?.cc {
                print("mark")
                if let parsedCC = self.scanCCStringToCCType(fieldEditor.string) {
                    simulator.registers.cc = parsedCC
                    print("new cc of \(simulator.registers.cc)")
                    print("new PSR of \(simulator.registers.psr)")
                }
            } else if control === registersUI?.psr.decimalTextField {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.psr = parsedString
                    }
                }
            } else if control === registersUI?.psr.hexTextField {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.psr = parsedString
                    }
                }
            } else if control === registersUI?.ir.decimalTextField {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.ir = parsedString
                    }
                }
            } else if control === registersUI?.ir.hexTextField {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    DispatchQueue.main.async {
                        self.simulator.registers.ir = parsedString
                    }
                }
            }

//            self.reloadRegisterUI()
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
    @IBAction func findMenuItemClickedWithSender(_: Any) {
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
        scrollRowToVisible(numberOfRows - 1)
        scrollRowToVisible(max(row, 0))
    }

    // gets all column indexes in a NSTableView
    var allColumnIndexes: IndexSet {
        return IndexSet(integersIn: tableColumns.indices)
    }

    @inline(__always) func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, stringValue: String) -> NSTableCellView {
        let cellView = makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.textField?.stringValue = stringValue

        return cellView
    }

    @inline(__always) func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, imageValue: NSImage) -> NSTableCellView {
        let cellView = makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.imageView?.image = imageValue

        return cellView
    }

    // reset color of specific row in table view to original color
    func resetRowColorOf(row: Int) {
        let referenceRowIndex = row >= 2 ? row - 2 : row + 2
        if let originalColor = self.rowView(atRow: referenceRowIndex, makeIfNecessary: false)?.backgroundColor {
            rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
        }
//        if let originalColor = self.rowView(atRow: row - 2, makeIfNecessary: false)?.backgroundColor {
//            self.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
//        } else if let originalColor = self.rowView(atRow: row + 2, makeIfNecessary: false)?.backgroundColor {
//            self.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
//        }
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
        return !simulator.isRunning && simulator.memory.runLatchIsSet
    }

    var shouldEnableStopSimulator: Bool {
        return simulator.isRunning && simulator.memory.runLatchIsSet
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
        DispatchQueue.main.async {
            if let control = self.view as? NSControl, let action = self.action, let validator = NSApp.target(forAction: action, to: self.target, from: self) {
                // safe to do because I checked for nil using if let
                control.isEnabled = (validator as AnyObject).validateToolbarItem(self)
            } else {
                super.validate()
            }
        }
    }
}

extension NSApplication {
    func getWindowWith(identifier _: NSUserInterfaceItemIdentifier) -> NSWindow? {
        let windowsWithIdentifier = windows.filter { $0.identifier == "MainWindowID" }
        assert(windowsWithIdentifier.count == 1)
        return windowsWithIdentifier.first
    }
}

// extension NSToolbarItem {
//
//    override func validate() {
//        preconditionFailure()
//    }
//
// }
