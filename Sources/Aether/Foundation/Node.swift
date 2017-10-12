//
//  Node.swift
//  Alib
//
//  Created by renan jegouzo on 22/02/2016.
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
#if os(Linux)
import Dispatch
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Hash : Hashable {
    public var hashValue: Int  {
        return ObjectIdentifier(self).hashValue
    }
}
public func ==(lhs: Hash, rhs: Hash) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Atom: Hash,CustomStringConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var description : String {
        let m=Swift.Mirror(reflecting: self)
        let name=String(describing:m.subjectType)
        return "{ class:\(name) }"
    }
    #if DEBUG
    var dbgdesc:String? = nil
    public var debugDescription : String {
        if let dd = dbgdesc {
            return dd
        } else {
            let dd = self.className+".init():\r\n"+Thread.callstack.joined(separator:"\r\n")
            dbgdesc = dd
            return dd
        }
    }
    #endif
    public var className : String {
        let m=Swift.Mirror(reflecting: self)
        return String(describing:m.subjectType)
    }
    public func wait(_ duration:Double, _ fn:(()->())? = nil) -> Future {
        return Atom.wait(duration,fn)
    }
    public static func wait(_ duration:Double, _ fn:(()->())? = nil) -> Future {
        let fut=Future()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(duration*Double(Misc.clocksPerSeconds))) / Double(Misc.clocksPerSeconds), execute: {
            fut.done()
        })
        if let fn = fn {
            fut.then { f in
                fn()
            }
        }
        return fut
    }
    public func main(fn:@escaping ()->()) {
        DispatchQueue.main.async {
            fn()
        }
    }
    public static func main(fn:@escaping ()->()) {
        DispatchQueue.main.async {
            fn()
        }
    }
    public func pulse(_ period:Double,_ tick:@escaping ()->()) -> Future {
        let fut=Future()
        wait(0).then { f in
            let t = Timer(period:period,tick:tick)
            fut["timer"]=t
            fut.onCancel { (p) in
                t.stop()
                fut["timer"]=nil
            }
        }
        return fut
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if DEBUG
    private static var inspect:[String]=[]   // ex: "Bitmap" "Future"
    private static let lock=Lock()
    private static var dbg=[String:Int]()
    private static var log=[String:Int]()
    #endif
    public static func debugInfo() {
        #if DEBUG
            let keys = Array(dbg.keys).sorted()
            for k in keys {
                Debug.info("\(k) ... \(dbg[k]!)")
            }
            var log=[(count:Int,message:String)]()
            for d in Atom.log {
                if d.1 > 10 {
                    log.append((count:d.1,message:d.0))
                }
            }
            log.sort(by: { (a, b) -> Bool in
                return a.count > b.count
            })
            for l in log {
                Debug.info("\(l.count) -> \(l.message)")
            }
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override init() {
        super.init()
        #if DEBUG
            Atom.lock.synced {
                if let c = Atom.dbg[self.className] {
                    Atom.dbg[self.className] = c+1
                } else {
                    Atom.dbg[self.className] = 1
                }
            }
            if Atom.inspect.contains(self.className) {
                let dbg = self.debugDescription
                if let n = Atom.log[dbg] {
                    Atom.log[dbg] = n + 1
                } else {
                    Atom.log[dbg] = 1
                }
            }
        #endif
        
    }
    deinit {
        #if DEBUG
            Atom.lock.synced {
                if let c = Atom.dbg[self.className] {
                    Atom.dbg[self.className] = c-1
                }
                if Atom.inspect.contains(self.className) {
                    let dbg = self.debugDescription
                    if let l = Atom.log[dbg] {
                        let n = l - 1
                        if n == 0 {
                            Atom.log.removeValue(forKey:dbg)
                        } else {
                            Atom.log[dbg] = n
                        }
                    } else {
                        //Debug.error("error")
                    }
                }
            }
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Classes {
    var keys=[String]()
    public func append(key:String) {
        if(!keys.contains(key)) {
            keys.append(key)
        }
    }
    public func append(keys:[String]) {
        for k in keys {
            self.append(key:k)
        }
    }
    public func append(classes:Classes) {
        self.append(keys: classes.keys)
    }
    public func remove(key:String) {
        if let i=keys.index(of: key) {
            keys.remove(at: i)
        }
    }
    public func remove(keys:[String]) {
        for k in keys {
            self.remove(key:k)
        }
    }
    public func remove(classes:Classes) {
        self.remove(keys: classes.keys);
    }
    public func contains(key:String) -> Bool {
        return keys.contains(key)
    }
    public func contains(keys:[String]) -> Bool {
        for k in keys {
            if !keys.contains(k) {
                return false
            }
        }
        return true
    }
    public func contains(classes:Classes) -> Bool {
        return self.contains(keys:classes.keys)
    }
    public init() {
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Node:Atom
{
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onDetach=Event<Void>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var prop:[String:Any]=[String:Any]()
    public private(set) var classes=Classes()
    public var parent: Node?
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent: Node?) {
        super.init()
        self.parent=parent
        
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var attached : Bool {
        return self.parent != nil
    }
    public func detach() {
        onDetach.dispatch(())
        onDetach.removeAll()
        self.parent = nil
        for p in prop.values {
            if let p=p as? Node, p != self && p.parent != nil  {
                p.detach()
            }
        }
        prop.removeAll()
    }
    deinit {
        if self.parent != nil {
            self.detach()
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func ancestor<T>() -> T? {
        if let s = self.parent {
            if let v=s as? T {
                return v
            } else {
                let v:T? = s.ancestor()
                return v
            }
        }
        return nil
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public subscript(k:String) -> Any? {
        get {
            if let v=prop[k] {
                if let p = v as? Property {
                    return p.value
                }
                return v
            }
            if let p=parent {
                return p[k]
            }
            return nil
        }
        set(v) {
            if let p=prop[k] as? Node {
                if let p = p as? Property {
                    p.value = v
                    return
                } else if let pv = v as? Node {
                    if pv != p {
                        p.detach()
                    }
                } else {
                    p.detach()
                }
            }
            prop[k]=v
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Property : Node {
    public let onGetValue=Event<Any?>()
    var _value:Any?
    public var value : Any? {
        get {
            onGetValue.dispatch(_value)
            return _value
        }
        set(v) {
            if let p = _value as? Node {
                p.detach()
            }
            _value = v
        }
    }
    public init() {
        self._value = nil
        super.init(parent:nil)
    }
    public init(value:Any) {
        self._value = value
        super.init(parent:nil)
    }
    override public func detach() {
        if let p = self.value as? Node {
            p.detach()
        }
        super.detach()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class NodeUI : Node {
    public var viewport:Viewport? {
        if let v=self as? Viewport {
            return v
        } else if let p=parent as? NodeUI {
            return p.viewport
        }
        return nil
    }
    public override var attached : Bool {
        return self.viewport != nil
    }
    public func animate(_ duration:Double,_ anime:@escaping (Double)->()) -> Future {
        let fut=Future(context:"animation")
        let start=ß.time
        if let vp=viewport {
            var a : Action<Void>? = nil
            a = vp.pulse.always {
                let t=(ß.time-start)/duration
                if t<1 {
                    anime(t)
                    fut.progress(t)
                } else {
                    vp.pulse.remove(a!)
                    anime(1)
                    fut.done()
                    a = nil
                }
            }
            fut.onCancel { p in
                vp.pulse.remove(a!)
                a = nil
            }
        }
        return fut
    }
    public override func wait(_ duration:Double,_ fn:(()->())? = nil) -> Future {
        let fut=Future(context:"wait")
        if duration == 0 {
            self.ui {
                fut.done()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(duration*Double(ß.clocksPerSeconds))) / Double(ß.clocksPerSeconds), execute: {
                if self.attached {
                    self.ui {
                        fut.done()
                    }
                } else {
                    fut.detach()
                }
            })
        }
        if let fn=fn {
            fut.then { f in
                fn()
            }
        }
        return fut
    }
    public func ui(_ fn:@escaping ()->()) {
        if let vp=viewport {
            vp.pulse.once {
                if self.attached {
                    fn()
                }
            }
        }
    }
    public func sui(_ fn:@escaping ()->()) {
        if let isui = Alib.Thread.current["ui.thread"] as? Bool {
            if isui {
                fn()
            } else {
                self.ui(fn)
            }
        }
    }
    public func urgent(_ info:String="",_ fn:@escaping ()->()) {
        if let vp=viewport {
            let _ = vp.bg.run(self,priority:Job.Priority.high,info:info,action:fn)
        }
    }
    public func bg(_ info:String="",_ fn:@escaping ()->()) {
        if let vp=viewport {
            let _ = vp.bg.run(self,info:info,action:fn)
        }
    }
    public func io(_ info:String="",_ fn:@escaping ()->()) {
        if let vp=viewport {
            let _ = vp.io.run(self,info:info,action:fn)
        }
    }
    public func zz(_ info:String="",_ fn:@escaping ()->()) {
        if let vp=viewport {
            let _ = vp.zz.run(self,info:info,action:fn)
        }
    }
    public init(parent:NodeUI?) {
        super.init(parent:parent)
    }
    open override func detach() {
        let viewport = self.viewport
        super.detach()
        if let viewport = viewport, viewport != self {
            viewport.clean(self)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Action<T> : Hash {
    let fn:((T)->())?
    public func invoke(_ p:T) {
        fn?(p);
    }
    public init(_ fn:@escaping ((T)->()))  {
        self.fn = fn
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class MultiEvent<T> {
    private var actions = [String:Set<Action<T>>]()
    private var onces = [String:Set<Action<T>>]()
    public func always(_ message:String,action:@escaping (T)->()) {
        if actions[message] != nil {
            actions[message]!.insert(Action<T>(action))
        } else {
            actions[message]=Set<Action<T>>()
            actions[message]!.insert(Action<T>(action))
        }
    }
    public func once(_ message:String,action:@escaping (T)->()) {
        if onces[message] != nil {
            actions[message]!.insert(Action<T>(action))
        } else {
            onces[message]=Set<Action<T>>()
            onces[message]!.insert(Action<T>(action))
        }
    }
    public func alive(_ owner:NodeUI,message:String,action:@escaping (T)->()) {
        let a=Action<T>(action)
        if actions[message] != nil {
            actions[message]!.insert(a)
        } else {
            actions[message]=Set<Action<T>>()
            actions[message]!.insert(a)
        }
        owner.onDetach.once({
            self.actions[message]!.remove(a)
        })
    }
    public func dispatch(_ message:String,_ p:T) {
        if let ac=actions[message]  {
            for a in ac {
                a.invoke(p);
            }
        }
        if let o=onces[message] {
            onces[message]=Set<Action<T>>()
            for a in o {
                a.invoke(p)
            }
        }
    }
    public init() {
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Event<T> {
    private var actions = Set<Action<T>>()
    private var onces = Set<Action<T>>()
    private let lock=Lock()
    public func Event() {
    }
    public func always(_ action: @escaping (T)->()) -> Action<T> {
        let a=Action<T>(action)
        lock.synced {
            self.actions.insert(a)
        }
        return a
    }
    public func once(_ action: @escaping (T)->()) {
        lock.synced {
            self.onces.insert(Action<T>(action))
        }
    }
    public func alive(_ owner: Node, _ action: @escaping (T)->()) {
        let a=Action<T>(action)
        lock.synced { 
            self.actions.insert(a);
        }
        owner.onDetach.once {
            self.actions.remove(a)
        }
    }
    public var count:Int {
        return actions.count+onces.count
    }
    public func dispatch(_ p:T)
    {
        var ac:Set<Action<T>>?
        var o:Set<Action<T>>?
        lock.synced {
            ac = self.actions
            o = self.onces
            self.onces.removeAll()
        }
        for a in ac! {
            a.invoke(p);
        }
        for a in o! {
            a.invoke(p)
        }
    }
    public func remove(_ action:Action<T>) {
        lock.synced { 
            self.actions.remove(action)
        }
    }
    public func removeAll() {
        lock.synced {
            self.actions.removeAll()
            self.onces.removeAll()
        }
    }
    public init() {
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Lock {
    public func synced(_ execute: () -> ()) {
        objc_sync_enter(self)
        execute()
        objc_sync_exit(self)
    }
    public init() {
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Timer : NSObject {
    var timer:Foundation.Timer?
    let tick:()->()
    init(period:Double,tick:@escaping ()->()) {
        self.tick=tick
        super.init()
        timer = Foundation.Timer.scheduledTimer(timeInterval: period, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    @objc func update() {
        tick()
    }
    func stop() {
        if let t=timer {
            t.invalidate()
        }
        timer=nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
