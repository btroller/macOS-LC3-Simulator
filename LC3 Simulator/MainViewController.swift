//
//  ViewController.swift
//  Delete
//
//  Created by Benjamin Troller on 10/15/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

// TODO: thoroughly test Simulator
// TODO: find any leaks -- Instruments fails to check for leaks when I start to open files
// TODO: make website for downloads
// TODO: always make room for scroll bar, no matter what's on the right side of the memory table view

// MAYBE: make memory labels editable while simulator is running
// MAYBE: remove index set tracker and just reload all of memory instead -- could make much simpler
// MAYBE: warn user when they load programs which overlap
// MAYBE: add button to clear console in console window itself
// MAYBE: disable text formatting options for text field in console window
// MAYBE: use notifications and callbacks to talk between model and controller classes (as opposed to keeping references to controller classes around)
// MAYBE: have fancier instruction string descriptions? maybe include ascii representation or numerical representation of what's there, too (possibly in separate columns)
// MAYBE: add list of previously-searched-for addresses
// MAYBE: have preference for showing 'NOP' vs 'BR #0'
// MAYBE: allow setting of memory to default values - ex. allows you to set 0x180 to point to the address of your intterupt. Approaches what Bellardo suggested in the way of creating memory snapshots which can be loaded, like custom OSs
// MAYBE: stop any editing sessions in the memory table view or registers when the simulator starts up - could send Notification from Simulator to main VC
// MAYBE: maybe have different formatting in search bar to indicate it's a hex search
// MAYBE: precompute instruction strings to make scrolling faster if necessary - could also do caching so they're only computed once?
// MABYE: allow scaling of simulator horizontally, scaling only the label column (or allowing to change size of label/instruciton columns to accomidate longer instructions or labels)
// MAYBE: add "Set PC" option in context menu - I'm starting to think this is less useful as time goes on
// MAYBE: set selection indicator color to grey when simulator is running
// MAYBE: make preference for having keyboard interrupts enabled by default
// MAYBE: could have a spare simulator sitting around & queued up to replace the current one in case that's what takes time to reset it. Maybe it's just UI junk, though
// MAYBE: make simulator window main window when breakpoint triggers

// EVENTUALLY: try using optimizaion profile
// EVENTUALLY: consider changing scroll to PC icon
// EVENTUALLY: disable ⌘F shortuct when the address search bar isn't in view. This doesn't currenlty break anything, but I'd guess it's misleading. Maybe make the search bar permanent somehow
// EVENTUALLY: could allow direct editing of instruction in right column, but would require parsing - essentially writing an assembly interpreter at that point, and might have to support labels and junk
// EVENTUALLY: move logic that should be run on simulator reinitialization to separate function from viewDidLoad() so I can call it separately and also from viewDidLoad()
// EVENTUALLY: make preference for choosing an OS (maybe some provided ones and then they can also have custom ones)
// EVENTUALLY: could have log of executed instructions w/ calculated values for debugging
// EVENTUALLY: give list of previously searched for addresses in search bar

import Cocoa
import Foundation

class MainViewController: NSViewController {
    
    // MARK: Constants

    let kStatusNoneImage        = NSImage(imageLiteralResourceName: NSImage.statusNoneName)
    let kStatusAvailableImage   = NSImage(imageLiteralResourceName: NSImage.statusAvailableName)
    let kStatusUnavailableIMage = NSImage(imageLiteralResourceName: NSImage.statusUnavailableName)

    // TODO: try keeping this thing in interface builder
    static let kPCIndicatorColor = NSColor(named: NSColor.Name("PCIndicatorColor"))!

