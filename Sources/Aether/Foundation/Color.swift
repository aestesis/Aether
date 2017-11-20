//
//  Color.swift
//  Aether
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

public struct Color : CustomStringConvertible,JsonConvertible {
    // http://www.easyrgb.com/en/math.php
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var r:Double
    public var g:Double
    public var b:Double
    public var a:Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var ai:UInt8 {
        get { return UInt8(a*255) }
        set(ai) { a=Double(ai)/255.0 }
    }
    public var ri:UInt8 {
        get { return UInt8(r*255) }
        set(ri) { r=Double(ri)/255.0 }
    }
    public var gi:UInt8 {
        get { return UInt8(g*255) }
        set(gi) { g=Double(gi)/255.0 }
    }
    public var bi:UInt8 {
        get { return UInt8(b*255) }
        set(bi) { b=Double(bi)/255.0 }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var rgba: UInt32 {
        let v0 = UInt32(ai)<<24
        let v1 = UInt32(bi)<<16
        let v2 = UInt32(gi)<<8
        let v3 = UInt32(ri)
        return v0 | v1 | v2 | v3
    }
    public var bgra: UInt32 {
        let v0 = UInt32(ai)<<24
        let v1 = UInt32(ri)<<16
        let v2 = UInt32(gi)<<8
        let v3 = UInt32(bi)
        return v0 | v1 | v2 | v3
    }
    public var abgr: UInt32 {
        let v0 = UInt32(ri)<<24
        let v1 = UInt32(gi)<<16
        let v2 = UInt32(bi)<<8
        let v3 = UInt32(ai)
        return v0 | v1 | v2 | v3
    }
    public var argb: UInt32 {
        let v0 = UInt32(bi)<<24
        let v1 = UInt32(gi)<<16
        let v2 = UInt32(ri)<<8
        let v3 = UInt32(ai)
        return v0 | v1 | v2 | v3
    }
    public var hsba : (h:Double,s:Double,b:Double,a:Double) {
        let vmax = max(max(self.r, self.g), self.b)
        let vmin = min(min(self.r, self.g), self.b)
        var h = 0.0
        let s = (vmax == 0) ? 0.0 : (vmax - vmin) / vmax
        let b = vmax
        if s != 0 {
            let rc = (vmax - self.r) / (vmax-vmin)
            let gc = (vmax - self.g) / (vmax-vmin)
            let bc = (vmax - self.b) / (vmax-vmin)
            if r == vmax {
                h = bc - gc
            } else if g == vmax {
                h = 2.0 + rc - bc
            } else {
                h = 4.0 + gc - rc
            }
            h /= 6.0
            if h<0 {
                h += 1.0
            }
        }
        return (h:h,s:s,b:b,a:self.a)
    }
    public var hsla : (h:Double,s:Double,l:Double,a:Double) {
        let vmax = max(max(self.r, self.g), self.b)
        let vmin = min(min(self.r, self.g), self.b)
        let d = vmax - vmin
        var h = 0.0
        var s = 0.0
        let l = (vmax+vmin)*0.5
        if d != 0 {
            if l<0.5 {
                s = d / (vmax + vmin)
            } else {
                s = d / (2 - vmax - vmin)
            }
            if self.r == vmax {
                h = (self.g-self.b) / d
            } else if self.g == vmax {
                h = 2 + (self.b - self.r) / d
            } else {
                h = 4 + (self.r - self.g) / d
            }
            h /= 6.0
            if h<0 {
                h += 1.0
            }
        }
        return (h:h,s:s,l:l,a:self.a)
    }

    public var description: String {
        return html
    }
    public var infloat4 : float4 {
        return float4(Float(r),Float(g),Float(b),Float(a))
    }
    public var json: JSON {
        return JSON(html)
    }
    public func lerp(to c:Color,coef m:Double) -> Color {
        let im=1-m
        return Color(a:im*a+m*c.a, r:im*r+m*c.r, g: im*g+m*c.g, b: im*b+m*c.b)
    }
    public func lerp(to c:Color,coef s:Signal) -> Color {
        return self.lerp(to: c, coef: s.value)
    }
    public var luminosity:Double {
        return 0.2126*r + 0.7152*g + 0.0722*b
    }
    public var html:String {
        return "#"+String(format:"%02X", Int(a*255))+String(format:"%02X", Int(r*255))+String(format:"%02X", Int(g*255))+String(format:"%02X", Int(b*255))
    }
    public var uint: UInt32 {
        return argb
    }
    public var saturated : Color {
        return Color(a:min(1,max(0,a)),r:min(1,max(0,r)),g:min(1,max(0,g)),b:min(1,max(0,b)))
    }
    public func adjusted(chroma:Double,luminosity:Double) -> Color {
        let lum=Vec3(x:luminosity,y:luminosity,z:luminosity);
        let w=Vec3(x:0.2989,y:0.5870,z:0.1140)
        let c=Vec3(x:self.r,y:self.g,z:self.b)
        let l=Vec3.dot(c,w)
        let vl=Vec3(x:l,y:l,z:l)
        let d=c-vl;
        var nc=(vl+d*chroma).clamp(min:Vec3.zero,max:Vec3.unity);
        nc=(nc+lum).clamp(min:Vec3.zero,max:Vec3.unity);
        return Color(a:a,r:nc.x,g:nc.y,b:nc.z);
    }
    public func adjusted(contrast:Double,brightness:Double) -> Color {
        let b=Vec3(x:brightness,y:brightness,z:brightness);
        let c=Vec3(x:self.r,y:self.g,z:self.b);
        let m=Vec3(x:0.5,y:0.5,z:0.5);
        var nc=(m+(c-m)*contrast).clamp(min:Vec3.zero,max:Vec3.unity);
        nc=(nc+b).clamp(min:Vec3.zero,max:Vec3.unity);
        return Color(a:a,r:nc.x,g:nc.y,b:nc.z);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(bgra:UInt32) {
        self.a = Double((Int(bgra) >> 24) & 255) / 255.0
        self.r = Double((Int(bgra) >> 16) & 255) / 255.0
        self.g = Double((Int(bgra) >> 8) & 255) / 255.0
        self.b = Double(Int(bgra) & 255) / 255.0
    }
    public init(abgr:UInt32) {
        self.r = Double((Int(abgr) >> 24) & 255) / 255.0
        self.g = Double((Int(abgr) >> 16) & 255) / 255.0
        self.b = Double((Int(abgr) >> 8) & 255) / 255.0
        self.a = Double(Int(abgr) & 255) / 255.0
    }
    public init(rgba:UInt32) {
        self.a = Double((Int(rgba) >> 24) & 255) / 255.0
        self.b = Double((Int(rgba) >> 16) & 255) / 255.0
        self.g = Double((Int(rgba) >> 8) & 255) / 255.0
        self.r = Double(Int(rgba) & 255) / 255.0
    }
    public init(argb:UInt32) {
        self.b = Double((Int(argb) >> 24) & 255) / 255.0
        self.g = Double((Int(argb) >> 16) & 255) / 255.0
        self.r = Double((Int(argb) >> 8) & 255) / 255.0
        self.a = Double(Int(argb) & 255) / 255.0
    }
    public init(a:Double=1,r:Double,g:Double,b:Double) {
        self.a=a
        self.r=r
        self.g=g
        self.b=b
    }
    public init(a:Double=1,l:Double) {
        self.a=a
        self.r=l
        self.g=l
        self.b=l
    }
    public init(a:Double=1,rgb:Color) {
        self.a=a
        self.r=rgb.r
        self.g=rgb.g
        self.b=rgb.b
    }
    #if os(iOS) || os(tvOS)
        public init(a:Double=1,h:Double,s:Double,b:Double) {
            self.a=min(max(a,0),1)
            let ui=UIColor(hue: CGFloat(h), saturation: CGFloat(s), brightness: CGFloat(b), alpha: CGFloat(a))
            var cr=CGFloat()
            var cg=CGFloat()
            var cb=CGFloat()
            var ca=CGFloat()
            ui.getRed(&cr,green:&cg,blue:&cb,alpha:&ca)
            self.r = Double(cr)
            self.g = Double(cg)
            self.b = Double(cb)
        }
    #elseif os(OSX)
        public init(a:Double=1,h:Double,s:Double,b:Double) {
            self.a=min(max(a,0),1)
            let ns=NSColor(hue: CGFloat(h), saturation: CGFloat(s), brightness: CGFloat(b), alpha: CGFloat(a))
            self.r=Double(ns.redComponent)
            self.g=Double(ns.greenComponent)
            self.b=Double(ns.blueComponent)
        }
    #else
        public init(a:Double=1,h:Double,s:Double,b:Double) {
            self.a=min(max(a,0),1)
            if s == 0 {
                self.r = b
                self.g = b
                self.b = b
            } else {
                let sectorPos = h * 360 / 60.0
                let sectorNumber = Int(floor(sectorPos))
                let fractionalSector = sectorPos - Double(sectorNumber)
                let p = b * (1.0 - s)
                let q = b * (1.0 - (s * fractionalSector));
                let t = b * (1.0 - (s * (1 - fractionalSector)))
                switch (sectorNumber)
                {
                    case 1:
                    self.r = q
                    self.g = b
                    self.b = p
                    case 2:
                    self.r = p
                    self.g = b
                    self.b = t
                    case 3:
                    self.r = p
                    self.g = q
                    self.b = b
                    case 4:
                    self.r = t
                    self.g = p
                    self.b = b
                    case 5:
                    self.r = b
                    self.g = p
                    self.b = q
                    default: // 0
                    self.r = b
                    self.g = t
                    self.b = p
                }
            }
        }
    #endif
    public init(a:Double=1,h:Double,s:Double,l:Double) {
        // https://stackoverflow.com/questions/4793729/rgb-to-hsl-and-back-calculation-problems
        self.a=min(max(a,0),1)
        if s == 0 {
            self.r = l
            self.g = l
            self.b = l
        } else {
            var t2 = 0.0
            if l<0.5 {
                t2 = l * (1+s)
            } else {
                t2 = (l+s) - (l*s)
            }
            let t1 = 2*l - t2
            
            let r = h + (1/3)
            let g = h
            let b = h - (1/3)
            
            func calc(_ c0:Double) -> Double {
                let c = ß.modulo(c0,1)
                if 6*c<1 {
                    return t1 + (t2-t1) * 6 * c
                } else if 2*c < 1 {
                    return t2
                } else if 3*c < 2 {
                    return t1 + (t2-t1) * (2/3-c) * 6
                }
                return t1
            }

            self.r = calc(r)
            self.g = calc(g)
            self.b = calc(b)
        }
    }
    public init(html:String) {
        var h:String=html;
        if(h[0]=="#") {
            h = h[1...]
        }
        if(h.length==8) {
            let ta = h[0...1]
            h=h[2...]
            a=Double(UInt8(strtoul(ta, nil, 16)))/255.0
        } else {
            a=1
        }
        if h.length==6 {
            r=Double(UInt8(strtoul(h[0...1], nil, 16)))/255.0
            g=Double(UInt8(strtoul(h[2...3], nil, 16)))/255.0
            b=Double(UInt8(strtoul(h[4...5], nil, 16)))/255.0
        } else {
            r=0
            g=0
            b=0
        }
    }
    public init(hex:String) {
        self.init(html:hex)
    }
    public init(json:JSON) {
        if let s=json.string {
            let c=Color(html:s)
            self.a=c.a
            self.r=c.r
            self.g=c.g
            self.b=c.b
        } else {
            self.a=0
            self.r=0
            self.g=0
            self.b=0
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(iOS) || os(tvOS)
    public var system: UIColor {
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    #elseif os(OSX)
    public var system: NSColor {
        return NSColor(deviceRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static var transparent: Color {
        return Color(html:"#00000000")
    }
    public static var black: Color {
        return Color(html:"#000000")
    }
    public static var darkGrey: Color {
        return Color(html:"#404040")
    }
    public static var grey: Color {
        return Color(html:"#808080")
    }
    public static var lightGrey: Color {
        return Color(html:"#C0C0C0")
    }
    public static var white: Color {
        return Color(html:"#FFFFFF")
    }
    public static var red: Color {
        return Color(html:"#FF0000")
    }
    public static var green: Color {
        return Color(html:"#00FF00")
    }
    public static var blue: Color {
        return Color(html:"#0000FF")
    }
    public static var aeOrange: Color {
        return Color(html:"#FFAA00")
    }
    public static var aeMagenta: Color {
        return Color(html:"#FF00AA")
    }
    public static var aeGreen: Color {
        return Color(html:"#AAFF00")
    }
    public static var aeAqua: Color {
        return Color(html:"#00FFAA")
    }
    public static var aeViolet: Color {
        return Color(html:"#AA00FF")
    }
    public static var aeBlue: Color {
        return Color(html:"#00AAFF")
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // TODO: load of json file https://gist.github.com/renanyoy/4acff1a8ba8de7f6f779   css??
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(l: Color, r: Color) -> Bool {
    return l.a==r.a&&l.r==r.r&&l.g==r.g&&l.b==r.b
}
public func !=(l: Color, r: Color) -> Bool {
    return l.a != r.a || l.r != r.r || l.g != r.g || l.b != r.b
}
public func +(l: Color, r: Color) -> Color {
    return Color(a:l.a+r.a,r:l.r+r.r,g:l.g+r.g,b:l.b+r.b)
}
public func -(l: Color, r: Color) -> Color {
    return Color(a:l.a-r.a,r:l.r-r.r,g:l.g-r.g,b:l.b-r.b)
}
public func *(l: Color, r: Color) -> Color {
    return Color(a:l.a*r.a,r:l.r*r.r,g:l.g*r.g,b:l.b*r.b)
}
public func *(lhs: Color, rhs: Double) -> Color {
    return Color(a:lhs.a*rhs,r:lhs.r*rhs,g:lhs.g*rhs,b:lhs.b*rhs)
}
public func /(l: Color, r: Double) -> Color {
    return Color(a:l.a/r,r:l.r/r,g:l.g/r,b:l.b/r)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
