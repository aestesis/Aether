//
//  Vector.swift
//  Alib
//
//  Created by renan jegouzo on 25/02/2016.
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
import SwiftyJSON

#if os(macOS) || os(iOS) || os(tvOS)
    import MetalKit
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct Vec4 : CustomStringConvertible,JsonConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x: Double    // // TODO: replace by MetalKit.double4 if metal
    public var y: Double
    public var z: Double
    public var w: Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var xyz: Vec3 {
        get { return Vec3(x:x,y:y,z:z) }
        set(v) {
            x=v.x
            y=v.y
            z=v.z
        }
    }
    public var description: String {
        return "{x:\(x),y:\(y),z:\(z),w:\(w)}"
    }
    public var infloat4 : float4 {
        return float4([Float(x),Float(y),Float(z),Float(w)])
    }
    public var indouble4 : double4 {
        return double4([x,y,z,w])
    }
    public var json : JSON {
        return JSON([x:x,y:y,z:z,w:w])
    }
    public var length : Double {
        return sqrt(x*x+y*y+z*z+w*w)
    }
    public func lerp(vector v:Vec4,coef c:Double) -> Vec4 {
        let ic=1-c
        return Vec4(x:ic*x+c*v.x,y:ic*y+c*v.y,z:ic*z+c*v.z,w:ic*w+c*v.w)
    }
    public var normalized : Vec4 {
        return self/length
    }
    public func transform(_ m:Mat4) -> Vec4 {
        return Vec4(x: x * m.r0.x + y * m.r1.x + z * m.r2.x + w * m.r3.x, y: x * m.r0.y + y * m.r1.y + z * m.r2.y + w * m.r3.y, z: x * m.r0.z + y * m.r1.z + z * m.r2.z + w * m.r3.z, w: x * m.r0.w + y * m.r1.w + z * m.r2.w + w * m.r3.w)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(x:Double=0,y:Double=0,z:Double=0,w:Double=0) {
        self.x=x
        self.y=y
        self.z=z
        self.w=w
    }
    public init(xyz:Vec3,w:Double=0) {
        self.x=xyz.x
        self.y=xyz.y
        self.z=xyz.z
        self.w=w
    }
    public init(json:JSON) {
        if let x=json["x"].double {
            self.x=x
        } else {
            self.x=0
        }
        if let y=json["y"].double {
            self.y=y
        } else {
            self.y=0
        }
        if let z=json["z"].double {
            self.z=z
        } else {
            self.z=0
        }
        if let w=json["w"].double {
            self.w=w
        } else {
            self.w=0
        }
    }
    public init(_ f:float4) {
        self.x = Double(f.x)
        self.y = Double(f.y)
        self.z = Double(f.z)
        self.w = Double(f.w)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func dot(_ v:Vec4,w:Vec4) -> Double {
        return v.x*w.x+v.y*w.y+v.z*w.z+v.w*v.w
    }
    public static var zero:Vec4 {
        return Vec4()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public subscript(col: Int) -> Double {
        get {
            switch col {
            case 1:
                return y
            case 2:
                return z
            case 3:
                return w
            default:
                return x
            }
        }
        set(v) {
            switch col {
            case 1:
                y=v
            case 2:
                z=v
            case 3:
                w=v
            default:
                x=v
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(a: Vec4, b: Vec4) -> Bool {
    return a.x==b.x&&a.y==b.y&&a.z==b.z&&a.w==b.w
}
public func !=(a: Vec4, b: Vec4) -> Bool {
    return a.x != b.x || a.y != b.y || a.z != b.z || a.w != b.w
}
public prefix func - (v: Vec4) -> Vec4 {
    return Vec4(x:-v.x,y:-v.y,z:-v.z,w:-v.w)
}
public func +(a:Vec4,b:Vec4)->Vec4 {
    return Vec4(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z,w:a.w+b.w)
}
public func -(a:Vec4,b:Vec4)->Vec4 {
    return Vec4(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z,w:a.w-b.w)
}
public func *(a:Vec4,b:Vec4)->Vec4 {
    return Vec4(x:a.x*b.x,y:a.y*b.y,z:a.z*b.z,w:a.w*b.w)
}
public func *(a:Vec4,b:Double)->Vec4 {
    return Vec4(x:a.x*b,y:a.y*b,z:a.z*b,w:a.w*b)
}
public func /(a:Vec4,b:Vec4)->Vec4 {
    return Vec4(x:a.x/b.x,y:a.y/b.y,z:a.z/b.z,w:a.w/b.w)
}
public func /(a:Vec4,b:Double)->Vec4 {
    return Vec4(x:a.x/b,y:a.y/b,z:a.z/b,w:a.w/b)
} 
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Vec3 : CustomStringConvertible,JsonConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x: Double
    public var y: Double
    public var z: Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var xyzw: Vec4 {
        return Vec4(xyz:self)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func clamp(min vmin:Vec3,max vmax:Vec3) -> Vec3 {
        return Vec3(x:min(vmax.x,max(vmin.x,x)),y:min(vmax.y,max(vmin.y,y)),z:min(vmax.z,max(vmin.z,z)))
    }
    public var description: String {
        return "{x:\(x),y:\(y),z:\(z)}"
    }
    public var infloat3 : float3 {
        return float3([Float(x),Float(y),Float(z)])
    }
    public var json : JSON {
        return JSON.parse(string: description)
    }
    public var length : Double {
        return sqrt(x*x+y*y+z*z)
    }
    public func lerp(vector v:Vec3,coef c:Double) -> Vec3 {
        let ic=1-c
        return Vec3(x:ic*x+c*v.x,y:ic*y+c*v.y,z:ic*z+c*v.z)
    }
    public var normalized : Vec3 {
        return self/length
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ r:Rot3) {
        self.init(phi:r.phi,theta:r.theta)
    }
    public init(_ p:Point,z:Double=0) {
        self.x=p.x
        self.y=p.y
        self.z=z
    }
    public init(x:Double=0,y:Double=0,z:Double=0) {
        self.x=x
        self.y=y
        self.z=z
    }
    public init(phi:Double,theta:Double) {
        self.x=cos(phi)*sin(theta)
        self.y=sin(phi)*sin(theta)
        self.z=cos(theta)
    }
    public init(json:JSON) {
        if let x=json["x"].double {
            self.x=x
        } else {
            self.x=0
        }
        if let y=json["y"].double {
            self.y=y
        } else {
            self.y=0
        }
        if let z=json["z"].double {
            self.z=z
        } else {
            self.z=0
        }
    }
    public init(_ v:float3) {
        self.x = Double(v.x)
        self.y = Double(v.y)
        self.z = Double(v.z)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func angle(_ l:Vec3,_ r:Vec3) -> Double {
        return acos(Vec3.dot(l,r))
    }
    public static func cross(_ l:Vec3,_ r:Vec3) -> Vec3 {
        return Vec3(x:l.y*r.z-l.z*r.y,y:l.z*r.x-l.x*r.z,z:l.x*r.y-l.y*r.x)
    }
    public static func dot(_ v0:Vec3,_ v1:Vec3) -> Double {
        return v0.x*v1.x+v0.y*v1.y+v0.z*v1.z
    }
    public static var zero:Vec3 {
        return Vec3()
    }
    public static var infinity:Vec3 {
        return Vec3(x:Double.infinity,y:Double.infinity,z:Double.infinity)
    }
    public static var unity:Vec3 {
        return Vec3(x:1,y:1,z:1)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public subscript(col: Int) -> Double {
        get {
            switch col {
            case 1:
                return y
            case 2:
                return z
            default:
                return x
            }
        }
        set(v) {
            switch col {
            case 1:
                y=v
            case 2:
                z=v
            default:
                x=v
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public func ==(a: Vec3, b: Vec3) -> Bool {
    return a.x==b.x&&a.y==b.y&&a.z==b.z
}
public func !=(a: Vec3, b: Vec3) -> Bool {
    return a.x != b.x || a.y != b.y || a.z != b.z
}
public prefix func -(v: Vec3) -> Vec3 {
    return Vec3(x:-v.x,y:-v.y,z:-v.z)
}
public func +(a:Vec3,b:Vec3)->Vec3 {
    return Vec3(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z)
}
public func +(a:Vec3,b:Point)->Vec3 {
    return Vec3(x:a.x+b.x,y:a.y+b.y,z:a.z)
}
public func -(a:Vec3,b:Vec3)->Vec3 {
    return Vec3(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z)
}
public func *(a:Vec3,b:Vec3)->Vec3 {
    return Vec3(x:a.x*b.x,y:a.y*b.y,z:a.z*b.z)
}
public func *(a:Vec3,b:Double)->Vec3 {
    return Vec3(x:a.x*b,y:a.y*b,z:a.z*b)
}
public func /(a:Vec3,b:Vec3)->Vec3 {
    return Vec3(x:a.x/b.x,y:a.y/b.y,z:a.z/b.z)
}
public func /(a:Vec3,b:Double)->Vec3 {
    return Vec3(x:a.x/b,y:a.y/b,z:a.z/b)
}
public func ^(a:Vec3,b:Vec3)->Vec3 {
    return Vec3.cross(a,b)
}
public func +=(a:inout Vec3,b:Vec3) {
    a = a + b
}
public func -=(a:inout Vec3,b:Vec3) {
    a = a - b
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
