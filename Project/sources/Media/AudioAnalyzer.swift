//
//  AudioAnalyzer.swift
//  Alib
//
//  Created by renan jegouzo on 19/05/2016.
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
// https://www.ee.columbia.edu/~dpwe/pubs/Ellis07-beattrack.pdf
public class AudioAnalyzer : Atom {
    static let beatRange = 720  // 20ms at 44.1Khz
    public var maxAmp:Float = 2.0
    public var fftAmp:Float=8
    var coamp:Float=0.5
    var impact:Float=0.5
    var timestamp:Int=512
    var peak:Float=0
    var current=EQ()
    var eqPeak=EQ()
    var correction=EQ()
    var samples=[Float](repeating: 0,count: 512)
    var bass=[Float](repeating: 0,count: 512)
    var medium=[Float](repeating: 0,count: 512)
    var treeble=[Float](repeating: 0,count: 512)
    //var beat=EQHD()
    let lock=Lock()
    var envelope:Double=0
    var menv=[Float]()
    var cenv:Float=0.0
    var ienv:Int=0
    var fft=[Float](repeating:0,count:128)
    var oenv=[Double]()
    var bpm=0.0
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func feed(_ buffer:[Float],offset:Int = 0,count:Int = 0) {
        let lenght = (count>0) ? count : buffer.count-offset
        let cmedium:Float = max(min(1.0,coamp*10.0),0.5)
        let ctreeble:Float = max(min(1.0,coamp*20.0),0.5)
        var b:Float = 0
        var m:Float = 0
        var t:Float = 0
        let nb = max(lenght,512)
        var samples=[Float](repeating: 0,count: nb)
        var bass=[Float](repeating: 0,count: nb)
        var medium=[Float](repeating: 0,count: nb)
        var treeble=[Float](repeating: 0,count: nb)
        var wp=0
        if samples.count > lenght && self.samples.count > (samples.count-lenght) {
            for s in lenght..<samples.count {
                samples[wp]=self.samples[s]
                bass[wp]=self.bass[s]
                medium[wp]=self.medium[s]
                treeble[wp]=self.treeble[s]
                wp += 1
            }
        }
        var ma:Float=0
        //var ms:Float=0
        for i in 0..<lenght {
            let vs=buffer[offset+i]
            let vcs=vs*coamp
            let va=abs(vs)
            let vca=va*coamp
            samples[wp]=vcs
            ma=max(ma,vca)
            ienv = (ienv+1)%5
            if ienv == 0 {
                menv.append(fftAmp*cenv*0.2)
                cenv=0
            }
            cenv += vcs
            //obeat.bass=(beat.bass*Float128(0.999999)+Float128(Double(vcs))*Float128(0.000001));
            //obeat.medium=(beat.medium*Float128(0.99999)+(Float128(Double(vcs))-beat.bass)*Float128(0.00001));
            //obeat.treeble=(beat.treeble*Float128(0.999)+(Float128(Double(vcs))-beat.bass-beat.medium)*Float128(0.001));
            current.low = current.low*0.9 + vcs*0.1
            current.medium = current.medium*0.7 + (vcs-current.low)*0.3
            current.high = vcs-current.medium-current.low
            bass[wp]=current.low
            medium[wp]=current.medium*cmedium
            treeble[wp]=current.high*ctreeble
            b = max(b,abs(current.low))
            m = max(m,abs(current.medium*cmedium))
            t = max(t,abs(current.high*ctreeble))
            wp += 1
        }
        while menv.count>=128 {
            let f = Alib.fft(Array(menv[0...127]))
            menv.removeSubrange(0...127)
            var a = 0.0
            for i in 0..<128 {
                a += Double(f[i])
            }
            self.envelope = a/128
            self.fft = f
            oenv.enqueue(self.envelope) // enqueue at 64 fps (8192hz / 128)
        }
        while oenv.count>256 {
            let _ = oenv.dequeue()
        }
        if oenv.count==256 {
            let minp = 64/3 // 180 bpm
            let maxp = 64   //  60 bpm
            var maxc = 0.0
            var maxlag = 0
            for lag in minp...maxp {
                var c = 0.0
                for i in 0..<192 {
                    c += oenv[i]*oenv[i+lag]
                }
                if c>maxc {
                    maxc = c
                    maxlag = lag
                }
            }
            self.bpm = 60*64/Double(maxlag) // needs AI for better accuracy
        }
        lock.synced {
            self.timestamp += lenght
            if ma>0 {
                self.coamp = min(self.coamp*0.99+(self.impact/ma)*0.01,self.maxAmp)
            }
            self.peak = ma
            self.eqPeak.low = b
            self.eqPeak.medium = m
            self.eqPeak.high = t
            self.samples = samples
            self.bass = bass
            self.medium = medium
            self.treeble = treeble
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func clear() {
        lock.synced { 
            self.peak=0
            self.current=EQ()
            self.eqPeak=EQ()
            self.samples=[Float](repeating: 0,count: 512)
            self.bass=[Float](repeating: 0,count: 512)
            self.medium=[Float](repeating: 0,count: 512)
            self.treeble=[Float](repeating: 0,count: 512)
            self.envelope=0.0
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var info:Info {
        var i:Info?=nil
        lock.synced {
            i=Info(analyzer:self)
        }
        return i!
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(correction:EQ=EQ(low:1,medium:7,high:15)) {
        super.init()
        self.correction=correction
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public struct Info {
        public let timestamp:Int
        public let peak:Float
        public let eq:EQ
        public let samples:[Float]
        public let bass:[Float]
        public let medium:[Float]
        public let treeble:[Float]
        public let amplification:Float
        public let envelope:Double
        public let fft:[Float]
        public let bpm:Double
        init(frames:Int) {
            timestamp=0
            peak=0
            eq=EQ()
            samples=[Float](repeating: 0,count: frames)
            bass=[Float](repeating: 0,count: frames)
            medium=[Float](repeating: 0,count: frames)
            treeble=[Float](repeating: 0,count: frames)
            amplification=0
            envelope=0
            fft=[Float](repeating:0,count:128)
            bpm=120
        }
        init(analyzer a:AudioAnalyzer) {
            timestamp=a.timestamp-a.samples.count
            peak=a.peak
            eq=a.eqPeak
            samples=a.samples
            bass=a.bass
            medium=a.medium
            treeble=a.treeble
            amplification=a.coamp
            envelope=a.envelope
            fft=a.fft
            bpm=a.bpm
            //obeat=EQH(EQHD(low:a.beat.low*Float128(200),medium:a.beat.medium*Float128(50),high:a.beat.high*Float128(25)))
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
public struct EQHD {
    public var low=Float128(0)
    public var medium=Float128(0)
    public var high=Float128(0)
    public init(low:Double=0,medium:Double=0,high:Double=0) {
        self.low=Float128(low)
        self.medium=Float128(medium)
        self.high=Float128(high)
    }
    public init(low:Float128=Float128(0),medium:Float128=Float128(0),high:Float128=Float128(0)) {
        self.low=low
        self.medium=medium
        self.high=high
    }
    public init(_ eq:EQH) {
        self.low = Float128(eq.low)
        self.medium = Float128(eq.medium)
        self.high = Float128(eq.high)
    }
    public init() {
    }
}
public func ==(l:EQHD, r: EQHD) -> Bool {
    return l.high == r.high && l.medium == r.medium && l.low == r.low
}
public func !=(l:EQHD, r: EQHD) -> Bool {
    return l.high != r.high || l.medium != r.medium || l.low != r.low
}
public func +=(left:inout EQHD,right:EQHD) {
    left = left + right
}
public func -=(left:inout EQHD,right:EQHD) {
    left = left - right
}
public func +(l: EQHD, r: EQHD) -> EQHD {
    return EQHD(low: l.low+r.low, medium: l.medium+r.medium, high: l.high+r.high)
}
public func +(l: EQHD, r: Float128) -> EQHD {
    return EQHD(low: l.low+r, medium: l.medium+r, high: l.high+r)
}
public func -(l: EQHD, r: EQHD) -> EQHD {
    return EQHD(low: l.low-r.low, medium: l.medium-r.medium, high: l.high-r.high)
}
public func -(l: EQHD, r: Float128) -> EQHD {
    return EQHD(low: l.low-r, medium: l.medium-r, high: l.high-r)
}
public func *(l: EQHD, r: EQHD) -> EQHD {
    return EQHD(low: l.low*r.low, medium: l.medium*r.medium, high: l.high*r.high)
}
public func *(l: EQHD, r: Float128) -> EQHD {
    return EQHD(low: l.low*r, medium: l.medium*r, high: l.high*r)
}
 */
/*
public func /(l: EQHD, r: EQHD) -> EQHD {
    return EQHD(low: l.low/r.low, medium: l.medium/r.medium, high: l.high/r.high)
}
public func /(l: EQHD, r: Float128) -> EQH {
    return EQH(low: l.low/r, medium: l.medium/r, high: l.high/r)
}
*/
public struct EQH {
    public var low:Double=0
    public var medium:Double=0
    public var high:Double=0
    public init(low:Double=0,medium:Double=0,high:Double=0) {
        self.low=low
        self.medium=medium
        self.high=high
    }
    /*
    public init(_ eq:EQHD) {
        self.low = eq.low.doubleValue
        self.medium = eq.medium.doubleValue
        self.high = eq.high.doubleValue
    }
 */
    public init(_ eq:EQ) {
        self.low = Double(eq.low)
        self.medium = Double(eq.medium)
        self.high = Double(eq.high)
    }
    public init() {
    }
}
public func ==(l:EQH, r: EQH) -> Bool {
    return l.high == r.high && l.medium == r.medium && l.low == r.low
}
public func !=(l:EQH, r: EQH) -> Bool {
    return l.high != r.high || l.medium != r.medium || l.low != r.low
}
public func +=(left:inout EQH,right:EQH) {
    left = left + right
}
public func -=(left:inout EQH,right:EQH) {
    left = left - right
}
public func +(l: EQH, r: EQH) -> EQH {
    return EQH(low: l.low+r.low, medium: l.medium+r.medium, high: l.high+r.high)
}
public func +(l: EQH, r: Double) -> EQH {
    return EQH(low: l.low+r, medium: l.medium+r, high: l.high+r)
}
public func -(l: EQH, r: EQH) -> EQH {
    return EQH(low: l.low-r.low, medium: l.medium-r.medium, high: l.high-r.high)
}
public func -(l: EQH, r: Double) -> EQH {
    return EQH(low: l.low-r, medium: l.medium-r, high: l.high-r)
}
public func *(l: EQH, r: EQH) -> EQH {
    return EQH(low: l.low*r.low, medium: l.medium*r.medium, high: l.high*r.high)
}
public func *(l: EQH, r: Double) -> EQH {
    return EQH(low: l.low*r, medium: l.medium*r, high: l.high*r)
}
public func /(l: EQH, r: EQH) -> EQH {
    return EQH(low: l.low/r.low, medium: l.medium/r.medium, high: l.high/r.high)
}
public func /(l: EQH, r: Double) -> EQH {
    return EQH(low: l.low/r, medium: l.medium/r, high: l.high/r)
}
public struct EQ {
    public var low:Float=0
    public var medium:Float=0
    public var high:Float=0
    public init(low:Float=0,medium:Float=0,high:Float=0) {
        self.low=low
        self.medium=medium
        self.high=high
    }
    public init() {
    }
}
public func ==(l:EQ, r: EQ) -> Bool {
    return l.high == r.high && l.medium == r.medium && l.low == r.low
}
public func !=(l:EQ, r: EQ) -> Bool {
    return l.high != r.high || l.medium != r.medium || l.low != r.low
}
public func +=(left:inout EQ,right:EQ) {
    left = left + right
}
public func -=(left:inout EQ,right:EQ) {
    left = left - right
}
public func +(l: EQ, r: EQ) -> EQ {
    return EQ(low: l.low+r.low, medium: l.medium+r.medium, high: l.high+r.high)
}
public func +(l: EQ, r: Float) -> EQ {
    return EQ(low: l.low+r, medium: l.medium+r, high: l.high+r)
}
public func -(l: EQ, r: EQ) -> EQ {
    return EQ(low: l.low-r.low, medium: l.medium-r.medium, high: l.high-r.high)
}
public func -(l: EQ, r: Float) -> EQ {
    return EQ(low: l.low-r, medium: l.medium-r, high: l.high-r)
}
public func *(l: EQ, r: EQ) -> EQ {
    return EQ(low: l.low*r.low, medium: l.medium*r.medium, high: l.high*r.high)
}
public func *(l: EQ, r: Float) -> EQ {
    return EQ(low: l.low*r, medium: l.medium*r, high: l.high*r)
}
public func /(l: EQ, r: EQ) -> EQ {
    return EQ(low: l.low/r.low, medium: l.medium/r.medium, high: l.high/r.high)
}
public func /(l: EQ, r: Float) -> EQ {
    return EQ(low: l.low/r, medium: l.medium/r, high: l.high/r)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


