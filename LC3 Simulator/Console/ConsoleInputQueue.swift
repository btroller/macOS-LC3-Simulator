//
//  ConsoleInputQueue.swift
//  LC3 Simulator
//
//  Created by Benjamin Troller on 2/25/19.
//  Copyright © 2019 Benjamin Troller. All rights reserved.
//

// TODO: Consider making this a singleton. It wouldn't require passing reference to it to the Simulator.

import Foundation

// A FIFO queue for storing characters typed as input.
class ConsoleInputQueue {
    
    // Handles notification from UI requesting to add characters from typed string
    @objc func newStringTyped(_ notification: Notification) {
        guard let newString = notification.userInfo?["newString"] as? String else { preconditionFailure() }
        
        self.backgroundQueue.async {
            self.push(newString)
        }
    }
    
    // Handles notification from UI requesting to reset the queue.
    @objc func clearConsoleInputQueueClicked(_ notification: Notification) {
        backgroundQueue.async {
            self.head  = nil
            self.tail  = nil
            self.count = 0
        }
    }
    
    // The work dispatch queue from Simulator.
    unowned let backgroundQueue: DispatchQueue
    
    init(dispatchQueue: DispatchQueue) {
        self.backgroundQueue = dispatchQueue
        
        NotificationCenter.default.addObserver(self, selector: #selector(newStringTyped(_:)),                name: ConsoleViewController.kNewStringTyped,           object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearConsoleInputQueueClicked(_:)), name: ConsoleViewController.kClearConsoleInputClicked, object: nil)
    }
    
    class Node {
        
        let character: Character
        var nextNode:  Node?     = nil
        
        init(character: Character) {
            self.character = character
        }
        
    }
    
    var head:  Node? = nil
    var tail:  Node? = nil
    var count: Int   = 0   {
        didSet {
            let notification = Notification(name: ConsoleViewController.kConsoleInputQueueCountChanged, object: nil, userInfo: ["newCount" : self.count])
            NotificationCenter.default.post(notification)
        }
    }
    var hasNext: Bool { count > 0 }
    
    func push(_ string: String) {
        for character in string {
            let newNode = Node(character: character)
            
            // Assign head to it if the list is empty.
            if head == nil {
                head = newNode
            }
            
            // Point last node to the new one.
            tail?.nextNode = newNode
            
            // Assign to end of list.
            tail = newNode
            
            count += 1
        }
    }
    
    func pop() -> Character? {
        // 0 elements.
        guard let returnValue = head?.character else {
            assert(head  == nil)
            assert(tail  == nil)
            assert(count ==   0)
            return nil
        }
        
        assert(head != nil)
        assert(tail != nil)
        
        // 1 element.
        if head === tail {
            assert(count == 1)
            
            head = nil
            tail = nil
        }
        // More than 1 element.
        else {
            assert(count > 1)
            
            head = head!.nextNode
        }
        
        count -= 1
        
        return returnValue
    }
    
}