    let kValueBinaryColumnIdentifier:    NSUserInterfaceItemIdentifier = "valueBinaryColumnID"
    let kValueBinaryCellIdentifier:      NSUserInterfaceItemIdentifier = "valueBinaryCellID"
    let kValueBinaryTextFieldIdentifier: NSUserInterfaceItemIdentifier = "valueBinaryTextFieldID"
    let kValueHexColumnIdentifier:       NSUserInterfaceItemIdentifier = "valueHexColumnID"
    let kValueHexCellIdentifier:         NSUserInterfaceItemIdentifier = "valueHexCellID"
    let kValueHexTextFieldIdentifier:    NSUserInterfaceItemIdentifier = "valueHexTextFieldID"
    let kStatusColumnIdentifier:         NSUserInterfaceItemIdentifier = "statusColumnID"
    let kStatusCellIdentifier:           NSUserInterfaceItemIdentifier = "statusCellID"
    let kAddressColumnIdentifier:        NSUserInterfaceItemIdentifier = "addressColumnID"
    let kAddressCellIdentifier:          NSUserInterfaceItemIdentifier = "addressCellID"
    let kLabelColumnIdentifier:          NSUserInterfaceItemIdentifier = "labelColumnID"
    let kLabelCellIdentifier:            NSUserInterfaceItemIdentifier = "labelCellID"
    let kLabelTextFieldIdentifier:       NSUserInterfaceItemIdentifier = "labelTextFieldID"
    let kInstructionColumnIdentifier:    NSUserInterfaceItemIdentifier = "instructionColumnID"
    let kInstructionCellIdentifier:      NSUserInterfaceItemIdentifier = "instructionCellID"

    // MARK: Variables

    var simulator = Simulator()

    // MARK: IB outlets

    // Formatters
    @IBOutlet var hexNumberFormatter:    HexNumberFormatter!
    @IBOutlet var binaryNumberFormatter: BinaryNumberFormatter!
    @IBOutlet var base10NumberFormatter: Base10NumberFormatter!
    @IBOutlet var ccFormatter:           CCFormatter!
    // Memory UI
    @IBOutlet var memoryTableView: NSTableView!
    // Registers UI
    @IBOutlet var r0HexTextField:      NSTextField!
    @IBOutlet var r0DecimalTextField:  NSTextField!
    @IBOutlet var r1HexTextField:      NSTextField!
    @IBOutlet var r1DecimalTextField:  NSTextField!
    @IBOutlet var r2HexTextField:      NSTextField!
    @IBOutlet var r2DecmialTextField:  NSTextField!
    @IBOutlet var r3HexTextField:      NSTextField!
    @IBOutlet var r3DecimalTextField:  NSTextField!
    @IBOutlet var r4HexTextField:      NSTextField!
    @IBOutlet var r4DecimalTextField:  NSTextField!
    @IBOutlet var r5HexTextField:      NSTextField!
    @IBOutlet var r5DecimalTextField:  NSTextField!
    @IBOutlet var r6HexTextField:      NSTextField!
    @IBOutlet var r6DecimalTextField:  NSTextField!
    @IBOutlet var r7HexTextField:      NSTextField!
    @IBOutlet var r7DecimalTextField:  NSTextField!
    @IBOutlet var pcHexTextField:      NSTextField!
    @IBOutlet var pcDecimalTextField:  NSTextField!
    @IBOutlet var irHexTextField:      NSTextField!
    @IBOutlet var irDecimalTextField:  NSTextField!
    @IBOutlet var psrHexTextField:     NSTextField!
    @IBOutlet var psrDecimalTextField: NSTextField!
    @IBOutlet var ccTextField:         NSTextField!

    // A goofy solution to have easier access to the NSTextFields making up the registers UI. It works, but it's cumbersome.
    // TODO: Replace this with something better.
    struct RegistersUI {
        struct DecimalHexTextFieldPair {
            var hexTextField:     NSTextField
            var decimalTextField: NSTextField

            init(hexTextField: NSTextField, decimalTextField: NSTextField) {
                self.hexTextField     = hexTextField
                self.decimalTextField = decimalTextField
            }

            func setEnabled(to newVal: Bool) {
                hexTextField    .isEnabled = newVal
                decimalTextField.isEnabled = newVal
            }
        }

        var regularRegs: [DecimalHexTextFieldPair]
        var pc:           DecimalHexTextFieldPair
        var ir:           DecimalHexTextFieldPair
        var psr:          DecimalHexTextFieldPair
        var cc:           NSTextField

