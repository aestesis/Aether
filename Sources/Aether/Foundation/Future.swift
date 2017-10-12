//
//  Future.swift
//  Alib
//
//  Created by renan jegouzo on 29/03/2016.
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Future : Atom {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum State {
        case inProgress
        case cancel
        case done
        case error
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onDetach=Event<Void>()
    private var _done=Event<Future>()
    private var _cancel=Event<Future>()
    private var _progress=Event<Future>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var state:State = .inProgress
    public private(set) var result:Any?
    public private(set) var progress:Double=0
    public private(set) var context:String?
    public var autodetach = true
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var prop:[String:Any]=[String:Any]()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public subscript(k:String) -> Any? {
        get {
            return prop[k]
        }
        set(v) {
            prop[k]=v
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func then(_ fn:@escaping (Future)->()) {
        let _ = _done.always(fn)
    }
    public func pulse(_ fn:@escaping (Future)->()) {
        let _ = _progress.always(fn)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func cancel()  {
        if state == .inProgress {
            state = .cancel
            _cancel.dispatch(self)
            if autodetach {
                self.detach()
            }
        }
    }
    public func done(_ result:Any?=nil) {
        if state == .inProgress {
            self.result = result
            state = .done
            progress = 1
            _progress.dispatch(self)
            _done.dispatch(self)
            if autodetach {
                self.detach()
            }
        }
    }
    public func error(_ error:Error,_ f:String=#file,_ l:Int=#line) {
        if state == .inProgress {
            self.result=Error(error,f,l)
            state = .error
            _done.dispatch(self)
            if autodetach {
                self.detach()
            }
        }
    }
    public func error(_ reason:String,_ f:String=#file,_ l:Int=#line) {
        error(Error(reason,f,l))
    }
    public func progress(_ value:Double) {
        if state == .inProgress {
            progress = value
            _progress.dispatch(self)
        }
    }
    public func onCancel(_ fn:@escaping (Future)->()) {
        let _ = _cancel.always(fn)
    }
    /*
     // TODO: leaking, must think about unpipe
    public func pipe(to:Future) {
        self.then { f in
            switch f.state {
            case .done:
                to.done(f.result)
            case .error:
                let e = f.result as! Error
                to.error(e)
            default:
                Debug.error("strange behavior",#file,#line)
                break
            }
        }
        self.pulse { f in
            to.progress(f.progress)
        }
        to.onCancel { f in
            self.cancel()
        }
    }
     */
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if DEBUG
    private let function:String
    private let file:String
    private let line:Int
    public override var debugDescription: String {
        return "Future.init(file:\(file),line:\(line),function:\(function))"
    }
    #endif
    public init(context:String?=nil,file:String=#file,line:Int=#line,function:String=#function) {
        #if DEBUG
        self.file = file
        self.line = line
        self.function = function
        #endif
        self.context=context
        super.init()
    }
    public func detach() {
        onDetach.dispatch(())
        onDetach.removeAll()
        _done.removeAll()
        _cancel.removeAll()
        _progress.removeAll()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Job : Future {
    public let priority: Priority
    public private(set) var action:(()->())?
    public private(set) var owner : Node
    public let info:String
    public enum Priority : Int {
        case high=0x0100
        case normal=0x0200
        case low=0x0300
    }
    public init(owner: Node, priority:Priority=Priority.normal, info:String="", action:@escaping ()->()) {
        self.owner=owner
        self.info=info
        self.action=action
        self.priority=priority
        super.init()
    }
    public override func detach() {
        action = nil
        super.detach()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Worker : NodeUI {
    public var paused:Bool=false
    var running=[Node:Int]()
    var jobs=[Job]()
    let lock=Lock()
    var release:Bool=false
    var threads:Int=0
    public func debugInfo() {
        for k in running.keys {
            if running[k]!>5 {
                Debug.info("running \(k.className)  \(running[k]!)")
            }
        }
    }
    public var count:Int {
        var c=0
        self.lock.synced {
            c = self.jobs.count
        }
        return c
    }
    public func stop() {
        var jl:[Job]?
        release=true
        self.lock.synced {
            jl = self.jobs
            self.jobs.removeAll()
        }
        for j in jl! {
            j.cancel()
        }
        var wait = true
        let w = self.wait(1) { 
            Debug.error("one thread takes too long, stop waiting...",#file,#line)
            wait = false
        }
        while threads>0 && wait {
            Thread.sleep(0.01)
        }
        if wait {
            w.cancel()
        }
    }
    public func cancel(_ owner:NodeUI) {
        var cancel=[Job]()
        lock.synced {
            self.jobs = self.jobs.filter({ (j) -> Bool in
                if j.owner == owner {
                    cancel.append(j)
                    return false
                }
                return true
            })
        }
        for j in cancel {
            j.cancel()
            j.detach()
        }
    }
    public func run(_ owner:NodeUI,priority:Job.Priority=Job.Priority.normal,info:String="",action:@escaping ()->()) -> Job {
        let j=Job(owner:owner,priority:priority,info:info,action:action)
        if release {
            Debug.error("returning fake job",#file,#line)
            return j    // returns fake job
        }
        lock.synced {
            self.jobs.append(j)
            self.jobs.sort(by: { (a, b) -> Bool in
                return a.priority.rawValue < b.priority.rawValue
            })
        }
        j.onCancel { (p) in
            self.lock.synced {
                self.jobs=self.jobs.filter({ (ij) -> Bool in
                    return ij != j
                })
            }
        }
        return j
    }
    public init(parent:NodeUI,threads:Int=1) {
        super.init(parent:parent)
        for _ in 1...threads {
            let _=Thread {
                self.threads += 1
                while !self.release {
                    if !self.paused {
                        var j:Job?=nil
                        self.lock.synced {
                            j=self.jobs.dequeue()
                            if let j=j {
                                if let r=self.running[j.owner] {
                                    self.running[j.owner] = r+1
                                } else {
                                    self.running[j.owner] = 1
                                }
                            }
                        }
                        if let j=j {
                            let owner = j.owner
                            if !self.release {
                                autoreleasepool {
                                    j.done(j.action!())
                                }
                            }
                            self.lock.synced {
                                if let r=self.running[owner] {
                                    self.running[owner] = r-1
                                }
                            }
                            j.detach()
                        } else {
                            Thread.sleep(0.001)
                        }
                    } else {
                        Thread.sleep(0.01)
                    }
                }
                self.threads -= 1
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Error : Atom, Swift.Error {
    public let message:String
    public let file:String
    public let line:Int
    public private(set) var origin:Error?
    public override var description: String {
        return "{ error:\"\(message)\" file:\"\(Debug.truncfile(file))\" line:\(line) }"
    }
    public init(_ message:String,_ file:String=#file,_ line:Int=#line) {
        self.message=message
        self.file=file
        self.line=line
        super.init()
    }
    public init(_ error:Error,_ file:String=#file,_ line:Int=#line) {
        self.origin=error
        self.message=error.message
        self.file=file
        self.line=line
        super.init()
    }
    public func get<T>() -> T? {
        if let v = self as? T {
            return v
        }
        if let s = self.origin {
            let v:T? = s.get()
            return v
        }
        return nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
#if os(Linux)   // https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20161031/003823.html
func autoreleasepool(fn:()->()) {
    fn()
}
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
