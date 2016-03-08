//
//  SDCloudQueryOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public struct SDCloudQueryOperation: SDCloudOperation, SDQueryOperation {
    
    public var query: CKQuery
    public var queryOperation = CKQueryOperation()
    
    public var operation: NSOperation { return queryOperation }
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var predicate: NSPredicate { return query.predicate }
    
    public var recordType: String { return query.recordType }
    
    public var database: CKDatabase?
    
    public var desiredKeys: [String]? {
        get { return queryOperation.desiredKeys }
        set { queryOperation.desiredKeys = newValue }
    }
    public var resultsLimit: Int {
        get { return queryOperation.resultsLimit }
        set { queryOperation.resultsLimit = newValue }
    }
    public var sortDescriptors: [NSSortDescriptor]? {
        get { return query.sortDescriptors }
        set { query.sortDescriptors = newValue }
    }
    
    public var recordFetchedBlock: ((CKRecord) -> ())?
    public var completionHandler: SDCompletionHandlerRecords?
    
    init(recordType: String, predicate: NSPredicate? = nil) {
        query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
    }
    
    public mutating func executeOperation(operationQueue: NSOperationQueue? = nil) {
        let currentSession = SDSession.currentSession
        
        let queue = operationQueue ?? currentSession.operationQueue
        
        queryOperation.database = database ?? currentSession.cloudDatabase
        
        var records = [CKRecord]()
        queryOperation.recordFetchedBlock = {
            records.append($0)
            self.recordFetchedBlock?($0)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            self.operationEnd = NSDate()
            
            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error
            operationResponse.otherOperations = [self.queryOperation]
            
            self.completionHandler?(records: records, operationResponse: operationResponse)
        }
        
        queue.addOperation(queryOperation)
    }
    
    public func addDependency(dataOperation: SDCloudOperation) {
        operation.addDependency(dataOperation.operation)
    }
    
}

