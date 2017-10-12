//
//  Thread.swift
//  Alib
//
//  Created by renan jegouzo on 03/03/2016.
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

public class Thread : Atom {
    var nst:Foundation.Thread?
    init(nst:Foundation.Thread) {
        self.nst=nst
    }
    static var current:Thread {
        if let t=Foundation.Thread.current.threadDictionary["aestesis.alib.Thread"] as? Thread {
            return t;
        }
        let t=Thread(nst:Foundation.Thread.current)
        Foundation.Thread.current.threadDictionary["aestesis.alib.Thread"]=t
        return t
    }
    var dictionary=[String:Any]()
    subscript(key: String) -> Any? {
        get { return dictionary[key] }
        set(v) { dictionary[key]=v }
    }
    public static func sleep(_ seconds:Double) {
        Foundation.Thread.sleep(forTimeInterval: TimeInterval(seconds))
    }
    public static var callstack : [String] {
        return Foundation.Thread.callStackSymbols
    }
    @objc func darun(_ obj:AnyObject?) {
        if let a=obj as? Action<Void> {
            a.invoke(())
        }
    }
    public init(_ fn:@escaping ()->()) {
        super.init()
        
        nst=Foundation.Thread(target:self, selector: #selector(darun), object:Action<Void>(fn))
        nst!.start()
    }
    public func cancel() {
        if let t=nst, !t.isCancelled {
            t.cancel()
        }
    }
    public var cancelled : Bool {
        if let t=nst {
            return t.isCancelled
        }
        return true
    }
    #if os(macOS) || os(iOS) || os(tvOS)
        public var priority : Double {
            get { return nst!.threadPriority }
            set(p) { nst!.threadPriority = p }
        }
    #else
        public var priority : Double = 0.0
    #endif
}
