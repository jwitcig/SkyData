//
//  SDCloudFetchObjectOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public struct SDCloudFetchObjectsOperation: SDCloudOperation, SDFetchOperation {
    
    public var fetchOperation = CKFetchRecordsOperation()
    
    public var operation: NSOperation { return fetchOperation }
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var database: CKDatabase?
    
    public var recordIDs: [CKRecordID] {
        get { return fetchOperation.recordIDs ?? [] }
        set { fetchOperation.recordIDs = newValue }
    }
    
    public var desiredKeys: [String]? {
        get { return fetchOperation.desiredKeys }
        set { fetchOperation.desiredKeys = newValue }
    }
    
    public var recordFetchedBlock: ((CKRecord) -> ())?
    public var completionHandler: SDCompletionHandlerRecordsFound?
    
    init(recordIDs: [CKRecordID]) {
        self.recordIDs = recordIDs
    }
    
    public mutating func executeOperation(operationQueue: NSOperationQueue? = nil) {
        let currentSession = SDSession.currentSession
        
        let queue = operationQueue ?? currentSession.operationQueue
        
        fetchOperation.database = database ?? currentSession.cloudDatabase
        
        var records = [CKRecord]()
        fetchOperation.perRecordCompletionBlock = { record, recordID, error in
            if let fetchedRecord = record {
                records.append(fetchedRecord)
            }
        }
        
        fetchOperation.fetchRecordsCompletionBlock = { IDsAndRecordsDict, error in
            self.operationEnd = NSDate()

            let recordIDsFound = records.map { $0.recordID }
            let recordIDsNotFound = self.recordIDs.filter(recordIDsFound.contains)
            
            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error
            operationResponse.otherOperations = [self.fetchOperation]
            
            self.completionHandler?(recordsFound: records, recordIDsNotFound: recordIDsNotFound, operationResponse: operationResponse)
        }
        
        queue.addOperation(fetchOperation)
    }
    
    public func addDependency(dataOperation: SDCloudOperation) {
        operation.addDependency(dataOperation.operation)
    }
    
}