        init(r0: [NSTextField], r1: [NSTextField], r2: [NSTextField], r3: [NSTextField], r4: [NSTextField], r5: [NSTextField], r6: [NSTextField], r7: [NSTextField], pc: [NSTextField], ir: [NSTextField], psr: [NSTextField], cc: NSTextField) {
            self.regularRegs = [ DecimalHexTextFieldPair(hexTextField: r0[0],  decimalTextField: r0[1]),
                                 DecimalHexTextFieldPair(hexTextField: r1[0],  decimalTextField: r1[1]),
                                 DecimalHexTextFieldPair(hexTextField: r2[0],  decimalTextField: r2[1]),
                                 DecimalHexTextFieldPair(hexTextField: r3[0],  decimalTextField: r3[1]),
                                 DecimalHexTextFieldPair(hexTextField: r4[0],  decimalTextField: r4[1]),
                                 DecimalHexTextFieldPair(hexTextField: r5[0],  decimalTextField: r5[1]),
                                 DecimalHexTextFieldPair(hexTextField: r6[0],  decimalTextField: r6[1]),
                                 DecimalHexTextFieldPair(hexTextField: r7[0],  decimalTextField: r7[1]) ]
            
            self.pc   =          DecimalHexTextFieldPair(hexTextField: pc[0],  decimalTextField: pc[1])
            self.ir   =          DecimalHexTextFieldPair(hexTextField: ir[0],  decimalTextField: ir[1])
            self.psr  =          DecimalHexTextFieldPair(hexTextField: psr[0], decimalTextField: psr[1])
            self.cc   =          cc
        }

        func setEnabled(to newVal: Bool) {
            DispatchQueue.main.async {
                for reg in self.regularRegs {
                    reg .setEnabled(to: newVal)
                }
                self.pc .setEnabled(to: newVal)
                self.ir .setEnabled(to: newVal)
                self.psr.setEnabled(to: newVal)
                self.cc .isEnabled =    newVal
            }
        }
    }

    var registersUI: RegistersUI?

    func reloadRegistersUI() {
        guard !simulatorIsRunningCopy else { return }
        
        for regNum in 0...7 {
            let regVal = self.simulator.backgroundQueue.sync { Int32(self.simulator.registers.r[regNum]) }
            self.registersUI?.regularRegs[regNum].hexTextField    .intValue = regVal
            self.registersUI?.regularRegs[regNum].decimalTextField.intValue = regVal
        }
        
        let pcVal = self.simulator.backgroundQueue.sync { Int32(self.simulator.registers.pc ) }
        self.registersUI?.pc .hexTextField    .intValue = pcVal
        self.registersUI?.pc .decimalTextField.intValue = pcVal
        
        let irVal = self.simulator.backgroundQueue.sync { Int32(self.simulator.registers.ir ) }
        self.registersUI?.ir .hexTextField    .intValue = irVal
        self.registersUI?.ir .decimalTextField.intValue = irVal
        
        let psrVal = self.simulator.backgroundQueue.sync { Int32(self.simulator.registers.psr) }
        self.registersUI?.psr.hexTextField    .intValue = psrVal
        self.registersUI?.psr.decimalTextField.intValue = psrVal

        let ccString = self.simulator.backgroundQueue.sync { self.simulator.registers.cc.rawValue }
        self.registersUI?.cc.stringValue = ccString
        
        self.registersUI?.setEnabled(to: !self.simulatorIsRunningCopy)
    }
    
    static let kSimulatorChangedRunStatus = Notification.Name("simulatorChangedRunStatus")

    // TODO: make this not cached?
    var simulatorIsRunningCopy: Bool      = false
    // Must maintain so that the table view can scroll and update memory locations even while simulator is running.
    var memoryCopy:             Memory    = Memory()
    
    func copyMemory() {
        self.memoryCopy = self.simulator.backgroundQueue.sync { self.simulator.memory }
    }
    
