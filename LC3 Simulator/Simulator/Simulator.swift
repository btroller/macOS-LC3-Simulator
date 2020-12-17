//
//  Simulator.swift
//  Delete
//
//  Created by Benjamin Troller on 12/13/18.
//  Copyright © 2018 Benjamin Troller. All rights reserved.
//

import Cocoa
import Foundation

// what should do if non-implemented/reserved instruction? send to exception handler? see current spot in book
// have way to manage files to be assembled and loaded each time so you can avoid loading from previously chosen ones
//  should I support C-file compiling as well? probably not necessary
// try using NSTask to support lc3as functionality
// consider making everything rewindable like Time Machine so you can easily undo some number of past actions -- could be simple and just have a copy of registers/simulator (use struct so that it's very easy) or intelligently make note of everything that's changed and rewind from there
// figure out when to stop executing for each case of step in, step out, etc -- should it be based on returning to an address (easy enough to store a copy w/ a let constant) or do I wait until a specific return happens? should notice after instruciton executes and PC is updated -- but it's not as simple as seeing that the PC is where it would've been otherwise, b/c that's not necessarily returning with RET or similar. You could just wind up there serendipitously through a mistake if somehting like JMP to lower-number address, keep executing and don't return until go through original code and hit original jump, htne pause. That's not really the same as a normal RET

// when character is read, immediately output it to screen, then set kbsr to appropriate value (if more in buffer, still 1, otherwise 0)
// TODO: try to rearrange I/O logic to be only in one place, like the spec says
// try setting initial SSP to x3000 so it subtracts from 3000

// prefs : follow PC, allow invalid ops? maybe hold off on invalid ops for initial release
// if implement jump to label, only exact match on label?
// allow "jump to addresss" and "jump to PC" in menu? probably only both if don't use search bar

class Simulator {
    // MARK: constants
    
    // Serial queues to work on.
    let backgroundQueue   = DispatchQueue(label: "Simulator work background queue",         qos: .userInitiated)
    let coordinatingQueue = DispatchQueue(label: "Simulator coordinating background queue", qos: .userInitiated)
    
    let kKeyboardPriorityLevel: UInt16 = 4

    // MARK: state-keeping

    var registers = Registers()
    var memory    = Memory()
    
    // A queue holding characters given as input.
    private let consoleInputQueue: ConsoleInputQueue

    private(set) var isRunning: Bool = false {
        didSet {
            NotificationCenter.default.post(name: MainViewController.kSimulatorChangedRunStatus, object: nil)
        }
    }
    
    init() {
        // Must be configured like this to allow the input queue to operate with the same DispatchQueue as performs operations on registers and memory.
        self.consoleInputQueue = ConsoleInputQueue(dispatchQueue: self.backgroundQueue)
    }

    func stopRunning() {
        backgroundQueue.async {
            self.isRunning = false
        }
    }

    // TODO: consider removing this altogether. Performance seems good without having to keep track of all the modififed memory locations. This adds complexity over a simple full table view reload. This was probably a premature optimization I did a while back because I was trying different things to improve performance. I know know that most performance hits come from printing text to the console.
    class IndexSetTracker {
        private var modifedMemoryLocations: IndexSet = []
        
        func popIndexes() -> IndexSet {
            defer { modifedMemoryLocations = [] }
            return modifedMemoryLocations
        }

        func insert(_ element: Int) {
            modifedMemoryLocations.insert(element)
        }
    }
    let modifiedMemoryLocationsTracker = IndexSetTracker()

    // NOTE: might not actually be next instruction executed thanks to interrupt until PC is updated appropriately
    var currentInstructionEntry: Memory.Entry {
        return memory[registers.pc]
    }

    enum ExceptionType: UInt16 {
        case privilegeModeViolation = 0x00
        case illegalOpcode          = 0x01
    }

    func loadR6WithSSPIfNotAlreadyThere() {
        // 3: Load R6 with SSP if not already there
        if registers.privilegeMode == .User {
            registers.savedUSP = registers.r[6]
            registers.r[6]     = registers.savedSSP
        }
    }

    func initiateException(withType exceptionType: ExceptionType) {
        let oldPC  = registers.pc
        let oldPSR = registers.psr

        // 2
        loadR6WithSSPIfNotAlreadyThere()

        // 1: set privilege mode to supervisor
        registers.privilegeMode = .Supervisor

        // 3: The PSR and PC of the interrupted process are pushed onto the Supervisor Stack.
        registers.r[6] &-= 1
        memory.setValue(at: registers.r[6], to: oldPSR,     then: modifiedMemoryLocationsTracker.insert(_:))
        registers.r[6] &-= 1
        memory.setValue(at: registers.r[6], to: oldPC &- 1, then: modifiedMemoryLocationsTracker.insert(_:))

        // 4: The exception supplies its 8-bit vector. In the case of the Privilege mode violation, that vector is xOO. In the case of the illegal opcode, that vector is xOl.
        let vector = exceptionType.rawValue
        // 5: The processor expands that vector to xOlOO or xOlOl, the corresponding 16-bit address in the interrupt vector table
        let expandedVector = vector &+ 0x0100
        // 6: The PC is loaded with the contents of memory location xOlOO or xOlOl, the address of the first instruction in the corresponding exception service routine.
        registers.pc = memory.getValueAndUpdateKeyboardRegs(at: expandedVector)
    }

