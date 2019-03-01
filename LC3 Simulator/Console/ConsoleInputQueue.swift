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
    private var head : Node<T>? = nil
    private var tail : Node<T>? = nil
    
    private class Node<T> {
        var elem : T
        var next : Node<T>?
        
        init(_ elem : T) {
            self.elem = elem
            self.next = nil
        }
        
//        init(_ elem : T, next : Node<T>) {
//            self.elem = elem
//            self.next = next
//        }
    }
    
    func push(_ elem: T) {
        if tail != nil {
            tail?.next = Node(elem)
            tail = tail?.next
        }
        else {
            // nothing's here yet
            head = Node(elem)
            tail = head
        }
    }
    
    var hasNext : Bool {
        return head != nil
    }
    
    func pop() -> T? {
        // TODO: update tail
        let nextElement = head?.elem
        if (tail === head) {
            tail = nil
        }
        head = head?.next
        return nextElement
    }
    
}
