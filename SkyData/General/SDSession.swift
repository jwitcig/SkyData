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
        var operations = [NSOperation]()
        
        let fetchUserIDOperation = SDFetchUserIDOperation(container: container)
        fetchUserIDOperation.completionBlock = {
            self.currentUserRecordID = fetchUserIDOperation.userRecordID
        }
        operations.append(fetchUserIDOperation)
        
        
        let serverSetupOperation = SDServerStoreSetupOperation(database: container.publicCloudDatabase, managedObjectModel: managedObjectModel)
        serverSetupOperation.addDependency(fetchUserIDOperation)

        operations.append(serverSetupOperation)

        
        NSOperationQueue().addOperations(operations, waitUntilFinished: false)
    }
    
}
