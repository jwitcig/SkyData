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
    
    var unprocessedCKNotifications = [CKQueryNotification]()
    
    var previousServerChangeToken: CKServerChangeToken?
    
    public func handlePush(userInfo userInfo: [NSObject : AnyObject]) {
        guard let notificationInfo = userInfo as? [String: NSObject] else {
            print("Error: Could not cast to push info dictionary")
            return
        }
        
        let notification = CKNotification(fromRemoteNotificationDictionary: notificationInfo)
        
        guard let queryNotification = notification as? CKQueryNotification else {
            print("Unimplemented notification type: '\(notification.notificationType)' : \(notification)")
            return
        }
        
        unprocessedCKNotifications.append(queryNotification)
        
        let syncOperationQueue = NSOperationQueue()
        
        // Enforce wait period for more change notifications to come in
        let waitOperation = createWaitOperation(previousWaitOperation: lastWaitOperation)
        syncOperationQueue.addOperation(waitOperation)
        
        // Check notifications, pull necessary notifications that werent sent
        
        let fetchUnreadNotificationsOperation = SDFetchNotificationsOperation(container: container, serverChangeToken: previousServerChangeToken, queue: syncOperationQueue)
        fetchUnreadNotificationsOperation.completionBlock = {
            
            let fetchedNotifications = fetchUnreadNotificationsOperation.notifications as! [CKQueryNotification]
            // Process notifications, pull records for each notification
            let createdAndUpdatedNotifications = fetchedNotifications.filter { $0.queryNotificationReason != .RecordDeleted }
            
            let uniqueRecordIDs = createdAndUpdatedNotifications.map { $0.recordID! }.unique
            
            let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: uniqueRecordIDs)
            fetchRecordsOperation.database = self.container.publicCloudDatabase
            
            var changedAndUpdatedRecords = [CKRecord]()
            fetchRecordsOperation.perRecordCompletionBlock = { record, recordID, error in
                if let cloudRecord = record {
                    changedAndUpdatedRecords.append(cloudRecord)
                }
            }
            
            fetchRecordsOperation.fetchRecordsCompletionBlock = { recordsDictionary, error in

            
            }
            
            fetchRecordsOperation.addDependency(fetchUnreadNotificationsOperation)
            syncOperationQueue.addOperation(fetchRecordsOperation)
        }
        fetchUnreadNotificationsOperation.addDependency(waitOperation)
        
        syncOperationQueue.addOperation(fetchUnreadNotificationsOperation)
        


        
        // Write record data to local managedObject
        
        // Mark received notifications as read
        
        let markNotificationsReadOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: self.unprocessedCKNotifications.notificationIDs)
        
        
    }
        
    private var lastWaitOperation: SDDelayOperation?
    
    private func createWaitOperation(previousWaitOperation previousWaitOperation: NSOperation? = nil) -> SDDelayOperation {
        
        previousWaitOperation?.cancel()
    
        let newOperation = SDDelayOperation(delayDuration: SDSession.NOTIFICATION_DELAY_DURATION)
        lastWaitOperation = newOperation
        
        return newOperation
    }
    
}
