//
//  Paint.swift
//  Alib
//
//  Created by renan jegouzo on 01/04/2016.
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

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct ColorGradient {
    var colors=[Double:Color]()
    public private(set) var useAlpha=false
    public init() {
    }
    public init(_ colors:[Double:Color]) {
        self.colors=colors
    }
    public mutating func add(_ position:Double,_ c:Color) {
        colors[position]=c
        if c.a<1 {
            useAlpha=true
        }
    }
    public func value(_ position:Double) -> Color {
        let keys = colors.keys.sorted()
        var i=0
        while keys[i+1]<position {
            i += 1
        }
        let p0 = keys[i]
        let c0 = colors[p0]!
        let p1 = keys[i+1]
        let c1 = colors[p1]!
        return c0.lerp(to:c1,coef:(position-p0)/(p1-p0))
    }
    public func createBitmap(parent:NodeUI,width:Double) -> Bitmap {
        let b=Bitmap(parent:parent,size:Size(width,1))
        var v = [UInt32](repeating:0,count:Int(width))
        for x in 0..<v.count {
            let c = self.value(Double(x)/Double(v.count-1))
            v[x] = c.abgr
        }
        b.set(pixels:v)
        return b
    }
    public func process(source:Bitmap, destination:Bitmap, blend:BlendMode = .opaque,color:Color = .white, _ fn:@escaping (RenderPass.Result)->())  {
        let b = destination
        let g = Graphics(image:b)
        g.program("program.gradient",blend:blend)
        g.uniforms(g.matrix)
        let vert=g.textureVertices(4)
        let strip=b.bounds.strip
        var uv = Rect(x:0,y:0,w:1,h:1).strip
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        g.sampler("sampler.clamp")
        g.render.use(texture:source)
        let bg = self.createBitmap(parent: destination, width: 16)
        g.render.use(texture:bg,atIndex:1)
        g.render.draw(trianglestrip:4)
        g.done { ok in
            bg.detach()
            fn(ok)
        }
    }
    public static var blackWhite : ColorGradient {
        var cg = ColorGradient()
        cg.add(0, .black)
        cg.add(1, .white)
        return cg
    }
    public static var rainbow : ColorGradient {
        var cg = ColorGradient()
        var h = 0.0
        var i = 0.0
        let dh = 1.0/16
        let di = 1.0/16
        for _ in 1...16 {
            cg.add(i, Color(h: h, s: 1, b: 1))
            i += di
            h += dh
        }
        cg.add(i, Color(h: h, s: 1, b: 1))
        return cg
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Paint : NodeUI {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _renderer:Renderer?=nil
    var renderer:Renderer? {
        get { return _renderer }
        set(r) {
            if let r = _renderer {
                r.detach()
            }
            _renderer = r
        }
    }
    public private(set) var mode:PaintMode
    public var blend:BlendMode
    public var strokeWidth:Double=1.0
    public private(set) var useAlpha:Bool=false
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var computedBlend:BlendMode {
        if blend == .opaque && useAlpha {
            return .alpha
        }
        return blend
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent:NodeUI,mode:PaintMode=PaintMode.fill,blend:BlendMode=BlendMode.opaque,color:Color?=nil) {
        self.mode=mode
        self.blend=blend
        super.init(parent:parent)
        if let c=color {
            self.color = c
        }
    }
    public init(parent:NodeUI,mode:PaintMode=PaintMode.fill,blend:BlendMode=BlendMode.opaque,linear:ColorGradient) {
        self.mode=mode
        self.blend=blend
        super.init(parent:parent)
        self.linearGradient(p0: Point.zero, p1: Point(1,1), cramp: linear)
    }
    public init(parent:NodeUI,mode:PaintMode=PaintMode.fill,blend:BlendMode=BlendMode.opaque,radial:ColorGradient) {
        self.mode=mode
        self.blend=blend
        super.init(parent:parent)
        self.radialGradient(colors:radial)
    }
    public init(parent:NodeUI,mode:PaintMode=PaintMode.fill,blend:BlendMode=BlendMode.opaque,pattern:Bitmap,scale:Size=Size(1,1),offset:Point=Point.zero) {
        self.mode=mode
        self.blend=blend
        super.init(parent:parent)
        self.pattern(pattern,scale:scale,offset:offset)
    }
    public init(parent:NodeUI,mode:PaintMode=PaintMode.stroke,blend:BlendMode=BlendMode.opaque,line:Bitmap,strokeWidth:Double=1) {
        self.strokeWidth = strokeWidth
        self.mode=mode
        self.blend=blend
        super.init(parent:parent)
        self.line(line)
    }
    override public func detach() {
        if let renderer=renderer {
            renderer.detach()
            self.renderer=nil
        }
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var color:Color {
        get {
            if let p=renderer as? RenderColor {
                return p.color
            }
            return Color.transparent
        }
        set(c) {
            renderer=RenderColor(c)
            useAlpha=(c.a != 1)
        }
    }
    public func linearGradient(p0:Point,p1:Point,cramp:ColorGradient) {
        renderer = RenderLinearGradient(p0:p0,p1:p1,colors:cramp)
        useAlpha = cramp.useAlpha
    }
    public func radialGradient(center:Point=Point(0.5,0.5),focal:Point=Point(0.5,0.5),radius:Double=0.5,colors:ColorGradient) {
        renderer = RenderRadialGradient(center:center,focal:focal,radius:radius,colors:colors)
        useAlpha = colors.useAlpha
    }
    public func pattern(_ image:Bitmap,scale:Size=Size(1,1),offset:Point=Point.zero) {
        renderer=RenderPattern(image:image,scale:scale,offset:offset)
    }
    public func line(_ image:Bitmap) {
        renderer=RenderLine(image)
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum PaintMode {
        case fill
        case stroke
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class Renderer {
        enum UV {
            case none
            case boundingBox
            case trace
        }
        var uv:UV {
            return .none
        }
        func offset(_ boudingBox:Rect) -> Point {
            return Point.zero
        }
        func scale(_ boundingBox:Rect) -> Size {
            return Size(1,1)
        }
        func detach() {
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class RenderColor : Renderer {
        var color:Color
        init(_ color:Color) {
            self.color=color
        }
    }
    class RenderTexture : Renderer {
        override var uv:UV {
            return .boundingBox
        }
        func texture(parent:NodeUI) -> Texture2D? {
            return nil
        }
    }
    class RenderLinearGradient : RenderTexture {
        var colors:ColorGradient
        var p0:Point
        var p1:Point
        init(p0:Point=Point.zero,p1:Point=Point(1,1),colors:ColorGradient)
        {
            self.colors=colors
            self.p0=p0
            self.p1=p1
        }
        override func texture(parent:NodeUI) -> Texture2D? {
            return nil
        }
    }
    class RenderRadialGradient : RenderTexture {
        var colors:ColorGradient
        var center:Point
        var focal:Point
        var radius:Double
        var texture:Bitmap?
        init(center:Point=Point(0.5,0.5),focal:Point=Point(0.5,0.5),radius:Double=0.5,colors:ColorGradient)
        {
            self.center=center
            self.focal=focal
            self.radius=radius
            self.colors=colors
        }
        override func texture(parent:NodeUI) -> Texture2D? {
            if let t=texture {
                return t
            }
            let sz=SizeI(32,32)
            let t = Bitmap(parent:parent,size:Size(sz))
            var pix=[UInt32](repeating:0,count:sz.w*sz.h)
            let ir = 0.5 / radius
            var i = 0
            let m = (Size(sz)-Size(1,1))*0.5
            for y in 0..<Int(sz.h) {
                let dy = (Double(y)-m.h)/m.h
                for x in 0..<Int(sz.w) {
                    let dx = (Double(x)-m.w)/m.w
                    let d = max(0.0,min(1.0,sqrt(dx*dx+dy*dy)*ir))
                    pix[i] = colors.value(d).abgr
                    i += 1
                }
            }
            t.set(pixels: pix)
            texture=t
            return t
        }
    }
    class RenderPattern : RenderTexture {
        var image:Bitmap
        var scale:Size
        var offset:Point
        override func offset(_ boundingBox:Rect) -> Point {
            return boundingBox.origin/(image.size*scale)
        }
        override func scale(_ boundingBox:Rect) -> Size {
            return boundingBox.size/(scale*image.size)
        }
        init(image:Bitmap,scale:Size=Size(1,1),offset:Point=Point.zero)
        {
            self.image=image
            self.scale=scale
            self.offset=offset
        }
        override func detach() {
            image.detach()
            super.detach()
        }
        override func texture(parent:NodeUI) -> Texture2D? {
            return image
        }
    }
    class RenderLine : RenderTexture {
        override var uv:UV {
            return .trace
        }
        override func scale(_ boundingBox:Rect) -> Size {
            return Size(1,1)/image.size
        }
        var image:Bitmap
        init(_ image:Bitmap)
        {
            self.image=image
        }
        override func texture(parent:NodeUI) -> Texture2D? {
            return image
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