    @objc private func simulatorChangedRunningStatus(_ notification: Notification) {
        DispatchQueue.main.async {
            self.simulatorIsRunningCopy = self.simulator.backgroundQueue.sync { self.simulator.isRunning }
            
            if !self.simulatorIsRunningCopy {
                self.copyMemory()
            }
            
            
            // Follow the PC after a run finishes. Only scrolls when PC is off-screen.
            if !self.simulatorIsRunningCopy {
                let pc = self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) }
                
                if !self.memoryTableView.rows(in: self.memoryTableView.visibleRect).contains(pc) {
                    self.memoryTableView.scrollToMakeRowVisibleWithSpacing(pc)
                }
            }
            
            // Update memory UI enabledness.
            self.registersUI?.setEnabled(to: !self.simulatorIsRunningCopy)
            
            // Force update of toolbar enabledness.
            NSApp.mainWindow?.toolbar?.validateVisibleItems()

            // Reload UI on finishing running.
            if !self.simulatorIsRunningCopy {
                self.updateUI_AfterPC_Change()
                self.memoryTableView.reloadModifedRows(self.simulator.backgroundQueue.sync { self.simulator.modifiedMemoryLocationsTracker.popIndexes() })
            }
        }
    }

    func updateUI_AfterPC_Change() {
        // If row of PC is visible, change its color to indicate that the PC is set to it.
        self.memoryTableView.rowView(atRow: self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) }, makeIfNecessary: false)?.backgroundColor = MainViewController.kPCIndicatorColor
        
        // Necessary because PC will be different.
        self.reloadRegistersUI()
    }

    // MARK: IB actions
    
    func resetPCRowColor() {
        memoryTableView.resetColorOf(row: self.simulator.backgroundQueue.sync { Int(simulator.registers.pc) })
    }

    @IBAction func runClickedWithSender(     _: AnyObject) {
        resetPCRowColor()
        self.simulator.runForever()
    }

    @IBAction func stepInClickedWithSender(  _: AnyObject) {
        resetPCRowColor()
        self.simulator.stepIn()
    }

    @IBAction func stepOutClickedWithSender( _: AnyObject) {
        resetPCRowColor()
        self.simulator.stepOut()
    }

    @IBAction func stepOverClickedWithSender(_: AnyObject) {
        resetPCRowColor()
        self.simulator.stepOver()
    }

    @IBAction func stopClickedWithSender(    _: AnyObject) {
        self.simulator.stopRunning()
    }

    // When requested to jump to the PC, insert the PC as a string into the search bar and search for it.
    @IBAction func scrollToPCClickedWithSender(_: AnyObject) {
            let pcAsInt = self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) }

            self.memoryTableView.scrollToMakeRowVisibleWithSpacing(pcAsInt)
    }

    // Reset machine state and upate UI.
    @IBAction func resetSimulatorPressedWithSender(_: AnyObject) {
        self.simulator.stopRunning() // required because it's running in a dispatch queue, so it'll keep execuing unless I kill it directly -- ARC doesn't do this for me. TODO: figure out why. Maybe a reference cycle somewhere?
        self.simulator = Simulator()
        self.copyMemory()
//            self.registersCopy = self.simulator.registers
        
        NotificationCenter.default.post(name: ConsoleViewController.kShouldReset, object: nil)
        self.viewDidLoad()

        // TODO: check that this works
        // Make the main window the key window again (otherwise, console window becomes key window).
        NSApp.getWindowWith(identifier: "MainWindowID")?.makeKeyAndOrderFront(self)
    }

    @IBAction func setPCPressedWithSender(_: AnyObject) {
        assert(memoryTableView.selectedRowIndexes.count == 1)
        guard !simulatorIsRunningCopy else { return }

        // Reset color of existing PC row.
        memoryTableView.resetColorOf(row: self.simulator.backgroundQueue.sync { Int(simulator.registers.pc) })
        
        // Set color of new PC row.
        let selectedRow = memoryTableView.selectedRowIndexes.first!
        self.simulator.backgroundQueue.sync { simulator.registers.pc = UInt16(selectedRow) }
        updateUI_AfterPC_Change()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Display the console window when this VC loads.
        // TODO: maybe use this sender instead of NSApp.mainWindow... in Console stuff
        // TODO: check that this works
        performSegue(withIdentifier: "showConsoleWindow", sender: self)

        self.copyMemory()
        
        // Update memory table view.
        self.memoryTableView.reloadData()
        self.memoryTableView.scrollToMakeRowVisibleWithSpacing(self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) })
        NSApp.mainWindow?.toolbar?.validateVisibleItems()
        
        // Update after PC change.
        updateUI_AfterPC_Change()
        
        // Initialize register UI.
        registersUI = RegistersUI(r0:  [r0HexTextField,  r0DecimalTextField ],
                                  r1:  [r1HexTextField,  r1DecimalTextField ],
                                  r2:  [r2HexTextField,  r2DecmialTextField ],
                                  r3:  [r3HexTextField,  r3DecimalTextField ],
                                  r4:  [r4HexTextField,  r4DecimalTextField ],
                                  r5:  [r5HexTextField,  r5DecimalTextField ],
                                  r6:  [r6HexTextField,  r6DecimalTextField ],
                                  r7:  [r7HexTextField,  r7DecimalTextField ],
                                  pc:  [pcHexTextField,  pcDecimalTextField ],
                                  ir:  [irHexTextField,  irDecimalTextField ],
                                  psr: [psrHexTextField, psrDecimalTextField],
                                  cc:   ccTextField)
        reloadRegistersUI()

        //        NSApp.mainWindow?.makeKeyAndOrderFront(self)
        NotificationCenter.default.addObserver(self, selector: #selector(simulatorChangedRunningStatus(_:)), name: MainViewController.kSimulatorChangedRunStatus, object: nil)
    }
}

extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    var breakpointColumnIndex:  Int { self.memoryTableView.column(withIdentifier: kStatusColumnIdentifier)      }
    var binaryValueColumnIndex: Int { self.memoryTableView.column(withIdentifier: kValueBinaryColumnIdentifier) }
    var hexValueColumnIndex:    Int { self.memoryTableView.column(withIdentifier: kValueHexColumnIdentifier)    }
    var labelColumnIndex:       Int { self.memoryTableView.column(withIdentifier: kLabelColumnIdentifier)       }
    
    func toggleBreakpoint(atRow rowNum: UInt16) {
        self.simulator.backgroundQueue.sync { self.simulator.memory[rowNum].shouldBreak.toggle() }
        self.copyMemory()
        
        // Reload the view containing the breakpoint icon.
        self.memoryTableView.reloadData(forRowIndexes: [Int(rowNum)], columnIndexes: [self.breakpointColumnIndex])
    }
    
    // TODO: rename to something better
    // TODO: abstact away from specific column like done in other cases (onItemDoubleClicked) - replace 0
    @IBAction func memoryTableViewItemClicked(_: AnyObject) {
        if memoryTableView.clickedColumn == breakpointColumnIndex, memoryTableView.clickedRow >= 0 {
            toggleBreakpoint(atRow: UInt16(memoryTableView.clickedRow))
        }
    }

    @IBAction func toggleBreakpointButtonClickedWithSender(_: AnyObject) {
        assert(memoryTableView.selectedRowIndexes.count == 1)

        guard let selectedRowIndex = memoryTableView.selectedRowIndexes.first else { preconditionFailure() }

        toggleBreakpoint(atRow: UInt16(selectedRowIndex))
    }
    
    @IBAction func memoryTableViewItemDoubleClicked(_: AnyObject) {
        guard memoryTableView.clickedRow >= 0 else { return }
        
        let clickedColumn = memoryTableView.clickedColumn
        
        if clickedColumn == breakpointColumnIndex {
            // just run the same logic for toggling a breakpoint as if it were clicked once
            memoryTableViewItemClicked(self)
        } else {
            let columnIdentifier: NSUserInterfaceItemIdentifier
            
            switch clickedColumn {
            case binaryValueColumnIndex:
                columnIdentifier = kValueBinaryColumnIdentifier
            case hexValueColumnIndex:
                columnIdentifier = kValueHexColumnIdentifier
            case labelColumnIndex:
                columnIdentifier = kLabelColumnIdentifier
            default:
                return
            }
            
            guard !simulatorIsRunningCopy else { return }
            
            let rowToEdit    = memoryTableView.clickedRow
            let columnToEdit = memoryTableView.column(withIdentifier: columnIdentifier)
         
            (memoryTableView.view(atColumn: columnToEdit, row: rowToEdit, makeIfNecessary: false) as? NSTableCellView)?.textField?.isEditable = true
            memoryTableView.editColumn(columnToEdit, row: rowToEdit, with: nil, select: false)
        }
    }

    // TODO: Document.
    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        return !simulatorIsRunningCopy
    }

    // MARK: NSTableView stuff

    func numberOfRows(in tableView: NSTableView) -> Int { 0x10000 }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier {
        case kStatusColumnIdentifier:
            let breakdotImage = self.memoryCopy[UInt16(row)].shouldBreak ? kStatusUnavailableIMage : kStatusNoneImage
            return tableView.createNSTableCellViewWithStringIdentifier(kStatusCellIdentifier, imageValue: breakdotImage)
        case kAddressColumnIdentifier:
            return tableView.createNSTableCellViewWithStringIdentifier(kAddressCellIdentifier,     stringValue: String(format: "x%04X", row))
        case kValueBinaryColumnIdentifier:
            // Use existing binary number formatter to format result.
            let formattedBinaryString = binaryNumberFormatter.string(for: self.memoryCopy[UInt16(row)].value)!
            
            return tableView.createNSTableCellViewWithStringIdentifier(kValueBinaryCellIdentifier, stringValue: formattedBinaryString)
        case kValueHexColumnIdentifier:
            // Use existing hex number formatter to format result.
            let formattedHexString = hexNumberFormatter.string(for: self.memoryCopy[UInt16(row)].value)!
            
            return tableView.createNSTableCellViewWithStringIdentifier(kValueHexCellIdentifier,    stringValue: formattedHexString)
        case kLabelColumnIdentifier:
            return tableView.createNSTableCellViewWithStringIdentifier(kLabelCellIdentifier,       stringValue: self.memoryCopy.getEntryLabel(    of: row))
        case kInstructionColumnIdentifier:
            return tableView.createNSTableCellViewWithStringIdentifier(kInstructionCellIdentifier, stringValue: self.memoryCopy.instructionString(of: row))
        default:
            preconditionFailure()
        }
    }

    // color newly-appearing rows green iff the simulator isn't running instructions and the row is of the PC
    func tableView(_: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if !simulatorIsRunningCopy, (row == self.simulator.backgroundQueue.sync { simulator.registers.pc }) {
            rowView.backgroundColor = MainViewController.kPCIndicatorColor
        }
    }
    
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
            if response == .OK {
                print("selected the files \(panel.urls)")
                self.simulator.backgroundQueue.sync { self.simulator.memory.loadProgramsFromFiles(at: panel.urls) }
                
                self.copyMemory()
                self.memoryTableView.reloadData()
            } else {
                print("didn't select something")
            }
        }
    }

    // EVENTUALLY: allow .asm files and do the whole automatic assembling and loading thing
    func panel(_: Any, shouldEnable url: URL) -> Bool { url.pathExtension == "obj" || url.hasDirectoryPath }
}

