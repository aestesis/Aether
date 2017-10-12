//
//  Cloud.swift
//  Alib
//
//  Created by renan jegouzo on 22/06/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import CloudKit

public class Cloud : Node {
    var db : CKDatabase? = nil
    public var ok : Bool {
        return db != nil
    }
    public let onStatusChanged=Event<Cloud.Status>()
    public func available(_ ok:@escaping ()->(), _ ko:(()->())?=nil) {
        if self.status == .available {
            ok()
        } else if self.status == .unknown {
            self.onStatusChanged.once { st in
                if st == .available {
                    ok()
                } else if let ko=ko {
                    ko()
                }
            }
        } else if let ko=ko {
            ko()
        }
    }
    public func remove(keys:[String]) {
        for k in keys {
            self.remove(k)
        }
    }
    public func remove(_ key:String) {
        let rid = CKRecordID(recordName: key)
        db?.delete(withRecordID: rid, completionHandler: { (rid, error) in
            if let error = error {
                Debug.error(error.localizedDescription,#file,#line)
            } else {
                Debug.error("iCloud: deleted \(key)")
            }
        })
    }
    public func get(_ key:String) -> Future {
        let fut = Future(context: "Cloud.get(\(key))")
        if let db=db {
            let rid = CKRecordID(recordName: key)
            db.fetch(withRecordID: rid, completionHandler: { (record, error) in
                if let error = error {
                    fut.error(error.localizedDescription,#file,#line)
                } else if let record = record {
                    if let value = record["value"] {
                        fut["record"] = record
                        fut.done(String(describing:value))
                    }
                }
            })
        } else {
            Debug.error("no db",#file,#line)
        }
        return fut
    }
    public func set(_ key:String,type:String="keyvalue", value:String) -> Future {
        let fut = Future(context: "Cloud.set(\(key),\(value))")
        if let db=db {
            get(key).then { f in
                var r:CKRecord?
                if let _ = f.result as? Alib.Error {
                    let rid = CKRecordID(recordName: key)
                    r = CKRecord(recordType: type, recordID: rid)
                } else {
                    r = f["record"] as? CKRecord
                }
                r!.setValue(value, forKey: "value")
                db.save(r!, completionHandler: { (record, error) in
                    if let error = error {
                        Debug.error("iCLoud save error, key:\(key) type:\(type) error:\(error.localizedDescription)")
                        fut.error(error.localizedDescription, #file, #line)
                    } else {
                        fut.done()
                    }
                })
            }
        }
        return fut
    }
    public func getJSON(_ key:String) -> Future {
        let fut = Future(context: "Cloud.getJSON(\(key))")
        get(key).then { f in
            if let err = f.result as? Alib.Error {
                fut.error(err, #file, #line)
            } else if let value=f.result as? String {
                fut.done(JSON.parse(string: value))
            }
        }
        return fut
    }
    public func setJSON(_ key:String,type:String="keyvalue",value:JSON) -> Future {
        let fut = Future(context: "Cloud.setJSON(\(key),\(value))")
        if let str = value.rawString() {
            set(key,type:type,value:str).then { f in
                fut.done(f.result)
            }
        } else {
            Debug.error("Cloud.setJSON(key:\(key),type:\(type),...) error, can't convert json to rawString()",#file,#line)
        }
        return fut
    }
    public func fetchAll(type:String="keyvalue") -> Future {
        let fut = Future(context: "Cloud.fetchAll()")
        if let db = db {
            var dict = [String:String]()
            let limit = 50
            let q = CKQuery(recordType:type,predicate:NSPredicate(format:"TRUEPREDICATE"))
            let op = CKQueryOperation(query: q)
            op.database = db
            let fetchedBlock : (CKRecord) -> (Void) = { r in
                let key = r.recordID.recordName
                if let value = r["value"] as? String {
                    dict[key] = value
                }
            }
            var cblock : ((CKQueryCursor?, Swift.Error?) -> Swift.Void)? = nil
            cblock = {  c,err in
                if let c=c {
                    let nop = CKQueryOperation(cursor: c)
                    nop.recordFetchedBlock = fetchedBlock
                    nop.queryCompletionBlock = cblock
                    nop.resultsLimit = limit
                    db.add(nop)
                } else if let err=err {
                    Debug.error(String(describing:err), #file, #line)
                    fut.error(Error(String(describing:err),#file,#line))
                } else {
                    fut.done(dict)
                }
            }
            op.recordFetchedBlock = fetchedBlock
            op.queryCompletionBlock = cblock
            op.resultsLimit = limit
            db.add(op)
        }
        return fut
    }
    public func fetchAllJSON(type:String="keyvalue",predicate:NSPredicate=NSPredicate(format:"TRUEPREDICATE")) -> Future {
        let fut = Future(context: "Cloud.fetchAllJSON()")
        if let db = db {
            var dict = [String:JSON]()
            let limit = 50
            let q = CKQuery(recordType:type,predicate:predicate)
            let op = CKQueryOperation(query: q)
            op.database = db
            let fetchedBlock : (CKRecord) -> (Void) = { r in
                let key = r.recordID.recordName
                //Debug.info("key: \(key)")
                if let value = r["value"] as? String {
                    dict[key] = JSON.parse(string: value)
                }
            }
            var cblock : ((CKQueryCursor?, Swift.Error?) -> Swift.Void)? = nil
            cblock = {  c,err in
                if let c=c {
                    let nop = CKQueryOperation(cursor: c)
                    nop.recordFetchedBlock = fetchedBlock
                    nop.queryCompletionBlock = cblock
                    nop.resultsLimit = limit
                    db.add(nop)
                } else if let err=err {
                    Debug.error(String(describing:err), #file, #line)
                    fut.error(Error(String(describing:err),#file,#line))
                } else {
                    fut.done(JSON(dict))
                }
            }
            op.recordFetchedBlock = fetchedBlock
            op.queryCompletionBlock = cblock
            op.resultsLimit = limit
            db.add(op)
        }
        return fut
    }
    public enum Status {
        case unknown
        case error
        case available
    }
    public private(set) var status:Status = .unknown
    public init(id:String,done:((Error?)->())?=nil) {
        super.init(parent:nil)
        let container = CKContainer(identifier:id)
        container.status(forApplicationPermission: .userDiscoverability) { (status, err) in
            switch status {
            case .granted:
                Debug.info("icloud.userDiscoverability granted")
                break
            case .denied:
                Debug.info("icloud.userDiscoverability denied")
                break
            default:
                Debug.info("icloud.userDiscoverability error")
                break
            }
        }
        container.accountStatus { (status, error) in
            if let error = error {
                Debug.error(error.localizedDescription,#file,#line)
                self.status = .error
                if let done = done {
                    done(Error(error.localizedDescription,#file,#line))
                }
                self.onStatusChanged.dispatch(self.status)
            } else if status == .available {
                self.db = container.privateCloudDatabase
                self.removeSubscriptions {
                    self.status = .available
                    if let done = done {
                        done(nil)
                    }
                    self.onStatusChanged.dispatch(self.status)
                }
            } else if let done = done {
                self.status = .error
                switch status {
                case .couldNotDetermine:
                    done(Error("CKAccountStatus.couldNotDetermine",#file,#line))
                    break
                case .noAccount:
                    done(Error("CKAccountStatus.noAccount",#file,#line))
                    break
                case .restricted:
                    done(Error("CKAccountStatus.restricted",#file,#line))
                    break
                default:
                    break
                }
                self.onStatusChanged.dispatch(self.status)
            }
        }
    }
    override public func detach() {
        self.onStatusChanged.removeAll()
        self.removeSubscriptions {}
    }
    public func subscribeNotification(recordType:String,notification:@escaping (CKQueryNotification)->()) {
        if let db = db {
            let predicate = NSPredicate(format:"TRUEPREDICATE")
            let subsciption = CKQuerySubscription(recordType: recordType, predicate: predicate, options: [.firesOnRecordCreation,.firesOnRecordUpdate,.firesOnRecordDeletion])
            //let subsciption = CKSubscription(recordType: recordType, predicate: predicate, options: [.firesOnRecordCreation,.firesOnRecordUpdate,.firesOnRecordDeletion])
            let info = CKNotificationInfo()
            info.desiredKeys = ["value"]
            info.shouldSendContentAvailable = true
            subsciption.notificationInfo = info
            db.save(subsciption, completionHandler: { (sub, error) in
                if let error = error {
                    Debug.error(error.localizedDescription,#file,#line)
                } else if let sub=sub {
                    Debug.warning("icloud subscription \(sub.subscriptionID) on recordType:\(recordType)",#file,#line)
                    DispatchQueue.main.async {
                        Application.applicationDelegate.onQueryNotification.alive(self) { qnot in
                            notification(qnot)
                        }
                    }
                }
            })
        }
    }
    public func removeSubscriptions(_ done:@escaping ()->()) {
        if let db=db {
            db.fetchAllSubscriptions(completionHandler: { (subs, error) in
                if let error=error {
                    Debug.error(error.localizedDescription,#file,#line)
                    done()
                } else if let subs=subs {
                    if subs.count>0 {
                        var n = subs.count
                        for s in subs {
                            db.delete(withSubscriptionID: s.subscriptionID, completionHandler: { (str, error) in
                                if let str = str {
                                    Debug.warning("delete iCloud subscription \(str)",#file,#line)
                                }
                                n -= 1
                                if n==0 {
                                    done()
                                }
                            })
                        }
                    } else {
                        done()
                    }
                }
            })
        }
    }
}
