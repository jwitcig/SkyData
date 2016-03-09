//
//  SMFetchUserIDOperation.swift
//  SkyData
//
//  Created by Developer on 3/8/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

class SDFetchUserIDOperation: NSOperation {
    
    var container: CKContainer
    
    var userRecordID: CKRecordID?
    
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
    
    init(container: CKContainer) {
        self.container = container
    }
    
    override func start() {
        executing = true
        
        container.fetchUserRecordIDWithCompletionHandler { userRecordID, error in
            
            self.userRecordID = userRecordID
            self.executing = false
            self.finished = true
        }
    }
    
    override func main() {
        if cancelled {
            return
        }
    }
    
}