    // NOTE: ONLY FOR KEYBOARD INTERRUPTS (but there are no others)
    // Comment numbering appears as I copied it from the book, not in the order I choose to execute it.
    func initiateInterrupt() {
        loadR6WithSSPIfNotAlreadyThere()

        // 4: push PSR and PC of interrupted process onto supervisor stack
        registers.r[6] &-= 1
        memory.setValue(at: registers.r[6], to: registers.psr, then: modifiedMemoryLocationsTracker.insert)
        registers.r[6] &-= 1
        memory.setValue(at: registers.r[6], to: registers.pc &- 1, then: modifiedMemoryLocationsTracker.insert(_:))

        // 1: set privilege mode to supervisor
        registers.privilegeMode = .Supervisor
        // 2: set priority level to PL4 (priority of keyboard)
        registers.priorityLevel = kKeyboardPriorityLevel

        // 5: keyboard supplies its 8-bit interrupt vector
        let interruptVector: UInt16 = 0x80
        // 6: processor expands vector
        let expandedInterruptVector = interruptVector &+ 0x100
        // 7: load PC with contents of memory at 0x180
        registers.pc = memory.getValueAndUpdateKeyboardRegs(at: expandedInterruptVector)
    }

    // execute instruction normally
    func executeNextInstruction() {
        // don't execute anything if the run latch is off
        if !memory.runLatchIsSet {
//            self.$isRunning.mutate({$0 = false})
            self.isRunning = false
            return
        }

        let entryToExecute = currentInstructionEntry
        registers.ir = entryToExecute.value
        let value = registers.ir
        registers.pc &+= 1

        // if interrupt to be dealt with, jump to appropriate stuff
        if registers.priorityLevel < kKeyboardPriorityLevel, memory.KBSRIsSet, memory.KBIEIsSet {
            initiateInterrupt()
            return
        }

        switch registers.ir.instructionType {
        case .ADDR:
            registers[value.SR_DR] = registers[value.SR1] &+ registers[value.SR2]
            registers.setCC(basedOn: registers[value.SR_DR])
        case .ADDI:
            registers[value.SR_DR] = registers[value.SR1] &+ value.sextImm5
            registers.setCC(basedOn: registers[value.SR_DR])
        case .ANDR:
            registers[value.SR_DR] = registers[value.SR1] & registers[value.SR2]
            registers.setCC(basedOn: registers[value.SR_DR])
        case .ANDI:
            registers[value.SR_DR] = registers[value.SR1] & value.sextImm5
            registers.setCC(basedOn: registers[value.SR_DR])
        case .BR:
            if (registers.cc == .N && value.N) || (registers.cc == .Z && value.Z) || (registers.cc == .P && value.P) {
                registers.pc = registers.pc &+ value.sextPCoffset9
            }
        case .JMP:
            registers.pc = registers[value.BaseR]
        case .JSR:
            registers.r[7] = registers.pc
            registers.pc = registers.pc &+ value.sextPCoffset11
        case .JSRR:
            registers[7] = registers.pc
            registers.pc = registers[value.BaseR]
        case .LD:
            registers[value.SR_DR] = memory.getValueAndUpdateKeyboardRegs(at: registers.pc &+ value.sextPCoffset9)
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDI:
            registers[value.SR_DR] = memory.getValueAndUpdateKeyboardRegs(at: memory.getValueAndUpdateKeyboardRegs(at: registers.pc &+ value.sextPCoffset9))
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LDR:
            registers[value.SR_DR] = memory.getValueAndUpdateKeyboardRegs(at: registers[value.BaseR] &+ value.sextOffset6)
            registers.setCC(basedOn: registers[value.SR_DR])
        case .LEA:
            registers[value.SR_DR] = registers.pc &+ value.sextPCoffset9
            registers.setCC(basedOn: registers[value.SR_DR])
        case .NOT:
            // TODO: create computed property in Memory to perform getSR functionality done manually here
            registers[value.SR_DR] = ~registers[value.getBits(high: 8, low: 6)]
            registers.setCC(basedOn: registers[value.SR_DR])
        case .RET:
            registers.pc = registers[7]
        case .RTI:
            // starts with state 8 in the diagram
            if registers.psr.getBit(at: 15) == 0 {
                registers.pc  = memory.getValueAndUpdateKeyboardRegs(at: registers.r[6])
                registers.r[6] &+= 1
                registers.psr = memory.getValueAndUpdateKeyboardRegs(at: registers.r[6])
                registers.r[6] &+= 1
                if registers.psr.getBit(at: 15) == 1 {
                    registers.savedSSP = registers.r[6]
                    registers.r[6] = registers.savedUSP
                }
            } else {
                // initiate privalege mode exception - shouldn't execute RTI outside of supervisor mode b/c the superisor stack isn't set up and won't be popped from correctly, messing up the PC and PSR
                initiateException(withType: .privilegeModeViolation)
            }
        case .ST:
            memory.setValue(at: registers.pc &+ value.sextPCoffset9, to: registers[value.SR_DR], then: modifiedMemoryLocationsTracker.insert)
        case .STI:
            let effectiveAddress = memory.getValueAndUpdateKeyboardRegs(at: registers.pc &+ value.sextPCoffset9)
//            print(effectiveAddress)
            memory.setValue(at: effectiveAddress, to: registers[value.SR_DR], then: modifiedMemoryLocationsTracker.insert)
        case .STR:
            memory.setValue(at: registers[value.BaseR] &+ value.sextOffset6, to: registers[value.SR_DR], then: modifiedMemoryLocationsTracker.insert)
        case .TRAP:
            registers[7] = registers.pc
            registers.pc = memory.getValueAndUpdateKeyboardRegs(at: value.trapVect8)
        case .NOT_IMPLEMENTED:
            // trigger illegal opcode exception
            initiateException(withType: .illegalOpcode)
        }

        // Update I/O stuff
        if !memory.KBSRIsSet, let char = consoleInputQueue.pop() {
            //            memory.setMemoryValue(at: Memory.KBDR, to: consoleVC.queue.pop()!.toUInt16ASCII)
            memory[Memory.KBDR].value = char.toUInt16ASCII
            memory[Memory.KBSR].value.setBit(at: 15, to: 1)
        }
        if !memory.DSRIsSet {
            // reset DSR if not set
            // can safely do b/c I always deal w/ input in DDR - see Memory for other side of this
            memory[Memory .DSR].value.setBit(at: 15, to: 1)
        }
    }
    
