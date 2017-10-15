//
//  Debug.swift
//  Aether
//
//  Created by renan jegouzo on 01/03/2016.
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


public class Debug {
    public static var codeRoot = "/aestesis-swift/"
    static func log(_ t:String) {
        #if os(iOS) || os(tvOS) || os(macOS)
            NSLog("%@ %@","\(Application.name):",t)
        #else
            NSLog("\(Application.name): \(t)")
        #endif
    }
    static func truncfile(_ f:String) -> String {
        if var n=f.lastIndexOf(codeRoot) {
            n += codeRoot.length
            return f[n..<f.length]
        }
        return f
    }
    public static func info(_ t:String,_ f:String=#file,_ l:Int=#line) {
        #if DEBUG
            log("🗯 \(t)  \(truncfile(f)):\(l)")
        #endif
    }
    public static func warning(_ t:String,_ f:String=#file,_ l:Int=#line) {
        log("⚡️ \(t)  \(truncfile(f)):\(l)")
    }
    public static func error(_ t:String,_ f:String=#file,_ l:Int=#line) {
        log("❗️ \(t)  \(truncfile(f)):\(l)")
    }
    public static func error(_ e:Error,_ f:String=#file,_ l:Int=#line) {
        error(e.description,f,l)
    }
    public static func assert(_ b:Bool) {
        if !b {
            print("assert");
        }
    }
    public static func notImplemented(_ f:String=#file,_ l:Int=#line) {
        log("💔 *** Not Implemented *** \(f):\(l)")
    }
    public static func profile(_ message:String,_ fn:()->()) {
        let t=ß.time
        fn()
        Debug.info("\(message) in \((ß.time-t).string(3))")
    }
}


