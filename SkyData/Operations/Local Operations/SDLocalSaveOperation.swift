//
//  SDLocalSaveOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreData

import SwiftTools

public struct SDLocalSaveOperation: SDLocalOperation, SDModifyOperation {
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var managedObjectContext = NSManagedObjectContext.contextForCurrentThread()
    
    public var completionHandler: SDCompletionHandlerManagedObjects?
    
    public mutating func executeOperation() {
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
            
            let insertedObjects = self.managedObjectContext.insertedObjects.array
            let updatedObjects = self.managedObjectContext.updatedObjects.array
            let deletedObjects = self.managedObjectContext.deletedObjects.array 
            
            let allEditedObjects = (insertedObjects + updatedObjects + deletedObjects)
            self.completionHandler?(managedObjects: allEditedObjects, operationResponse: operationResponse)
        }
    }
    
}