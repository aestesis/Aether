//
//  Rect.swift
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
import SwiftyJSON

#if os(macOS) || os(iOS) || os(tvOS)
    import CoreGraphics
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct Rect : CustomStringConvertible,JsonConvertible  {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var origin: Point
    public var size: Size
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x: Double {
        get { return origin.x }
        set(x){ origin.x=x }
    }
    public var y: Double {
        get { return origin.y }
        set(y){ origin.y=y }
    }
    public var w: Double {
        get { return size.width }
        set(width){ size.width=width; }
    }
    public var h: Double {
        get { return size.height }
        set(height){ size.height=height; }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var width: Double {
        get { return size.width }
        set(width){ size.width=width; }
    }
    public var height: Double {
        get { return size.height }
        set(height){ size.height=height }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var left: Double {
        get { return x }
        set(l) { w+=x-l; x=l }
    }
    public var right: Double {
        get { return x+width }
        set(r) { width=r-x }
    }
    public var top: Double {
        get { return y }
        set(t) { h+=y-t; y=t }
    }
    public var bottom: Double {
        get { return y+height }
        set(b) { height=b-y }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var topLeft : Point {
        return Point(left,top)
    }
    public var topRight : Point {
        return Point(right,top)
    }
    public var bottomLeft : Point {
        return Point(left,bottom)
    }
    public var bottomRight : Point {
        return Point(right,bottom)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func intersect(_ r:Rect) -> Bool {
        return !(self.right < r.left || self.bottom < r.top || self.left > r.right || self.top > r.bottom)
    }
    public func intersection(_ r:Rect) -> Rect {
        var rr = Rect.zero
        rr.left = max(self.left,r.left)
        rr.right = min(self.right,r.right)
        rr.top = max(self.top,r.top)
        rr.bottom = min(self.bottom,r.bottom)
        if rr.w<=0 || rr.h<=0 {
            return Rect.zero
        }
        return rr
    }
    public func union(_ r:Rect) -> Rect {
        if self == Rect.zero {
            return r
        } else if r == Rect.zero {
            return self
        } else {
            var rr = Rect.zero
            rr.left = min(self.left,r.left)
            rr.right = max(self.right,r.right)
            rr.top = min(self.top,r.top)
            rr.bottom = max(self.bottom,r.bottom)
            return rr
        }
    }
    public func union(_ o:Point,_ s:Size=Size(1,1)) -> Rect {
        return self.union(Rect(o:o,s:s))
    }
    public func extend(_ border:Double) -> Rect {
        return Rect(o:Point(x-border,y-border),s:size.extend(border))
    }
    public func extend(w:Double,h:Double) -> Rect {
        return Rect(o:Point(x-w,y-h),s:size.extend(w:w,h:h))
    }
    public func extend(_ border:Size) -> Rect {
        return Rect(x:x-border.w,y:y-border.h,w:w+border.w*2,h:h+border.h*2)
    }
    public var bounds : Rect {
        return Rect(o:Point.zero,s:size)
    }
    public var ceil : Rect {
        return Rect(o:origin.floor,s:size.ceil)
    }
    public var center: Point {
        get { return origin+size.scale(0.5).point }
        set(c) { origin = c - size.scale(0.5).point }
    }
    public func clip(point p:Point) -> Point {
        return constrains(point:p)
    }
    public func contains(_ point:Point) -> Bool {
        return point.x>=left&&point.x<=right&&point.y>=top&&point.y<=bottom
    }
    public func constrains(point p: Point) -> Point {
        return Point(min(max(left,p.x),right),min(max(top,p.y),bottom))
    }
    public func crop(_ ratio:Double,align:Align=Align.fullCenter,margin:Double=0) -> Rect {
        let dd=ratio
        let ds=self.ratio
        var r=Rect.zero
        if ds>dd {
            let h=height-margin*2;
            let w=dd*h;
            r=Rect(x:x+(width-w)*0.5,y:y+margin,w:w,h:h);
        } else {
            let w=width-margin*2;
            let h=w/dd;
            r=Rect(x:x+margin, y:y+(height-h)*0.5,w:w,h:h);
        }
        switch(align.horizontalPart) {
        case .right:
            r.x = self.right-r.width
        case .left:
            r.x = self.x
        default:
            break
        }
        switch(align.verticalPart) {
        case .top:
            r.y = self.y
        case .bottom:
            r.y = self.bottom - r.height
        default:
            break
        }
        return r
    }
    public var description: String {
        return "{x:\(x),y:\(y),w:\(width),h:\(height)}"
    }
    public var diagonale : Double {
        return sqrt(width*width+height*height)
    }
    public func fit(_ ratio:Double,margin:Double=0) -> Rect {
        let dd=ratio
        let ds=self.ratio
        if ds<dd {
            let h=height-margin*2;
            let w=dd*h;
            return Rect(x:x+(width-w)*0.5,y:y+margin,w:w,h:h);
        } else {
            let w=width-margin*2;
            let h=w/dd;
            return Rect(x:x+margin,y:y+(height-h)*0.5,w:w,h:h);
        }
    }
    public func fit(rect r:Rect,align a:Align = .centerMiddle) -> Rect {
        let s=max(r.w/self.w,r.h/self.h)
        var rd = Rect(0,0,w*s,h*s)
        switch a.horizontalPart {
        case .right:
            rd.x = r.right - rd.width
        case.middle:
            rd.center.x = r.center.x
        default:
            break
        }
        switch a.verticalPart {
        case .bottom:
            rd.y = r.bottom - rd.height
        case .center:
            rd.center.y = r.center.y
        default:
            break
        }
        return rd
    }
    public func aligned(in r:Rect,align a:Align) -> Rect {
        var rd = self
        switch a.horizontalPart {
        case .right:
            rd.x = r.right - rd.width
        case.middle:
            rd.center.x = r.center.x
        default:
            break
        }
        switch a.verticalPart {
        case .bottom:
            rd.y = r.bottom - rd.height
        case .center:
            rd.center.y = r.center.y
        default:
            break
        }
        return rd
    }
    public var floor : Rect {
        return Rect(o:origin.ceil,s:size.floor)
    }
    public var int: RectI {
        return RectI(x:Int(x),y:Int(y),w:Int(width),h:Int(height))
    }
    public var json: JSON {
        return JSON(["x":x,"y":y,"w":w,"h":h])
    }
    public func lerp(_ to:Rect,coef:Double) -> Rect {
        return Rect(o:origin.lerp(to.origin,coef:coef),s:size.lerp(to.size,coef:coef))
    }
    public func percent(_ r:Rect) -> Rect {
        return Rect(x:x+width*r.x,y:y+height*r.y,w:width*r.w,h:height*r.h)
    }
    public func percent(_ px:Double=0,_ py:Double=0,_ pw:Double=1,_ ph:Double=1) -> Rect {
        return Rect(x:x+width*px,y:y+height*py,w:width*pw,h:height*ph)
    }
    public func percent(px:Double=0,py:Double=0,pw:Double=1,ph:Double=1) -> Rect {
        return Rect(x:x+width*px,y:y+height*py,w:width*pw,h:height*ph)
    }
    public func point(_ px:Double,_ py:Double) -> Point {
        return Point(x+width*px,y+height*py)
    }
    public func point(px:Double,py:Double) -> Point {
        return Point(x+width*px,y+height*py)
    }
    public func point(_ percent:Point) -> Point {
        return Point(x+width*percent.x,y+height*percent.y)
    }
    public func point(align:Align) -> Point {
        return self.point(align.point)
    }
    public var ratio : Double {
        return size.ratio
    }
    public var random : Point {
        return Point(x+width*ß.rnd,y+height*ß.rnd)
    }
    public var rotate : Rect {
        return Rect(x:y,y:x,w:height,h:width)
    }
    public var round : Rect {
        return Rect(o:origin.round,s:size.round)
    }
    public func scale(_ scale:Double) -> Rect {
        let sz=size.scale(scale)
        return Rect(origin:origin.translate(-0.5*(sz.width-width),-0.5*(sz.height-height)),size:sz)
    }
    public func scale(_ w:Double,_ h:Double) -> Rect {
        let sz=size.scale(w,h)
        return Rect(origin:origin.translate(-0.5*(sz.width-width),-0.5*(sz.height-height)),size:sz)
    }
    public func scale(_ w:Double,h:Double) -> Rect {
        let sz=size.scale(w,h)
        return Rect(origin:origin.translate(-0.5*(sz.width-width),-0.5*(sz.height-height)),size:sz)
    }
    public var square : Rect {
        let m=min(width,height)
        return Rect(x:x+(width-m)*0.5,y:y+(height-m)*0.5,w:m,h:m)
    }
    public var strip : [Point] {
        return [self.topLeft,self.bottomLeft,self.topRight,self.bottomRight]
    }
    public func strip(_ rotation:Rotation) -> [Point] {
        switch rotation {
        case .none:
            return [self.topLeft,self.bottomLeft,self.topRight,self.bottomRight]
        case .anticlockwise:
            return [self.topRight,self.topLeft,self.bottomRight,self.bottomLeft]
        case .clockwise:
            return [self.bottomLeft,self.bottomRight,self.topLeft,self.topRight]
        case .upSideDown:
            return [self.bottomLeft,self.topLeft,self.bottomRight,self.topRight]
        }
    }
    public var surface : Double {
        return size.surface
    }
    public func translate(x:Double,y:Double) -> Rect {
        return Rect(o:Point(origin.x+x,origin.y+y),s:size)
    }
    public func translate(_ point:Point) -> Rect {
        return Rect(o:Point(self.x+point.x,self.y+point.y),s:size)
    }
    public func wrap(_ p:Point) -> Point {
        return Point(x:ß.modulo(p.x-left,width)+left,y:ß.modulo(p.y-top,height)+top)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(_ r:CGRect) {
        self.origin=Point(r.origin)
        self.size=Size(r.size)
    }
    public init(_ r:RectI) {
        self.origin=Point(p:r.origin)
        self.size=Size(r.size)
    }
    public init(origin: Point,size: Size) {
        self.origin=origin
        self.size=size
    }
    public init(o: Point,s: Size) {
        self.origin=o
        self.size=s
    }
    public init(x:Double,y:Double,w:Double,h:Double)
    {
        origin=Point(x,y)
        size=Size(w,h)
    }
    public init(_ x:Double,_ y:Double,_ w:Double,_ h:Double)
    {
        origin=Point(x,y)
        size=Size(w,h)
    }
    public init(left:Double,top:Double,right:Double,bottom:Double) {
        origin=Point(left,top)
        size=Size(right-left,bottom-top)
    }
    public init(json: JSON) {
        origin=Point(json:json);
        size=Size(json:json);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var system : CGRect {
        return CGRect(origin: origin.system, size: size.system)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero: Rect {
        return Rect(o:Point.zero,s:Size.zero)
    }
    public static var infinity: Rect {
        return Rect(o:-Point.infinity,s:Size.infinity)
    }
    public static var unity: Rect {
        return Rect(o:Point.zero,s:Size.unity)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(lhs: Rect, rhs: Rect) -> Bool {
    return (lhs.origin==rhs.origin)&&(lhs.size==rhs.size)
}
public func !=(lhs: Rect, rhs: Rect) -> Bool {
    return (lhs.origin != rhs.origin)||(lhs.size != rhs.size)
}
public func +(lhs: Rect, rhs: Rect) -> Rect {
    return Rect(left:min(lhs.left,rhs.left),top:min(lhs.top,rhs.top),right:max(lhs.right,rhs.right),bottom:max(lhs.bottom,rhs.bottom))
}
public func +(lhs: Rect, rhs: Point) -> Rect {
    return Rect(left:min(lhs.left,rhs.x),top:min(lhs.top,rhs.y),right:max(lhs.right,rhs.x),bottom:max(lhs.bottom,rhs.y))
}
public func *(lhs: Rect, rhs: Size) -> Rect {
    return Rect(x:lhs.x*rhs.w,y:lhs.y*rhs.h,w:lhs.w*rhs.w,h:lhs.h*rhs.h)
}
public func /(lhs: Rect, rhs: Size) -> Rect {
    return Rect(x:lhs.x/rhs.w,y:lhs.y/rhs.h,w:lhs.w/rhs.w,h:lhs.h/rhs.h)
}
public func *(l:Rect,r:Double) -> Rect {
    return Rect(x:l.x*r,y:l.y*r,w:l.w*r,h:l.h*r)
}
public func /(l:Rect,r:Double) -> Rect {
    return Rect(x:l.x/r,y:l.y/r,w:l.w/r,h:l.h/r)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct RectI : CustomStringConvertible,JsonConvertible  {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var origin: PointI
    public var size: SizeI
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var x: Int {
        get { return origin.x }
        set(x){ origin.x=x }
    }
    public var y: Int {
        get { return origin.y }
        set(y){ origin.y=y }
    }
    public var w: Int {
        get { return size.width }
        set(width){ size.width=width; }
    }
    public var h: Int {
        get { return size.height }
        set(height){ size.height=height; }
    }
    public var width: Int {
        get { return size.width }
        set(width){ size.width=width; }
    }
    public var height: Int {
        get { return size.height }
        set(height){ size.height=height; }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var left: Int {
        get { return x }
        set { x=left; }
    }
    public var right: Int {
        get { return x+width }
        set { width=right-x }
    }
    public var top: Int {
        get { return y }
        set { y=top }
    }
    public var bottom: Int {
        get { return y+height }
        set { height=bottom-y }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var topleft : PointI {
        return PointI(x:left,y:top)
    }
    public var topright : PointI {
        return PointI(x:right,y:top)
    }
    public var bottomleft : PointI {
        return PointI(x:left,y:bottom)
    }
    public var bottomright : PointI {
        return PointI(x:right,y:bottom)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var description: String {
        return "{x:\(x),y:\(y),w:\(width),h:\(height)}"
    }
    public var json: JSON {
        return JSON([x:x,y:y,w:w,h:h])
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(origin: PointI,size: SizeI) {
        self.origin=origin;
        self.size=size;
    }
    public init(o: PointI,s: SizeI) {
        self.origin=o;
        self.size=s;
    }
    public init(x:Int,y:Int,w:Int,h:Int)
    {
        origin=PointI(x:x,y:y);
        size=SizeI(w,h);
    }
    public init(left:Int,top:Int,right:Int,bottom:Int) {
        origin=PointI(x:left,y:top)
        size=SizeI(right-left,bottom-top)
    }
    public init(json: JSON) {
        origin=PointI(json:json);
        size=SizeI(json:json);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var zero: RectI {
        return RectI(o:PointI.zero,s:SizeI.zero)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public func ==(lhs: RectI, rhs: RectI) -> Bool {
    return (lhs.origin==rhs.origin)&&(lhs.size==rhs.size);
}
public func +(lhs: RectI, rhs: RectI) -> RectI {
    return RectI(left:min(lhs.left,rhs.left),top:min(lhs.top,rhs.top),right:max(lhs.right,rhs.right),bottom:max(lhs.bottom,rhs.bottom))
}
public func +(lhs: RectI, rhs: PointI) -> RectI {
    return RectI(left:min(lhs.left,rhs.x),top:min(lhs.top,rhs.y),right:max(lhs.right,rhs.x),bottom:max(lhs.bottom,rhs.y))
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
