//
//  SDFetchNotificationsOperation.swift
//  SkyData
//
//  Created by Developer on 3/11/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

import SwiftTools

class SDFetchNotificationsOperation: NSOperation {

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
    
    var fetchUnreadNotificationsCompletionBlock: (([CKNotification])->())?
    
    // Passes fetched notifications all the way to the initial grandparent fetch operation
    var notifications = [CKNotification]() {
        willSet {
            let newItems = Set(newValue).subtract(Set(notifications))
            parentFetchOperation?.notifications.appendContentsOf(newItems)
        }
    }
    
    /*
        fetch '0'
            notifications = [1, 2]
            
            subfetch '1'
                notifications = [3, 4]
                
                notifications {
                    didSet {
                        superOperation.notifications += notifications
                    }
                }
                
                subfetch '2'
                    notifications = [5, 6]
    */
    
    var container: CKContainer
    var previousServerChangeToken: CKServerChangeToken?
    
    var newServerChangeToken: CKServerChangeToken?
   
    private var parentFetchOperation: SDFetchNotificationsOperation?
    
    // Holds reference to the queue running this operation to use for internally created operations
    var queue: NSOperationQueue
    
    init(container: CKContainer, serverChangeToken previousServerChangeToken: CKServerChangeToken?, queue: NSOperationQueue) {
        self.container = container
        self.previousServerChangeToken = previousServerChangeToken
        self.queue = queue
    }
    
    private convenience init(container: CKContainer, serverChangeToken previousServerChangeToken: CKServerChangeToken?, queue: NSOperationQueue, parentFetchOperation: SDFetchNotificationsOperation) {
        
        self.init(container: container, serverChangeToken: previousServerChangeToken, queue: queue)
        
        self.parentFetchOperation = parentFetchOperation
    }
    
    override func start() {
        print("[SkyData] Started SDFetchNotificationsOperation")
        executing = true
        
        main()
    }
    
    override func main() {
        guard !cancelled else { return }

        let fetchUnreadNotificationsOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: previousServerChangeToken)
        fetchUnreadNotificationsOperation.container = container
        
        fetchUnreadNotificationsOperation.notificationChangedBlock = {
            self.notifications.append($0)
        }
        
        fetchUnreadNotificationsOperation.fetchNotificationChangesCompletionBlock = { newServerChangeToken, error in
            
            self.newServerChangeToken = newServerChangeToken

            guard !fetchUnreadNotificationsOperation.moreComing else {
                let newFetchOperation = SDFetchNotificationsOperation(container: self.container, serverChangeToken: newServerChangeToken, queue: self.queue, parentFetchOperation: self)
                self.queue.addOperation(newFetchOperation)
                return
            }

            self.completed()
        }
        queue.addOperation(fetchUnreadNotificationsOperation)
    }
    
    func completed() {
        print("[SkyData] Ended SDFetchNotificationsOperation")
        
        fetchUnreadNotificationsCompletionBlock?(notifications)
        
        self.executing = false
        self.finished = true

        parentFetchOperation?.completed()
    }
    
}