// parsing new values from memory table view
// TODO: put scanning functions inside of control()
extension MainViewController: NSTextFieldDelegate {
    func scanStringToT<T>(string: String, with formatter: Formatter) -> T? {
        var obj: AnyObject? = nil
        _ = formatter.getObjectValue(&obj, for: string, errorDescription: nil)
        return obj as? T
    }

    func scanBinaryStringToUInt16(_ string: String) -> UInt16? {
        return scanStringToT(string: string, with: binaryNumberFormatter)
    }
    func scanHexStringToUInt16(   _ string: String) -> UInt16? {
        return scanStringToT(string: string, with: hexNumberFormatter)
    }
    func scanBase10StringToUInt16(_ string: String) -> UInt16? {
        return scanStringToT(string: string, with: base10NumberFormatter)
    }
    func scanCCStringToCCType(    _ string: String) -> Registers.CCType? {
        return scanStringToT(string: string, with: ccFormatter)
    }

    func updateMemoryTableView(control: NSControl, fieldEditor: NSText, scanner: (String) -> UInt16?) {
        let rowBeingEdited = memoryTableView.row(for: control)

        if rowBeingEdited >= 0, let parsedString = scanner(fieldEditor.string) {
            self.simulator.backgroundQueue.sync { self.simulator.memory[UInt16(rowBeingEdited)].value = parsedString }
            self.copyMemory()
            // Get an endless recursive loop without doing this asynchronously.
            // TODO: figure out why looping when not done async
            DispatchQueue.main.async {
                self.memoryTableView.reloadModifedRows([rowBeingEdited])
            }
            
            (control as? NSTextField)?.isEditable = false
        }
    }

