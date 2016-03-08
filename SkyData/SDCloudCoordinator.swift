//
//  ORCloudRequest.swift
//  ORMKit
//
//  Created by Developer on 6/16/15.
//  Copyright (c) 2015 JwitApps. All rights reserved.
//

import Foundation
import CloudKit

public class SDDataCoordinator: SDCoordinator {
    
    internal var mainOperationQueue = NSOperationQueue()
    
    public var container: CKContainer
    public var database: CKDatabase
    
    public init(container: CKContainer, database: CKDatabase) {
        self.container = container
        self.database = database
    }
    
    public func fetchIDs(operation operation: SDCloudDataOperation, completionHandler: SDResponseCompletionHandlerRecordsIDs) {
        
        guard let recordType = operation.recordType else { print("Must supply recordType for this operation."); return }
        
        let query = CKQuery(recordType: recordType, predicate: operation.predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.database = operation.database ?? database
        queryOperation.desiredKeys = ["recordName"]
        
        var recordIDs = [CKRecordID]()
        queryOperation.recordFetchedBlock = {
            recordIDs.append($0.recordID)
        }
        
        queryOperation.completionBlock = {
            var operationResponse = SDDataOperationResponse(operation: operation)
            operationResponse.otherOperations = [queryOperation]
            
            completionHandler(recordIDs: recordIDs, operationResponse: operationResponse)
        }
        
        mainOperationQueue.addOperation(queryOperation)
    }
    
    public func fetch(operation operation: SDCloudDataOperation, completionHandler: SDResponseCompletionHandlerRecords) {

        guard let recordType = operation.recordType else { print("Must supply recordType for this operation."); return }
        
        let query = CKQuery(recordType: recordType, predicate: operation.predicate)
        query.sortDescriptors = operation.sortDescriptors
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.database = operation.database ?? database
        queryOperation.desiredKeys = operation.desiredKeys
        queryOperation.resultsLimit = operation.resultsLimit
        
        var records = [CKRecord]()
        queryOperation.recordFetchedBlock = {
            records.append($0)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            var operationResponse = SDDataOperationResponse(operation: operation)
            operationResponse.otherOperations = [queryOperation]
            
            completionHandler(records: records, operationResponse: operationResponse)
        }
        mainOperationQueue.addOperation(queryOperation)
    }
    
    public func save(record record: CKRecord, operation: SDCloudDataOperation = SDCloudDataOperation(), completionHandler: SDResponseCompletionHandler) {
        
        save(records: [record], operation: operation, completionHandler: completionHandler)
    }
    
    public func save(records records: [CKRecord], operation: SDCloudDataOperation = SDCloudDataOperation(), completionHandler: SDResponseCompletionHandler) {
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        saveOperation.database = operation.database ?? database
        
        saveOperation.completionBlock = {
            var operationResponse = SDDataOperationResponse(operation: operation)
            operationResponse.otherOperations = [saveOperation]
            
            completionHandler(operationResponse: operationResponse)
        }
    }
    
    
}