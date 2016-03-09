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
    
    override func start() {
        executing = true
        
        createSubscriptions()
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
        
        completionBlock = {
            self.executing = false
            self.finished = true
        }
        
        subscriptionsToSave = subscriptions
    }
    
}
