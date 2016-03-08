//
//  adsf.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreData

public struct SDLocalQueryOperation: SDLocalOperation, SDQueryOperation {
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var predicates = [NSPredicate(value: true)]
    public var compoundPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    public var recordType: String
    
    public var managedObjectContext: NSManagedObjectContext?
    
    public var desiredKeys: [String]?
    public var resultsLimit = 0
    public var sortDescriptors: [NSSortDescriptor]?
    
    public var completionHandler: SDCompletionHandlerManagedObjects?
    
    public mutating func executeOperation() {
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

}