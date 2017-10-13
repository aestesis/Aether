//
//  RenderPass.swift
//  Aether
//
//  Created by renan jegouzo on 18/03/2016.
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
    import simd
#else
    import Uridium
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class RenderPass : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum Result {
        case error
        case discarded
        case success
    }
    public enum CullMode {
        case none
        case front
        case back
        #if os(macOS) || os(iOS) || os(tvOS)
            var system:MTLCullMode {
                switch self {
                case .none:
                    return MTLCullMode.none
                case .front:
                    return MTLCullMode.front
                case .back:
                    return MTLCullMode.back
                }
            }
        #else
        // TODO:
        #endif
    }
    public enum Winding {
        case clockwise
        case counterClockwise
        #if os(macOS) || os(iOS) || os(tvOS)
            var system:MTLWinding {
                switch self {
                case .clockwise:
                    return MTLWinding.clockwise
                case .counterClockwise:
                    return MTLWinding.counterClockwise
                }
            }
        #else 
        // TODO:
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var onDone=Event<Result>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
        var cb:MTLCommandBuffer
        var drawable:MTLDrawable?
        var command:MTLRenderCommandEncoder?
    #else
        var cb:Tin.CommandBuffer
        var command:Tin.RenderCommandEncoder?
    #endif
    var size:Size = .zero
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func commit() {
        command!.endEncoding()
        if let d=drawable {
            cb.present(d)
        }
        command = nil
        cb.commit()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func use(_ sampler:Sampler, atIndex index:Int=0) {
        command!.setFragmentSamplerState(sampler.state, index:index)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(program:Program) {
        command!.setRenderPipelineState(program.rps!)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(state:DepthStencilState) {
        command!.setDepthStencilState(state.state)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(vertexBuffer buffer:Buffer,atIndex index:Int) {
        command!.setVertexBuffer(buffer.b,offset:0,index:index)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(fragmentBuffer fragment:Buffer,atIndex index:Int) {
        command!.setFragmentBuffer(fragment.b, offset: 0, index: index)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(texture:Texture2D, atIndex index:Int=0) {
        command!.setFragmentTexture(texture.texture, index: index)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func use(vertexTexture vt: Texture2D, atIndex index:Int=0) {
        command!.setVertexTexture(vt.texture,index:index)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func draw(triangle n:Int) {
        command!.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: n)
    }
    public func draw(trianglestrip n:Int) {
        command!.drawPrimitives(type:.triangleStrip,vertexStart:0,vertexCount:n)
    }
    public func draw(triangle n:Int,index:Buffer) {
        command!.drawIndexedPrimitives(type:.triangle,indexCount:n,indexType:.uint32,indexBuffer:index.b,indexBufferOffset:0)
    }
    public func draw(line n:Int) {
        command!.drawPrimitives(type:.line,vertexStart:0,vertexCount:n)
    }
    public func draw(sprite n:Int) {
        command!.drawPrimitives(type:.point,vertexStart:0,vertexCount:n)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func clip(rect r:Rect) {
        command!.setScissorRect(MTLScissorRect(x:Int(r.x),y:Int(r.y),width:Int(r.w),height:Int(r.h)))
    }
    public func set(cull:CullMode) {
        command!.setCullMode(cull.system)
    }
    public func set(front:Winding) {
        command!.setFrontFacing(front.system)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
        init(texture:Texture2D,clear:Color?=nil,depthClear:Double?=nil,storeDepth:Bool=false) {
            cb=texture.viewport!.gpu.queue.makeCommandBuffer()!
            super.init(parent:texture.viewport!)
            let descriptor=MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].texture=texture.texture
            if let c=clear {
                descriptor.colorAttachments[0].loadAction=MTLLoadAction.clear
                descriptor.colorAttachments[0].clearColor=MTLClearColorMake(c.r,c.g,c.b,c.a)
            } else {
                descriptor.colorAttachments[0].loadAction=MTLLoadAction.load
            }
            descriptor.colorAttachments[0].storeAction = MTLStoreAction.store
            if let depthClear = depthClear {    // https://metashapes.com/blog/reading-depth-buffer-metal-api/
                let dd=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:MTLPixelFormat.depth32Float,width:Int(texture.pixels.width),height:Int(texture.pixels.height),mipmapped:false)
                dd.usage = [.renderTarget]
                dd.resourceOptions = .storageModePrivate
                let dt=self.viewport!.gpu.device?.makeTexture(descriptor:dd)
                descriptor.depthAttachment.clearDepth = depthClear
                descriptor.depthAttachment.texture = dt
                descriptor.depthAttachment.loadAction=MTLLoadAction.clear
                if storeDepth {
                    descriptor.depthAttachment.storeAction=MTLStoreAction.store
                } else {
                    descriptor.depthAttachment.storeAction=MTLStoreAction.dontCare
                }
            }
            size = texture.display
            command=cb.makeRenderCommandEncoder(descriptor:descriptor)
            if let cm = command {
                cm.setViewport(MTLViewport(originX:0,originY:0,width:texture.pixels.width,height:texture.pixels.height,znear:0,zfar:1))
            }
            cb.addCompletedHandler({ (cb:MTLCommandBuffer) in
                if cb.status == .error {
                    if cb.error!.localizedDescription.lowercased().contains("discarded") {
                        self.onDone.dispatch(.discarded)
                    } else {
                        Debug.error("Texture rendering error, parent:\(texture.parent!.className), error:\(cb.error!.localizedDescription)")
                        self.onDone.dispatch(.error)
                    }
                } else {
                    if storeDepth {
                        let w = Int(texture.pixels.width)
                        let h = Int(texture.pixels.height)
                        let src = descriptor.depthAttachment.texture!
                        let depth = self.viewport!.gpu.device!.makeBuffer(length:w*h*4,options:MTLResourceOptions())
                        let cb = texture.viewport!.gpu.queue.makeCommandBuffer()
                        let blit = cb?.makeBlitCommandEncoder()
                        blit?.copy(from:src,sourceSlice:0,sourceLevel:0,sourceOrigin:MTLOriginMake(0,0,0),sourceSize:MTLSizeMake(w,h,1),to:depth!,destinationOffset:0,destinationBytesPerRow:4*w,destinationBytesPerImage:4*w*h)
                        blit?.endEncoding()
                        cb?.commit()
                        cb?.waitUntilCompleted()
                        var r = [Float32](repeating:0,count:w*h)
                        memcpy(&r,depth?.contents(),w*h*4)
                        texture["depth"] = r
                        self.onDone.dispatch(.success)
                    } else {
                        self.onDone.dispatch(.success)
                    }
                }
                self.detach()
            })
        }
        init(viewport:Viewport,clear:Color?=nil,depthClear:Double=1.0,descriptor:MTLRenderPassDescriptor,drawable:CAMetalDrawable,depth:MTLTexture?=nil) {
            self.drawable=drawable
            cb=viewport.gpu.queue.makeCommandBuffer()!
            descriptor.colorAttachments[0].texture=drawable.texture
            if let c=clear {
                descriptor.colorAttachments[0].loadAction=MTLLoadAction.clear
                descriptor.colorAttachments[0].clearColor=MTLClearColorMake(c.r,c.g,c.b,c.a)
            } else {
                descriptor.colorAttachments[0].loadAction=MTLLoadAction.dontCare
            }
            descriptor.colorAttachments[0].storeAction = MTLStoreAction.store
            if let depth=depth {
                descriptor.depthAttachment.clearDepth = depthClear
                descriptor.depthAttachment.texture = depth
                descriptor.depthAttachment.loadAction=MTLLoadAction.clear
                descriptor.depthAttachment.storeAction=MTLStoreAction.dontCare
            }
            size = viewport.size
            let vsize = viewport.size * viewport.scale
            command=cb.makeRenderCommandEncoder(descriptor: descriptor)
            if let cm = command {
                cm.setViewport(MTLViewport(originX:0,originY:0,width:vsize.width,height:vsize.height,znear:0,zfar:1))
            }
            super.init(parent:viewport)
            cb.addCompletedHandler({ (cb:MTLCommandBuffer) in
                if cb.status == .error {
                    if cb.error!.localizedDescription.lowercased().contains("discarded") {
                        self.onDone.dispatch(.discarded)
                    } else {
                        Debug.error("Viewport rendering error:\(cb.error!.localizedDescription)")
                        self.onDone.dispatch(.error)
                    }
                } else {
                    self.onDone.dispatch(.success)
                }
                self.detach()
            })
        }
    #else
        init(texture:Texture2D,clear:Color?=nil,depthClear:Double?=nil,storeDepth:Bool=false) {
            super.init(parent:texture.viewport!)
        }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override public func detach() {
        onDone.removeAll()
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Sampler : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    enum Mode {
        case clamp
        case wrap
        case mirror
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var state:MTLSamplerState
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    init(viewport:Viewport,modeX:Mode,modeY:Mode) {
        let d=MTLSamplerDescriptor()
        switch modeX {
        case .clamp:
            d.sAddressMode = .clampToEdge
            break
        case .wrap:
            d.sAddressMode = .repeat
            break
        case .mirror:
            d.sAddressMode = .mirrorRepeat
            break;
        }
        switch modeY {
        case .clamp:
            d.tAddressMode = .clampToEdge
            break
        case .wrap:
            d.tAddressMode = .repeat
            break
        case .mirror:
            d.tAddressMode = .mirrorRepeat
            break;
        }
        d.minFilter = .linear
        d.magFilter = .linear
        d.mipFilter = .linear
        state = viewport.gpu.device!.makeSamplerState(descriptor: d)!
        super.init(parent:viewport)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class DepthStencilState : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum Mode {
        case none
        case greater
        case lesser
        case all
    }
    #if os(macOS) || os(iOS) || os(tvOS)
        var state:MTLDepthStencilState
        public init(viewport:Viewport,mode:Mode,write:Bool) {
            let d=MTLDepthStencilDescriptor()
            d.isDepthWriteEnabled = write
            switch mode {
            case .none:
                d.depthCompareFunction = .never
            case .greater:
                d.depthCompareFunction = .greaterEqual
            case .lesser:
                d.depthCompareFunction = .lessEqual
            case .all:
                d.depthCompareFunction = .always
            }
            state = viewport.gpu.device!.makeDepthStencilState(descriptor:d)!
            super.init(parent:viewport)
        }
        public init(viewport:Viewport) {
            let d=MTLDepthStencilDescriptor()
            d.isDepthWriteEnabled = false
            d.depthCompareFunction = .always
            state = viewport.gpu.device!.makeDepthStencilState(descriptor:d)!
            super.init(parent:viewport)
        }
    #else
        public init(viewport:Viewport,mode:Mode,write:Bool) {
            super.init(parent:viewport)
            Debug.notImplemented()
            // TODO:
        }
        public init(viewport:Viewport) {
            super.init(parent:viewport)
            Debug.notImplemented()
            // TODO:
        }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Program : NodeUI {
    
    // TODO: MetaProgram using MTLRenderPipelineReflection
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var rps:MTLRenderPipelineState?
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(viewport:Viewport,vertex:String,fragment:String,blend:BlendMode,fmt:[MTLVertexFormat]) {
        super.init(parent:viewport)
        self.initSelf(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    init(viewport:Viewport,vertex:String,fragment:String,blend:BlendMode,vdesc:MTLVertexDescriptor) {
        super.init(parent:viewport)
        self.initSelf(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:vdesc)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(library:ProgramLibrary,vertex:String,fragment:String,blend:BlendMode,fmt:[MTLVertexFormat]) {
        super.init(parent:library)
        self.initSelf(library,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    private func initSelf(_ library:ProgramLibrary,vertex:String,fragment:String,blend:BlendMode,vdesc:MTLVertexDescriptor) {
        let pipe=MTLRenderPipelineDescriptor()
        let ca=pipe.colorAttachments[0]
        ca?.pixelFormat=MTLPixelFormat.bgra8Unorm
        switch blend {
        case BlendMode.opaque:
            ca?.isBlendingEnabled=true
            ca?.rgbBlendOperation=MTLBlendOperation.add
            ca?.alphaBlendOperation=MTLBlendOperation.max
            ca?.sourceRGBBlendFactor=MTLBlendFactor.one
            ca?.destinationRGBBlendFactor=MTLBlendFactor.zero
            ca?.sourceAlphaBlendFactor=MTLBlendFactor.one
            ca?.destinationAlphaBlendFactor=MTLBlendFactor.one
            break
        case BlendMode.alpha:
            ca?.isBlendingEnabled=true
            ca?.rgbBlendOperation=MTLBlendOperation.add
            ca?.alphaBlendOperation=MTLBlendOperation.max
            ca?.sourceRGBBlendFactor=MTLBlendFactor.sourceAlpha
            ca?.destinationRGBBlendFactor=MTLBlendFactor.oneMinusSourceAlpha
            ca?.sourceAlphaBlendFactor=MTLBlendFactor.one
            ca?.destinationAlphaBlendFactor=MTLBlendFactor.one
            break
        case BlendMode.setAlpha:
            ca?.isBlendingEnabled=true
            ca?.rgbBlendOperation=MTLBlendOperation.add
            ca?.alphaBlendOperation=MTLBlendOperation.add
            ca?.sourceRGBBlendFactor=MTLBlendFactor.zero
            ca?.destinationRGBBlendFactor=MTLBlendFactor.one
            ca?.sourceAlphaBlendFactor=MTLBlendFactor.one
            ca?.destinationAlphaBlendFactor=MTLBlendFactor.zero
            break
        case BlendMode.add:
            ca?.isBlendingEnabled=true
            ca?.rgbBlendOperation=MTLBlendOperation.add
            ca?.alphaBlendOperation=MTLBlendOperation.add
            ca?.sourceRGBBlendFactor=MTLBlendFactor.one
            ca?.destinationRGBBlendFactor=MTLBlendFactor.one
            ca?.sourceAlphaBlendFactor=MTLBlendFactor.one
            ca?.destinationAlphaBlendFactor=MTLBlendFactor.one
            break
        case BlendMode.sub:
            ca?.isBlendingEnabled=true
            ca?.rgbBlendOperation=MTLBlendOperation.reverseSubtract
            ca?.alphaBlendOperation=MTLBlendOperation.add
            ca?.sourceRGBBlendFactor=MTLBlendFactor.one
            ca?.destinationRGBBlendFactor=MTLBlendFactor.one
            ca?.sourceAlphaBlendFactor=MTLBlendFactor.one
            ca?.destinationAlphaBlendFactor=MTLBlendFactor.one
            break
        default:    // BlendMode.Copy
            ca?.isBlendingEnabled=false
            break
        }
        pipe.vertexFunction=library.lib!.makeFunction(name: vertex)!
        pipe.fragmentFunction=library.lib!.makeFunction(name: fragment)!
        pipe.vertexDescriptor=vdesc
        pipe.depthAttachmentPixelFormat = .depth32Float
        do {
            try rps=viewport!.gpu.device!.makeRenderPipelineState(descriptor: pipe)
        } catch {
            Debug.error("error: Program.initSelf()")
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func VertexDescriptor(_ fmt:[MTLVertexFormat]) -> MTLVertexDescriptor {
        let vd=MTLVertexDescriptor()
        var off=0
        var i=0
        for f in fmt {
            vd.attributes[i].bufferIndex=0
            vd.attributes[i].offset=off
            vd.attributes[i].format=f
            i += 1
            off+=SizeOf(f)
        }
        vd.layouts[0].stepFunction = .perVertex
        vd.layouts[0].stride=off
        return vd
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func SizeOf(_ f:MTLVertexFormat) -> Int {
        switch f {
        case MTLVertexFormat.float:
            return 1*4
        case MTLVertexFormat.float2:
            return 2*4
        case MTLVertexFormat.float3:
            return 3*4
        case MTLVertexFormat.float4:
            return 4*4
        default:
            Debug.notImplemented()
            return 0
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func populateDefaultBlendModes(store:NodeUI,key:String,library:ProgramLibrary,vertex:String,fragment:String,fmt:[MTLVertexFormat]) {
        for bm in BlendMode.defaultModes {
            store[Program.fullKey(key,blend:bm)] = Program(library:library,vertex:vertex,fragment:fragment,blend:bm,fmt:fmt)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func fullKey(_ key:String,blend:BlendMode) -> String{
        switch blend {
        case BlendMode.opaque:
            return key+".opaque"
        case BlendMode.alpha:
            return key+".alpha"
        case BlendMode.setAlpha:
            return key+".setalpha"
        case BlendMode.color:
            return key+".color"
        case BlendMode.add:
            return key+".add"
        case BlendMode.sub:
            return key+".sub"
        default:
            return key+".copy"
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Buffer : NodeUI {
    var b:MTLBuffer
    init(buffers:Buffers,size:Int) {
        b=buffers.viewport!.gpu.device!.makeBuffer(length:size,options:MTLResourceOptions())!
        super.init(parent:buffers)
    }
    override public func detach() {
        if let bs=parent as? Buffers {
            bs.set(self)
        }
        super.detach()
    }
    public var ptr:UnsafeMutableRawPointer {
        return b.contents()
    }
    public var size:Int {
        return b.length
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Buffers : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    let lock=Lock()
    var bl=[Int:Set<Buffer>]()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    init(viewport:Viewport) {
        super.init(parent:viewport)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func get(_ size:Int, persistent:Bool=false) -> Buffer {
        let sz = persistent ? size : (size<16384 ? (size<512 ? ((size / 32) + 1) * 32 : ((size / 1024) + 1) * 1024) : (size / 32768 + 1) * 32768)
        var b:Buffer?
        lock.synced {
            if self.bl[sz] != nil {
                if let b0=self.bl[sz]!.first {
                    self.bl[sz]!.remove(b0)
                    b=b0
                    return
                }
            }
            b=Buffer(buffers:self,size:sz)
            //Debug.info("new gpu buffer, size: \(size)")
        }
        return b!
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func set(_ b:Buffer) {
        lock.synced {
            if self.bl[b.size] != nil {
                #if DEBUG
                if self.bl[b.size]!.contains(b) {
                    Debug.error("buffer already in pool",#file,#line)
                    return
                }
                #endif
                self.bl[b.size]!.insert(b)
            } else {
                self.bl[b.size]=Set<Buffer>()
                self.bl[b.size]!.insert(b)
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class ProgramLibrary : NodeUI {
    var lib:MTLLibrary?
    public init(parent:NodeUI,filename:String="default") {
        super.init(parent:parent)
        let bundle = Bundle(for: type(of:parent))
        let libpath = bundle.path(forResource: filename, ofType: "metallib")!
        do {
            lib = try viewport!.gpu.device!.makeLibrary(filepath: libpath)
        } catch {
            Debug.error("can't load metal library \(filename) in \(bundle.infoDictionary!["CFBundleName"]!)")
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
