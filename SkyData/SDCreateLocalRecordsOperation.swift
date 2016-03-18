//
//  SDCreateLocalRecordsOperation.swift
//  SkyData
//
//  Created by Developer on 3/11/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

import SwiftTools

class SDCreateLocalRecordsOperation: NSOperation {
    
    override var asynchronous: Bool { return false }
    
    var _executing = false
    var _finished = false
    override var executing : Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    override var finished : Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    var recordTypesAndNames = [String: [String]]()
    var createdRecords = [CKRecord]() {
        didSet {
            recordTypesAndNames = [String: [String]]()
            createdRecords.forEach {
                let recordType = $0.recordType
                let recordName = $0.recordID.recordName
                
                if recordTypesAndNames[recordType] == nil {
                    recordTypesAndNames[recordType] = []
                }
                
                recordTypesAndNames[recordType]!.append(recordName)
            }
        }
    }
    
    var parentManagedObjectContext: NSManagedObjectContext
    
    // Holds reference to the queue running this operation to use for internally created operations
    var queue: NSOperationQueue
    
    var managedObjectIDs = [NSManagedObjectID]()
    
    init(managedObjectContext: NSManagedObjectContext, queue: NSOperationQueue) {
        self.parentManagedObjectContext = managedObjectContext
        self.queue = queue
    }
    
    override func start() {
        if cancelled { self.completed(); return }

        print("[SkyData] Started SDCreateLocalRecordsOperation")
        executing = true
        
        main()
    }
    
    override func main() {
        if cancelled { self.completed(); return }
        
        let context = NSManagedObjectContext(parentContext: self.parentManagedObjectContext)
        context.retainsRegisteredObjects = true
        context.performBlock {
            if self.cancelled { self.completed(); return }

            var managedObjects = [NSManagedObject]()
            for (recordType, recordNames) in self.recordTypesAndNames {
                recordNames.forEach {
                    let managedObject = NSEntityDescription.insertNewObjectForEntityForName(recordType, inManagedObjectContext: context)
                    
                    managedObject["recordName"] = $0
                    managedObjects.append(managedObject)
                }
            }
            
            do {
                try context.save()
                
                print(managedObjects.count)

                print(context.insertedObjects.count)
                
                objc_sync_enter(self.managedObjectIDs)
                self.managedObjectIDs = managedObjects.objectIDs
                objc_sync_exit(self.managedObjectIDs)
                
            } catch let error as NSError {
                print("SkyData] SDCreateLocalRecordsOperation: Save failed: \(error.localizedDescription)")
                return
            }
            
            self.completed()
        }
    }
    
    func completed() {
        print("[SkyData] Ended SDCreateLocalRecordsOperation")
        
        self.executing = false
        self.finished = true
    }
    
}