    // Update UI after an edit.
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // Don't allow edit to go through if simulator is running.
        guard !simulatorIsRunningCopy else {
            control.abortEditing()
            return true
        }
        
        // Make sure we update the registers UI based on anything changed (primarily set of MCR).
        defer {
            reloadRegistersUI()
        }

        switch control.identifier {
        case kValueHexTextFieldIdentifier:
            updateMemoryTableView(control: control, fieldEditor: fieldEditor, scanner: scanHexStringToUInt16(_:))
        case kValueBinaryTextFieldIdentifier:
            updateMemoryTableView(control: control, fieldEditor: fieldEditor, scanner: scanBinaryStringToUInt16(_:))
        case kLabelTextFieldIdentifier:
            // reload all rows which somehow reference the modified one
            let rowBeingEdited = self.memoryTableView.row(for: control)
            
            // Row is sometimes -1. Probably because of redraw? Not actually sure, because I don't run into this when dealing with other columns.
            guard rowBeingEdited > 0 else { break }
            
            self.simulator.backgroundQueue.sync { self.simulator.memory[UInt16(rowBeingEdited)].label = fieldEditor.string }
            self.copyMemory()
            self.memoryTableView.reloadData()
        default:
            // a text field from the registers
            // TODO: clean up, put in switch statement
            if let decimalRegNum = registersUI?.regularRegs.firstIndex(where: { $0.decimalTextField === control }) {
                if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                    self.simulator.backgroundQueue.sync { self.simulator.registers.r[decimalRegNum] = parsedString }
                }
            } else if let hexRegNum = registersUI?.regularRegs.firstIndex(where: { $0.hexTextField === control }) {
                if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                    self.simulator.backgroundQueue.sync { self.simulator.registers.r[hexRegNum] = parsedString }
                }
            } else {
                switch control {
                case registersUI?.pc.decimalTextField:
                    if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                        self.memoryTableView.resetColorOf(row: self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) })
                        self.simulator.backgroundQueue.sync { self.simulator.registers.pc = parsedString }
                    }
                case registersUI?.pc.hexTextField:
                    if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                        self.memoryTableView.resetColorOf(row: self.simulator.backgroundQueue.sync { Int(self.simulator.registers.pc) })
                        self.simulator.backgroundQueue.sync { self.simulator.registers.pc = parsedString }
                    }
                case registersUI?.cc:
                    if let parsedCC = self.scanCCStringToCCType(fieldEditor.string) {
                        self.simulator.backgroundQueue.sync { simulator.registers.cc = parsedCC }
                        print("new cc of \(simulator.registers.cc)")
                        print("new PSR of \(simulator.registers.psr)")
                    }
                case registersUI?.psr.decimalTextField:
                    if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                        self.simulator.backgroundQueue.sync { self.simulator.registers.psr = parsedString }
                    }
                case registersUI?.psr.hexTextField:
                    if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                        self.simulator.backgroundQueue.sync { self.simulator.registers.psr = parsedString }
                    }
                case registersUI?.ir.decimalTextField:
                    if let parsedString = self.scanBase10StringToUInt16(fieldEditor.string) {
                        self.simulator.backgroundQueue.sync { self.simulator.registers.ir = parsedString }
                    }
                case registersUI?.ir.hexTextField:
                    if let parsedString = self.scanHexStringToUInt16(fieldEditor.string) {
                        self.simulator.backgroundQueue.sync { self.simulator.registers.ir = parsedString }
                    }
                default:
                    break
                }
            }
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
                self.view.window?.makeFirstResponder(self.memoryTableView)
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
    var allColumnIndexes: IndexSet { return IndexSet(integersIn: tableColumns.indices) }

    func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, stringValue: String) -> NSTableCellView {
        let cellView = makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.textField?.stringValue = stringValue

        return cellView
    }

    func createNSTableCellViewWithStringIdentifier(_ identifier: NSUserInterfaceItemIdentifier, imageValue: NSImage) -> NSTableCellView {
        let cellView = makeView(withIdentifier: identifier, owner: self) as! NSTableCellView

        cellView.imageView?.image = imageValue

        return cellView
    }

    // Reset color of a specific row in table view to original color.
    func resetColorOf(row: Int) {
        // Need to grab a row 2 away from the current one for reference to match the alternating table view row colors.
        let referenceRowIndex = (row >= 2) ? (row - 2) : (row + 2)
        guard let originalColor = self.rowView(atRow: referenceRowIndex, makeIfNecessary: true)?.backgroundColor else { preconditionFailure() }
        
        rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = originalColor
    }

    func reloadModifedRows(_ modifiedRows: IndexSet) {
        self.reloadData(forRowIndexes: modifiedRows, columnIndexes: self.allColumnIndexes)
    }
}

