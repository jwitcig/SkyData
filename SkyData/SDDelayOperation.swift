//
//  SDNotificationDelayOperation.swift
//  SkyData
//
//  Created by Developer on 3/9/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import SwiftTools

class SDDelayOperation: NSOperation {
    
    override var asynchronous: Bool { return false }
    
    var _executing = false
    var _finished = false
    override var executing : Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    override var finished : Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    var delayDuration: Double
    
    init(delayDuration: Double) {
        self.delayDuration = delayDuration
    }
    
    override func start() {
        if cancelled { self.completed(); return }

        print("[SkyData] Started SDDelayOperation")
    
        startTimer()
    }
    
    private func startTimer() {
        if cancelled { self.completed(); return }

        executing = true

        runOnMainThread {
            self.performSelector("completed", withObject: nil, afterDelay: self.delayDuration)
        }
    }
    
    func stopTimer() {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "completed", object: nil)
    }
    
    override func main() {
        if cancelled {
            return
        }
    }
    
    override func cancel() {
        executing = false
        stopTimer()
    }
    
    func completed() {
        print("[SkyData] Ended SDDelayOperation")
        
        self.executing = false
        self.finished = true
    }
    
}