    // The following functions act similarly to C macros. They're probably too complicated to be worthwhile, but they ensure that all operations which should be performed for each attempt to run instructions are done correctly.
    func simulatorRunWrapper(runWhileNormalConditionsAndAlso additionalCondition: @escaping () -> Bool, instructionCompletionHandler: (() -> Void)? = nil) {
        coordinatingQueue.async {
            self.backgroundQueue.sync {
                self.isRunning = true
            }
            
            repeat {
                self.backgroundQueue.sync {
                    self.executeNextInstruction()
                    // Execute the next things to execute, if any were given.
                    instructionCompletionHandler?()
                }
            } while self.backgroundQueue.sync { !self.currentInstructionEntry.shouldBreak && self.isRunning && additionalCondition() }
            
            self.backgroundQueue.sync {
                self.isRunning = false
            }
            
//            NotificationCenter.default.post(name: Simulator.kRunFinishedWithModifiedMemoryLocations, object: self.modifiedMemoryLocationsTracker.popIndexes())
        }
    }

    // Run just one instruction.
    func stepIn() {
        simulatorRunWrapper(runWhileNormalConditionsAndAlso: { false })
    }

    // Run until we step out of the current subroutine.
    func stepOut() {
        simulatorRunWrapper(runWhileNormalConditionsAndAlso: {
            let instructionType = self.registers.ir.instructionType
            
            return instructionType != .RET && instructionType != .RTI
        })
    }
    
    // Run until have stepped over the next instruction. If the next instruciton invokes a subroutine, finish running that subroutine as well.
    func stepOver() {
        var levelsDeep = 0

        simulatorRunWrapper(runWhileNormalConditionsAndAlso: { levelsDeep > 0 }, instructionCompletionHandler: {
            switch self.registers.ir.instructionType {
            case .TRAP:
                levelsDeep += 1
            case .JSR:
                levelsDeep += 1
            case .JSRR:
                levelsDeep += 1
            case .RET:
                levelsDeep -= 1
            case .RTI:
                levelsDeep -= 1
            default:
                break
            }
        })
    }

    // Run until we're told to halt by the user or OS.
    func runForever() {
        simulatorRunWrapper(runWhileNormalConditionsAndAlso: { true })
    }
}

extension Character {
    var toUInt16ASCII: UInt16 {
        return UInt16(truncating: self.unicodeScalars.first!.value as NSNumber)
    }
}
