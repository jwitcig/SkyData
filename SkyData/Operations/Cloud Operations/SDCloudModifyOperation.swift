//
//  SDCloudSaveOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public struct SDCloudModifyOperation: SDCloudOperation, SDModifyOperation {

    public var modifyOperation = CKModifyRecordsOperation()
    public var operation: NSOperation { return modifyOperation }
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var recordsToSave: [CKRecord]? {
        get { return modifyOperation.recordsToSave }
        set { modifyOperation.recordsToSave = newValue }
    }
    public var recordsIDsToDelete: [CKRecordID]? {
        get { return modifyOperation.recordIDsToDelete }
        set { modifyOperation.recordIDsToDelete = newValue }
    }
    
    public var database: CKDatabase?
    
    public var completionHandler: SDCompletionHandlerModifyRecords?
    
    init(recordsToSave: [CKRecord]? = nil, recordsIDsToDelete: [CKRecordID]? = nil) {
        self.recordsToSave = recordsToSave
        self.recordsIDsToDelete = recordsIDsToDelete
    }
    
    public mutating func executeOperation(operationQueue: NSOperationQueue? = nil) {
        let currentSession = SDSession.currentSession
        
        let queue = operationQueue ?? currentSession.operationQueue
        
        modifyOperation.database = database ?? currentSession.cloudDatabase
                
        modifyOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
           self.operationEnd = NSDate()
            
            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error
            operationResponse.otherOperations = [self.modifyOperation]
            
            self.completionHandler?(savedRecords: savedRecords ?? [], deletedRecordsIDs: deletedRecordsIDs ?? [], operationResponse: operationResponse)
        }
        
        queue.addOperation(modifyOperation)
    }
    
    public func addDependency(dataOperation: SDCloudOperation) {
        operation.addDependency(dataOperation.operation)
    }
}