// Allows me to pass strings as arguments which expect NSUserInterfaceItemIdentifiers. Avoiding bloat from explicit calls to the NSUserInterfaceItemIdentifier constructor.
extension NSUserInterfaceItemIdentifier: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension MainViewController: NSMenuItemValidation, NSToolbarItemValidation {
    // TODO: Determine if second {memoryTableView.selectedRowIndexes.count == 1} condition is necessary.
    var shouldEnableSetPCToSelectedRow: Bool {
        return !simulatorIsRunningCopy && memoryTableView.selectedRowIndexes.count == 1
    }

    var shouldEnableToggleBreakpoint: Bool {
        return memoryTableView.selectedRowIndexes.count == 1
    }

    var shouldEnableControlWhichStartsSimulator: Bool {
//        return !simulatorIsRunningCopy && self.memoryCopy.runLatchIsSet
        return !simulatorIsRunningCopy && self.simulator.backgroundQueue.sync { self.simulator.memory.runLatchIsSet }
    }

    var shouldEnableControlWhichStopSimulator: Bool {
        return simulatorIsRunningCopy // && simulator.memory.runLatchIsSet
    }

    // Validates menu items.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier {
        case "setPCToSelectedRowMenuItemID":
            return shouldEnableSetPCToSelectedRow
        case "toggleBreakpointMenuItemID":
            return shouldEnableToggleBreakpoint
        case "runMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stopMenuItemID":
            return shouldEnableControlWhichStopSimulator
        case "stepInMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOutMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "stepOverMenuItemID":
            return shouldEnableControlWhichStartsSimulator
        case "openFileMenuItemID":
            return !simulatorIsRunningCopy
        case "scrollToPCMenuItemID":
            return !simulatorIsRunningCopy
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
            return shouldEnableControlWhichStopSimulator
        case "scrollToPCToolbarItemID":
            return !simulatorIsRunningCopy
        default:
            return true
        }
    }
}

// trick non-image NSToolbarItems into calling validate() anyway, enabling or disabling them as desired
// NOTE: must use this subclass of NSToolbarItem for it to work. I tried extending NSToolbarItem, but it fought me
class CustomNSToolbarItem: NSToolbarItem {
    override func validate() {
        if let control   = self.view as? NSControl,
           let action    = self.action,
           let validator = NSApp.target(forAction: action, to: self.target, from: self) {
            control.isEnabled = (validator as AnyObject).validateToolbarItem(self)
        } else {
            super.validate()
        }
    }
}

extension NSApplication {
    func getWindowWith(identifier: NSUserInterfaceItemIdentifier) -> NSWindow? {
        let windowsWithIdentifier = windows.filter { $0.identifier == identifier }
        assert(windowsWithIdentifier.count == 1)
        
        return windowsWithIdentifier.first
    }
}
