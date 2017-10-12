//
//  Web.swift
//  Alib
//
//  Created by renan jegouzo on 30/03/2016.
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
public struct URL {
    // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURL_Class/
    var nsurl:Foundation.URL?
    public var scheme:String? {
        if let nu=nsurl {
            return nu.scheme
        }
        return nil
    }
    public var user:String? {
        if let nu=nsurl {
            return nu.user
        }
        return nil
    }
    public var password:String? {
        if let nu=nsurl {
            return nu.password
        }
        return nil
    }
    public var host:String? {
        if let nu=nsurl {
            return nu.host
        }
        return nil
    }
    public var port:Int? {
        if let nu=nsurl {
            if let p=(nu as NSURL).port {
                return Int(truncating:p)
            }
        }
        return nil
    }
    public var path:String {
        if let nu=nsurl {
            return nu.path
        }
        return ""
    }
    public var pathAndQuery:String? {
        if let nu=nsurl {
            var r=""
            r += nu.path
            if let q=nu.query {
                r += "?"+q
            }
            return r
        }
        return nil
    }
    public var query:String? {
        if let nu=nsurl {
            return nu.query
        }
        return nil
    }
    public var absolute:String? {
        if let nu=nsurl {
            return nu.absoluteString
        }
        return nil
    }
    public init?(string:String) {
        nsurl=Foundation.URL(string: string)
        if nsurl == nil {
            return nil
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Socket : Stream {
    // https://gist.github.com/kvannotten/57ddd5531c228e7e08c6
    let lock=Lock()
    var sread:InputStream?
    var swrite:OutputStream?
    var release=false
    var rBuffer=[UInt8]()
    var handles=[Handle]()
    #if DEBUG
    var host:String
    var file:String
    var line:Int
    #endif
    public override var available:Int {
        return rBuffer.count
    }
    #if DEBUG
    public override var debugDescription:String {
        return "Socket.init(host:\"\(host)\",file:\"\(file)\",line:\(line))"
    }
    #endif
    public init(host:String,port:Int,timeout:Double=5,file:String=#file,line:Int=#line) {
        //Debug.warning("open socket \(host):\(port)",#file,#line)
        #if DEBUG
            self.host = host
            self.file = file
            self.line = line
        #endif
        var readStream : Unmanaged<CFReadStream>?
        var writeStream : Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,host as CFString!,UInt32(port),&readStream,&writeStream)
        sread=readStream!.takeRetainedValue()
        swrite=writeStream!.takeRetainedValue()
        super.init(timeout:timeout)
        CFReadStreamScheduleWithRunLoop(sread,CFRunLoopGetMain(),CFRunLoopMode.commonModes)
        CFWriteStreamScheduleWithRunLoop(swrite,CFRunLoopGetMain(),CFRunLoopMode.commonModes)
        var connected=false
        var errsock = false
        let wdel=Handle({ (event:Foundation.Stream.Event) in
            if ß.hasFlag(event.rawValue,Foundation.Stream.Event.openCompleted.rawValue) {
                connected=true
                self.onOpen.dispatch(())
            }
            if ß.hasFlag(event.rawValue,Foundation.Stream.Event.hasSpaceAvailable.rawValue) {
                self.onFreespace.dispatch(())
            }
            if ß.hasFlag(event.rawValue,Foundation.Stream.Event.errorOccurred.rawValue) {
                errsock=true
            }
        })
        swrite!.delegate=wdel
        handles.append(wdel)
        var readOk=false
        let rdel=Handle({ (event:Foundation.Stream.Event) in
            if ß.hasFlag(event.rawValue,Foundation.Stream.Event.hasBytesAvailable.rawValue) {
                readOk=true
            }
            if ß.hasFlag(event.rawValue,Foundation.Stream.Event.errorOccurred.rawValue) {
                errsock=true
            }
        })
        sread!.delegate=rdel
        handles.append(rdel)
        sread!.open()
        swrite!.open()
        let _ = Thread {    // TODO: replace by thread pool
            let start=ß.time
            while !self.release && !readOk {
                Thread.sleep(0.05)
                if !connected && (ß.time-start>self.timeout || errsock) {
                    //Debug.error("can't connect \(host):\(port)")
                    self.onError.dispatch(Error("can't connect \(host):\(port)",#file,#line))
                    self.close()
                }
            }
            //Debug.warning("started \(host)")
            while !self.release {
                var buffer=[UInt8](repeating: 0,count: 1024)
                let done=CFReadStreamRead(self.sread,UnsafeMutablePointer(mutating:buffer),buffer.count)
                if done>0 {
                    if done < buffer.count {
                        buffer.removeSubrange(done..<buffer.count)
                    }
                    self.lock.synced {
                        self.rBuffer.append(contentsOf: buffer)
                    }
                    self.onData.dispatch(())
                } else if done==0 && !self.release {     // EOF
                    self.close()
                } else if done<0 && !self.release {      // error
                    self.close()
                    self.onError.dispatch(Error("broken connection",#file,#line))
                }
            }
            //Debug.warning("released \(host)")
        }
    }
    public override func close() {
        super.close()
        if !release {
            release=true
            //Debug.warning("closing socket")
            CFReadStreamUnscheduleFromRunLoop(sread,CFRunLoopGetMain(),CFRunLoopMode.commonModes)
            CFWriteStreamUnscheduleFromRunLoop(swrite,CFRunLoopGetMain(),CFRunLoopMode.commonModes)
            CFReadStreamClose(sread)
            CFWriteStreamClose(swrite)
            handles.removeAll()
        }
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        if available>0 {
            var rb:[UInt8]?
            lock.synced {
                let m=min(self.available,desired)
                rb=Array(self.rBuffer[0..<m])
                self.rBuffer.removeSubrange(0..<m)
            }
            return rb
        }
        return nil
    }
    public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        //Debug.info("CFWriteStreamCanAcceptBytes=\(CFWriteStreamCanAcceptBytes(self.swrite))")
        return CFWriteStreamWrite(self.swrite,UnsafeMutablePointer(mutating:data).advanced(by: offset),data.count)
    }
    class Handle : NSObject, StreamDelegate {
        let fn:(Foundation.Stream.Event)->()
        @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
            //Debug.info("stream event: \(eventCode)")
            fn(eventCode)
        }
        init(_ fn:@escaping (Foundation.Stream.Event)->()) {
            self.fn=fn
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Request : Future {    // TODO: request response stream from http, filesystem??..
    // http://www.tcpipguide.com/free/t_HTTPRequestMessageFormat.htm
    static let session = URLSession(configuration: URLSessionConfiguration.default)
    public let url:URL
    public let method:String
    public let timeOut:Double
    public private(set) var response=Response()
    var client:Socket? = nil
    var request:URLRequest? = nil
    var writer=UTF8Writer()
    var release=false
    public init(url:String,method:String="GET",header:[String:String]?=nil, timeOut:Double=0.5) {
        if let u = URL(string:url) {
            self.url = u
        } else {
            Debug.error("Wrong URL format: \(url)")
            self.url = URL(string:"error://")!
        }
        self.method=method
        self.timeOut=timeOut
        var port=80
        if let p=self.url.port {
            port=Int(p)
        }
        if let host = self.url.host {
            if !url.contains("https:") {
                client=Socket(host:host,port:port)
            }
            if let client=client {
                client.pipe(to: response)
                writer.pipe(to: client)
            } else {
                request = URLRequest(url: self.url.nsurl!)
            }
        }
        super.init(context:url)
        if let client = client {
            var req = [String]()
            var q = "/"
            if let pq=self.url.pathAndQuery {
                if pq.length>0 {
                    q = pq
                }
            }
            req.append(contentsOf: [   "\(method) \(q) HTTP/1.1",
                                       "Date: \(ß.date)",
                                       "Connection: close",
                                       "Host: \(self.url.host!)"
                ])
            if let hl=header {
                for h in Request.appendDefaultHeader(hl) {
                    req.append("\(h.0): \(h.1)")
                }
            }
            req.append(Request.CR)  // empty line
            client.onOpen.once {
                let _=Thread {  // TODO: replace by a network thread/tasks pool
                    let _ = self.writer.write(req.joined(separator: Request.CR))
                }
            }
            client.onError.once { (error) in
                self.error(error)
            }
            self.response.onClose.once {
                self.close()
            }
            self.response.onData.once {
                if self.response.parseHeader() {
                    if self.response.status==200 {
                        self.autodetach = false
                        self.done(self.response)
                    } else if self.response.status >= 302 && self.response.status <= 307 { // redirect  // TODO: protection infinite redirection
                        if let url = self.response.header["location"] ?? self.response.header["Location"] {
                            let r = Request(url:url,method:method,header:header,timeOut:timeOut)
                            r.then { f in
                                self.done(f.result)
                            }
                            self.onCancel { f in
                                r.cancel()
                            }
                        }
                    } else {
                        self.error(Response.ResponseError(self.response.statusMessage,self.response,#file,#line))
                    }
                } else {
                    self.error(Error("Bad http response header",#file,#line))
                }
            }
        } else if let request = request {
            //request.httpMethod = method
            // request.httpBody =
            let task=Request.session.dataTask(with: request, completionHandler: { (data, res, err) in
                if let err=err {
                    self.error(Error(err.localizedDescription,#file,#line))
                } else if let data=data {
                    if data.count>0 {
                        var buf = [UInt8] (repeating:0,count:data.count)
                        data.withUnsafeBytes { (src:UnsafePointer<UInt8>) -> () in
                            for i in 0..<buf.count {    // TODO: copy faster, or avoid copy...
                                buf[i] = src[i]
                            }
                        }
                        let _ = self.response.write(buf,offset:0,count:buf.count)
                    }
                    self.done(self.response)
                    self.close()
                } else {
                    self.error(Error("response without data",#file,#line))
                }
            })
            task.resume()
        } else {
            self.error(Error("wrong URL",#file,#line))
        }
    }
    override public func detach() {
        self.close()
    }
    public func close() {
        release=true
        writer.close()
        response.close()
        if let client = client {
            client.close()
            self.client = nil
        }
        super.detach()
    }
    public static var CR:String {
        return "\r\n"
    }
    static func appendDefaultHeader(_ header:[String:String]) -> [String:String] {
        var h=header
        if h["User-Agent"]==nil {
            h["User-Agent"]="Mozilla/4.0"
        }
        return h
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Response : UTF8Reader {
    // http://www.tcpipguide.com/free/t_HTTPResponseMessageFormat.htm#Figure_318
    public private(set) var status:Int=0
    public private(set) var statusMessage:String=""
    public private(set) var header=[String:String]()
    func parseHeader() -> Bool {
        if let http=readLine() {
            let htp=http.trim().split(" ")
            if htp.count < 3 {
                onError.dispatch(Error("Wrong Http Response, bad format",#file,#line))
                return false
            }
            if let s=Int(htp[1]) {
                status=s
            } else {
                onError.dispatch(Error("Wrong Http Response, bad format",#file,#line))
                return false
            }
            statusMessage=htp[1..<htp.count].joined(separator: " ")
            while let l=readLine() {
                let t=l.trim()
                if t.length==0 {
                    break
                }
                var p=t.split(":")
                if p.count>=2 {
                    header[p[0]]=p[1..<p.count].joined(separator: ":").trim()
                } else {
                    Debug.error("wrong header format, in response: \(l)")
                }
            }
            return true
        }
        return false
    }
    public func readBitmap(_ parent:NodeUI) -> Bitmap? {
        //Debug.info("available: \(available)")
        if let data=read(available) {
            Debug.info("magic: "+String(format:"%2x",data[0])+" "+String(format:"%2x",data[1])+" "+String(format:"%2x",data[2])+" "+String(format:"%2x",data[3]))
            return Bitmap(parent:parent,data:data)
        }
        return nil
    }
    public class ResponseError : Alib.Error {
        public let response:Response
        init(_ message: String, _ response:Response, _ file: String=#file, _ line: Int=#line) {
            self.response=response
            super.init(message,file,line)
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Web  {
    static func parseXML(_ text:String) -> AEXMLDocument? {
        if let a = text.indexOf("<"), let b = text.lastIndexOf(">"), a<b {
            do {
                return try AEXMLDocument(xml:text[a...b])
            } catch {
                return nil
            }
        }
        return nil
    }
    static func parseJSON(_ text:String) -> JSON? {
        var t = text
        let f0 = t.indexOf("[")
        let f1 = t.indexOf("{")
        if let f0=f0, let f1=f1, f1<f0 {
            if let e = t.lastIndexOf("}") {
                t = t[f1...e]
            }
        } else if let f0=f0 {
            if let e = t.lastIndexOf("]") {
                t = t[f0...e]
            }
        } else if let f1=f1 {
            if let e = t.lastIndexOf("}") {
                t = t[f1...e]
            }
        }
        let j = JSON.parse(string: t)
        return (j == JSON.null) ? nil : j
    }
    public static func getText(_ url:String,_ fn:@escaping (Any?)->()) {
        let header=["User-Agent":"Mozilla/5.0 \(Application.name)/\(Application.version) (\(Application.author))"]
        let _ = Request(url:url,header:header).then { (fut) in
            if let res=fut.result as? Response {
                res.onClose.once {
                    if let text=res.readAll() {
                        fn(text)
                    } else {
                        fn(Error("empty response: \(url)"))
                    }
                }
            } else if let err=fut.result as? Alib.Error {
                if let re:Response.ResponseError = err.get() {
                    re.response.onClose.once {
                        if let text=re.response.readAll() {
                            fn(text)
                        } else {
                            fn(Error("empty response: \(url)"))
                        }
                    }
                } else {
                    fn(Error(err))
                }
            }
        }
    }
    public static func getXML(_ url:String,_ fn:@escaping (Any?)->()) {
        let header=["User-Agent":"Mozilla/5.0 \(Application.name)/\(Application.version) (\(Application.author))"]
        let _ = Request(url:url,header:header).then { (fut) in
            if let res=fut.result as? Response {
                res.onClose.once {
                    if let text=res.readAll() {
                        if let xdoc = parseXML(text) {
                            fn(xdoc)
                        } else {
                            fn(Error("bad xml format: \(url)"))
                        }
                    } else {
                        fn(Error("empty response: \(url)"))
                    }
                }
            } else if let err=fut.result as? Alib.Error {
                if let re:Response.ResponseError = err.get() {
                    re.response.onClose.once {
                        if let text=re.response.readAll() {
                            if let xdoc = parseXML(text) {
                                fn(xdoc)
                            } else {
                                fn(Error("bad xml format: \(url)"))
                            }
                        } else {
                            fn(Error("empty response: \(url)"))
                        }
                    }
                } else {
                    fn(Error(err))
                }
            }
        }
    }
    public static func getJSON(_ url:String,_ fn:@escaping (Any?)->()) {
        let header=["User-Agent":"Mozilla/5.0 \(Application.name)/\(Application.version) (\(Application.author))"]
        let _ = Request(url:url,header:header).then { (fut) in
            if let res=fut.result as? Response {
                res.onClose.once {
                    if let text=res.readAll() {
                        if let j = parseJSON(text) {
                            fn(j)
                        } else {
                            fn(Error("bad json format \(url)"))
                        }
                    } else {
                        fn(Error("empty response: \(url)"))
                    }
                }
            } else if let err=fut.result as? Alib.Error {
                if let re:Response.ResponseError = err.get() {
                    re.response.onClose.once {
                        if let text=re.response.readAll() {
                            if let j = parseJSON(text) {
                                fn(j)
                            } else {
                                fn(Error("bad json format \(url)"))
                            }
                        } else {
                            fn(Error("empty response: \(url)"))
                        }
                    }
                } else {
                    fn(Error(err))
                }
            }
        }
    }
    public static func getBitmap(parent:NodeUI, url:String,_ fn:@escaping (Any?)->()) {
        let _ = Request(url:url).then { (fut) in
            if let res=fut.result as? Response {
                res.onClose.once {
                    fn(res.readBitmap(parent))
                }
            } else if let err=fut.result as? Alib.Error {
                fn(err)
            }
        }
    }
    public static func getICE(url:String,header headerfn:(([String:String])->())?=nil,meta:(([String:String])->())?=nil,audio:(([String:String],Stream)->())?=nil,error:((Error)->())?=nil) -> Request {
        let header=["User-Agent":"WinampMPEG/5.09","Icy-MetaData":"1"]
        let r=Request(url:url,header:header)
        let _ = r.then { (fut) in
            if let res=fut.result as? Response {
                if let rmi=res.header["icy-metaint"] {
                    if let mi=Int(rmi) {
                        var co=0
                        let ms=CircularStream(capacity: 65536*2)
                        r.onDetach.once {
                            res.close()
                        }
                        ms.onClose.once {
                            res.close()
                        }
                        if let fn=headerfn {
                            fn(res.header)
                        }
                        if let fn=audio {
                            fn(res.header,ms)
                        }
                        var needed=1
                        let _ = res.onData.always({
                            while true {
                                let na=min(res.available,ms.free)
                                if na<=0 {
                                    break
                                }
                                let n=min(na,mi-co)
                                if n>0 {
                                    if let b=res.read(n) {
                                        co += b.count
                                        let _ = ms.write(b,offset:0,count:b.count)
                                    }
                                }
                                if co == mi  {
                                    if res.available<needed { // wait next call for more data
                                        break
                                    }
                                    if needed == 1 {
                                        if let b=res.read(1) {
                                            needed = Int(b[0])*16
                                        }
                                    }
                                    if needed == 0 {
                                        co = 0
                                        needed = 1
                                    } else if needed > 1 && res.available >= needed {
                                        var metadata=[String:String]()
                                        if let buf=res.read(needed) {
                                            if let mstring=String(bytes:buf,encoding:String.Encoding.utf8) {
                                                for l in mstring.split(";") {
                                                    let ww=l.split("=")
                                                    if ww.count == 2 {
                                                        let k=ww[0].trim()
                                                        let v=ww[1]
                                                        if let b=v.indexOf("'") {
                                                            if let e=v.lastIndexOf("'") {
                                                                if e-b>1 {
                                                                    metadata[k]=v[b+1..<e].trim()
                                                                } else {
                                                                    metadata[k]=""
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if let fn=meta {
                                                    fn(metadata)
                                                }
                                            }
                                        } else {
                                            Debug.error("pataclop!")
                                        }
                                        co = 0
                                        needed = 1
                                    }
                                }
                            }
                        })
                    }
                } else {
                    if let fn=meta {
                        fn(res.header)
                    }
                    if let fn=audio {
                        fn(res.header,res)
                    }
                }
            } else if let err=fut.result as? Alib.Error {
                if let fn=error {
                    fn(Error("\(err.message) url:\(url)"))
                }
            }
        }
        return r
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
