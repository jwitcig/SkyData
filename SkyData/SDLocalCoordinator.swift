//
//  ORLocalRequest.swift
//  ORMKit
//
//  Created by Developer on 6/16/15.
//  Copyright (c) 2015 JwitApps. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif
import CoreData

public class SDLocalDataCoordinator: SDCoordinator {
    
    internal var mainOperationQueue = NSOperationQueue()
    
    internal var managedObjectContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    public func fetchIDs(entityName entityName: String, predicate: NSPredicate, context localContext: NSManagedObjectContext? = nil) -> ((String, [String]), ORLocalDataResponse) {
        
        let context = localContext ?? managedObjectContext
        
        let dataRequest = ORLocalDataRequest()
        
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        request.includesSubentities = true
        
        var objects = [NSManagedObject]()
        var error: NSError?
        do {
            objects = try context.executeFetchRequest(request) as! [NSManagedObject]
        } catch let err as NSError {
            error = err
            objects = []
            
            let errorAlertController = UIAlertController(title: "Error", message: "An error has occured.", preferredStyle: .Alert)
            
            errorAlertController.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
            ORSession.currentSession.currentViewController.presentViewController(errorAlertController, animated: true, completion: nil)
        }
        
        let recordNames = (objects as? [ORModel])?.recordNames ?? []
        return ((entityName, recordNames), ORLocalDataResponse(request: dataRequest, error: error, context: context))
    }
    
    public func fetch(operation operation: SDLocalDataOperation) -> SDResponseManagedObjects  {
        
        let context = operation.managedObejctContext ?? managedObjectContext
        
        guard let recordType = operation.recordType else {
            print("Must supply recordType for this operation.")
            return ([], SDDataOperationResponse(operation: operation))
        }
        
        let request = NSFetchRequest(entityName: recordType)
        request.predicate = operation.compoundPredicate
        request.includesSubentities = true
        request.sortDescriptors = operation.sortDescriptors
        request.fetchLimit = operation.resultsLimit
        request.includesPendingChanges = true
        
        var managedObjects = [NSManagedObject]()
        var error: NSError?
        do {
            managedObjects = try context.executeFetchRequest(request) as! [NSManagedObject]
        } catch let err as NSError {
            error = err
        }
        var operationResponse = SDDataOperationResponse(operation: operation)
        operationResponse.error = error
        return (managedObjects, operationResponse)
    }
    
    public func save(operation operation: SDLocalDataOperation) -> SDResponse {
        let context = operation.managedObejctContext ?? managedObjectContext
        
        var error: NSError?
        do {
            try context.save()
        } catch let err as NSError {
            error = err
        }
        
        var operationResponse = SDDataOperationResponse(operation: operation)
        operationResponse.error = error
        return operationResponse
    }
    
    public func delete(managedObjects managedObjects: [NSManagedObject], operation: SDLocalDataOperation) -> SDResponse {
        let context = operation.managedObejctContext ?? managedObjectContext
        
        managedObjects.forEach(context.delete)
        
        var error: NSError?
        do {
            try context.save()
        } catch let err as NSError {
            error = err
        }
        
        var operationResponse = SDDataOperationResponse(operation: operation)
        operationResponse.error = error
        
        return operationResponse
    }
    
}