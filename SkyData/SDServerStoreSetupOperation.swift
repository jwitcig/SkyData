//
//  SDServerStoreSetupOperation.swift
//  SkyData
//
//  Created by Developer on 3/8/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

import SwiftTools

class SDServerStoreSetupOperation: CKModifySubscriptionsOperation {

    var managedObjectModel: NSManagedObjectModel
    
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
    
    init(database: CKDatabase, managedObjectModel: NSManagedObjectModel) {
        self.managedObjectModel = managedObjectModel
        
        super.init(subscriptionsToSave: nil, subscriptionIDsToDelete: nil)
        
        self.database = database
    }
    
    // We don't set the 'executing' because we are using super.start() which will handle starting execution
    override func start() {

        print("[SkyData] Started SDServerStoreSetupOperation")
        
        createSubscriptions()
        
        super.start()
    }
    
    func createSubscriptions() {
        let entityNames = managedObjectModel.entities.map { $0.name! }

        let subscriptions: [CKSubscription] = entityNames.map { entityName in
            
            let predicate = NSPredicate.allRows
            let subscriptionID = "\(entityName)SyncSubscription"
            let subscription = CKSubscription(recordType: entityName, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnce, .FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
            
            subscription.notificationInfo = CKNotificationInfo()
            
            return subscription
        }
        
        modifySubscriptionsCompletionBlock = { subscriptions, subscriptionIDs, error in
            print("[SkyData] Completed SDServerStoreSetupOperation")

            self.completionBlock?()
            
            self.executing = false
            self.finished = true
        }
        
        subscriptionsToSave = subscriptions
    }
    
    override func main() {
        if cancelled {
            return
        }
    }
    
}
