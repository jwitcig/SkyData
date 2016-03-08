//
//  SDSession.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreData

public class SDSession {
    
    public static var currentSession = SDSession()
    
    internal var operationQueue = NSOperationQueue()
    
    var cloudDatabase: CKDatabase?
    
    init(cloudDatabase: CKDatabase? = nil) {
        self.cloudDatabase = cloudDatabase
    }
    
}
