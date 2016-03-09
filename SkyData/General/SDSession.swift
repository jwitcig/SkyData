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
        
        print("[SkyData] Started SDServerStoreSetupOperation")
        let serverConfig = SDServerStoreConfig(database: container.publicCloudDatabase, managedObjectModel: managedObjectModel)
        serverConfig.saveSubscriptionsOperation.addDependency(fetchUserIDOperation)

        operations.append(serverConfig.saveSubscriptionsOperation)

        
        NSOperationQueue().addOperations(operations, waitUntilFinished: false)
    }
    
}
