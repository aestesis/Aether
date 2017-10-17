//
//  Size.swift
//  Aether
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
import SwiftyJSON

#if os(macOS) || os(iOS) || os(tvOS)
    import CoreGraphics
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct Size :  CustomStringConvertible,JsonConvertible {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var width:Double
    public var height:Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var w:Double {
        get { return width; }
        set(w) { width=w; }
    }
    public var h:Double {
        get { return height; }
        set(h) { height=h; }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var ceil: Size {
        return Size(Foundation.ceil(width),Foundation.ceil(height))
    }
    public func crop(_ ratio:Double,margin:Double=0) -> Size {
        let dd = ratio
        let ds = self.ratio
        if ds>dd {
            let h=height-margin*2;
            let w=dd*h;
            return Size(w,h);
        } else {
            let w=width-margin*2;
            let h=w/dd;
            return Size(w,h);
        }
    }
    public func extend(_ border:Double) -> Size {
        return Size(width+border*2,height+border*2)
    }
    public func extend(w:Double,h:Double) -> Size {
        return Size(width+w*2,height+h*2)
    }
    public func extend(_ sz:Size) -> Size {
        return self + sz*2
    }
    public var int: SizeI {
        return SizeI(Int(width),Int(height))
    }
    public var floor: Size {
        return Size(Foundation.floor(width),Foundation.floor(height))
    }
    public var length: Double {
        return sqrt(width*width+height*height)
    }
    public func lerp(_ to:Size,coef:Double) -> Size {
        return Size(to.width*coef+width*(1-coef),to.height*coef+height*(1-coef))
    }
    public var normalize: Size {
        return Size(width/length,height/length)
    }
    public func point(_ px:Double,_ py:Double) -> Point {
        return Point(width*px,height*py)
    }
    public var point: Point {
        return Point(width,height)
    }
    public func point(px:Double,py:Double) -> Point {
        return Point(width*px,height*py)
    }
    public var ratio: Double {
        return width/height
    }
    public var round: Size {
        return Size(Foundation.round(width),Foundation.round(height))
    }
    public var rotate: Size {
        return Size(height,width)
    }
    public func scale(_ scale:Double) -> Size {
        return Size(width*scale,height*scale)
    }
    public func scale(_ w:Double,_ h:Double) -> Size {
        return Size(width*w,height*h)
    }
    public var surface:Double {
        return width*height;
    }
    public var transposed:Size {
        return Size(h,w)
    }
    public var description: String {
        return "{w:\(width),h:\(height)}"
    }
    public var json: JSON {
        return JSON([w:w,h:h])
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ s:CGSize) {
        width=Double(s.width)
        height=Double(s.height)
    }
    public init(_ s:SizeI) {
        width=Double(s.width)
        height=Double(s.height)
    }
    public init(_ p:PointI) {
        width=Double(p.x)
        height=Double(p.y)
    }
    public init(_ square:Double) {
        width=square;
        height=square;
    }
    public init(_ w:Double,_ h:Double) {
        width=w;
        height=h;
    }
    public init(_ w:Int,_ h:Int) {
        width=Double(w);
        height=Double(h);
    }
    public init(json: JSON) {
        if let w=json["width"].double {
            width=w
        } else if let w=json["w"].double {
            width=w
        } else {
            width=0;
        }
        if let h=json["height"].double {
            height=h
        } else if let h=json["h"].double {
            height=h
        } else {
            height=0;
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var system : CGSize {
        return CGSize(width:CGFloat(w),height: CGFloat(h))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero: Size {
        return Size(0,0)
    }
    public static var infinity: Size {
        return Size(Double.infinity,Double.infinity)
    }
    public static var unity: Size {
        return Size(1,1)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public func ==(lhs: Size, rhs: Size) -> Bool {
    return (lhs.width==rhs.width)&&(lhs.height==rhs.height);
}
public func !=(lhs: Size, rhs: Size) -> Bool {
    return (lhs.width != rhs.width)||(lhs.height != rhs.height);
}
public func +(lhs: Size, rhs: Size) -> Size {
    return Size((lhs.w+rhs.w),(lhs.h+rhs.h));
}
public func -(lhs: Size, rhs: Size) -> Size {
    return Size((lhs.w-rhs.w),(lhs.h-rhs.h));
}
public func *(lhs: Size, rhs: Size) -> Size {
    return Size((lhs.w*rhs.w),(lhs.h*rhs.h));
}
public func *(lhs: Size, rhs: Double) -> Size {
    return Size((lhs.w*rhs),(lhs.h*rhs));
}
public func /(lhs: Size, rhs: Size) -> Size {
    return Size((lhs.w/rhs.w),(lhs.h/rhs.h));
}
public func /(lhs: Size, rhs: Double) -> Size {
    return Size((lhs.w/rhs),(lhs.h/rhs));
}
public prefix func - (size: Size) -> Size {
    return Size(-size.w,-size.h)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct SizeI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var width:Int
    public var height:Int
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var w:Int {
        get { return width; }
        set(w) { width=w; }
    }
    public var h:Int {
        get { return height; }
        set(h) { height=h; }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var point: PointI {
        return PointI(x:width,y:height)
    }
    public var surface:Int {
        return width*height;
    }
    public var description: String {
        return "{w:\(width),h:\(height)}"
    }
    public var json: JSON {
        return JSON.parse(string: description)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ w:Int,_ h:Int) {
        width=w;
        height=h;
    }
    
    public init(json: JSON) {
        #if os(macOS) || os(iOS) || os(tvOS)
            if let w=json["width"].number {
                width=Int(truncating:w)
            } else if let w=json["w"].number {
                width=Int(truncating:w)
            } else {
                width=0;
            }
            if let h=json["height"].number {
                height=Int(truncating:h)
            } else if let h=json["h"].number {
                height=Int(truncating:h)
            } else {
                height=0;
            }
        #else
            if let w=json["width"].number {
                width=Int(w)
            } else if let w=json["w"].number {
                width=Int(w)
            } else {
                width=0;
            }
            if let h=json["height"].number {
                height=Int(h)
            } else if let h=json["h"].number {
                height=Int(h)
            } else {
                height=0;
            }
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero: SizeI {
        return SizeI(0,0)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public func ==(lhs: SizeI, rhs: SizeI) -> Bool {
    return (lhs.width==rhs.width)&&(lhs.height==rhs.height);
}
public func !=(lhs: SizeI, rhs: SizeI) -> Bool {
    return (lhs.width != rhs.width)||(lhs.height != rhs.height);
}
public func +(lhs: SizeI, rhs: SizeI) -> SizeI {
    return SizeI((lhs.w+rhs.w),(lhs.h+rhs.h));
}
public func -(lhs: SizeI, rhs: SizeI) -> SizeI {
    return SizeI((lhs.w-rhs.w),(lhs.h-rhs.h));
}
public func *(lhs: SizeI, rhs: SizeI) -> SizeI {
    return SizeI((lhs.w*rhs.w),(lhs.h*rhs.h));
}
public func *(lhs: SizeI, rhs: Int) -> SizeI {
    return SizeI((lhs.w*rhs),(lhs.h*rhs));
}
public func /(lhs: SizeI, rhs: SizeI) -> SizeI {
    return SizeI((lhs.w/rhs.w),(lhs.h/rhs.h));
}
public func /(lhs: SizeI, rhs: Int) -> SizeI {
    return SizeI((lhs.w/rhs),(lhs.h/rhs));
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
