//
//  SDCloudSaveOperation.swift
//  SkyData
//
//  Created by Developer on 3/7/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit

public class SDCloudModifyOperation: CKModifyRecordsOperation, SDCloudOperation, SDModifyOperation {

    public var operationStart = NSDate()
    public var operationEnd: NSDate?
    
    public var completionHandler: SDCompletionHandlerModifyRecords?
    
    init(recordsToSave: [CKRecord]? = nil, recordsIDsToDelete: [CKRecordID]? = nil) {
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordsIDsToDelete
    }
    
    override public func start() {
        let currentSession = SDSession.currentSession
        
        modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
           self.operationEnd = NSDate()
            
            var operationResponse = SDOperationResponse(operation: self)
            operationResponse.error = error
            
            self.completionHandler?(savedRecords: savedRecords ?? [], deletedRecordsIDs: deletedRecordsIDs ?? [], operationResponse: operationResponse)
            
        }
    }
    
    

}
