//
//  Signal.swift
//  Alib
//
//  Created by renan jegouzo on 22/04/2016.
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
public struct Signal {  // perfect number 0...1
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var value:Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ value:Double) {
        self.value = value
    }
    public static func realTime(frequency:Double,phase:Double=0) -> Signal {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(Darwin.sin(ß.time*frequency*ß.π*2+phase)*0.5+0.5)  
        #else
            return Signal(Glibc.sin(ß.time*frequency*ß.π*2+phase)*0.5+0.5)
        #endif
    }
    public static func realTime(period:Double) -> Signal {
        
        return Signal(((ß.time*period).truncatingRemainder(dividingBy: 1.0)+1).truncatingRemainder(dividingBy: 1))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func begin(_ begin:Double) -> Signal {
        return self.range(begin: begin, end: 1-begin)
    }
    public var bounce : Signal {
        return Signal((value<0.5) ? value*2 : (1-value)*2)
    }
    public func elastic(_ amplitude:Double=0.1,period p:Double=0.3) -> Signal {   // TODO: check it, must be buggy
        if value<=0 {
            return Signal(0)
        } else if value >= 1 {
            return Signal(1)
        }
        var a = amplitude
        var s = 1.73
        let v = value * 2
        if a<1 {
            a = 1
            s = p/4
        } else {
            s = p / 2+ß.π * asin(1/a)
        }
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(Darwin.pow(2,-10*v)*Darwin.sin((v-s)*2*ß.π/p)+1)
        #else
            return Signal(Glibc.pow(2,-10*v)*Glibc.sin((v-s)*2*ß.π/p)+1)
        #endif
    }
    public var exp:Signal {
        if value>=1 {
            return self
        }
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(-Darwin.pow(2,-10*value) + 1)
        #else
            return Signal(-Glibc.pow(2,-10*value) + 1)
        #endif
    }
    public func length(_ length:Double) -> Signal {
        return self.range(begin:0, length: length)
    }
    public func loop(_ n:Double) -> Signal {
        return Signal((value*n).truncatingRemainder(dividingBy: 1))
    }
    public func midPow(_ p:Double) -> Signal {
        if value<0.5 {
            return Signal(Signal(value*2).pow(p).value*0.5)
        } else {
            return Signal(1-Signal((1-value)*2).pow(p).value*0.5)
        }
    }
    public func pow(_ p:Double) -> Signal {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(Darwin.pow(value,p))
        #else
            return Signal(Glibc.pow(value,p))
        #endif
    }
    public func range(begin:Double,length:Double) -> Signal {
        let v=min(max(value,begin),begin+length)
        return Signal((v-begin)/length)
    }
    public func range(begin:Double,end:Double) -> Signal {
        let v=min(max(value,begin),end)
        return Signal((v-begin)/(end-begin))
    }
    public var rotation : Double {
        return value * ß.π * 2
    }
    static func saturate(_ v:Double) -> Double {
        return min(max(v,0),1)
    }
    public var sin : Signal {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(Darwin.sin(ß.π*value-ß.π2)*0.5+0.5)
        #else
            return Signal(Glibc.sin(ß.π*value-ß.π2)*0.5+0.5)
        #endif
    }
    public var square : Signal {
        return Signal(value<0.5 ? 0 : 1)
    }
    public func tremolo(_ frequency:Double,amplitude:Double) -> Signal {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Signal(Signal.saturate(value+Darwin.sin(rotation+frequency)*amplitude))
        #else
            return Signal(Signal.saturate(value+Glibc.sin(rotation+frequency)*amplitude))
        #endif
    }
    public var revers : Signal {
        return Signal(1-value)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func lerp(from:Double,to:Double) -> Double {
        return from + (to-from) * value
    }
    public func lerp(from:Point,to:Point) -> Point {
        return from.lerp(to, coef: value)
    }
    public func lerp(from:Size,to:Size) -> Size {
        return from.lerp(to, coef: value)
    }
    public func lerp(from:Rect,to:Rect) -> Rect {
        return from.lerp(to, coef: value)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum Ease {
        case none
        case linear
        case quad
        case cubic
        case quart
        case quint
        case smooth
        case elastic
        case exp
        case circular
        case sin
    }
    public func easeOut(_ ease:Ease) -> Signal {
        switch ease {
        case .none:
            Debug.notImplemented()
            break
        case .linear:
            return self
        case .quad:
            return Signal(-value*(value*2))
        case .cubic:
            let v=value-1
            return Signal(v*v*v+1)
        case .quart:
            let v=value-1
            return Signal(-(v*v*v*v-1))
        case .quint:
            let v=value-1
            return Signal(0.5*(v*v*v*v*v+2))
        case .smooth:
            return self.pow(0.5)
        case .elastic:
            return self.elastic()
        case .exp:
            return self.exp
        case .circular:
            let v=value-1
            return Signal(sqrt((1-v*v)))
        case .sin:
            #if os(macOS) || os(iOS) || os(tvOS)
                return Signal(Darwin.sin(value*ß.π2))
            #else
                return Signal(Glibc.sin(value*ß.π2))
            #endif
        }
        return self
    }
    public func easeIn(_ ease:Ease) -> Signal {
        return self.revers.easeOut(ease).revers
    }
    public func ease(_ i:Ease,o:Ease,blend:Double=0) -> Signal {
        if o == .none {
            return self.easeIn(i)
        }
        if i == .none {
            return self.easeOut(o)
        }
        if blend != 0 {
            let min = 0.5 - blend * 0.5
            let max = 0.5 + blend * 0.5
            let vin = value / max
            let vout = (value-min) / max
            let vblend = (value-min) / blend
            if vblend<0 {
                return Signal(Signal(vin).easeIn(i).value*max)
            } else if vblend > 1 {
                return Signal(Signal(vout).easeOut(o).value*max+min)
            }
            return Signal( (Signal(vin).easeIn(i).value*max)*(1-vblend) + (Signal(vout).easeOut(o).value*max+min)*vblend )
        }
        let vin=value*2
        let vout=value*2-1
        if vout<0 {
            return Signal(Signal(vin).easeIn(i).value*0.5)
        }
        return Signal(Signal(vout).easeOut(o).value*0.5+0.5)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO/
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
