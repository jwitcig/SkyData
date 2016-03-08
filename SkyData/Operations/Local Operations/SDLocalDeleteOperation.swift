//
//  SDLocalDeleteOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreData

import SwiftTools

public struct SDLocalDeleteOperation: SDLocalOperation, SDModifyOperation {
    
    private var saveOperation = SDLocalSaveOperation()
    
    public var objectsToDelete: [NSManagedObject]
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var managedObjectContext: NSManagedObjectContext {
        get { return saveOperation.managedObjectContext }
        set { saveOperation.managedObjectContext = newValue }
    }
    
    public var completionHandler: SDCompletionHandlerResponse?
    
    init(objectsToDelete: [NSManagedObject]) {
        self.objectsToDelete = objectsToDelete
    }
    
    public mutating func executeOperation() {
        objectsToDelete.forEach(managedObjectContext.deleteObject)
        
        managedObjectContext.performBlock {
            var error: NSError?
            
            do {
                try self.managedObjectContext.save()
            } catch let err as NSError {
                error = err
            }
            
            self.operationEnd = NSDate()
            
            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error
            
            self.completionHandler?(operationResponse: operationResponse)
        }
    }
    
}