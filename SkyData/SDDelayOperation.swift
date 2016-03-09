//
//  SDNotificationDelayOperation.swift
//  SkyData
//
//  Created by Developer on 3/9/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//


class SDDelayOperation: NSOperation {
    
    override var asynchronous: Bool { return true }
    
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
    
    var timer: NSTimer?
    
    init(delayDuration: Double) {
        self.delayDuration = delayDuration
    }
    
    override func start() {
        executing = true
        
        print("[SkyData] Started SDDelayOperation")
    
        startTimer()
    }
    
    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(delayDuration, target: self, selector: Selector("completed"), userInfo: nil, repeats: false)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func main() {
        if cancelled {
            return
        }
    }
    
    override func cancel() {
        stopTimer()
    }
    
    func cancelAndRestart() {
        cancel()
        startTimer()
    }
    
    func completed() {
        completionBlock?()
        
        print("[SkyData] Ended SDDelayOperation")
        
        self.executing = false
        self.finished = true
    }
    
}