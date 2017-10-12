//
//  Library.swift
//  Alib
//
//  Created by renan jegouzo on 25/04/2016.
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
import SystemConfiguration

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Library : NodeUI {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var keepCount:Int = 100
    public var tryMax:Int = 5
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var servers:[String]
    var server:String {
        if servers.count == 1 {
            return servers[0]
        }
        return servers[Int(floor(ß.rnd*Double(servers.count)*0.99999))]
    }
    var images = [String:Image]()
    var urls=Set<String>()
    var downloads=Set<Future>()
    var release=false
    let lock=Lock() 
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func bitmap(_ url:String) -> Bitmap? {
        var b:Bitmap?=nil
        lock.synced {
            if let i=self.images[url] {
                b=i.bitmap
            } else {
                self.images[url]=Image(library:self,url:url)
            }
        }
        return b
    }
    func download(_ url:String) -> Future {
        let fut=Future(context:"download")
        fut["url"]=url
        lock.synced { 
            if !self.urls.contains(url) {
                self.urls.insert(url)
            }
            self.downloads.insert(fut)
        }
        return fut
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func run() {
        // cleaner //
        let _ = Thread {
            while !self.release {
                self.lock.synced {
                    if self.images.count > self.keepCount {
                        let l=self.images
                        let a=self.images.values
                        var b=a.sorted(by: { (a, b) -> Bool in
                            return a.lastAccess>b.lastAccess
                        })
                        for i in self.keepCount..<l.count {
                            self.images.removeValue(forKey: b[i].url)
                            b[i].detach()
                        }
                    }
                }
                Thread.sleep(1)
            }
        }
        // downloader //
        let _ = Thread {
            var insrv=false
            while !self.release {
                if !insrv && self.urls.count>0 {
                    let fm=FileManager.default
                    insrv=true
                    let url:String=self.urls.first!
                    let filename=Application.localPath("library/"+url)
                    let dir=NSString(string:filename).deletingLastPathComponent
                    if !fm.fileExists(atPath: dir) {
                        do {
                            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            Debug.error("error, Library.DownloadManager()")
                        }
                    }
                    if fm.fileExists(atPath: filename) {
                        Debug.error("error, Library.DownloadManager()")
                    }
                    var ntries=0
                    var next:((Future)->())?=nil
                    next={ f in
                        if let res=f.result as? Response {
                            res.onClose.once {
                                insrv=false
                                self.lock.synced{
                                    self.urls.remove(url)
                                    let d=self.downloads
                                    for f in d {
                                        if (f["url"] as! String)==url {
                                            self.downloads.remove(f)
                                            self.bg {
                                                f.done()
                                            }
                                        }
                                    }
                                }
                            }
                            let writer=FileWriter(filename:filename,error: { err in
                                Debug.error(Error(err,#file,#line))
                            })
                            res.pipe(to: writer)
                        } else {
                            Debug.error("error downloading asset \(url)  #try: \(ntries)")
                            if ntries<self.tryMax {
                                Thread.sleep(0.1)
                                let _ = Request(url:"\(self.server)\(url)").then(next!)
                                ntries += 1
                            } else {
                                Debug.error("too many tries, aborting.. \(url)")
                                insrv=false
                                self.lock.synced{
                                    self.urls.remove(url)
                                    let d=self.downloads
                                    for f in d {
                                        if (f["url"] as! String)==url {
                                            self.downloads.remove(f)
                                            f.error(Error("too manies tries Library.download(\(url))",#file,#line))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Request(url:"\(self.server)\(url)").then(next!)
                }
                Thread.sleep(0.1)
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent:NodeUI,server:String) {
        self.servers=[server]
        super.init(parent:parent)
        run()
    }
    public init(parent:NodeUI,servers:[String]) {
        self.servers=servers
        super.init(parent:parent)
        run()
    }
    public override func detach() {
        release=true
        keepCount=0
        self.lock.synced {
            for b in self.images.values {
                b.detach()
            }
            self.images.removeAll()
        }
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class Image : NodeUI {
        let url:String
        var bitmap:Bitmap?=nil
        var lastAccess=ß.time
        func load(_ path:String) {
            bitmap=Bitmap(parent:self,path:path)
            lastAccess=ß.time
        }
        override func detach() {
            if let b=bitmap {
                b.detach()
                bitmap=nil
            }
            super.detach()
        }
        init(library:Library,url:String) {
            self.url=url
            super.init(parent:library)
            let path=Application.localPath("library/\(url)")
            if Application.fileExists(path) {
                load(path)
            } else {
                library.download(url).then { fut in
                    if let err = fut.result as? Alib.Error {
                        Debug.error(err,#file,#line)
                    } else {
                        self.load(path)
                    }
                }
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class CheckNet : Atom {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum State {
        case unknown
        case disconnected
        case connected
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onUpdate=Event<State>()
    public let onChanged=Event<State>()
    public let onConnected=Event<Void>()
    public let onDisconnected=Event<Void>()
    public private(set) var state=State.unknown
    public private(set) var lastDispatch=State.unknown
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    let url:String
    var release=false
    var count:Int=0
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(url:String="http://google.com/") {
        self.url=url
        super.init()
        let _=Thread {
            var req:Request?
            while !self.release {
                if let r = req {
                    r.cancel()
                    req = nil
                    self.set(.disconnected)
                } else {
                    req = Request(url: url)
                    req!.then { fut in
                        if let _ = fut.result as? Alib.Error {
                            self.set(.disconnected)
                        } else {
                            self.set(.connected)
                        }
                        req=nil
                    }
                }
                Thread.sleep(5)
            }
        }
    }
    deinit {
        stop()
    }
    func stop() {
        release=true
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func set(_ st:State) {
        onUpdate.dispatch(st)
        let dispatch = {
            if self.lastDispatch != self.state {
                self.lastDispatch = self.state
                Debug.warning("network status changed: \(self.state)")
                self.onChanged.dispatch(self.state)
                if self.state == .connected {
                    self.onConnected.dispatch(())
                } else {
                    self.onDisconnected.dispatch(())
                }
            }
        }
        if state != st {
            state = st
            count = 1
            if st != .disconnected {
                dispatch()
            }
        } else {
            count += 1
            if count == 2 && st == .disconnected {
                dispatch()
            }
        }
    }
    public static func publicIP(_ fn:@escaping (String?)->()) {
        Request(url:"http://checkip.dyndns.org/").then { fut in
            if let res=fut.result as? Response {
                res.onClose.once {
                    if let text=res.readAll() {
                        if let first = text.indexOf("Address: ") {
                            if let last = text.indexOf("</body>") {
                                fn(text[first+9..<last])
                            } else {
                                fn(nil)
                            }
                        }
                    }
                }
            } else if let err=fut.result as? Alib.Error {
                Debug.error(err)
                fn(nil)
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



