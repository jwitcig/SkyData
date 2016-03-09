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

class SDServerStoreConfig {

    var managedObjectModel: NSManagedObjectModel
    var database: CKDatabase
        
    var saveSubscriptionsOperation: CKModifySubscriptionsOperation

    init(database: CKDatabase, managedObjectModel: NSManagedObjectModel) {
        self.managedObjectModel = managedObjectModel
        self.database = database

        self.saveSubscriptionsOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: nil)
        self.saveSubscriptionsOperation.database = database
        
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
        
        saveSubscriptionsOperation.modifySubscriptionsCompletionBlock = { subscriptions, subscriptionIDs, error in
            print("[SkyData] Completed SDServerStoreSetupOperation")

            self.saveSubscriptionsOperation.completionBlock?()
        }
        
        saveSubscriptionsOperation.subscriptionsToSave = subscriptions
    }
    
    
}
