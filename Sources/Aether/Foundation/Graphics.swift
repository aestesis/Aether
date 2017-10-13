//
//  Graphics.swift
//  Aether
//
//  Created by renan jegouzo on 15/03/2016.
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
    import Metal
    import MetalKit
#endif

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

// http://code.tutsplus.com/tutorials/ios-8-getting-started-with-metal--cms-21987
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Graphics : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var matrix:Mat4
    var output:Size
    var clip:Rect
    var clipping=false
    public private(set) var render:RenderPass
    private var renderOwner = false
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func done(_ fn: @escaping (RenderPass.Result)->()) {
        render.onDone.once { result in
            fn(result)
        }
    }
    public var root : Graphics {
        var g : Graphics = self
        while let gn = g.parent as? Graphics {
            g = gn
        }
        return g
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func fill(rect:Rect,blend:BlendMode=BlendMode.opaque,color:Color) {
        program("program.color",blend:blend)
        uniforms(matrix)
        let vert=colorVertices(4)
        let strip=rect.strip
        for i in 0...3 {
            vert[i]=ColorVertice(position:strip[i].infloat3,color:color.infloat4)
        }
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(rect:Rect,image:Bitmap,from:Rect?=nil,blend:BlendMode=BlendMode.opaque,color:Color=Color.white,rotation:Rotation=Rotation.none) {
        var wrap = false
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(4) 
        let strip=rect.strip
        var rs = Rect(x:0,y:0,w:1,h:1)
        if let r=from {
            rs = r / image.size
            wrap = rs.left<0 || rs.top<0 || rs.right>1 || rs.bottom>1   // TODO: separate U and V wrap
        }
        var uv=rs.strip(rotation)
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        sampler(wrap ? "sampler.wrap" : "sampler.clamp")
        render.use(texture:image)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(rect:Rect,image:Bitmap,from:Rect?=nil,gradient:Bitmap,altGradient:Bool=false,blend:BlendMode = .opaque,color:Color = .white,rotation:Rotation=Rotation.none)  {
        var wrap = false
        if altGradient {
            program("program.gradient.alt",blend:blend)
        } else {
            program("program.gradient",blend:blend)
        }
        uniforms(matrix)
        let vert=textureVertices(4)
        let strip=rect.strip
        var rs = Rect(x:0,y:0,w:1,h:1)
        if let r=from {
            rs = r / image.size
            wrap = rs.left<0 || rs.top<0 || rs.right>1 || rs.bottom>1   // TODO: separate U and V wrap
        }
        var uv=rs.strip(rotation)
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        sampler(wrap ? "sampler.wrap" : "sampler.clamp")
        render.use(texture:image)
        render.use(texture:gradient,atIndex:1)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(rect:Rect,image:Bitmap,mask:Bitmap,blend:BlendMode=BlendMode.alpha,color:Color=Color.white) {
        program("program.texture.mask",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        var uv = rs.strip
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        sampler("sampler.clamp")
        render.use(texture:image)
        render.use(texture:mask,atIndex:1)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(rect:Rect,image:Bitmap,mask:Bitmap,blend:BlendMode=BlendMode.alpha,color:Color=Color.white,rotation:Rotation=Rotation.none,maskRotation:Rotation=Rotation.none) {
        program("program.texture.bitmap.mask",blend:blend)
        uniforms(matrix)
        let vert=textureMaskVertices(4)
        let cl=color.infloat4
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv = rs.strip(rotation)
        let uvm = rs.strip(maskRotation)
        for i in 0...3 {
            vert[i]=TextureMaskVertice(position:strip[i].infloat3,uv:uv[i].infloat2,uvmask:uvm[i].infloat2,color:cl)
        }
        sampler("sampler.clamp")
        render.use(texture:image)
        render.use(texture:mask,atIndex:1)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func blendParam(_ p:Float32)   {
        let b=buffer(MemoryLayout<Float32>.size)
        let ptr = b.ptr.assumingMemoryBound(to: Float32.self)
        ptr[0] = p
        render.use(fragmentBuffer:b,atIndex:0)
    }
    public func blend(rect:Rect,base:Bitmap,overlay:Bitmap,blend:BlendMode=BlendMode.opaque,opacity:Double=1.0) {
        program("program.blend",blend:blend)
        uniforms(matrix)
        blendParam(Float32(opacity))
        let vert=blendVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv=rs.strip
        for i in 0...3 {
            vert[i]=BlendVertice(position:strip[i].infloat3,uv:uv[i].infloat2)
        }
        sampler("sampler.clamp")
        render.use(texture:base,atIndex:0)
        render.use(texture:overlay,atIndex:1)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(strip vs:[Vertice],image:Bitmap,sampler smp:String="sampler.clamp",blend:BlendMode=BlendMode.opaque) {
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(vs.count*2) // TODO: WTF, needs to mul x2 ???
        for i in 0..<vs.count {
            let v=vs[i]
            vert[i] = TextureVertice(position:v.position.infloat3, uv: v.uv.infloat2, color: v.color.infloat4)
        }
        sampler(smp)
        render.use(texture:image)
        render.draw(trianglestrip:vs.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(triangle vs:[Vertice],image:Bitmap,sampler smp:String="sampler.clamp",blend:BlendMode=BlendMode.opaque) {
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(vs.count*2) // TODO: WTF, needs to mul x2 ???
        for i in 0..<vs.count {
            let v=vs[i]
            vert[i] = TextureVertice(position:v.position.infloat3,uv:v.uv.infloat2,color:v.color.infloat4)
        }
        sampler(smp)
        render.use(texture:image)
        render.draw(triangle:vs.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(sprites:[PointSprite],image:Bitmap,scale:Double=1,blend:BlendMode=BlendMode.opaque) {
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(6*sprites.count*2) // TODO: WTF, needs to mul x2 ???
        var i = 0
        let s=Rect(x:0,y:0,w:1,h:1)
        for sp in sprites {
            let cl = sp.color.infloat4
            let d = sp.position.rect(image.size).scale(sp.scale*scale)
            vert[i]=TextureVertice(position:d.topLeft.infloat3,uv:s.topLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomRight.infloat3,uv:s.bottomRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,color:cl)
            i += 1
        }
        sampler("sampler.clamp")
        render.use(texture:image)
        render.draw(triangle:6*sprites.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw9grid(rect:Rect,image:Bitmap,blend:BlendMode=BlendMode.opaque,color:Color=Color.white) {
        let r = rect
        let sd = r.size
        let m = image.bounds.center
        let source = image.size
        if sd.w<image.size.width || sd.h<image.size.height {
            Debug.error(Error("destination can't be smaller than 9grid source",#file,#line))
            return
        }
        let rl:[(d:Rect,s:Rect)] = [
            (d:Rect(x:r.x,y:r.y,w:m.x,h:m.y),s:Rect(x:0,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x+sd.w-m.x,y:r.y,w:m.x,h:m.y),s:Rect(x:m.x,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+sd.h-m.y,w:m.x,h:m.y),s:Rect(x:0,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x+sd.w-m.x,y:r.y+sd.h-m.y,w:m.x,h:m.y),s:Rect(x:m.x,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+m.y,w:m.x,h:sd.h-source.h),s:Rect(x:0,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+sd.w-m.x,y:r.y+m.y,w:m.x,h:sd.h-source.h),s:Rect(x:m.x,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+m.x,y:r.y,w:sd.w-source.w,h:m.y),s:Rect(x:m.x-0.5,y:0,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+sd.height-m.y,w:sd.w-source.w,h:m.y),s:Rect(x:m.x-0.5,y:m.y,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+m.y,w:sd.w-source.w,h:sd.h-source.h),s:Rect(x:m.x-0.5,y:m.y-0.5,w:1,h:1))
        ]
        program("program.texture",blend:blend)
        uniforms(matrix)
        #if os(tvOS) || os(iOS)
            let vert=textureVertices(6*rl.count*2)    // ugly patch, buffer too short on iOS, WTF ???
        #else
            let vert=textureVertices(6*rl.count)
        #endif
        let cl=color.infloat4
        var i=0
        for r in rl {
            let d=r.d
            let s=r.s/source
            vert[i]=TextureVertice(position:d.topLeft.infloat3,uv:s.topLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomRight.infloat3,uv:s.bottomRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,color:cl)
            i += 1
        }
        sampler("sampler.clamp")
        render.use(texture:image)
        render.draw(triangle:6*rl.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw9grid(rect:Rect,image:Bitmap,from:Rect?=nil,mask:Bitmap,gradient:Bitmap,blend:BlendMode = .opaque,color:Color = .white)  {
        let r = rect
        let s = from ?? image.bounds
        let m = mask.bounds.center
        let ms = mask.size
        let rl:[(d:Rect,s:Rect,m:Rect)] = [
            (d:Rect(x:r.x,y:r.y,w:m.x,h:m.y),s:Rect(x:s.x,y:s.y,w:m.x,h:m.y),m:Rect(x:0,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y,w:m.x,h:m.y),s:Rect(x:s.x+s.w-m.x,y:s.y,w:m.x,h:m.y),m:Rect(x:m.x,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+r.h-m.y,w:m.x,h:m.y),s:Rect(x:s.x,y:s.y+s.h-m.y,w:m.x,h:m.y),m:Rect(x:0,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y+r.h-m.y,w:m.x,h:m.y),s:Rect(x:s.x+s.w-m.x,y:s.y+s.h-m.y,w:m.x,h:m.y),m:Rect(x:m.x,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+m.y,w:m.x,h:r.h-ms.h),s:Rect(x:s.x,y:s.y+m.y,w:m.x,h:s.h-ms.h),m:Rect(x:0,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y+m.y,w:m.x,h:r.h-ms.h),s:Rect(x:s.x+s.w-m.x,y:s.y+m.y,w:m.x,h:s.h-ms.h),m:Rect(x:m.x,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+m.x,y:r.y,w:r.w-ms.w,h:m.y),s:Rect(x:s.x+m.x,y:r.y,w:s.w-ms.w,h:m.y),m:Rect(x:m.x-0.5,y:0,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+r.height-m.y,w:r.w-ms.w,h:m.y),s:Rect(x:s.x+m.x,y:s.y+s.height-m.y,w:s.w-ms.w,h:m.y),m:Rect(x:m.x-0.5,y:m.y,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+m.y,w:r.w-ms.w,h:r.h-ms.h),s:Rect(x:s.x+m.x,y:s.y+m.y,w:s.w-ms.w,h:s.h-ms.h),m:Rect(x:m.x-0.5,y:m.y-0.5,w:1,h:1))
        ]
        program("program.gradient.mask",blend:blend)
        uniforms(matrix)
        #if os(tvOS) || os(iOS)
            let vert=textureMaskVertices(6*rl.count*2)    // ugly patch, buffer too short on iOS, WTF ???
        #else
            let vert=textureMaskVertices(6*rl.count)
        #endif
        let cl=color.infloat4
        var i=0
        for r in rl {
            let d=r.d
            let m = r.m/mask.size
            let s = r.s/image.size
            vert[i]=TextureMaskVertice(position:d.topLeft.infloat3,uv:s.topLeft.infloat2,uvmask:m.topLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,uvmask:m.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,uvmask:m.bottomLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,uvmask:m.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomRight.infloat3,uv:s.bottomRight.infloat2,uvmask:m.bottomRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,uvmask:m.bottomLeft.infloat2,color:cl)
            i += 1
        }
        if s.left<0 || s.right>1 || s.top<0 || s.bottom>1 {
            sampler("sampler.wrap")
        } else {
            sampler("sampler.clamp")
        }
        render.use(texture:image)
        render.use(texture:mask,atIndex:1)
        render.use(texture:gradient,atIndex:2)
        render.draw(triangle:6*rl.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw9grid(rect:Rect,image:Bitmap,from:Rect?=nil,mask:Bitmap,blend:BlendMode=BlendMode.opaque,color:Color=Color.white) {
        let r = rect
        let s = from ?? image.bounds
        let m = mask.bounds.center
        let d = s.size / r.size
        let ms = mask.size
        let rl:[(d:Rect,s:Rect,m:Rect)] = [
            (d:Rect(x:r.x,y:r.y,w:m.x,h:m.y),s:Rect(x:s.x,y:s.y,w:m.x*d.w,h:m.y*d.h),m:Rect(x:0,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y,w:m.x,h:m.y),s:Rect(x:s.x+s.w-m.x*d.w,y:s.y,w:m.x*d.w,h:m.y*d.h),m:Rect(x:m.x,y:0,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+r.h-m.y,w:m.x,h:m.y),s:Rect(x:s.x,y:s.y+s.h-m.y*d.h,w:m.x*d.w,h:m.y*d.h),m:Rect(x:0,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y+r.h-m.y,w:m.x,h:m.y),s:Rect(x:s.x+s.w-m.x*d.w,y:s.y+s.h-m.y*d.h,w:m.x*d.w,h:m.y*d.h),m:Rect(x:m.x,y:m.y,w:m.x,h:m.y)),
            (d:Rect(x:r.x,y:r.y+m.y,w:m.x,h:r.h-ms.h),s:Rect(x:s.x,y:s.y+m.y*d.h,w:m.x*d.w,h:s.h-ms.h*d.h),m:Rect(x:0,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+r.w-m.x,y:r.y+m.y,w:m.x,h:r.h-ms.h),s:Rect(x:s.x+s.w-m.x*d.w,y:s.y+m.y*d.h,w:m.x*d.w,h:s.h-ms.h*d.h),m:Rect(x:m.x,y:m.y-0.5,w:m.x,h:1)),
            (d:Rect(x:r.x+m.x,y:r.y,w:r.w-ms.w,h:m.y),s:Rect(x:s.x+m.x*d.w,y:s.y,w:s.w-ms.w*d.w,h:m.y*d.h),m:Rect(x:m.x-0.5,y:0,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+r.height-m.y,w:r.w-ms.w,h:m.y),s:Rect(x:s.x+m.x*d.w,y:s.y+s.h-m.y*d.w,w:s.w-ms.w*d.w,h:m.y*d.h),m:Rect(x:m.x-0.5,y:m.y,w:1,h:m.y)),
            (d:Rect(x:r.x+m.x,y:r.y+m.y,w:r.w-ms.w,h:r.h-ms.h),s:Rect(x:s.x+m.x*d.w,y:s.y+m.y*d.h,w:s.w-ms.w*d.w,h:s.h-ms.h*d.h),m:Rect(x:m.x-0.5,y:m.y-0.5,w:1,h:1))
        ]
        program("program.texture.bitmap.mask",blend:blend)
        uniforms(matrix)
        #if os(tvOS) || os(iOS)
            let vert=textureMaskVertices(6*rl.count*2)    // ugly patch, buffer too short on iOS, WTF ???
        #else
            let vert=textureMaskVertices(6*rl.count)
        #endif
        let cl=color.infloat4
        var i=0
        for r in rl {
            let d=r.d
            let m = r.m/mask.size
            let s = r.s/image.size
            vert[i]=TextureMaskVertice(position:d.topLeft.infloat3,uv:s.topLeft.infloat2,uvmask:m.topLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,uvmask:m.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,uvmask:m.bottomLeft.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.topRight.infloat3,uv:s.topRight.infloat2,uvmask:m.topRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomRight.infloat3,uv:s.bottomRight.infloat2,uvmask:m.bottomRight.infloat2,color:cl)
            i += 1
            vert[i]=TextureMaskVertice(position:d.bottomLeft.infloat3,uv:s.bottomLeft.infloat2,uvmask:m.bottomLeft.infloat2,color:cl)
            i += 1
        }
        sampler("sampler.clamp")
        render.use(texture:image)
        render.use(texture:mask,atIndex:1)
        render.draw(triangle:6*rl.count)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func drawString(font:Font,position:Point,align:Align=Align.topLeft,text:String,blend:BlendMode=BlendMode.color,color:Color=Color.white) {    // deprecated
        draw(position:position,text:text,font:font,align:align,blend:blend,color:color)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(position:Point,text:String,font:Font,align:Align=Align.topLeft,blend:BlendMode=BlendMode.color,color:Color=Color.white) {
        let b=font.mask(text:text,align:align)
        var rect=Rect(o:position,s:b.size)
        if align.hasFlag(Align.right) {
            rect.x -= b.size.width
        } else if align.hasFlag(Align.horizontalCenter) {
            rect.x -= b.size.width*0.5
        }
        if align.hasFlag(Align.bottom) {
            rect.y -= b.size.height
        } else if align.hasFlag(Align.verticalCenter) {
            rect.y -= b.size.height*0.5
        }
        //self.fill(rect:rect,color:.grey)    // 4debug
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv=rs.strip
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        sampler("sampler.clamp")
        render.use(texture:b)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(rect rs:Rect,text:String,font:Font,lines:Int=0,align:Align=Align.topLeft,blend:BlendMode=BlendMode.color,color:Color=Color.white) {
        let b=font.mask(text:text,align:align,width:rs.width,lines:lines)
        var rect=Rect(o:rs.origin,s:b.size)
        if align.hasFlag(Align.right) {
            rect.x += rs.width - b.size.width
        } else if align.hasFlag(Align.horizontalCenter) {
            rect.x += (rs.width-b.size.width)*0.5
        }
        if align.hasFlag(Align.bottom) {
            rect.y += rs.height - b.size.height
        } else if align.hasFlag(Align.verticalCenter) {
            rect.y += (rs.height - b.size.height)*0.5
        }
        program("program.texture",blend:blend)
        uniforms(matrix)
        let vert=textureVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv=rs.strip
        for i in 0...3 {
            vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
        }
        sampler("sampler.clamp")
        render.use(texture:b)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func blurParam(_ p:float2)   {
        let b=buffer(MemoryLayout<float2>.size)
        let ptr=b.ptr.assumingMemoryBound(to: float2.self) //UnsafeMutablePointer<float2>(b.ptr)
        ptr[0]=p
        render.use(fragmentBuffer:b,atIndex:0)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func blurHorizontal(_ rect:Rect,source:Bitmap,sigma:Double,sampler smp:String="sampler.clamp") {
        program("program.blur.horizontal",blend:BlendMode.copy)
        uniforms(matrix)
        blurParam(float2(Float(sigma/source.size.width),Float(sigma/source.size.height)))
        let vert=blurVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv=rs.strip
        for i in 0...3 {
            vert[i]=BlurVertice(position:strip[i].infloat3,uv:uv[i].infloat2)
        }
        sampler(smp)
        render.use(texture:source)
        render.draw(trianglestrip:4)
    }
    public func blurVertical(_ rect:Rect,source:Bitmap,sigma:Double,sampler smp:String="sampler.clamp") {
        program("program.blur.vertical",blend:BlendMode.copy)
        uniforms(matrix)
        blurParam(float2(Float(sigma/source.size.width),Float(sigma/source.size.height)))
        let vert=blurVertices(4)
        let strip=rect.strip
        let rs = Rect(x:0,y:0,w:1,h:1)
        let uv=rs.strip
        for i in 0...3 {
            vert[i]=BlurVertice(position:strip[i].infloat3,uv:uv[i].infloat2)
        }
        sampler(smp)
        render.use(texture:source)
        render.draw(trianglestrip:4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(_ path:Path,_ paint:Paint) {
        if let rt=paint.renderer as? Paint.RenderTexture, let t=rt.texture(parent:self) {
            program("program.texture",blend:paint.computedBlend)
            sampler("sampler.wrap")
            render.use(texture:t)
        } else {
            program("program.color",blend:paint.computedBlend)
        }
        uniforms(matrix)
        let tess=paint.viewport!.gpu.tess
        let contours=path.parse(paint)
        tess.beginPolygon()
        for c in contours {
            tess.beginContour()
            tess.sendVertex(c.vertices)
            tess.endContour()
        }
        tess.endPolygon()
        for s in tess.shapes {
            if paint.renderer is Paint.RenderTexture {
                let vert=textureVertices(s.vertices.count)
                for i in 0..<s.vertices.count {
                    let v=s.vertices[i]
                    vert[i]=TextureVertice(position:v.position.infloat3,uv:v.uv.infloat2,color:Color.white.infloat4)
                }
            } else {
                let vert=colorVertices(s.vertices.count)
                for i in 0..<s.vertices.count {
                    vert[i]=ColorVertice(position:s.vertices[i].position.infloat3,color:paint.color.infloat4)
                }
            }
            switch s.kind {
            case .triangles:
                render.draw(triangle:s.vertices.count)
                break
            case .triangle_STRIP:
                render.draw(trianglestrip:s.vertices.count)
                break
            case .triangle_FAN:
                let nidx=(s.vertices.count-2)*3
                let b=buffer(MemoryLayout<UInt32>.size*nidx)
                let index=b.ptr.assumingMemoryBound(to: UInt32.self)    //UnsafeMutablePointer<UInt32>(b.ptr)
                let first:UInt32=0
                var last:UInt32=1
                var d:Int=0
                for i in 2..<s.vertices.count {
                    index[d] = first
                    d += 1
                    index[d] = last
                    d += 1
                    index[d] = UInt32(i)
                    d += 1
                    last = UInt32(i)
                }
                render.draw(triangle:nidx,index:b)
                break
            }
        }
    }
    public func draw(_ path:Path,_ color:Color) {
        self.draw(path,Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func line(_ p0:Point,_ p1:Point,_ paint:Paint) {
        let p=Path()
        p.append(Path.Segment.moveTo(p0))
        p.append(Path.Segment.lineTo(p1))
        p.append(Path.Segment.close())
        draw(p,paint)
    }
    public func line(_ p0:Point,_ p1:Point,_ color:Color) {
        self.line(p0,p1,Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func polygon(_ points:[Point],_ paint:Paint) {
        let p=Path()
        p.append(Path.Segment.moveTo(points[0]))
        for i in 1..<points.count {
            p.append(Path.Segment.lineTo(points[i]))
        }
        p.append(Path.Segment.lineTo(points[0]))
        draw(p,paint)
    }
    public func polygon(_ points:[Point],_ color:Color) {
        self.polygon(points, Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func polygon(center:Point,count:Int,rotation:Double,radius:Double,paint:Paint) {
        if(radius>0.1) {
            let p=Path()
            let da=ß.π*2/Double(count)
            var a=rotation
            p.append(Path.Segment.moveTo(center+Point(angle:a,radius:radius)))
            for _ in 1..<count {
                a = a+da
                p.append(Path.Segment.lineTo(center+Point(angle:a,radius:radius)))
            }
            draw(p,paint)
        }
    }
    public func polygon(center:Point,count:Int,rotation:Double,radius:Double,color:Color) {
        self.polygon(center:center,count:count,rotation:rotation,radius:radius,paint:Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func rosace(center:Point,count:Int,rotation:Double,r0:Double,r1:Double,paint:Paint) {
        if r0>0.1 || r1>0.1 {
            let p=Path()
            let da=ß.π*2/Double(count)
            let da2=0.5*da
            var a=rotation
            p.append(Path.Segment.moveTo(center+Point(angle:a,radius:r0)))
            for _ in 1...count {
                let ma = a + da2
                a = a+da
                p.append(Path.Segment.quadTo(center+Point(angle:ma,radius:r1),center+Point(angle:a,radius:r0)))
                p.append(Path.Segment.lineTo(center+Point(angle:a,radius:r0)))   // why  ??  was moveTo in C#
            }
            draw(p,paint)
        }
    }
    public func rosace(center:Point,count:Int,rotation:Double,r0:Double,r1:Double,color:Color) {
        self.rosace(center: center, count: count, rotation: rotation, r0: r0, r1: r1, paint:Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func circle(center pc:Point,radius r:Double,paint:Paint) {
        if r>0.1 {
            let p=Path()
            let cq=0.551915024494
            let c=r*cq
            p.append(Path.Segment.moveTo(pc.translate(0,r)))
            p.append(Path.Segment.cubicTo(pc.translate(c,r),pc.translate(r,c),pc.translate(r,0)))
            p.append(Path.Segment.cubicTo(pc.translate(r,-c),pc.translate(c,-r),pc.translate(0,-r)))
            p.append(Path.Segment.cubicTo(pc.translate(-c,-r),pc.translate(-r,-c),pc.translate(-r,0)))
            p.append(Path.Segment.cubicTo(pc.translate(-r,c),pc.translate(-c,r),pc.translate(0,r)))
            draw(p,paint)
        }
    }
    public func circle(center pc:Point,radius r:Double,color:Color) {
        self.circle(center: pc, radius: r, paint: Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func arcSector(center pc:Point,r0:Double,r1:Double,a0:Double,a1:Double,paint:Paint) {
        if r0>0.1 || r1>0.1 {
            let amin=min(a0,a1)
            let amax=max(a0,a1)
            let rmin=min(r0,r1)
            let rmax=max(r0,r1)
            let p=Path()
            let sArc={ (r:Double,a1:Double,a2:Double) in
                let a = (a2-a1)*0.5
                let x4 = cos(a)*r
                let y4 = sin(a)*r
                let x1 = x4
                let y1 = -y4
                let k = 0.551915024494
                let f = k * tan(a)
                let x2 = x1+f*y4
                let y2 = y1+f*x4
                let x3 = x2
                let y3 = -y2
                let ar = a1 + a
                let cosar = cos(ar)
                let sinar = sin(ar)
                let p2 = pc.translate(x2*cosar-y2*sinar,x2*sinar+y2*cosar)
                let p3 = pc.translate(x3*cosar-y3*sinar,x3*sinar+y3*cosar)
                let p4 = pc.translate(r*cos(a2),r*sin(a2))
                p.append(Path.Segment.cubicTo(p2,p3,p4))
            }
            let ia = ß.π * 0.5
            p.append(Path.Segment.moveTo(pc+Point(angle:amin,radius:rmin)))
            p.append(Path.Segment.lineTo(pc+Point(angle:amin,radius:rmax)))
            var aa=amin
            while aa<amax {
                let ae = min(aa+ia,amax)
                sArc(rmax,aa,ae)
                aa += ia
            }
            p.append(Path.Segment.lineTo(pc+Point(angle:amax,radius:rmin)))
            aa=amax
            while aa>amin {
                let ae = max(aa-ia,amin)
                sArc(rmin,aa,ae)
                aa -= ia
            }
            draw(p,paint)
        }
    }
    public func arcSector(center pc:Point,r0:Double,r1:Double,a0:Double,a1:Double,color:Color) {
        self.arcSector(center: pc, r0: r0, r1: r1, a0: a0, a1: a1, paint: Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func arcSector(center pc:Point,radius r:Double,a0:Double,a1:Double,paint:Paint)
    {
        if r>0.1 {
            let amin=min(a0,a1)
            let amax=max(a0,a1)
            let p=Path()
            let sArc={ (r:Double,a1:Double,a2:Double) in
                let a = (a2-a1)*0.5
                let x4 = cos(a)*r
                let y4 = sin(a)*r
                let x1 = x4
                let y1 = -y4
                let k = 0.551915024494
                let f = k * tan(a)
                let x2 = x1+f*y4
                let y2 = y1+f*x4
                let x3 = x2
                let y3 = -y2
                let ar = a1 + a
                let cosar = cos(ar)
                let sinar = sin(ar)
                let p2 = pc.translate(x2*cosar-y2*sinar,x2*sinar+y2*cosar)
                let p3 = pc.translate(x3*cosar-y3*sinar,x3*sinar+y3*cosar)
                let p4 = pc.translate(r*cos(a2),r*sin(a2))
                p.append(Path.Segment.cubicTo(p2,p3,p4))
            }
            let ia = ß.π * 0.5
            p.append(Path.Segment.moveTo(pc+Point(angle:amin,radius:r)))
            var aa=amin
            while aa<amax {
                let ae = min(aa+ia,amax)
                sArc(r,aa,ae)
                aa += ia
            }
            p.append(Path.Segment.close())
            draw(p,paint)
        }
    }
    public func arcSector(center pc:Point,radius r:Double,a0:Double,a1:Double,color:Color) {
        self.arcSector(center: pc, radius: r, a0: a0, a1: a1, paint: Paint(parent:self,color:color))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func roundRectangle(_ rect:Rect,radius r0:Double,paint:Paint) {
        let r=min(min(r0,rect.width*0.5),rect.height*0.5)
        let p=Path()
        let sArc={ (pc:Point,a1:Double,a2:Double) in
            let a = (a2-a1)*0.5
            let x4 = cos(a)*r
            let y4 = sin(a)*r
            let x1 = x4
            let y1 = -y4
            let k = 0.551915024494
            let f = k * tan(a)
            let x2 = x1+f*y4
            let y2 = y1+f*x4
            let x3 = x2
            let y3 = -y2
            let ar = a1 + a
            let cosar = cos(ar)
            let sinar = sin(ar)
            let p2 = pc.translate(x2*cosar-y2*sinar,x2*sinar+y2*cosar)
            let p3 = pc.translate(x3*cosar-y3*sinar,x3*sinar+y3*cosar)
            let p4 = pc.translate(r*cos(a2),r*sin(a2))
            p.append(Path.Segment.cubicTo(p2,p3,p4))
        }
        p.append(Path.Segment.moveTo(rect.left+r,rect.top))
        p.append(Path.Segment.lineTo(rect.right-r,rect.top))
        sArc(rect.topRight.translate(-r,r),-ß.π2,0)
        p.append(Path.Segment.lineTo(rect.right,rect.bottom-r))
        sArc(rect.bottomRight.translate(-r,-r),0,ß.π2)
        p.append(Path.Segment.lineTo(rect.left+r,rect.bottom))
        sArc(rect.bottomLeft.translate(r,-r),ß.π2,ß.π)
        p.append(Path.Segment.lineTo(rect.left,rect.top+r))
        sArc(rect.topLeft.translate(r,r),ß.π,3*ß.π2)
        draw(p,paint)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func contains(_ rect:Rect) -> Bool {
        let vv:[Vec3]=[matrix.transform(Vec3(rect.topLeft)),matrix.transform(Vec3(rect.topRight)),matrix.transform(Vec3(rect.bottomLeft)),matrix.transform(Vec3(rect.bottomRight))]
        var mix = Double.infinity
        var max = -Double.infinity
        var miy = Double.infinity
        var may = -Double.infinity
        for v in vv {
            if v.x>max {
                max = v.x
            }
            if v.x<mix {
                mix = v.x
            }
            if v.y>may {
                may = v.y
            }
            if v.y<miy {
                miy = v.y
            }
        }
        if max<=clip.left {
            return false
        }
        if mix>=clip.right {
            return false
        }
        if may<=clip.top {
            return false
        }
        if miy>=clip.bottom {
            return false
        }
        return true
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    static func transformClip(_ m:Mat4,_ r:Rect) -> Rect {
        let tl=m.transform(Vec3(r.topLeft))
        let br=m.transform(Vec3(r.bottomRight))
        return Rect(x:min(tl.x,br.x),y:min(tl.y,br.y),w:abs(br.x-tl.x),h:abs(br.y-tl.y))
    }
    public func setClipping() {
        let gpu = Mat4.gpu(size:self.output).inverted
        let tl = gpu.transform(Vec3(clip.topLeft))
        let br = gpu.transform(Vec3(clip.bottomRight))
        let r = Rect(x:min(tl.x,br.x),y:min(tl.y,br.y),w:abs(br.x-tl.x),h:abs(br.y-tl.y)).ceil
        render.clip(rect:r)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent g:Graphics,matrix m:Mat4=Mat4.identity,clip:Rect,clipping:Bool=false) {
        self.matrix=m*g.matrix
        self.output=g.output
        self.clip = g.clip.intersection(Graphics.transformClip(self.matrix,clip))
        self.render=g.render
        self.clipping=clipping
        renderOwner = false
        super.init(parent:g)
        if clipping {
            self.setClipping()
        }
    }
    public init(parent g:Graphics,matrix m:Mat4=Mat4.identity) {
        self.matrix=m*g.matrix
        self.output=g.output
        self.clip=g.clip
        self.render=g.render
        renderOwner = false
        super.init(parent:g)
    }
    public init(parent:NodeUI,graphics g:Graphics,matrix m:Mat4=Mat4.identity) {
        self.matrix=m*g.matrix
        self.output=g.output
        self.clip=g.clip
        self.render=g.render
        renderOwner = false
        super.init(parent:parent)
    }
    #if os(macOS) || os(iOS) || os(tvOS)
    public init(viewport:Viewport,descriptor:MTLRenderPassDescriptor,drawable:CAMetalDrawable,depth:MTLTexture?=nil,clear:Color?=nil,depthClear:Double=1.0,clip:Rect?=nil) {
        let m = Mat4.gpu(size:viewport.size)
        self.matrix=m
        self.output=viewport.size
        self.clip = Graphics.transformClip(m,(clip ?? Rect(o:Point.zero,s:viewport.size)))
        self.render=RenderPass(viewport:viewport,clear:clear,depthClear:depthClear,descriptor:descriptor,drawable:drawable,depth:depth)
        renderOwner = true
        super.init(parent:viewport)
    }
    #endif
    public init(image:Bitmap,clear:Color?=nil,depthClear:Double?=nil,storeDepth:Bool=false,clip:Rect?=nil) {
        let m = Mat4.gpu(size:image.size)
        self.matrix=m
        self.output=image.size
        self.clip = Graphics.transformClip(m,(clip ?? image.bounds))
        self.render=RenderPass(texture:image,clear:clear,depthClear:depthClear,storeDepth:storeDepth)
        renderOwner = true
        super.init(parent:image)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    deinit {
        if renderOwner {
            let r=render
            r.onDone.once { ok in
                r.detach()
            }
            r.commit()
        } else if clipping {
            var g = self
            while let gn = g.parent as? Graphics {
                g = gn
                if g.renderOwner || g.clipping {
                    g.setClipping()
                    break
                }
            }

        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func depthStencil(state:String) {
        if let d = self[state] as? DepthStencilState {
            render.use(state:d)
        }
    }
    public func program(_ prog:String,blend:BlendMode=BlendMode.opaque) {
        var pn:String=""
        switch blend {
        case BlendMode.opaque:
            pn = prog+".opaque"
            break
        case BlendMode.alpha:
            pn = prog+".alpha"
            break
        case BlendMode.setAlpha:
            pn = prog+".setalpha"
            break
        case BlendMode.mulAlpha:
            pn = prog+".mulalpha"
            break
        case BlendMode.color:
            pn = prog+".color"
            break
        case BlendMode.add:
            pn = prog+".add"
            break
        case BlendMode.sub:
            pn = prog+".sub"
            break
        case BlendMode.multiply:
            pn = prog+".multiply"
            break
        case BlendMode.screen:
            pn = prog+".screen"
            break
        case BlendMode.overlay:
            pn = prog+".overlay"
            break
        case BlendMode.softLight:
            pn = prog+".softlight"
            break
        case BlendMode.lighten:
            pn = prog+".lighten"
            break
        case BlendMode.darken:
            pn = prog+".darken"
            break
        case BlendMode.average:
            pn = prog+".average"
            break
        case BlendMode.substract:
            pn = prog+".substract"
            break
        case BlendMode.difference:
            pn = prog+".difference"
            break
        case BlendMode.negation:
            pn = prog+".negation"
            break
        case BlendMode.colorDodge:
            pn = prog+".colordodge"
            break
        case BlendMode.colorBurn:
            pn = prog+".colorburn"
            break
        case BlendMode.hardLight:
            pn = prog+".hardlight"
            break
        case BlendMode.exclusion:
            pn = prog+".exclusion"
            break
        case BlendMode.reflect:
            pn = prog+".reflect"
            break
        case BlendMode.glow:
            pn = prog+".glow"
            break
        case BlendMode.phoenix:
            pn = prog+".phoenix"
            break
        default:
            pn = prog+".copy"
            break
        }
        if let p=self[pn] as? Program {
            render.use(program:p)
        } else {
            Debug.error("program \"\(pn)\" not found",#file,#line)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func sampler(_ sampler:String)  {
        if let s=self[sampler] as? Sampler {
            render.use(s)
        } else {
            Debug.error("Not found")
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func buffer(_ size:Int) -> Buffer {
        let b=viewport!.gpu.buffers!.get(size)
        render.onDone.once { ok in
            b.detach()
        }
        return b
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func colorVertices(_ n:Int) -> UnsafeMutablePointer<ColorVertice> {
        let b=buffer(n * MemoryLayout<ColorVertice>.size)
        render.use(vertexBuffer:b,atIndex:0)
        return b.ptr.assumingMemoryBound(to: ColorVertice.self)  //UnsafeMutablePointer<ColorVertice>(b.ptr)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func textureVertices(_ n:Int) -> UnsafeMutablePointer<TextureVertice> {
        let b=buffer(n * MemoryLayout<TextureVertice>.size)
        render.use(vertexBuffer:b,atIndex:0)
        return b.ptr.assumingMemoryBound(to: TextureVertice.self) //UnsafeMutablePointer<TextureVertice>(b.ptr)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func textureMaskVertices(_ n:Int) -> UnsafeMutablePointer<TextureMaskVertice> {
        let b=buffer(n * MemoryLayout<TextureMaskVertice>.size)
        render.use(vertexBuffer:b,atIndex:0)
        return b.ptr.assumingMemoryBound(to: TextureMaskVertice.self)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func blurVertices(_ n:Int) -> UnsafeMutablePointer<BlurVertice> {
        let b=buffer(n * MemoryLayout<BlurVertice>.size)
        render.use(vertexBuffer:b,atIndex:0)
        return b.ptr.assumingMemoryBound(to: BlurVertice.self) //UnsafeMutablePointer<BlurVertice>(b.ptr)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func blendVertices(_ n:Int) -> UnsafeMutablePointer<BlendVertice> {
        let b=buffer(n * MemoryLayout<BlendVertice>.size)
        render.use(vertexBuffer:b,atIndex:0)
        return b.ptr.assumingMemoryBound(to: BlendVertice.self) //UnsafeMutablePointer<BlendVertice>(b.ptr)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func uniforms(_ matrix:Mat4)   {
        let b=buffer(MemoryLayout<Uniforms>.size)
        let ptr=b.ptr.assumingMemoryBound(to: Uniforms.self) //UnsafeMutablePointer<Uniforms>(b.ptr)
        ptr[0]=Uniforms(matrix:matrix.infloat4x4)
        render.use(vertexBuffer:b,atIndex:1)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func uniforms(view:Mat4,world:Mat4,eye:Vec3)   {
        let b=buffer(MemoryLayout<Uniforms3D>.size)
        let ptr=b.ptr.assumingMemoryBound(to: Uniforms3D.self)
        ptr[0]=Uniforms3D(view:view.infloat4x4,world:world.infloat4x4,eye:eye.infloat3)
        render.use(vertexBuffer:b,atIndex:1)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func uniforms(buffer b:Buffer,atIndex i:Int)   {
        render.use(vertexBuffer:b,atIndex:i)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    static func globals(_ viewport:Viewport) {
        viewport["program.color.copy"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.copy,fmt:[.float3,.float4])
        viewport["program.color.opaque"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.opaque,fmt:[.float3,.float4])
        viewport["program.color.alpha"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.alpha,fmt:[.float3,.float4])
        viewport["program.color.setalpha"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.setAlpha,fmt:[.float3,.float4])
        viewport["program.color.add"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.add,fmt:[.float3,.float4])
        viewport["program.color.sub"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorFuncFragment",blend:BlendMode.sub,fmt:[.float3,.float4])
        #if os(tvOS) || os(iOS)
            viewport["program.color.multiply"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendMultiply",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.screen"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendScreen",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.overlay"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendOverlay",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.softlight"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendSoftLight",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.lighten"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendLighten",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.darken"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendDarken",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.average"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendAverage",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.substract"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendSubstract",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.difference"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendDifference",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.negation"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendNegation",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.colordodge"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendColorDodge",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.colorburn"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendColorBurn",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.hardlight"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendHardLight",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.reflect"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendReflect",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.glow"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendGlow",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.phoenix"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendPhoenix",blend:BlendMode.opaque,fmt:[.float3,.float4])
            viewport["program.color.exclusion"]=Program(viewport:viewport,vertex:"colorFuncVertex",fragment:"colorBlendExclusion",blend:BlendMode.opaque,fmt:[.float3,.float4])
        #endif
        viewport["program.texture.copy"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragment",blend:BlendMode.copy,fmt:[.float3,.float4,.float2])
        viewport["program.texture.opaque"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragment",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
        viewport["program.texture.alpha"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragment",blend:BlendMode.alpha,fmt:[.float3,.float4,.float2])
        viewport["program.texture.setalpha"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragmentSetAlpha",blend:BlendMode.setAlpha,fmt:[.float3,.float4,.float2])
        viewport["program.texture.color"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragmentColor",blend:BlendMode.alpha,fmt:[.float3,.float4,.float2])
        viewport["program.texture.add"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragment",blend:BlendMode.add,fmt:[.float3,.float4,.float2])
        viewport["program.texture.sub"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragment",blend:BlendMode.sub,fmt:[.float3,.float4,.float2])
        #if os(tvOS) || os(iOS)
            viewport["program.texture.mulalpha"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureFuncFragmentMulAlpha",blend:BlendMode.setAlpha,fmt:[.float3,.float4,.float2])
            viewport["program.texture.multiply"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendMultiply",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.screen"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendScreen",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.overlay"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendOverlay",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.softlight"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendSoftLight",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.lighten"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendLighten",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.darken"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendDarken",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.average"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendAverage",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.substract"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendSubstract",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.difference"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendDifference",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.negation"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendNegation",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.colordodge"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendColorDodge",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.colorburn"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendColorBurn",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.hardlight"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendHardLight",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.reflect"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendReflect",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.glow"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendGlow",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.phoenix"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendPhoenix",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
            viewport["program.texture.exclusion"]=Program(viewport:viewport,vertex:"textureFuncVertex",fragment:"textureBlendExclusion",blend:BlendMode.opaque,fmt:[.float3,.float4,.float2])
        #endif
        Program.populateDefaultBlendModes(store: viewport, key: "program.texture.mask", library: viewport.gpu.library!, vertex: "textureFuncVertex", fragment: "textureMaskFragment", fmt: [.float3,.float4,.float2])
        Program.populateDefaultBlendModes(store: viewport, key: "program.texture.bitmap.mask", library: viewport.gpu.library!, vertex: "textureBitmapMaskFuncVertex", fragment: "textureBitmapMaskFragment", fmt: [.float3,.float4,.float2])
        Program.populateDefaultBlendModes(store: viewport, key: "program.gradient.mask", library: viewport.gpu.library!, vertex: "textureBitmapMaskFuncVertex", fragment: "textureGradientMaskFragment", fmt: [.float3,.float4,.float2])
        viewport["program.blur.horizontal.copy"]=Program(viewport:viewport,vertex:"blurFuncVertex",fragment:"blurH",blend:BlendMode.copy,fmt:[.float3,.float2])
        viewport["program.blur.vertical.copy"]=Program(viewport:viewport,vertex:"blurFuncVertex",fragment:"blurV",blend:BlendMode.copy,fmt:[.float3,.float2])
        viewport["sampler.clamp"]=Sampler(viewport:viewport,modeX:Sampler.Mode.clamp,modeY:Sampler.Mode.clamp)
        viewport["sampler.wrap"]=Sampler(viewport:viewport,modeX:Sampler.Mode.wrap,modeY:Sampler.Mode.wrap)
        viewport["sampler.mirror"]=Sampler(viewport:viewport,modeX:Sampler.Mode.mirror,modeY:Sampler.Mode.mirror)
        viewport["sampler.clamp.wrap"]=Sampler(viewport:viewport,modeX:Sampler.Mode.clamp,modeY:Sampler.Mode.wrap)
        viewport["sampler.wrap.clamp"]=Sampler(viewport:viewport,modeX:Sampler.Mode.wrap,modeY:Sampler.Mode.clamp)
        viewport["sampler.mirror.clamp"]=Sampler(viewport:viewport,modeX:Sampler.Mode.mirror,modeY:Sampler.Mode.clamp)
        viewport["sampler.clamp.mirror"]=Sampler(viewport:viewport,modeX:Sampler.Mode.clamp,modeY:Sampler.Mode.mirror)
        viewport["font.default"]=Font(parent:viewport,name:"Helvetica",size:24)
        
        viewport["program.blend.multiply"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendMultiply",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.screen"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendScreen",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.overlay"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendOverlay",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.softlight"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendSoftLight",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.add"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendAdd",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.lighten"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendLighten",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.darken"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendDarken",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.average"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendAverage",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.substract"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendSubstract",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.difference"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendDifference",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.negation"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendNegation",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.colordodge"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendColorDodge",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.colorburn"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendColorBurn",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.hardlight"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendHardLight",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.reflect"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendReflect",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.glow"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendGlow",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.phoenix"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendPhoenix",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.sub"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendSub",blend:BlendMode.opaque,fmt:[.float3,.float2])
        viewport["program.blend.exclusion"]=Program(viewport:viewport,vertex:"blendFuncVertex",fragment:"blendExclusion",blend:BlendMode.opaque,fmt:[.float3,.float2])
        
        Program.populateDefaultBlendModes(store:viewport,key:"program.gradient",library:viewport.gpu.library!,vertex:"textureFuncVertex",fragment:"gradientFragment",fmt:[.float3,.float4,.float2])
        Program.populateDefaultBlendModes(store:viewport,key:"program.gradient.alt",library:viewport.gpu.library!,vertex:"textureFuncVertex",fragment:"altGradientFragment",fmt:[.float3,.float4,.float2])
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct ColorVertice {
    var position:float3
    var color:float4
}
public struct TextureVertice  {
    var position:float3
    var color:float4
    var uv:float2
    public init(position:float3,uv:float2,color:float4) {
        self.position=position
        self.uv=uv
        self.color=color
    }
}
public struct TextureMaskVertice  {
    var position:float3
    var color:float4
    var uv:float2
    var uvmask:float2
    public init(position:float3,uv:float2,uvmask:float2,color:float4) {
        self.position=position
        self.uv=uv
        self.uvmask=uvmask
        self.color=color
    }
}
struct BlurVertice  {
    var position:float3
    var uv:float2
}
struct Uniforms {
    var matrix:float4x4
}
struct Uniforms3D {
    var view:float4x4
    var world:float4x4
    var eye:float3
}
struct BlendVertice  {
    var position:float3
    var uv:float2
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Vertice { // public version
    public var position:Vec3
    public var color:Color
    public var uv:Point
    public init(position:Vec3=Vec3.zero,uv:Point=Point.zero,color:Color=Color.white) {
        self.position = position
        self.uv = uv
        self.color = color
    }
    public static func trianglesFromQuad(_ v0:Vertice,_ v1:Vertice,_ v2:Vertice,_ v3:Vertice) -> [Vertice] {
        var ov = [Vertice]()
        let c = (v0+v1+v2+v3)*0.25
        ov.append(v0)
        ov.append(c)
        ov.append(v1)
        ov.append(v1)
        ov.append(c)
        ov.append(v2)
        ov.append(v2)
        ov.append(c)
        ov.append(v3)
        ov.append(v3)
        ov.append(c)
        ov.append(v0)
        return ov
    }
    var textureVertice : TextureVertice {
        return TextureVertice(position: position.infloat3, uv: uv.infloat2, color: color.infloat4)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(lhs:Vertice, rhs: Vertice) -> Bool {
    return (lhs.color==rhs.color)&&(lhs.position==rhs.position)&&(lhs.uv==rhs.uv)
}
public func !=(lhs:Vertice, rhs: Vertice) -> Bool {
    return (lhs.color != rhs.color) || (lhs.position != rhs.position) || (lhs.uv != rhs.uv)
}
public func +(lhs: Vertice, rhs: Vertice) -> Vertice {
    return Vertice(position: lhs.position+rhs.position, uv: lhs.uv+rhs.uv, color: lhs.color+rhs.color)
}
public func -(lhs: Vertice, rhs: Vertice) -> Vertice {
    return Vertice(position: lhs.position-rhs.position, uv: lhs.uv-rhs.uv, color: lhs.color-rhs.color)
}
public func *(lhs: Vertice, rhs: Double) -> Vertice {
    return Vertice(position: lhs.position*rhs, uv: lhs.uv*rhs, color: lhs.color*rhs)
}
public func /(lhs: Vertice, rhs: Double) -> Vertice {
    return Vertice(position: lhs.position/rhs, uv: lhs.uv/rhs, color: lhs.color/rhs)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct PointSprite {
    public var position:Point
    public var scale:Double
    public var color:Color
    public init(position:Point,scale:Double=1,color:Color=Color.white) {
        self.position=position
        self.scale=scale
        self.color=color
    }
}
public enum BlendMode : Int {
    case opaque = 0
    case copy
    case add
    case sub
    case setAlpha   // keep rgb, replace alpha by source red channel
    case mulAlpha   // keep rgb, mul alpha by source red channel
    case color      // set color from mask
    case lighten
    case darken
    case multiply
    case average
    case substract
    case difference
    case negation
    case screen
    case exclusion
    case overlay
    case softLight
    case hardLight
    case colorDodge
    case colorBurn
    case linearLight
    case glow
    case phoenix
    case reflect
    case alpha = 0x10000
    case mask = 0x20000    // ?? not sure if neeeded
    public static var defaultModes : [BlendMode] {
        return [ .opaque,.copy,.add,.sub,.alpha ]
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
