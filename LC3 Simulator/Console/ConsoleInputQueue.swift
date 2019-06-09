//
//  ConsoleInputQueue.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

import Foundation

// a first-in, first-out queue data structure for storing characters typed as input
// generic for fun, but could just make of Character type
class ConsoleInputQueue {
    private var queue: String = "" {
        didSet {
            NotificationCenter.default.post(name: ConsoleViewController.kConsoleInputQueueCountChanged, object: nil, userInfo: nil)
        }
    }

    func push(_ string: String) {
        queue.append(string)
    }

    func pop() -> Character? {
        return queue.popFirst()
    }

    var count: Int {
        return queue.count
    }

    var hasNext: Bool {
        return !queue.isEmpty
    }
}

extension String {
    mutating func popFirst() -> Character? {
        guard let firstChar = self.first else {
            return nil
        }
        removeFirst()
        return firstChar
    }
}
