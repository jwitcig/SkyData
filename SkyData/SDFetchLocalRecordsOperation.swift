//
//  SDFetchLocalRecordsOperations.swift
//  SkyData
//
//  Created by Developer on 3/11/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

import SwiftTools

class SDFetchLocalRecordsOperation: NSOperation {
    
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
    
    private var recordTypesAndRecords = [String: [CKRecord]]()
    var updatedRecords = [CKRecord]() {
        didSet {
            recordTypesAndRecords = [String: [CKRecord]]()
            updatedRecords.forEach {
                let recordType = $0.recordType
                
                if recordTypesAndRecords[recordType] == nil {
                    recordTypesAndRecords[recordType] = []
                }
                
                recordTypesAndRecords[recordType]!.append($0)
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

        print("[SkyData] Started SDFetchLocalRecordsOperation")
        executing = true
        
        main()
    }
    
    override func main() {
        if cancelled { self.completed(); return }
        
        let fetchCompletionOperation = NSBlockOperation {
            self.completed()
        }
        
        var fetchOperations = [NSBlockOperation]()
        for (recordType, records) in recordTypesAndRecords {
            if cancelled { self.completed(); return }

            let fetchRequest = NSFetchRequest(entityName: recordType)
            fetchRequest.predicate = NSPredicate(key: "recordName", comparator: .In, value: records.recordIDs.recordNames)
            
            let fetchOperation = NSBlockOperation {
                let context = NSManagedObjectContext(parentContext: self.parentManagedObjectContext)

                do {
                    let managedObjects = try context.executeFetchRequest(fetchRequest) as! [NSManagedObject]
                    
                    objc_sync_enter(self.managedObjectIDs)
                    self.managedObjectIDs.appendContentsOf(managedObjects.objectIDs)
                    objc_sync_exit(self.managedObjectIDs)
                    
                } catch let error as NSError {
                    print("SkyData] SDFetchLocalRecordsOperation: Fetch failed: \(error.localizedDescription)")
                    return
                }
            }
            
            fetchCompletionOperation.addDependency(fetchOperation)
            fetchOperations.append(fetchOperation)
        }
        queue.addOperations(fetchOperations + [fetchCompletionOperation], waitUntilFinished: false)
    }
    
    func completed() {
        print("[SkyData] Ended SDFetchLocalRecordsOperation")
        
        self.executing = false
        self.finished = true
    }
    
}
