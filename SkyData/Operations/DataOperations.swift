//
//  SDDataOperations.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

public protocol SDOperation {
    var operationStart: NSDate { get set }
    var operationEnd: NSDate? { get set }
}

public protocol SDLocalOperation: SDOperation {    
    mutating func executeOperation()
}

public protocol SDCloudOperation: SDOperation {
    var operation: NSOperation { get }
    
    func addDependency(dataOperation: SDCloudOperation)
    
    mutating func executeOperation(operationQueue: NSOperationQueue?)
}

public protocol SDQueryOperation: SDOperation {
    var recordType: String { get }
    
    var resultsLimit: Int { get set }
    var sortDescriptors: [NSSortDescriptor]? { get set }
}

public protocol SDFetchOperation: SDOperation {
    var desiredKeys: [String]? { get set }
}

public protocol SDModifyOperation: SDOperation {

}

public struct SDOperationResponse {
    
    var operation: SDOperation
    
    var otherOperations: [NSOperation]?
    
    var thread = NSThread.currentThread()
    
    var error: NSError?
    
    var success: Bool {
        return error == nil ? true : false
    }
    
    init(operation: SDOperation) {
        self.operation = operation
    }
    
}

public typealias SDCompletionHandlerResponse = (operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerRecordsIDs = (recordIDs: [CKRecordID], operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerModifyRecords = (savedRecords: [CKRecord], deletedRecordsIDs: [CKRecordID], operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerRecords = (records: [CKRecord], operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerManagedObject = (managedObject: NSManagedObject, operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerManagedObjects = (managedObjects: [NSManagedObject], operationResponse: SDOperationResponse) -> ()

public typealias SDCompletionHandlerRecordsFound = (recordsFound: [CKRecord], recordIDsNotFound: [CKRecordID], operationResponse: SDOperationResponse) -> ()
