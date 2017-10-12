//
//  AudioOutput.swift
//  Alib
//
//  Created by renan jegouzo on 06/04/2016.
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
import AudioToolbox

// example: https://gist.github.com/hngrhorace/1360885

public class AudioOutput : Atom {
    public typealias FillCallback = (_ samples:UnsafeMutableRawPointer,_ frames:Int)->(Int)     // samples ptr type Float
    public static let buffersCount=3
    var bufSize:Int
    var nbuf = 0
    let fill:FillCallback
    var release=false
    var format:AudioStreamBasicDescription
    public init(nchan:Int,sampleRate:Int,fill:@escaping FillCallback) {
        let bytesPerChannel=MemoryLayout<Float>.size// sizeof(Float.self)
        let bytesPerPacket=nchan*bytesPerChannel
        self.fill=fill
        bufSize = sampleRate*nchan*bytesPerChannel/20
        format=AudioStreamBasicDescription(mSampleRate: Float64(sampleRate), mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsPacked|kLinearPCMFormatFlagIsFloat, mBytesPerPacket: UInt32(bytesPerPacket), mFramesPerPacket: 1, mBytesPerFrame: UInt32(bytesPerPacket), mChannelsPerFrame: UInt32(nchan), mBitsPerChannel: UInt32(bytesPerChannel*8), mReserved: 0)
        super.init()
        let callback:AudioQueueOutputCallback = { (userData, queue, buffer) in
            let this=unsafeBitCast(userData, to: AudioOutput.self)
            this.nbuf -= 1
            this.enqueue(queue,buffer)
        }
        let _=Thread({
            var output:AudioQueueRef?=nil
            let this=unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            AudioQueueNewOutput(&self.format, callback, this, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue, 0, &output)
            for _ in 1...AudioOutput.buffersCount {
                var aqb:AudioQueueBufferRef?=nil
                AudioQueueAllocateBuffer(output!, UInt32(self.bufSize), &aqb)
                self.enqueue(output!, aqb!)
            }
            AudioQueueStart(output!, nil)
            CFRunLoopRun()
            AudioQueueDispose(output!,false)
            Debug.info("AudioOutput disposed.")
        })
    }
    deinit {
        stop()
    }
    func enqueue(_ queue:AudioQueueRef,_ buffer:AudioQueueBufferRef) {
        if !release {
            let data=UnsafeMutableRawPointer(buffer.pointee.mAudioData)
            let sz=fill(data,Int(buffer.pointee.mAudioDataBytesCapacity)/Int(self.format.mBytesPerFrame))*Int(self.format.mBytesPerFrame)
            buffer.pointee.mAudioDataByteSize=UInt32(sz)
            AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
            nbuf += 1
        } else {
            AudioQueueFreeBuffer(queue,buffer)
            if nbuf == 0 {
                AudioQueueStop(queue, false)
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
    }
    func stop() {
        release=true
    }
}
