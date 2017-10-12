//
//  Point.swift
//  Alib
//
//  Created by renan jegouzo on 23/02/2016.
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
    import MetalKit
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Point : CustomStringConvertible,JsonConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x:Double;
    public var y:Double;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var ceil: Point {
        return Point(Foundation.ceil(self.x),Foundation.ceil(y))
    }
    public var description : String {
        return "{x:\(x),y:\(y)}"
    }
    public var floor: Point {
        return Point(Foundation.floor(self.x),Foundation.floor(y))
    }
    public var int: PointI {
        return PointI(x:Int(x),y:Int(y))
    }
    public var infloat2 : float2 {
        return float2([Float(x),Float(y)])
    }
    public var infloat3 : float3 {
        return float3([Float(x),Float(y),0])
    }
    public var length:Double {
        return sqrt(x*x+y*y);
    }
    public func lerp(_ to:Point,coef:Double) -> Point {
        return Point(to.x*coef+x*(1-coef),to.y*coef+y*(1-coef))
    }
    public func lerp(_ to:Point,coef:Signal) -> Point {
        return self.lerp(to,coef:coef.value)
    }
    public var normalize:Point {
        return Point(x/length,y+length)
    }
    public func rect(w:Double,h:Double) -> Rect {
        return Rect(x:x-w*0.5,y:y-h*0.5,w:w,h:h)
    }
    public func rect(_ s:Size) -> Rect {
        return Rect(x:x-s.w*0.5,y:y-s.h*0.5,w:s.w,h:s.h)
    }
    public var round: Point {
        return Point(Foundation.round(self.x),Foundation.round(y))
    }
    public var json: JSON {
        return JSON(["x":x,"y":y])
    }
    public var size: Size {
        return Size(x,y)
    }
    public func translate(_ x:Double,_ y:Double) -> Point {
        return Point(self.x+x,self.y+y)
    }
    public func translate(_ point:Point) -> Point {
        return Point(self.x+point.x,self.y+point.y)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ p:Vec3) {
        self.x=Double(p.x);
        self.y=Double(p.y);
    }
    public init(_ p:CGPoint) {
        self.x=Double(p.x);
        self.y=Double(p.y);
    }
    public init(_ p:PointI) {
        self.x=Double(p.x);
        self.y=Double(p.y);
    }
    public init(_ x:Double=0,_ y:Double=0) {
        self.x=x
        self.y=y
    }
    public init(x:Double=0,y:Double=0) {
        self.x=x
        self.y=y
    }
    public init(_ p:Point) {
        self.x=p.x
        self.y=p.y
    }
    public init(p:PointI) {
        self.x=Double(p.x)
        self.y=Double(p.y)
    }
    public init(angle:Double,radius:Double=1) {
        x=cos(angle)*radius
        y=sin(angle)*radius
    }
    public init(json: JSON) {
        if let jx=json["x"].double {
            x=jx
        } else {
            x=0
        }
        if let jy=json["y"].double {
            y=jy
        } else {
            y=0
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var system : CGPoint {
        return CGPoint(x:CGFloat(x),y:CGFloat(y))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero:Point=Point(0,0)
    public static var unity:Point=Point(1,1)
    public static var infinity:Point=Point(Double.infinity,Double.infinity)
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(lhs:Point, rhs: Point) -> Bool {
    return (lhs.x==rhs.x)&&(lhs.y==rhs.y)
}
public func !=(lhs:Point, rhs: Point) -> Bool {
    return (lhs.x != rhs.x)||(lhs.y != rhs.y)
}
public func +=(left:inout Point,right:Point) {
    left = left + right
}
public func -=(left:inout Point,right:Point) {
    left = left - right
}
public func +(lhs: Point, rhs: Point) -> Point {
    return Point((lhs.x+rhs.x),(lhs.y+rhs.y))
}
public func -(lhs: Point, rhs: Point) -> Point {
    return Point((lhs.x-rhs.x),(lhs.y-rhs.y))
}
public prefix func -(lhs: Point) -> Point {
    return Point(-lhs.x,-lhs.y)
}
public func *(lhs: Point, rhs: Point) -> Point {
    return Point((lhs.x*rhs.x),(lhs.y*rhs.y))
}
public func *(lhs: Point, rhs: Double) -> Point {
    return Point((lhs.x*rhs),(lhs.y*rhs))
}
public func /(lhs: Point, rhs: Point) -> Point {
    return Point((lhs.x/rhs.x),(lhs.y/rhs.y))
}
public func /(lhs: Point, rhs: Double) -> Point {
    return Point((lhs.x/rhs),(lhs.y/rhs))
}
public func *(lhs: Point, rhs: Size) -> Point {
    return Point((lhs.x*rhs.w),(lhs.y*rhs.h))
}
public func /(lhs: Point, rhs: Size) -> Point {
    return Point((lhs.x/rhs.w),(lhs.y/rhs.h))
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct PointI : CustomStringConvertible,JsonConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x:Int
    public var y:Int
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var description : String {
        return "{x:\(x),y:\(y)}"
    }
    public var json: JSON {
        return JSON([x:x,y:y])
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ x:Int,_ y:Int) {
        self.x=x;
        self.y=y;
    }
    public init(x:Int=0,y:Int=0) {
        self.x=x;
        self.y=y;
    }
    public init(json: JSON) {
        x = json["x"].intValue
        y = json["y"].intValue
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero:PointI=PointI(x:0,y:0);
    public static var unity:PointI=PointI(x:1,y:1);
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public func ==(lhs: PointI, rhs: PointI) -> Bool {
    return (lhs.x==rhs.x)&&(lhs.y==rhs.y);
}
public func +(lhs: PointI, rhs: PointI) -> PointI {
    return PointI(x:(lhs.x+rhs.x),y:(lhs.y+rhs.y));
}
public func -(lhs: PointI, rhs: PointI) -> PointI {
    return PointI(x:(lhs.x-rhs.x),y:(lhs.y-rhs.y));
}
public func *(lhs: PointI, rhs: PointI) -> PointI {
    return PointI(x:(lhs.x*rhs.x),y:(lhs.y*rhs.y));
}
public func *(lhs: PointI, rhs: Int) -> PointI {
    return PointI(x:(lhs.x*rhs),y:(lhs.y*rhs));
}
public func /(lhs: PointI, rhs: PointI) -> PointI {
    return PointI(x:(lhs.x/rhs.x),y:(lhs.y/rhs.y));
}
public func /(lhs: PointI, rhs: Int) -> PointI {
    return PointI(x:(lhs.x/rhs),y:(lhs.y/rhs));
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


