//
//  Decimal.swift
//  Alib
//
//  Created by renan jegouzo on 17/09/2016.
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
import Swift

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: not implemented, do it!
// example: http://stackoverflow.com/questions/18492674/16bit-float-multiplication-in-c
// doc: http://www.rfwireless-world.com/Tutorials/floating-point-tutorial.html
// https://www.cs.umd.edu/class/sum2003/cmsc311/Notes/BinMath/multFloat.html
// https://www.cs.umd.edu/class/sum2003/cmsc311/Notes/BinMath/addFloat.html

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct Float128 {
    // TODO: complete Float128 struct
    static let bitM:UInt64 = 0x8000000000000000
    var n:Bool       // value = n(-) * 1.m * 2^e
    var e:Int32
    var m:UInt64
    public init() {
        n = false
        e = 0
        m = 0
    }
    public init(_ value:Double) {
        Debug.assert(Double.radix==2)
        if value != 0 {
            self.n = (value.sign == .minus)
            self.e = Int32(value.exponent) - 63
            self.m = Float128.bitM + value.significandBitPattern << (UInt64(63-52))
            self.normalize()
        } else {
            n = false
            e = 0
            m = 0
        }
    }
    public init(_ value:Int) {
        if value>=0 {
            n = false
            e = 0
            m = UInt64(value)
        } else {
            n = true
            e = 0
            m = UInt64(-value)
        }
        self.normalize()
    }
    public init(mantissa:UInt64,exponent:Int32,negative:Bool) {
        self.n = negative
        self.e = exponent
        self.m = mantissa
        self.normalize()
    }
    public var abs : Float128 {
        return Float128(mantissa:m,exponent:e,negative:false)
    }
    public var doubleValue : Double {
        if n {
            return -pow(2.0,Double(e)) * Double(m)
        } else {
            return pow(2.0,Double(e)) * Double(m)
        }
    }
    mutating func normalize() {
        if m != 0 {
            while (m & Float128.bitM) == 0 {
                m <<= 1
                e -= 1
            }
        } else {
            e = 0
            n = false
        }
    }
}
public func ==(l:Float128,r:Float128) -> Bool {
    return l.m == r.m && l.e == r.e && l.n == r.n
}
public func !=(l:Float128,r:Float128) -> Bool {
    return (l.m != r.m) || (l.e != r.e) || (l.n != r.n)
}
public func *(l:Float128,r:Float128) -> Float128 {  // TODO: multiplication based on UInt128
    let m = mul128(l.m,r.m).h
    let e = l.e + r.e + Int32(64)
    let n = (l.n != r.n)    // xor
    return Float128(mantissa: m, exponent: e, negative: n)
}
func mul128(_ x:UInt64,_ y:UInt64) -> (h:UInt64,l:UInt64) {  // from: http://www.edaboard.com/thread253439.html
    let xl = x & UInt64(0xffffffff)
    let xh = x >> UInt64(32)
    let yl = y & UInt64(0xffffffff)
    let yh = y >> UInt64(32)
    let xlyl = xl*yl
    let xhyl = xh*yl
    let xlyh = xl*yh
    let xhyh = xh*yh
    var l = xlyl & 0xffffffff
    var h = (xlyl>>32)+(xhyl & 0xffffffff)+(xlyh & 0xffffffff)
    l += (h & 0xffffffff) << 32
    h >>= 32
    h += (xhyl>>32)+(xlyh>>32)+xhyh
    return (h:h,l:l)
}
public func +(l:Float128,r:Float128) -> Float128 {
    var a = l
    var b = r
    if a.m == 0 {
        return b
    }
    if b.m == 0 {
        return a
    }
    if a.e>b.e {
        let d = a.e-b.e
        if d>=64 {
            return a
        }
        b.m = (b.m >> UInt64(d))
        b.e = a.e
    } else {
        let d = b.e-a.e
        if d>=64 {
            return b
        }
        a.m = (a.m >> UInt64(d))
        a.e = b.e
    }
    if a.n == b.n {
        var e = a.e
        let mr = UInt64.addWithOverflow(a.m,b.m)
        var m = mr.0
        if mr.overflow {
            m =  (Float128.bitM | (mr.0 >> 1))
            e += 1
        }
        return Float128(mantissa:m,exponent:e,negative:a.n)
    } else if b.n {
        let mr = UInt64.subtractWithOverflow(a.m,b.m)
        var m:UInt64 = 0
        var n:Bool = false
        if mr.overflow {
            n = true
            m = ~mr.0
        } else {
            m = mr.0    // TODO: check if need a ~
        }
        return Float128(mantissa:m,exponent:a.e,negative:n)
    } else {
        let mr = UInt64.subtractWithOverflow(b.m,a.m)
        var m:UInt64 = 0
        var n:Bool = false
        if mr.overflow {
            n = true
            m = ~mr.0
        } else {
            m = mr.0    // TODO: check if need a ~
        }
        return Float128(mantissa:m,exponent:a.e,negative:n)
    }
}
public func -(l:Float128,r:Float128) -> Float128 {
    return l+Float128(mantissa:r.m,exponent:r.e,negative:!r.n)
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Float256 {
    // TODO: complete Float256 struct
    static let bitM:UInt64 = 0x8000000000000000
    static let hp = pow(Double(2),Double(64))
    var n:Bool       // value = n(-) * 1.m * 2^e
    var e:Int32
    var m:UInt128
    public init() {
        n = false
        e = 0
        m = UInt128(0)
    }
    public init(_ value:Double) {
        Debug.assert(Double.radix==2)
        if value != 0 {
            n = (value.sign == .minus)
            e = Int32(value.exponent) - 127
            m = UInt128(upperBits:Float256.bitM + value.significandBitPattern << (UInt64(63-52)),lowerBits:0)
            self.normalize()
        } else {
            n = false
            e = 0
            m = UInt128(0)
        }
    }
    public init(_ value:Int) {
        if value>=0 {
            n = false
            e = -64
            m = UInt128(upperBits:UInt64(value),lowerBits:0)
        } else {
            n = true
            e = 0
            m = UInt128(upperBits:UInt64(-value),lowerBits:0)
        }
        self.normalize()
    }
    public init(mh:UInt64,ml:UInt64,exponent:Int32,negative:Bool) {
        self.n = negative
        self.e = exponent
        self.m = UInt128(upperBits:mh,lowerBits:ml)
        self.normalize()
    }
    public init(m:UInt128,exponent:Int32,negative:Bool) {
        self.n = negative
        self.e = exponent
        self.m = m
        self.normalize()
    }
    public var abs : Float256 {
        return Float256(m:m,exponent:e,negative:false)
    }
    public var doubleValue : Double {
        if n {
            return -pow(2.0,Double(e)) * (Double(m.value.upperBits) * Float256.hp + Double(m.value.lowerBits))
        } else {
            return pow(2.0,Double(e)) * (Double(m.value.upperBits) * Float256.hp + Double(m.value.lowerBits))
        }
    }
    mutating func normalize() {
        if m.value.upperBits == 0 && m.value.lowerBits == 0 {
            e = 0
            n = false
        } else {
            while (m.value.upperBits & Float256.bitM) == 0 {
                m <<= 1
                e -= 1
            }
        }
    }
}
public func ==(l:Float256,r:Float256) -> Bool {
    return l.m == r.m && l.e == r.e && l.n == r.n
}
public func !=(l:Float256,r:Float256) -> Bool {
    return l.m != r.m || l.e != r.e || l.n != r.n
}
public func *(l:Float256,r:Float256) -> Float256 {
    let m = mul256((h:l.m.value.upperBits,l:l.m.value.lowerBits),(h:r.m.value.upperBits,l:r.m.value.lowerBits))
    let e = l.e + r.e + Int32(128)
    let n = (l.n != r.n)
    return Float256(mh:m.h,ml:m.l,exponent:e,negative: n)
}

func mul256(_ x:(h:UInt64,l:UInt64),_ y:(h:UInt64,l:UInt64)) -> (h:UInt64,l:UInt64,overflow:Bool) {  // from: http://www.edaboard.com/thread253439.html
    let xlyl = mul128(x.l,y.l)
    let xhyl = mul128(x.h,y.l)
    let xlyh = mul128(x.l,y.h)
    let xhyh = mul128(x.h,y.h)
    
    var sum:(h:UInt64,l:UInt64) = (h:0,l:0)
    var o=UInt64.addWithOverflow(xlyl.h, xhyl.l)
    if o.overflow {
        sum.l += 1
    }
    o=UInt64.addWithOverflow(o.0, xlyh.l)
    if o.overflow {
        sum.l += 1
    }
    o=UInt64.addWithOverflow(sum.l, xlyl.h)
    if o.overflow {
        sum.h += 1
    }
    o=UInt64.addWithOverflow(o.0, xlyh.h)
    if o.overflow {
        sum.h += 1
    }
    o=UInt64.addWithOverflow(o.0, xhyh.l)
    if o.overflow {
        sum.h += 1
    }
    sum.l = o.0
    o=UInt64.addWithOverflow(sum.h, xhyh.h)
    sum.h = o.0
    return (h:sum.h,l:sum.l,overflow:o.overflow)
}
public func +(l:Float256,r:Float256) -> Float256 {
    var a = l
    var b = r
    if a.m == 0 {
        return b
    }
    if b.m == 0 {
        return a
    }
    if a.e>b.e {
        let d = a.e-b.e
        if d>=128 {
            return a
        }
        b.m = b.m >> UInt128(Int(d))
        b.e = a.e
    } else {
        let d = b.e-a.e
        if d>=64 {
            return b
        }
        a.m = a.m >> UInt128(Int(d))
        a.e = b.e
    }
    if a.n == b.n {
        var e = a.e
        let mr = UInt128.addWithOverflow(a.m, b.m)
        var m = mr.0
        if mr.overflow {
            m = (mr.0 >> 1)
            m.value.upperBits |= Float256.bitM
            e += 1
        }
        return Float256(m:m,exponent:e,negative:a.n)
    } else if b.n {
        let mr = UInt128.subtractWithOverflow(a.m,b.m)
        var m = mr.0
        var n = false
        if mr.overflow {
            n = true
            m = ~mr.0
        } else {
            m = mr.0
        }
        return Float256(m:m,exponent:a.e,negative:n)
    } else {
        let mr = UInt128.subtractWithOverflow(b.m,a.m)
        var m = mr.0
        var n:Bool = false
        if mr.overflow {
            n = true
            m = ~mr.0
        }
        return Float256(m:m,exponent:a.e,negative:n)
    }
}
public func -(l:Float256,r:Float256) -> Float256 {
    return l+Float256(m:r.m,exponent:r.e,negative:!r.n)
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


