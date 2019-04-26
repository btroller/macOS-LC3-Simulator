//
//  lc3OS.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 1/26/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Foundation

class LC3OS {

    static let nonZeroValues: [UInt16: UInt16] = [
        // Trap vector table (valid entries)
        0x0020: 0x0400,
        0x0021: 0x0430,
        0x0022: 0x0450,
        0x0023: 0x04A0,
        0x0024: 0x04E0,
        0x0025: 0xFD70,
        // Implementation of GETC
        0x0400: 0x3E07,
        0x0401: 0xA004,
        0x0402: 0x07FE,
        0x0403: 0xA003,
        0x0404: 0x2E03,
        0x0405: 0xC1C0,
        0x0406: 0xFE00,
        0x0407: 0xFE02,
        // Implementation of OUT
        0x0430: 0x3E0A,
        0x0431: 0x3208,
        0x0432: 0xA205,
        0x0433: 0x07FE,
        0x0434: 0xB004,
        0x0435: 0x2204,
        0x0436: 0x2E04,
        0x0437: 0xC1C0,
        0x0438: 0xFE04,
        0x0439: 0xFE06,
        // Implementation of PUTS
        0x0450: 0x3E16,
        0x0451: 0x3012,
        0x0452: 0x3212,
        0x0453: 0x3412,
        0x0454: 0x6200,
        0x0455: 0x0405,
        0x0456: 0xA409,
        0x0457: 0x07FE,
        0x0458: 0xB208,
        0x0459: 0x1021,
        0x045A: 0x0FF9,
        0x045B: 0x2008,
        0x045C: 0x2208,
        0x045D: 0x2408,
        0x045E: 0x2E08,
        0x045F: 0xC1C0,
        0x0460: 0xFE04,
        0x0461: 0xFE06,
        0x0462: 0xF3FD,
        0x0463: 0xF3FE,
        // Implementation of IN
        0x04A0: 0x3E06,     // ST R7, SaveR7
        0x04A1: 0xE006,     // LEA R0, Message
        0x04A2: 0xF022,     // PUTS
        0x04A3: 0xF020,     // GETC
        0x04A4: 0xF021,     // OUT
        0x04A5: 0x2E01,     // LD R7, SaveR7
        0x04A6: 0xC1C0,     // RET
        0x04A7: 0x3001,     // SaveR7 (.BLKW #1)
        /* the "Input a character> " message goes here */
        // Implementation of PUTSP
        0x04E0: 0x3E27,
        0x04E1: 0x3022,
        0x04E2: 0x3222,
        0x04E3: 0x3422,
        0x04E4: 0x3622,
        0x04E5: 0x1220,
        0x04E6: 0x6040,
        0x04E7: 0x0406,
        0x04E8: 0x480D,
        0x04E9: 0x2418,
        0x04EA: 0x5002,
        0x04EB: 0x0402,
        0x04EC: 0x1261,
        0x04ED: 0x0FF8,
        0x04EE: 0x2014,
        0x04EF: 0x4806,
        0x04F0: 0x2013,
        0x04F1: 0x2213,
        0x04F2: 0x2413,
        0x04F3: 0x2613,
        0x04F4: 0x2E13,
        0x04F5: 0xC1C0,
        0x04F6: 0x3E06,
        0x04F7: 0xA607,
        0x04F8: 0x0801,
        0x04F9: 0x0FFC,
        0x04FA: 0xB003,
        0x04FB: 0x2E01,
        0x04FC: 0xC1C0,
        0x04FE: 0xFE06,
        0x04FF: 0xFE04,
        0x0500: 0xF3FD,
        0x0501: 0xF3FE,
        0x0502: 0xFF00,
        // Implementation of HALT
        0xFD00: 0x3E3E,
        0xFD01: 0x303C,
        0xFD02: 0x2007,
        0xFD03: 0xF021,
        0xFD04: 0xE006,
        0xFD05: 0xF022,
        0xFD06: 0xF025,
        0xFD07: 0x2036,
        0xFD08: 0x2E36,
        0xFD09: 0xC1C0,
        0xFD70: 0x3E0E,
        0xFD71: 0x320C,
        0xFD72: 0x300A,
        0xFD73: 0xE00C,
        0xFD74: 0xF022,
        0xFD75: 0xA22F,
        0xFD76: 0x202F,
        0xFD77: 0x5040,
        0xFD78: 0xB02C,
        0xFD79: 0x2003,
        0xFD7A: 0x2203,
        0xFD7B: 0x2E03,
        0xFD7C: 0xC1C0,
        /* the "halting the processor" message goes here */
        0xFDA5: 0xFFFE,
        0xFDA6: 0x7FFF,
        // Display status register
        0xFE04: 0x8000,
        // Machine control register
        0xFFFE: 0xFFFF
    ]

    static let osSymbols = [
        "TRAP_GETC": 0x0400,
        "TRAP_OUT": 0x0430,
        "TRAP_PUTS": 0x0450,
        "TRAP_IN": 0x04A0,
        "TRAP_PUTSP": 0x04E0,
        "TRAP_HALT": 0xFD70,
        "KBSR": 0xFE00,
        "KBDR": 0xFE02,
        "DSR": 0xFE04,
        "DDR": 0xFE06,
        "MCR": 0xFFFE,
        "SS_START": 0x0300
    ]

}
