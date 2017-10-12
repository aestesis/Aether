//
//  AudioStream.swift
//  Alib
//
//  Created by renan jegouzo on 10/04/2016.
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
import CoreAudio
import AudioToolbox

#if os(iOS)
    import oggIOS
#elseif os(tvOS)
    import oggTV
#elseif os(OSX)
    import oggOSX
#endif

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class AudioStream : Atom {
    public class Error : Alib.Error {
        public enum Kind {
            case input
            case decoder
            case output
        }
        public var kind:Kind
        public init(_ kind:Kind,_ message:String,_ file:String=#file,_ line:Int=#line) {
            self.kind=kind
            super.init(message,file,line)
        }
    }
    public enum State {
        case invalid
        case buffering
        case playing
        case released
    }
    public private(set) var state:State=State.invalid
    var release:Bool=false
    
    var ice:Request?
    var input:AudioFileStream?
    var decode:AudioConverter?
    var output:AudioOutput?
    var reader:VorbisReader?
    public func stop() {
        release=true
        if let o=output {
            o.stop()
            output = nil
        }
        if let d=decode {
            d.close()
            decode = nil
        }
        if let i=input {
            i.close()
            input = nil
        }
        if let i=ice {
            i.close()
            ice = nil
        }
        if let r=reader {
            r.stop()
            reader = nil
        }
    }
    public init(url:String,buffering:Double=0.5,header:(([String:String])->())?=nil,metadata:(([String:String])->())?=nil,mono:(([Float])->())?=nil,error:((Error)->())?=nil) {
        super.init()
        self.state = .buffering
        var daurl=url //"http://udshu.io:8000/live.ogg"
        var doit:(()->())?=nil
        doit = {
            self.ice=Web.getICE(url:daurl,meta:{ m in
                if let fn=metadata {
                    fn(m)
                }
            }, audio:{ (header,stream) in
                if self.release {
                    stream.close()
                    self.ice!.close()
                    self.ice=nil
                    return
                }
                stream.onError.once({ (err) in
                    if let fn=error {
                        fn(Error(.input,err.message,#file,#line))
                    }
                })
                var contentType=""
                if let c=header["Content-Type"] {
                    contentType=c
                }
                if let c=header["content-type"] {
                    contentType=c
                }
                Debug.info("new AudioStream: \(contentType)")
                // maybe add ffmpeg: https://github.com/kewlbear/FFmpeg-iOS-build-script  (40Mb library :/)
                if let containerId=AudioStream.mimes[contentType] {
                    self.input=AudioFileStream(containerId)
                    self.input!.onReady.once {
                        let fmt=self.input!.format
                        let nchan=Int(fmt.mChannelsPerFrame)
                        let bytesPerChannel=MemoryLayout<Float>.size
                        let pcm = AudioStreamBasicDescription(mSampleRate: fmt.mSampleRate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagIsPacked | kLinearPCMFormatFlagIsFloat, mBytesPerPacket: UInt32(bytesPerChannel * nchan), mFramesPerPacket: 1, mBytesPerFrame: UInt32(bytesPerChannel * nchan), mChannelsPerFrame: UInt32(nchan), mBitsPerChannel: UInt32(bytesPerChannel*8), mReserved: 0)
                        self.decode = AudioConverter(from:fmt,to:pcm)
                        var ploutch = 0
                        if let input=self.input, let decode=self.decode {
                            if let cookie=input.magicCookie {
                                decode.set(cookie:cookie)
                            }
                            input.pipe(to:decode)
                            let _ = Thread {
                                let prebufsize = Int(pcm.mSampleRate*Double(pcm.mBytesPerFrame)*Double(pcm.mChannelsPerFrame)*buffering)
                                Thread.current.priority = 1
                                while !self.release && decode.available<prebufsize {
                                    //Debug.info("buffering... response:\(self.ice!.response.available) stream:\(stream.available)   file:\(input.available)   decode:\(decode.available)")
                                    Thread.sleep(0.05)
                                }
                                if !self.release {
                                    self.output=AudioOutput(nchan:Int(nchan),sampleRate:Int(pcm.mSampleRate)) { (samples,frames) in
                                        let sz = Int(frames) * Int(pcm.mBytesPerFrame)
                                        if let b=decode.read(sz) {
                                            if let fn=mono {
                                                let bb =  UnsafeMutableRawPointer(mutating:b).assumingMemoryBound(to: Float.self)
                                                var zb=[Float](repeating: 0,count: b.count/(nchan*4))
                                                if nchan==1 {
                                                    for j in 0..<zb.count {
                                                        zb[j] = bb[j]
                                                    }
                                                } else if nchan==2 {
                                                    var i=0
                                                    for j in 0..<zb.count {
                                                        zb[j] = (bb[i] + bb[i+1]) * 0.5
                                                        i += 2
                                                    }
                                                } else {
                                                    Debug.notImplemented()
                                                }
                                                fn(zb)
                                            }
                                            memcpy(samples, UnsafePointer(b), b.count)
                                            ploutch = 0
                                            return b.count/Int(pcm.mBytesPerFrame)
                                        }
                                        Debug.info("ploutch in AudioOutput... response:\(self.ice!.response.available) stream:\(stream.available)   file:\(input.available)   decode:\(decode.available)")
                                        ploutch += 1
                                        return 0
                                    }
                                    while !self.release {
                                        if ploutch>=3 {
                                            if let error = error {
                                                error(Error(.output, "stream broken or ended",#file,#line))
                                            }
                                        }
                                        Thread.sleep(0.1)
                                    }
                                }
                                Debug.warning("AudioStream.Thread released")
                            }
                            let _ = decode.onError.always { (err) in
                                Debug.error(err,#file,#line)
                                if let error = error {
                                    let _ = self.wait(0) {
                                        error(Error(.decoder,err.message,#file,#line))
                                    }
                                }
                            }
                        } else {
                            if let error = error {
                                let _ = self.wait(0) {
                                    error(Error(.decoder,"can't create decoder",#file,#line))
                                }
                            }
                        }
                    }
                    let _ = self.input!.onError.always { (err) in
                        Debug.error(err)
                        if let error = error {
                            let _ = self.wait(0) {
                                error(Error(.input,err.message,#file,#line))
                            }
                        }
                    }
                    stream.pipe(to:self.input!)
                } else if contentType == "application/ogg" || contentType == "audio/ogg" {
                    var smprate = 0
                    self.reader = VorbisReader(input:stream, onInfo:{ (info:VorbisReader.VorbisInfo) in
                        Debug.warning("ogg: \(info.sampleRate)")
                        if smprate != info.sampleRate && !self.release {    // create a new AudioOutput if first one or if the sample rate changed in a chained ogg stream  // TOTEST:
                            Debug.warning("AudioStream: new ogg sample rate (\(info.sampleRate))")
                            smprate = info.sampleRate
                            if let o = self.output {
                                o.stop()
                                self.output = nil
                            }
                            let _ = Thread {
                                if self.release {
                                    return
                                }
                                if let reader = self.reader {
                                    let prebuffersize = Int(Double(info.sampleRate*info.channels) * buffering)
                                    while !self.release && reader.avaibleSamples<prebuffersize {
                                        //Debug.info("available  \(self.reader!.avaibleSamples)")
                                        Thread.sleep(0.05)
                                    }
                                }
                                if self.release {
                                    return
                                }
                                Debug.info("audio start, buffered:  \(self.reader!.avaibleSamples)")
                                var ploutch = 0
                                self.output=AudioOutput(nchan:info.channels,sampleRate:info.sampleRate) { (samples,frames) in
                                    if let reader=self.reader, let b = reader.readSamples(Int(frames)*info.channels) {
                                        ploutch = min(ploutch+1, AudioOutput.buffersCount)
                                        if let fn=mono {
                                            var zb=[Float](repeating: 0,count: b.count/info.channels)
                                            if info.channels==1 {
                                                for j in 0..<zb.count {
                                                    zb[j] = max(min(b[j],1),-1)
                                                }
                                            } else if info.channels==2 {
                                                var i=0
                                                for j in 0..<zb.count {
                                                    zb[j] = max(min((b[i] + b[i+1]) * 0.5,1),-1)
                                                    i += 2
                                                }
                                            } else {
                                                Debug.notImplemented()
                                            }
                                            fn(zb)
                                        }
                                        memcpy(samples, UnsafePointer(b), b.count*MemoryLayout<Float>.size)
                                        return b.count/info.channels
                                    } else if self.release {
                                        // nothing to do, just skipping
                                    } else if let error = error {
                                        ploutch -= 1
                                        Debug.error("output buffer underflow, active buffers: \(ploutch)  available input data:\(stream.available)",#file,#line)
                                        if ploutch == 0 {
                                            let _ = self.wait(0) {
                                                error(Error(.output,"output buffer underflow",#file,#line))
                                            }
                                        }
                                    }
                                    return 0
                                }
                            }
                        }
                        if let fn=metadata {
                            var meta=[String:String]()
                            for c in info.comments {
                                let kv = c.split("=")
                                if kv.count == 2 {
                                    meta[kv[0].trim()]=kv[1].trim()
                                }
                            }
                            meta["bitrate"]=String(info.bitRate/1000)
                            meta["samplerate"]=String(info.sampleRate)
                            fn(meta)
                        }
                    },onError:{ err in
                        if let fn=error {
                            fn(Error(.decoder,err.message,#file,#line))
                        }
                    })
                } else {
                    if let fn=error {
                        fn(Error(.decoder,"Unknown stream format '\(contentType)'",#file,#line))
                    }
                }
            }, error:{ err in
                if let fn=error {
                    if let erres:Response.ResponseError = err.get() {
                        if erres.response.status == 302 {
                            if let loc=erres.response.header["Location"] {  // redirection
                                if loc.contains("http:") {
                                    daurl=loc
                                    doit!()
                                } else {
                                    daurl += loc
                                    doit!()
                                }
                            }
                        } else {
                            fn(Error(.input,"\(err.message): \(url)",#file,#line))
                        }
                    } else {
                        fn(Error(.input,err.message,#file,#line))
                    }
                }
            })
        }
        doit!()
    }
    static var mimes : [String:AudioFileTypeID] = [
        "audio/aac":kAudioFileAAC_ADTSType,
        "audio/aacp":kAudioFileAAC_ADTSType,
        "audio/mpeg":kAudioFileMP3Type,
        "audio/mp4":kAudioFileMPEG4Type,
        "audio/x-aiff":kAudioFileAIFFType ,
        "audio/x-wav":kAudioFileWAVEType
    ]
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
struct AudioControl : StreamControl {
    var desc : [AudioStreamPacketDescription]
    var length : Int
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class AudioConverter : Stream {
    let inBufferSize = 8 * 1024
    let outBufferSize = 16 * 1024
    
    var indata=[UInt8]()
    var incontrols=[AudioControl]()
    let inlock = Lock()
    var outdata=[UInt8]()
    let outlock = Lock()
    
    var inbufdata:[UInt8]
    var inbuf:AudioBuffer
    var outbufdata:[UInt8]
    var outbuf:AudioBuffer
    
    var cv:AudioConverterRef?=nil
    let from:AudioStreamBasicDescription
    let to:AudioStreamBasicDescription
    
    var release = false
    var running = false
    let pdcount = 32
    var pd:UnsafeMutablePointer<AudioStreamPacketDescription>
    
    public func set(cookie:[UInt8]) {
        let sz:UInt32=UInt32(cookie.count)
        AudioConverterSetProperty(cv!, kAudioConverterCompressionMagicCookie,sz,UnsafePointer(cookie))
    }
    
    public init?(from:AudioStreamBasicDescription,to:AudioStreamBasicDescription) {
        self.from=from
        self.to=to
        var f=from
        var t=to

        // http://stackoverflow.com/questions/6610958/os-x-ios-sample-rate-conversion-for-a-buffer-using-audioconverterfillcomplex/6624147#6624147
        
        pd=UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: pdcount)
        inbufdata=[UInt8](repeating: 0, count: inBufferSize)
        inbuf=AudioBuffer(mNumberChannels:to.mChannelsPerFrame,mDataByteSize:UInt32(inBufferSize),mData:&inbufdata)
        outbufdata=[UInt8](repeating: 0, count: outBufferSize)
        outbuf=AudioBuffer(mNumberChannels:to.mChannelsPerFrame,mDataByteSize:UInt32(outBufferSize),mData:&outbufdata)
        
        super.init()
        
        let st = AudioConverterNew(&f, &t, &cv)
        if st != 0 {
            Debug.error(AudioConverter.error(st),#file,#line)
            return nil
        }

        //Debug.info("AudioConverter: input audio format \(from)")
        
        let _ = Thread {
            self.running = true
            if self.release {
                return
            }
            let cbinput:AudioConverterComplexInputDataProc={ (cfref,npackets,bufList,desc,user) in
                let this=unsafeBitCast(user,to: AudioConverter.self)
                while !this.release && this.incontrols.count<1 {
                    Thread.sleep(0.01)
                }
                if this.release {
                    return 100
                }
                var ret : OSStatus = 0
                this.inlock.synced {
                    if let ac=this.incontrols.dequeue() {
                        memcpy(&this.inbufdata,&this.indata,ac.length)
                        bufList[0].mNumberBuffers=1
                        bufList[0].mBuffers=this.inbuf
                        this.indata.removeSubrange(0..<ac.length)
                        if ac.desc.count >= this.pdcount {
                            Debug.error("too much AudioStreamPacketDescription",#file,#line)
                        }
                        for i in 0..<min(ac.desc.count,this.pdcount) {
                            this.pd[i] = ac.desc[i]
                        }
                        desc! [0] = this.pd
                        npackets [0] = UInt32(ac.desc.count)
                    } else {
                        Debug.error("AudioConverterComplexInputDataProc, no data",#file,#line)
                        ret = 100
                    }
                }
                return ret
            }
            while !self.release && self.indata.count < self.inBufferSize {
                Thread.sleep(0.01)
            }
            while !self.release {
                if let cv = self.cv  {
                    let ptrSelf=unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
                    var npackets=UInt32(self.outbufdata.count/Int(to.mBytesPerPacket))
                    var buflist=AudioBufferList(mNumberBuffers: 1, mBuffers:self.outbuf)
                    let status = AudioConverterFillComplexBuffer(cv,cbinput,ptrSelf,&npackets,&buflist,nil)
                    if status != 0 {
                        self.onError.dispatch(Error("AudioConverter.AudioConverterFillComplexBuffer(\(status))",#file,#line))   // TODO: debug crash there
                    } else if npackets != 0 {
                        // TODO: check c value
                        self.outlock.synced {
                            self.outdata.append(contentsOf: self.outbufdata)
                        }
                    }
                } else {
                    Debug.error("cv error",#file,#line)
                    break
                }
            }
            self.running = false
        }
    }
    deinit {
        pd.deallocate(capacity:pdcount)
        if let cv=cv {
            AudioConverterDispose(cv)
            self.cv = nil
        }
    }
    override public func close() {
        release = true
        super.close()
        while running {
            Thread.sleep(0.01)
        }
        if let cv=self.cv {
            AudioConverterReset(cv)
        }
    }
    public override var available: Int {
        return outdata.count
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        var ret:[UInt8]?=nil
        outlock.synced {
            let n=min(desired,self.outdata.count)
            if n>0 {
                ret=Array(self.outdata[0..<n])
                self.outdata.removeSubrange(0..<n)
            }
        }
        if ret != nil {
            onFreespace.dispatch(())
        }
        return ret
    }
    public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        inlock.synced {
            self.indata.append(contentsOf: data[offset..<(offset+count)])
        }
        onData.dispatch(())
        return count
    }
    public override func writeControl(_ data: [StreamControl], offset: Int, count: Int) -> Int {
        inlock.synced {
            for i in offset..<(offset+count) {
                if let ac = data[i] as? AudioControl {
                    self.incontrols.append(ac)
                }
            }
        }
        return count
    }
    static func error(_ status:OSStatus) -> String {
        var str = ""
        str.unicodeScalars.append(UnicodeScalar(Int((status >> 24) & 0xFF))!)
        str.unicodeScalars.append(UnicodeScalar(Int((status >> 16) & 0xFF))!)
        str.unicodeScalars.append(UnicodeScalar(Int((status >> 8) & 0xFF))!)
        str.unicodeScalars.append(UnicodeScalar(Int(status & 0xFF))!)
        Debug.info("error(\(str))")
        if status == kAudioConverterErr_FormatNotSupported {
            return "Format Not Supported"
        } else if status == kAudioConverterErr_OperationNotSupported {
            return "Operation Not Supported"
        } else if status == kAudioConverterErr_PropertyNotSupported {
            return "Property Not Supported"
        } else if status == kAudioConverterErr_InvalidInputSize {
            return "Invalid input size"
        } else if status == kAudioConverterErr_InvalidOutputSize {
            return "Invalid output size"
        } else if status == kAudioConverterErr_UnspecifiedError {
            return "Unspecified error"
        } else if status == kAudioConverterErr_BadPropertySizeError {
            return "Bad property size error"
        } else if status == kAudioConverterErr_RequiresPacketDescriptionsError {
            return "Require packet description error"
        } else if status == kAudioConverterErr_InputSampleRateOutOfRange {
            return "Input sample rate out of range"
        } else if status == kAudioConverterErr_OutputSampleRateOutOfRange {
            return "Output sample rate out of range"
        }
        #if os(OSX)
            if status == kAudioHardwareIllegalOperationError {
                return "Audio Hardware Illegal Operation Error"
            }
        #else
            if status == kAudioConverterErr_HardwareInUse {
                return "Hardware in use"
            } else if status == kAudioConverterErr_NoHardwarePermission {
                return "No hardware permission"
            }
        #endif
        let err = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        return err.localizedDescription
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class AudioFileStream : Stream {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var sid:AudioFileStreamID?=nil
    let onReady=Event<Void>()
    var buffer=[UInt8]()
    var controls=[AudioControl]()
    let lock=Lock()
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    init(_ containerId:AudioFileTypeID) {
        super.init()
        let ptrSelf=unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        let onProperties:@convention(c) (UnsafeMutableRawPointer,AudioFileStreamID,AudioFileStreamPropertyID,UnsafeMutablePointer<AudioFileStreamPropertyFlags>)->() = { (user,sid,property,flags) in
            let this=unsafeBitCast(user,to: AudioFileStream.self)
            if property == kAudioFileStreamProperty_ReadyToProducePackets {
                this.onReady.dispatch(())
            } else if property == kAudioFileStreamProperty_MagicCookieData {
                Debug.info("it's a kind of magic!!")
            }
            flags[0]=AudioFileStreamPropertyFlags.cacheProperty // cache all properties
        }
        let onData:@convention(c) (UnsafeMutableRawPointer,UInt32,UInt32,UnsafeRawPointer,UnsafeMutablePointer<AudioStreamPacketDescription>)->() = { (user,bytes,packets,data,desc) in
            let this=unsafeBitCast(user,to: AudioFileStream.self)
            this.lock.synced {
                let p=data.assumingMemoryBound(to: UInt8.self)  //UnsafePointer<UInt8>(data)
                for i in 0..<Int(bytes) {
                    this.buffer.append(p[i])    // TODO: faster algo
                }
                if packets == 0 {
                    let p = [AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 0, mDataByteSize: bytes)]
                    this.controls.append(AudioControl(desc:p,length:Int(bytes)))
                } else {
                    var p = [AudioStreamPacketDescription]()
                    for i in 0..<Int(packets) {
                        p.append(desc[i])
                    }
                    this.controls.append(AudioControl(desc:p,length:Int(bytes)))
                }
            }
            this.onData.dispatch(())
        }
        let st=AudioFileStreamOpen(ptrSelf,onProperties,onData,containerId,&sid)
        if st != 0 {
            Debug.error(AudioFileStream.error(status:st))
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    static func error(status st:OSStatus) -> String {
        if st == kAudioFileStreamError_UnsupportedFileType {
            return "The specified file type is not supported."
        }
        if st == kAudioFileStreamError_UnsupportedDataFormat {
            return "The data format is not supported by the specified file type."
        }
        if st == kAudioFileStreamError_UnsupportedProperty {
            return "The property is not supported."
        }
        if st == kAudioFileStreamError_BadPropertySize {
            return "The size of the buffer you provided for property data was not correct."
        }
        if st == kAudioFileStreamError_NotOptimized {
            return "It is not possible to produce output packets because the streamed audio file's packet table or other defining information is not present or appears after the audio data."
        }
        if st == kAudioFileStreamError_InvalidPacketOffset {
            return "A packet offset was less than 0, or past the end of the file, or a corrupt packet size was read when building the packet table."
        }
        if st == kAudioFileStreamError_InvalidFile {
            return "The file is malformed, not a valid instance of an audio file of its type, or not recognized as an audio file."
        }
        if st == kAudioFileStreamError_ValueUnknown {
            return "The property value is not present in this file before the audio data."
        }
        if st == kAudioFileStreamError_DataUnavailable {
            return "The amount of data provided to the parser was insufficient to produce any result."
        }
        if st == kAudioFileStreamError_IllegalOperation {
            return "An illegal operation was attempted."
        }
        if st == kAudioFileStreamError_UnspecifiedError {
            return "An unspecified error has occurred."
        }
        if st == kAudioFileStreamError_DiscontinuityCantRecover {
            return "A discontinuity has occurred in the audio data, and Audio File Stream Services cannot recover."
        }
        return "Unidentified error \(st)"
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override var available: Int {
        var ret = 0
        lock.synced { 
            ret = self.buffer.count
        }
        return ret
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func read(_ desired:Int) -> [UInt8]? {
        var ret:[UInt8]?=nil
        lock.synced {
            let n=min(desired,self.buffer.count)
            if n>0 {
                let b=Array(self.buffer[0..<n])
                self.buffer.removeSubrange(0..<n)
                ret=b
            }
        }
        return ret
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override var availableControl: Int {
        var ret = 0
        lock.synced { 
            ret = self.controls.count
        }
        return ret
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func readControl(_ desired:Int) -> [StreamControl]? {
        var ret:[StreamControl]?=nil
        lock.synced {
            let n=min(desired,self.controls.count)
            if n>0 {
                var b = [StreamControl]()
                for i in 0..<n {
                    b.append(self.controls[i])
                }
                self.controls.removeSubrange(0..<n)
                ret = b
            }
        }
        return ret
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var parsing = 0
    override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        var dc = 0
        lock.synced {
            if let sid = self.sid {
                parsing += 1
                let st = AudioFileStreamParseBytes(sid, UInt32(count), UnsafeMutablePointer(mutating:data).advanced(by: offset), AudioFileStreamParseFlags(rawValue:0))
                if st == 0 {
                    dc = data.count
                } else {
                    Debug.error("can't feed AudioFileStream (\(AudioFileStream.error(status: st)))")
                }
                parsing -= 1
            }
        }
        return dc
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func close() {
        self.onReady.removeAll()
        lock.synced {
            if let sid = self.sid {
                while parsing>0 {
                    Thread.sleep(0.01)
                }
                AudioFileStreamClose(sid)   // maybe crash in delegate INPUT STREAM cause of this....
                self.sid = nil
            }
        }
        super.close()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var format : AudioStreamBasicDescription {
        var desc=AudioStreamBasicDescription()
        var size:UInt32=UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let status=AudioFileStreamGetProperty(sid!,kAudioFileStreamProperty_DataFormat,&size,&desc)
        if status != 0 {
            Debug.error("error: \(status) \(AudioFileStream.error(status: status))")
        }
        return desc
    }
    var magicCookie : [UInt8]? {
        var size=UInt32(0)
        var writable=DarwinBoolean(false)
        let stinfo=AudioFileStreamGetPropertyInfo(sid!,kAudioFileStreamProperty_MagicCookieData,&size,&writable)
        if stinfo != 0 {
            return nil  // no cookie in file
        }
        var cookie=[UInt8](repeating: 0, count: Int(size))
        let status=AudioFileStreamGetProperty(sid!,kAudioFileStreamProperty_MagicCookieData,&size,&cookie)
        if status != 0 {
            Debug.error("error: \(status) \(AudioFileStream.error(status: status))")
            return nil
        }
        return cookie
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class VorbisReader : Atom {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    struct VorbisInfo {
        var channels:Int
        var sampleRate:Int
        var bitRate:Int
        var vendor:String
        var comments:[String]
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    let lock=Lock()
    var outbuf=[Float]()
    var release=false
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var avaibleSamples:Int {
        return outbuf.count
    }
    func readSamples(_ samples:Int) -> [Float]? {
        var ret:[Float]?=nil
        lock.synced {
            let n=min(samples,self.outbuf.count)
            if n>0 {
                let b=Array(self.outbuf[0..<n])
                self.outbuf.removeSubrange(0..<n)
                ret=b
            }
        }
        return ret
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func stop() {
        release = true
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    init(input:Stream,onInfo:((VorbisInfo)->())?=nil,onSamples:(([Float])->())?=nil,onError:((Error)->())?=nil) {
        super.init()
        let _ = Thread {
            var oy=ogg_sync_state()
            var os=ogg_stream_state()
            var og=ogg_page()
            var op=ogg_packet()
            var vi=vorbis_info()
            var vc=vorbis_comment()
            var vd=vorbis_dsp_state()
            var vb=vorbis_block()
            var error:Error?
            ogg_sync_init(&oy)
            while !self.release && error==nil {
                var eos=0
                var buffer=ogg_sync_buffer(&oy,4096)
                /*
                while !self.release && input.available<4096 {
                    Thread.sleep(0.1)
                    // TODO: handle timeout and normal file ending...
                }
                if self.release {
                    break
                }
                 */
                if let bytes=input.read(4096) {
                    memcpy(buffer,bytes,bytes.count)
                    ogg_sync_wrote(&oy,bytes.count)
                    
                    if ogg_sync_pageout(&oy,&og) != 1 {
                        if bytes.count<4096 {
                            break
                        } else {
                            error = Error("Input does not appear to be an Ogg bitstream.")
                            break
                        }
                    }
                    
                    ogg_stream_init(&os,ogg_page_serialno(&og))
                    vorbis_info_init(&vi)
                    vorbis_comment_init(&vc)
                    
                    if ogg_stream_pagein(&os,&og) < 0 {
                        error = Error("Input does not appear to be an Ogg bitstream.")
                        break
                    }
                    let r = ogg_stream_packetout(&os,&op)
                    if r != 1 {
                        error = Error("Error reading initial header packet.")
                        break
                    }
                    if vorbis_synthesis_headerin(&vi,&vc,&op) < 0 {
                        error = Error("This Ogg bitstream does not contain Vorbis audio data.")
                        break
                    }
                    
                    // it's a vorbis!
                    
                    var i = 0
                    while i < 2 && error==nil {
                        while i < 2 && error==nil {
                            let result = ogg_sync_pageout(&oy,&og)
                            if result == 0 {
                                break   // need more data
                            }
                            if result == 1 {
                                ogg_stream_pagein(&os,&og)
                                while i<2 && error==nil {
                                    let result = ogg_stream_packetout(&os,&op)
                                    if result == 0 {
                                        break
                                    }
                                    if result < 0 {
                                        error = Error("Corrupt secondary header.")
                                        break
                                    }
                                    if vorbis_synthesis_headerin(&vi,&vc,&op)<0 {
                                        error = Error("Corrupt secondary header.")
                                        break
                                    }
                                    i += 1
                                }
                            }
                        }
                        if error != nil {
                            break
                        }
                        buffer = ogg_sync_buffer(&oy,4096)
                        while !self.release && input.available<4096 {
                            Thread.sleep(0.1)
                            // TODO: handle timeout and normal file ending...
                        }
                        if self.release {
                            break
                        }
                        if let bytes=input.read(4096) {
                            memcpy(buffer,bytes,bytes.count)
                            ogg_sync_wrote(&oy,bytes.count)
                        } else if (i<2) {
                            error = Error("End of file.")
                            break
                        } else {
                            ogg_sync_wrote(&oy,0)
                        }
                    }
                    if error != nil {
                        break
                    }
                    if let fn=onInfo {
                        var l=[String]()
                        if var ptr=vc.user_comments {
                            while ptr[0] != nil {
                                l.append(String(validatingUTF8:ptr[0]!)!)
                                ptr = ptr.advanced(by:1)
                            }
                            let vendor = String(validatingUTF8: vc.vendor) ?? String(cString: vc.vendor);
                            fn(VorbisInfo(channels:Int(vi.channels),sampleRate:vi.rate,bitRate:vi.bitrate_nominal,vendor:vendor,comments:l))
                        }
                    }
                    if vorbis_synthesis_init(&vd,&vi) == 0 {
                        vorbis_block_init(&vd,&vb)
                        while eos == 0 && !self.release  {
                            while eos == 0 && !self.release  {
                                let result = ogg_sync_pageout(&oy,&og)
                                if result == 0 {
                                    break
                                }
                                if result < 0 {
                                    Debug.error("VorbisReader: corrupted data...",#file,#line)
                                    // TODO:
                                } else {
                                    ogg_stream_pagein(&os,&og)
                                    while !self.release {
                                        let result = ogg_stream_packetout(&os,&op)
                                        if result == 0 {
                                            break
                                        } else if result < 0 {
                                            // Debug.error("VorbisReader: corrupted data...",#file,#line)
                                            // happens sometime.. not a problem
                                        } else {
                                            if vorbis_synthesis(&vb,&op) == 0 {
                                                vorbis_synthesis_blockin(&vd,&vb)
                                            }
                                            while !self.release {
                                                var pcm:UnsafeMutablePointer<UnsafeMutablePointer<Float>?>?=nil
                                                let samples = vorbis_synthesis_pcmout(&vd,&pcm)
                                                if samples<=0 {
                                                    break
                                                }
                                                var interlaced=[Float](repeating:0,count:Int(samples*vi.channels))
                                                for i in 0..<Int(vi.channels) {
                                                    var n=i
                                                    for j in 0..<Int(samples) {
                                                        interlaced[n] = pcm![i]![j]
                                                        n += Int(vi.channels)
                                                    }
                                                }
                                                if let fn=onSamples {
                                                    fn(interlaced)
                                                } else {
                                                    var wait = true
                                                    let st = ß.time
                                                    while wait && !self.release {
                                                        self.lock.synced {
                                                            wait = self.outbuf.count>Int(vi.rate)*Int(vi.channels)*10
                                                        }
                                                        if wait && !self.release {
                                                            Thread.sleep(0.1)
                                                            if ß.time-st>2 {
                                                                Debug.error("VorbisReader: write timeout",#file,#line)
                                                                break
                                                            }
                                                        }
                                                    }
                                                    self.lock.synced {
                                                        self.outbuf.append(contentsOf:interlaced)
                                                    }
                                                }
                                                vorbis_synthesis_read(&vd,samples)
                                            }
                                        }
                                    }
                                    if ogg_page_eos(&og) != 0 {
                                        eos = 1
                                    }
                                }
                            }
                            if eos == 0 && !self.release {
                                buffer = ogg_sync_buffer(&oy,4096)
                                let st = ß.time
                                while !self.release && input.available<4096 {
                                    Thread.sleep(0.05)
                                    if input.available > 0 || self.release {
                                        //Debug.warning("Vorbisreader: incomplete buffer",#file,#line)
                                        break
                                    }
                                    if (ß.time-st)>1 {
                                        if let fn=onError {
                                            fn(Error("VorbisReader: read timeout",#file,#line))
                                        }
                                    }
                                }
                                if self.release {
                                    break
                                }
                                if let bytes=input.read(4096) {
                                    memcpy(buffer,bytes,bytes.count)
                                    ogg_sync_wrote(&oy,bytes.count)
                                } else {
                                    ogg_sync_wrote(&oy,0)
                                    eos = 1
                                }
                            }
                        }
                        vorbis_block_clear(&vb)
                        vorbis_dsp_clear(&vd)
                    } else {
                        Debug.error("VorbisReader: Corrupt header during playback initialization.")
                    }
                    ogg_stream_clear(&os)
                    vorbis_comment_clear(&vc)
                    vorbis_info_clear(&vi)
                }
            }
            ogg_sync_clear(&oy)
            if let err=error {
                if let fn=onError {
                    fn(err)
                } else {
                    Debug.error(err,#file,#line)
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
