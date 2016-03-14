//
//  SDWriteLocalDataOperation.swift
//  SkyData
//
//  Created by Developer on 3/14/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

import SwiftTools

class SDWriteLocalDataOperation: NSOperation {

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
    
    var recordData: (Set<NSManagedObjectID>, [CKRecord])!
    
    init(managedObjectContext: NSManagedObjectContext, queue: NSOperationQueue) {
        self.parentManagedObjectContext = managedObjectContext
        self.queue = queue
    }
    
    override func start() {
        print("[SkyData] Started SDWriteLocalDataOperation")
        executing = true
        
        main()
    }
    
    override func main() {
        guard !cancelled else { return }
        
        let writeCompletionOperation = NSBlockOperation {
            self.completed()
        }
        
        let allMangagedObjectIDs = recordData.0
        let allCloudRecords = recordData.1
        
        let context = NSManagedObjectContext(parentContext: self.parentManagedObjectContext)
        
        var writeOperations = [NSBlockOperation]()
        
        let recordTypes = allCloudRecords.map { $0.recordType }.unique
        recordTypes.forEach { recordType in
            
            let relevantCloudRecords = allCloudRecords.filter { $0.recordType == recordType }
           
            let fetchRequest = NSFetchRequest(entityName: recordType)
            fetchRequest.predicate = NSPredicate(key: "self", comparator: .In, value: allMangagedObjectIDs)
            
            let writeOperation = NSBlockOperation {
                context.performBlockAndWait {
                    var fetchedManagedObjects = [NSManagedObject]()
                    
                    do {
                        fetchedManagedObjects = try context.executeFetchRequest(fetchRequest) as! [NSManagedObject]
                    } catch let error as NSError {
                        print("SkyData] SDWriteLocalDataOperation: Fetch failed: \(error.localizedDescription)")
                        
                        writeOperations.forEach {$0.cancel()}
                        self.cancel()
                    }
                    
                    fetchedManagedObjects.forEach { managedObject in
                        let record = relevantCloudRecords.filter { $0.recordID.recordName == managedObject["recordName"]! as! String }.first
                        
                        if let cloudRecord = record {
                            cloudRecord.allKeys().forEach {
                                managedObject[$0] = cloudRecord[$0]
                            }
                        }
                    }
                    
                    do {
                        try context.save()
                    } catch let error as NSError {
                        print("SkyData] SDWriteLocalDataOperation: Save failed: \(error.localizedDescription)")
                        
                        writeOperations.forEach {$0.cancel()}
                        self.cancel()
                    }
                }
            }
            
            writeCompletionOperation.addDependency(writeOperation)
            writeOperations.append(writeOperation)
        }
        queue.addOperations(writeOperations + [writeCompletionOperation], waitUntilFinished: false)
    }
    
    func completed() {
        print("[SkyData] Ended SDWriteLocalDataOperation")
        
        self.executing = false
        self.finished = true
    }
    
}
