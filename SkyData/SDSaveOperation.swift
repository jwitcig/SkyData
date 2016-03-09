//
//  SDSaveOperation.swift
//  SkyData
//
//  Created by Developer on 3/8/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreData

public struct SDSaveOperation: SDOperation, SDModifyOperation {
    
    public var operationStart = NSDate()
    public var operationEnd: NSDate?

    public var objectsToSave: [NSManagedObject]
    
    init(objectsToSave: [NSManagedObject]) {
        
        self.objectsToSave = objectsToSave
        
    }
}