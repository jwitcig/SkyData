//
//  SDLocalQueryOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreData

import SwiftTools

public struct SDLocalQueryOperation: SDLocalOperation, SDQueryOperation {
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var predicates = [NSPredicate(value: true)]
    public var compoundPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    public var recordType: String
    
    public var managedObjectContext = NSManagedObjectContext.contextForCurrentThread()
    
    public var resultsLimit = 0
    public var sortDescriptors: [NSSortDescriptor]?
    
    public var completionHandler: SDCompletionHandlerManagedObjects?
    
    public mutating func executeOperation() {
        
        let fetchRequest = NSFetchRequest(entityName: recordType)
        fetchRequest.predicate = compoundPredicate
        fetchRequest.fetchLimit = resultsLimit
        
        managedObjectContext.performBlock {
            var managedObjects = [NSManagedObject]()
            var error: NSError?
            
            do {
                managedObjects = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
            } catch let err as NSError {
                error = err
            }
            
            self.operationEnd = NSDate()

            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error

            self.completionHandler?(managedObjects: managedObjects, operationResponse: operationResponse)
        }
    }

}