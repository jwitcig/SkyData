//
//  SDSession.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

import SwiftTools

public class SDSession {
    
    public static var defaultSession = SDSession()
    
    public var currentUserRecordID: CKRecordID?
    
    public var container: CKContainer!
    var managedObjectContext: NSManagedObjectContext!
    var managedObjectModel: NSManagedObjectModel!
    
    private static let NOTIFICATION_DELAY_DURATION = 1.2
    
    init() { }
    
    public func setup(container: CKContainer, managedObjectContext: NSManagedObjectContext, managedObjectModel: NSManagedObjectModel) {
        self.container = container
        self.managedObjectContext = managedObjectContext
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
        
        print(queryNotification)
        
        unprocessedCKNotifications.append(queryNotification)
        
        let syncOperationQueue = NSOperationQueue()
        
        // Operations
        let waitOperation = createWaitOperation(previousWaitOperation: lastWaitOperation)
        
        let fetchUnreadNotificationsOperation = SDFetchNotificationsOperation(container: container, serverChangeToken: previousServerChangeToken, queue: syncOperationQueue)
        
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [])
        
        let fetchLocalRecordsOperation = SDFetchLocalRecordsOperation(managedObjectContext: managedObjectContext, queue: syncOperationQueue)
        
        let createLocalRecordsOperation = SDCreateLocalRecordsOperation(managedObjectContext: managedObjectContext, queue: syncOperationQueue)
        
        let writeLocalDataJoiningOperation = NSBlockOperation()
        
        let writeLocalDataOperation = SDWriteLocalDataOperation(managedObjectContext: managedObjectContext, queue: syncOperationQueue)
        
        let markNotificationsReadOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: [])

        
        // Enforce wait period for more change notifications to come in
        syncOperationQueue.addOperation(waitOperation)
        
        // Check notifications, pull necessary notifications that werent sent
        var unreadNotifications = [CKQueryNotification]()
        
        var createNotifications: [CKQueryNotification] {
            return unreadNotifications.filter { $0.queryNotificationReason == .RecordCreated }
        }
        var updateNotifications: [CKQueryNotification] {
            return unreadNotifications.filter { $0.queryNotificationReason == .RecordUpdated }
        }
        var deleteNotifications: [CKQueryNotification] {
            return unreadNotifications.filter { $0.queryNotificationReason == .RecordDeleted }
        }
        var createAndUpdateNotifications: [CKQueryNotification] {
            return createNotifications + updateNotifications
        }
        var uniqueCreateRecordIDs: Set<CKRecordID> {
            return createNotifications.map { $0.recordID! }.set
        }
        var uniqueUpdateRecordIDs: Set<CKRecordID> {
            return updateNotifications.map { $0.recordID! }.set
        }
        var uniqueDeleteRecordIDs: Set<CKRecordID> {
            return deleteNotifications.map { $0.recordID! }.set
        }
        
        fetchUnreadNotificationsOperation.fetchUnreadNotificationsCompletionBlock = { fetchedNotifications in

            print("fetched notifications: \(fetchedNotifications.count)")

            unreadNotifications = fetchedNotifications.filter { $0.notificationType != .ReadNotification } as! [CKQueryNotification]
            
            markNotificationsReadOperation.notificationIDs = unreadNotifications.notificationIDs
            
            // Process notifications, pull records for each notification
            fetchRecordsOperation.recordIDs = uniqueUpdateRecordIDs.union(uniqueCreateRecordIDs).array
        }
        
        fetchUnreadNotificationsOperation.addDependency(waitOperation)
        
        syncOperationQueue.addOperation(fetchUnreadNotificationsOperation)
        
        // Process notifications, pull records for each notification
        fetchRecordsOperation.database = self.container.publicCloudDatabase
        
        var updatedRecords = [CKRecord]()
        var createdRecords = [CKRecord]()
        fetchRecordsOperation.perRecordCompletionBlock = { record, recordID, error in
            if let cloudRecord = record {
                if uniqueUpdateRecordIDs.contains(cloudRecord.recordID) {
                    updatedRecords.append(cloudRecord)
                }
                
                if uniqueCreateRecordIDs.contains(cloudRecord.recordID) {
                    createdRecords.append(cloudRecord)
                }
            }
        }
        
        fetchRecordsOperation.fetchRecordsCompletionBlock = { recordsDictionary, error in            
            fetchLocalRecordsOperation.updatedRecords = updatedRecords
            
            createLocalRecordsOperation.createdRecords = createdRecords
        }
        
        fetchRecordsOperation.addDependency(fetchUnreadNotificationsOperation)
        syncOperationQueue.addOperation(fetchRecordsOperation)

        // Fetch local records        
        fetchLocalRecordsOperation.addDependency(fetchRecordsOperation)
        
        syncOperationQueue.addOperation(fetchLocalRecordsOperation)
        
        // Create local records for create notifications
        createLocalRecordsOperation.completionBlock = {
            print("Created local managedObjects: \(createLocalRecordsOperation.managedObjectIDs.count)")
        }
        createLocalRecordsOperation.addDependency(fetchRecordsOperation)
        
        syncOperationQueue.addOperation(createLocalRecordsOperation)
        
        // Write record data to local managedObjects
        writeLocalDataJoiningOperation.addExecutionBlock {
            let fetchedRecordIDs = fetchLocalRecordsOperation.managedObjectIDs.set
            let createdRecordIDs = createLocalRecordsOperation.managedObjectIDs.set
            
            let allRecordIDs = fetchedRecordIDs.union(createdRecordIDs)
            writeLocalDataOperation.recordData = (allRecordIDs, createdRecords + updatedRecords)
        }
        writeLocalDataJoiningOperation.addDependency(fetchLocalRecordsOperation)
        writeLocalDataJoiningOperation.addDependency(createLocalRecordsOperation)
        
        
        
        writeLocalDataOperation.completionBlock = {
            
            print(self.managedObjectContext.insertedObjects.map { $0.changedValues() })
            runOnMainThread {
                self.managedObjectContext.performBlock {
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        print("error on final save")
                    }
                }
            }
            
        }

        writeLocalDataOperation.addDependency(writeLocalDataJoiningOperation)
        
        syncOperationQueue.addOperation(writeLocalDataJoiningOperation)
        syncOperationQueue.addOperation(writeLocalDataOperation)
        
        // Mark received notifications as read
        markNotificationsReadOperation.markNotificationsReadCompletionBlock = {
            print("notifications marked as read: \($0.0!.count)")
        }
        
        markNotificationsReadOperation.addDependency(fetchUnreadNotificationsOperation)
        
        container.addOperation(markNotificationsReadOperation)
    }
        
    private var lastWaitOperation: SDDelayOperation?
    
    private func createWaitOperation(previousWaitOperation previousWaitOperation: NSOperation? = nil) -> SDDelayOperation {
        
        previousWaitOperation?.cancel()
    
        let newOperation = SDDelayOperation(delayDuration: SDSession.NOTIFICATION_DELAY_DURATION)
        lastWaitOperation = newOperation
        
        return newOperation
    }
    
}
