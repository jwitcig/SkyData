//
//  SDSession.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

public class SDSession {
    
    public static var defaultSession = SDSession()
    
    public var currentUserRecordID: CKRecordID?
    
    public var container: CKContainer!
    var managedObjectModel: NSManagedObjectModel!
    
    private static let NOTIFICATION_DELAY_DURATION = 1.2
    var notificationReceiverDelayOperation: SDDelayOperation?
    
    public init(container: CKContainer? = nil, managedObjectModel: NSManagedObjectModel? = nil) {
        self.container = container
        self.managedObjectModel = managedObjectModel
    }
    
    public func setup(container: CKContainer, managedObjectModel: NSManagedObjectModel) {
        self.container = container
        self.managedObjectModel = managedObjectModel
        
        var operations = [NSOperation]()
        
        let fetchUserIDOperation = SDFetchUserIDOperation(container: container)
        fetchUserIDOperation.completionBlock = {
            self.currentUserRecordID = fetchUserIDOperation.userRecordID
        }
        operations.append(fetchUserIDOperation)
        
//        print("[SkyData] Started SDServerStoreSetupOperation")
        
        let serverConfig = SDServerStoreConfig(database: container.publicCloudDatabase, managedObjectModel: managedObjectModel)
        serverConfig.saveSubscriptionsOperation.addDependency(fetchUserIDOperation)

        operations.append(serverConfig.saveSubscriptionsOperation)

        
        NSOperationQueue().addOperations(operations, waitUntilFinished: false)
    }
    
    public func handlePush(userInfo userInfo: [NSObject : AnyObject]) {
        let delayOperation = notificationReceiverDelayOperation ?? SDDelayOperation(delayDuration: SDSession.NOTIFICATION_DELAY_DURATION)
        
        var newDelay = true
        if delayOperation.executing && delayOperation.finished == false {
            delayOperation.cancelAndRestart()
            newDelay = false
        }
        
        guard let notificationInfo = userInfo as? [String: NSObject] else {
            print("Error: Could not cast push info dictionary")
            return
        }
        
        delayOperation.completionBlock = {
            self.notificationReceiverDelayOperation = nil
        }
        
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: notificationInfo)
        if let queryNotification = cloudKitNotification as? CKQueryNotification {
            
            print(queryNotification.queryNotificationReason)
            
        }
        if newDelay {
            NSOperationQueue().addOperation(delayOperation)
        }
    }
    
}
