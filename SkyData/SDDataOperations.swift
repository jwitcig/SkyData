//
//  SDDataOperations.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public struct SDDataOperation {
    
    var operation = CKOperation()
    
    var operationStart = NSDate()
    var operationEnd: NSDate?
    
    var predicate = NSPredicate(value: true)
    
    var recordType: String?
    
    var database: CKDatabase?
    
    var desiredKeys: [String]?
    var resultsLimit = 0
    var sortDescriptors: [NSSortDescriptor]?
    
    func addDependency(dataOperation: SDDataOperation) {
        operation.addDependency(dataOperation.operation)
    }
    
}

public struct SDDataOperationResponse {
    
    var dataOperation: SDDataOperation
    
    var otherOperations: [NSOperation]?
    
    var thread = NSThread.currentThread()
    
    init(operation: SDDataOperation) {
        self.dataOperation = operation
    }
    
}