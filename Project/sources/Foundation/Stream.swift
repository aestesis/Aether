//
//  Stream.swift
//  Alib
//
//  Created by renan jegouzo on 31/03/2016.
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
#if os(macOS) || os(iOS) || os(tvOS)
    import Darwin
#else
    import Glibc
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public protocol StreamControl {
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Stream : Atom {
    public let onOpen=Event<Void>()
    public let onData=Event<Void>()
    public let onFreespace=Event<Void>()
    public let onClose=Event<Void>()
    public let onError=Event<Error>()
    public private(set) var timeout:Double=5
    var pipes = [Stream : (data:Action<Void>,free:Action<Void>,error:Action<Error>)]()
    public var available:Int {
        Debug.notImplemented()
        return 0
    }
    public var free:Int {
        return Int.max
    }
    public var availableControl:Int {
        return 0
    }
    public var freeControl:Int {
        return Int.max
    }
    public func close() {
        onClose.dispatch(())
        for p in pipes.keys {
            unpipe(p)
            p.close()
        }
        pipes.removeAll()
        onOpen.removeAll()
        onData.removeAll()
        onFreespace.removeAll()
        onClose.removeAll()
        onError.removeAll()
    }
    public func flush() {
        if available>0 {
            onData.dispatch(())
        }
    }
    public func pipe(to:Stream,pipeError:Bool=false) {
        let update = {
            let mb=min(to.free,self.available)
            if mb > 0 {
                if let b=self.read(mb) {
                    let w = to.write(b,offset:0,count:b.count)
                    if w != b.count {
                        Debug.error(Error("write \(w)/\(b.count)",#file,#line))
                    }
                }
            }
            let mc=min(to.freeControl,self.availableControl)
            if mc > 0 {
                if let b=self.readControl(mc) {
                    let w = to.writeControl(b, offset: 0, count: b.count)
                    if w != b.count {
                        Debug.error(Error("write \(w)/\(b.count)",#file,#line))
                    }
                }
            }
        }
        if pipeError {
            let error = { error in
                to.onError.dispatch(error)
            }
            pipes[to]=(data:onData.always(update),free:to.onFreespace.always(update),error:onError.always(error))
        } else {
            let error : (Error)->() = { error in
                // no piping...
            }
            pipes[to]=(data:onData.always(update),free:to.onFreespace.always(update),error:onError.always(error))
        }
        if available>0 {
            onData.dispatch(())
        }
    }
    public func unpipe(_ to:Stream) {
        if let p = pipes[to] {
            self.onData.remove(p.data)
            to.onFreespace.remove(p.free)
            self.onError.remove(p.error)
            pipes[to]=nil
        }
    }
    public func read(_ desired:Int) -> [UInt8]? {
        Debug.notImplemented()
        return nil
    }
    public func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        Debug.notImplemented()
        return 0
    }
    public func readControl(_ desired:Int) -> [StreamControl]? {
        Debug.notImplemented()
        return nil
    }
    public func writeControl(_ data:[StreamControl],offset:Int,count:Int) -> Int {
        Debug.notImplemented()
        return 0
    }
    init(timeout:Double=5,data:(()->())?=nil,free:(()->())?=nil,error:((Error)->())?=nil) {
        self.timeout=timeout
        if let d=data {
            let _ = onData.always(d)
        }
        if let f=free {
            let _ = onFreespace.always(f)
        }
        if let e=error {
            let _ = onError.always(e)
        }
        super.init()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class CircularStream : Stream {
    private let lock=Lock()
    var buffer:[UInt8]
    var ro:Int=0
    var wo:Int=0
    public override var available:Int {
        return (ro<=wo) ? (wo-ro) : (buffer.count-(ro-wo))
    }
    public override var free:Int {
        return buffer.count - available
    }
    public override func write(_ data:[UInt8],offset o:Int,count c:Int) -> Int {
        var ret:Int=0
        lock.synced {
            var offset=o
            var count=c
            if self.free < count {
                let max = ß.time + self.timeout
                while self.free<count && ß.time<max {
                    Thread.sleep(0.01)
                }
            }
            if self.free<count {
                ret=0
                return
            }
            while true {
                let n=min(self.buffer.count-self.wo, count)
                if n<=0 {
                    break
                }
                self.buffer.replaceSubrange(self.wo..<self.wo+n, with: data[offset..<offset+n])
                offset += n
                count -= n
                self.wo = (self.wo + n) % self.buffer.count
            }
            ret = c-count
        }
        self.onData.dispatch(())
        return ret
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        if available == 0 {
            let max=ß.time+timeout
            while available==0 && ß.time<max {
                Thread.sleep(0.01)
            }
            if available == 0 {
                return nil
            }
        }
        var count=min(available,desired)
        var data=[UInt8](repeating: 0, count: count)
        lock.synced {
            var w=0
            while true {
                let n=min((self.ro>self.wo) ? (self.buffer.count-self.ro) : (self.wo-self.ro), count)
                if n<=0 {
                    break
                }
                data.replaceSubrange(w..<w+n, with: self.buffer[self.ro..<self.ro+n])
                self.ro = (self.ro + n) % self.buffer.count
                count -= n
                w += n
            }
        }
        onFreespace.dispatch(())
        return data
    }
    init(capacity:Int,timeout:Double=5,data:(()->())?=nil,error:((Error)->())?=nil) {
        buffer=[UInt8](repeating: 0, count: capacity)
        super.init(timeout:timeout,data:data,error:error)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class BufferedStream : Stream {
    let lock=Lock()
    var buffer=[UInt8]()
    public override var free:Int {
        return Int.max
    }
    public override var available:Int {
        return buffer.count
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        var ret:[UInt8]?=nil
        lock.synced {
            let n=min(desired,self.buffer.count)
            if n>0 {
                ret=Array(self.buffer[0..<n])
                self.buffer.removeSubrange(0..<n)
            }
        }
        if ret != nil {
            onFreespace.dispatch(())
        }
        return ret
    }
    public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        lock.synced {
            self.buffer.append(contentsOf: data[offset..<(offset+count)])
        }
        onData.dispatch(())
        return count
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class UTF8Writer : BufferedStream {
    public func write(_ string:String) -> Int {
        let b=Array(string.utf8)
        return self.write(b, offset: 0, count: b.count)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class UTF8Reader : BufferedStream {
    var cursor=0
    public var bigEndian : Bool = false
    public func readLine() -> String? {
        var str:String?
        lock.synced {
            while self.cursor<self.buffer.count {
                if self.buffer[self.cursor]==10 {
                    let sub=self.buffer[0..<self.cursor]
                    str=String(bytes:sub,encoding:String.Encoding.utf8)
                    if let s=str {
                        str=s.replacingOccurrences(of:"\r",with:"")
                    }
                    self.buffer.removeSubrange(0...self.cursor)
                    self.cursor=0
                    break
                }
                self.cursor += 1
            }
        }
        return str
    }
    public func readAll() -> String? {
        var str:String?
        self.onFreespace.dispatch(())
        lock.synced {
            str=String(bytes: self.buffer, encoding: String.Encoding.utf8)
            self.buffer.removeAll()
        }
        return str
    }
    public func readUInt8() -> UInt8? {
        var b : UInt8? = nil
        if available>1 {
            if let t=self.read(1) {
                b = t[0]
            }
        }
        return b
    }
    public func readUInt16() -> UInt16? {
        var b : UInt16? = nil
        if available>2 {
            if let t=self.read(2) {
                if bigEndian {
                    b = UInt16(t[1]) | (UInt16(t[0])<<8)
                } else {
                    b = UInt16(t[0]) | (UInt16(t[1])<<8)
                }
            }
        }
        return b
    }
    public func readUInt32() -> UInt32? {
        var b : UInt32? = nil
        if available>4 {
            if let t=self.read(4) {
                if bigEndian {
                    let v0 = UInt32(t[3])
                    let v1 = UInt32(t[2])<<8
                    let v2 = UInt32(t[1])<<16
                    let v3 = UInt32(t[0])<<24
                    b = v0 | v1 | v2 | v3
                } else {
                    let v0 = UInt32(t[0])
                    let v1 = UInt32(t[1])<<8
                    let v2 = UInt32(t[2])<<16
                    let v3 = UInt32(t[3])<<24
                    b = v0 | v1 | v2 | v3
                }
            }
        }
        return b
    }
    public func readUInt64() -> UInt64? {
        var b : UInt64? = nil
        if available>4 {
            if let t=self.read(8) {
                if bigEndian {
                    let v0 = UInt64(t[7])
                    let v1 = UInt64(t[6])<<8
                    let v2 = UInt64(t[5])<<16
                    let v3 = UInt64(t[4])<<24
                    let v4 = UInt64(t[3])<<32
                    let v5 = UInt64(t[2])<<40
                    let v6 = UInt64(t[1])<<48
                    let v7 = UInt64(t[0])<<56
                    b = v0 | v1 | v2 | v3 | v4 | v5 | v6 | v7
                } else {
                    let v0 = UInt64(t[0])
                    let v1 = UInt64(t[1])<<8
                    let v2 = UInt64(t[2])<<16
                    let v3 = UInt64(t[3])<<24
                    let v4 = UInt64(t[4])<<32
                    let v5 = UInt64(t[5])<<40
                    let v6 = UInt64(t[6])<<48
                    let v7 = UInt64(t[7])<<56
                    b = v0 | v1 | v2 | v3 | v4 | v5 | v6 | v7
                }
            }
        }
        return b
    }
    init(bigEndian:Bool=false) {
        self.bigEndian = bigEndian
        super.init()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class DataReader : Stream {
    let data : Data
    var cursor : Int
    public init(data:Data) {
        self.cursor = 0
        self.data = data
        super.init()
    }
    override public var available: Int {
        return data.count - cursor
    }
    override public func read(_ desired: Int) -> [UInt8]? {
        let r = min(desired,available)
        let b = [UInt8](repeating:0,count:r)
        data.copyBytes(to: UnsafeMutablePointer(mutating:b), from: cursor..<cursor+r)
        cursor += r
        return b
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
#if os(iOS) || os(tvOS) || os(OSX)
    public class FileReader : Stream {
        let filename:String
        var file:InputStream?
        let size:Int
        var read:Int=0
        public override var available:Int {
            return size-read
        }
        public override func read(_ desired:Int) -> [UInt8]? {
            var data=[UInt8](repeating: 0, count: desired)
            //let n=fread(UnsafeMutablePointer(data),1,desired,file)
            let n=file!.read(UnsafeMutablePointer(mutating:data), maxLength: desired)
            if n>0 {
                read += n
                if read<size {
                    wait(0.001).then { _ in
                        if self.read<self.size {
                            self.onData.dispatch(())
                        }
                    }
                } else if read == size {
                    wait(0.001).then { _ in
                        self.close()
                    }
                }
                if n==desired {
                    return data
                }
                data.removeSubrange(n..<desired)
                return data
            }
            return nil
        }
        public override func close() {
            if let f=file {
                f.close()
                self.file = nil
            }
            read=size
            super.close()
        }
        init(filename:String,timeout:Double=5,data:(()->())?=nil,error:((Error)->())?=nil) {
            self.filename=filename
            file = InputStream(fileAtPath: filename)
            file!.open()
            do {
                let ai = try FileManager.default.attributesOfItem(atPath: filename)
                size = Int((ai[FileAttributeKey.size]! as AnyObject).int64Value)
            } catch {
                size = 0
            }
            super.init(timeout:timeout,data:data,error:error)
            wait(0.001).then { _ in
                if self.read<self.size {
                    self.onData.dispatch(())
                }
            }
        }
    }
    public class FileWriter : Stream {
        let filename:String
        var file:OutputStream?
        let he=HE()
        public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
            return file!.write(UnsafePointer<UInt8>(data)!.advanced(by:offset), maxLength:count)
        }
        public override func close() {
            if let f=file {
                f.close()
                file = nil
            }
        }
        init(filename:String,timeout:Double=5,data:(()->())?=nil,error:((Error)->())?=nil) {
            self.filename=filename
            file=OutputStream(toFileAtPath: filename, append: false)
            file!.delegate = he
            file!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            file!.open()
            super.init(timeout:timeout,data:data,error:error)
        }
    }
    class HE : NSObject,StreamDelegate {
        @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
            Debug.info("stream event: \(eventCode)")
        }
    }
#else
public class FileReader : Stream {
    let filename:String
    var file:UnsafeMutablePointer<FILE>
    let size:Int
    var read:Int=0
    public override var available:Int {
        return size-read
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        var data=[UInt8](count:desired, repeatedValue:0)
        let n=fread(UnsafeMutablePointer(data),1,desired,file)
        if n>0 {
            read += n
            if read<size {
                wait(0.001).then { _ in
                    if self.read<self.size {
                        self.onData.dispatch()
                    }
                }
            } else if read == size {
                wait(0.001).then { _ in
                    self.close()
                }
            }
            if n==desired {
                return data
            }
            data.removeRange(n..<desired)
            return data
        }
        return nil
    }
    public override func close() {
        if file != nil {
            fclose(file)
            file = nil
        }
        read=size
        super.close()
    }
    init(filename:String,timeout:Double=5,data:(()->())?=nil,error:((Error)->())?=nil) {
        self.filename=filename
        file=fopen(filename, "r")
        fseek(file, 0, SEEK_END)
        size=ftell(file)
        fseek(file, 0,SEEK_SET)
        super.init(timeout:timeout,data:data,error:error)
        wait(0.001).then { _ in
            if self.read<self.size {
                self.onData.dispatch()
            }
        }
    }
}
public class FileWriter : Stream {
    let filename:String
    let file:UnsafeMutablePointer<FILE>
    public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        return fwrite(UnsafePointer<Int8>(data).advancedBy(offset), 1, count, file)
    }
    public override func close() {
        fclose(file)
    }
    init(filename:String,timeout:Double=5,data:(()->())?=nil,error:((Error)->())?=nil) {
        self.filename=filename
        file=fopen(filename, "w")
        super.init(timeout:timeout,data:data,error:error)
    }
}
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
