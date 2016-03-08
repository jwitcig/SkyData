//
//  SDCloudDeleteOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public struct SDCloudDeleteOperation: SDCloudOperation, SDModifyOperation {
    
    private var cloudModifyOperation = SDCloudModifyOperation()
    
    public var operation: NSOperation { return cloudModifyOperation.operation }
    
    public var operationStart: NSDate {
        get { return cloudModifyOperation.operationStart }
        set { cloudModifyOperation.operationStart = newValue }
    }
    public var operationEnd: NSDate? {
        get { return cloudModifyOperation.operationEnd }
        set { cloudModifyOperation.operationEnd = newValue }
    }
    
    public var recordsIDsToDelete: [CKRecordID]? {
        get { return cloudModifyOperation.recordsIDsToDelete }
        set { cloudModifyOperation.recordsIDsToDelete = newValue }
    }
    
    public var database: CKDatabase? {
        get { return cloudModifyOperation.database }
        set { cloudModifyOperation.database = newValue }
    }
    
    public var completionHandler: SDCompletionHandlerModifyRecords?
    
    init(recordsIDsToDelete: [CKRecordID]) {
        self.recordsIDsToDelete = recordsIDsToDelete
    }
    
    public mutating func executeOperation(operationQueue: NSOperationQueue? = nil) {
        cloudModifyOperation.completionHandler = completionHandler
        
        cloudModifyOperation.executeOperation(operationQueue)
    }
    
    public func addDependency(dataOperation: SDCloudOperation) {
        operation.addDependency(dataOperation.operation)
    }
}
