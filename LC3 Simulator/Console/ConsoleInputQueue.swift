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
class ConsoleInputQueue<T> {
    private var head: Node<T>?
    private var tail: Node<T>?

    var count: Int = 0 {
        didSet {
            NotificationCenter.default.post(name: ConsoleViewController.kConsoleInputQueueCountChanged, object: nil, userInfo: nil)
        }
    }

    private class Node<T> {
        var elem: T
        var next: Node<T>?

        init(_ elem: T) {
            self.elem = elem
            next = nil
        }
    }

    func push(_ elem: T) {
        count += 1
        if tail != nil {
            tail?.next = Node(elem)
            tail = tail?.next
        } else {
            // nothing's here yet
            head = Node(elem)
            tail = head
        }
    }

    var hasNext: Bool {
        return head != nil
    }

    func pop() -> T? {
        count = max(0, count - 1) // ensure that even on a nil-returning pop() the count doesn't go below 0
        let nextElement = head?.elem
        if tail === head {
            tail = nil
        }
        head = head?.next
        return nextElement
    }
}
