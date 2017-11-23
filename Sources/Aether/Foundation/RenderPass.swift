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
#if os(macOS) || os(iOS) || os(tvOS)
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
        }
        public enum Winding {
            case clockwise
            case counterClockwise
            var system:MTLWinding {
                switch self {
                case .clockwise:
                    return MTLWinding.clockwise
                case .counterClockwise:
                    return MTLWinding.counterClockwise
                }
            }
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public private(set) var onDone=Event<Result>()
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        var cb:MTLCommandBuffer
        var drawable:MTLDrawable?
        var command:MTLRenderCommandEncoder?
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
            if useDepth {
                command!.setRenderPipelineState(program.rpsdepth!)
            } else {
                command!.setRenderPipelineState(program.rpsnodepth!)
            }
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
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class Program : NodeUI {
        // TODO: MetaProgram using MTLRenderPipelineReflection
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        var rpsdepth:MTLRenderPipelineState?
        var rpsnodepth:MTLRenderPipelineState?
        public init(viewport:Viewport,vertex:String,fragment:String,blend:BlendMode,fmt:[MTLVertexFormat]) {
            super.init(parent:viewport)
            rpsnodepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.invalid)
            rpsdepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.depth32Float)
        }
        init(viewport:Viewport,vertex:String,fragment:String,blend:BlendMode,vdesc:MTLVertexDescriptor) {
            super.init(parent:viewport)
            rpsnodepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.invalid)
            rpsdepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.depth32Float)
        }
        public init(library:ProgramLibrary,vertex:String,fragment:String,blend:BlendMode,fmt:[MTLVertexFormat]) {
            super.init(parent:library)
            rpsnodepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.invalid)
            rpsdepth = self.createPipelineState(viewport.gpu.library!,vertex:vertex,fragment:fragment,blend:blend,vdesc:Program.VertexDescriptor(fmt),depth:.depth32Float)
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        private func createPipelineState(_ library:ProgramLibrary,vertex:String,fragment:String,blend:BlendMode,vdesc:MTLVertexDescriptor,depth:MTLPixelFormat) -> MTLRenderPipelineState? {
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
            pipe.depthAttachmentPixelFormat = depth
            do {
                let rps = try viewport!.gpu.device!.makeRenderPipelineState(descriptor: pipe)
                return rps
            } catch {
                Debug.error("error: Program.initSelf()")
            }
            return nil
        }
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
        }
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
            // super.detach()   // don't detach has been re-attached to Buffers
        }
        public func destroy() { // really detach
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
#else
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class RenderPass : NodeUI {
        public enum Result {
            case error
            case discarded
            case success
        }
        public enum CullMode {
            case none
            case front
            case back
        }
        public enum Winding {
            case clockwise
            case counterClockwise
        }
        struct ProgramStates {
            var program : Program?
            var sampler = [Int:Sampler]()
            var vertexBuffer = [Int:Buffer]()
            var fragmentBuffer = [Int:Buffer]()
            var vertexTexture = [Int:Texture2D]()
            var fragmentTexture = [Int:Texture2D]()
            var depth : DepthStencilState?
            var clip = Rect.zero
            var cull = CullMode.front
            var winding = Winding.clockwise
            func createLayout() {
                for s in sampler {

                }
                for v in vertexBuffer {

                }
                for f in fragmentBuffer {
                    
                }
            }
            mutating func reset() {
                sampler.removeAll()
                vertexBuffer.removeAll()
                fragmentBuffer.removeAll()
                vertexTexture.removeAll()
                fragmentTexture.removeAll()
                depth = nil
                clip = .zero
                cull = .front
                winding = .clockwise
            }
        }

        public let onDone=Event<Result>()

        var renderPass:Tin.RenderPass

        var states = ProgramStates()

        public func use(program:Program) {
            states.reset()
            states.program = program
        }
        func use(_ sampler:Sampler, atIndex index:Int=0) {
            states.sampler[index] = sampler
        }
        public func use(state:DepthStencilState) {
            states.depth = state
        }
        public func use(vertexBuffer buffer:Buffer,atIndex index:Int) {
            states.vertexBuffer[index] = buffer
        }
        public func use(fragmentBuffer buffer:Buffer,atIndex index:Int) {
            states.fragmentBuffer[index] = buffer
        }
        public func use(texture:Texture2D, atIndex index:Int=0) {
            states.fragmentTexture[index] = texture
        }
        public func use(vertexTexture vt: Texture2D, atIndex index:Int=0) {
            states.vertexTexture[index] = vt
        }
        public func clip(rect r:Rect) {
            states.clip = r
        }
        public func set(cull:CullMode) {
            states.cull = cull
        }
        public func set(front:Winding) {
            states.winding = front
        }
        func createPipeline() -> Tin.Pipeline? {
            //pipeline = program.createPipeline(renderpass:self)
            return nil
        }
        public func draw(triangle n:Int) {
        }
        public func draw(trianglestrip n:Int) {
        }
        public func draw(triangle n:Int,index:Buffer) {
        }
        public func draw(line n:Int) {
        }
        public func draw(sprite n:Int) {
        }
        public func commit() {
        }
        init(texture:Texture2D,clear:Color?=nil,depthClear:Double?=nil,storeDepth:Bool=false) {
            renderPass = Tin.RenderPass(to:texture.texture!)!
            super.init(parent:texture)
        }
        init(viewport:Viewport,clear:Color?=nil,depthClear:Double=1.0,image:Tin.Image) {
            renderPass = Tin.RenderPass(to:image)!
            super.init(parent:viewport)
        }
    }
    class Sampler : NodeUI {
        enum Mode {
            case clamp
            case wrap
            case mirror
        }
        init(viewport:Viewport,modeX:Mode,modeY:Mode) {
            super.init(parent:viewport)
        }
    }
    public class DepthStencilState : NodeUI {
        public enum Mode {
            case none
            case greater
            case lesser
            case all
        }
        public init(viewport:Viewport,mode:Mode,write:Bool) {
            super.init(parent:viewport)
        }
        public init(viewport:Viewport) {
            super.init(parent:viewport)
        }
    }
    public class Buffer : NodeUI {
        var buffer:Tin.Buffer?
        init(buffers:Buffers,size:Int) {
            super.init(parent:buffers)
            self.buffer = Tin.Buffer(engine:viewport!.gpu.engine!,size:size)
        }
        public func recycle() {
            if let bs=parent as? Buffers {
                bs.set(self)
            }
        }
        public func data(fn:(UnsafeMutableRawPointer)->()) {
            buffer?.withMemoryMap { p in
                fn(p)
            }
        }
        public var size:Int {
            return buffer!.size
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public typealias VertexFormat = Tin.Pipeline.VertexFormat
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class Program : NodeUI {
        let vertexName : String
        let fragmentName : String
        var vertex : Tin.Shader?
        var fragment : Tin.Shader? 
        let vertexFormat : [VertexFormat]
        public init(viewport:Viewport,vertex:String,fragment:String,blend:BlendMode,fmt:[VertexFormat]) {
            self.vertexName = vertex
            self.fragmentName = fragment
            if let vertexCode = Application.getData("Shaders/\(vertex).vert.spv") {
                self.vertex = Tin.Shader(engine:viewport.gpu.engine!,code:vertexCode)
            } else {
                Debug.error("Shaders/\(vertex).vert.spv not found")
            }
            if let fragmentCode = Application.getData("Shaders/\(fragment).frag.spv") {
                self.fragment = Tin.Shader(engine:viewport.gpu.engine!,code:fragmentCode)
            } else {
                Debug.error("Shaders/\(fragment).vert.spv not found")
            }
            self.vertexFormat = fmt
            super.init(parent:viewport)
        }
        public convenience init(library:ProgramLibrary,vertex:String,fragment:String,blend:BlendMode,fmt:[VertexFormat]) {
            self.init(viewport:library.viewport!,vertex:vertex,fragment:fragment,blend:blend,fmt:fmt)
        }
        public static func populateDefaultBlendModes(store:NodeUI,key:String,library:ProgramLibrary,vertex:String,fragment:String,fmt:[VertexFormat]) {
            for bm in BlendMode.defaultModes {
                store[Program.fullKey(key,blend:bm)] = Program(library:library,vertex:vertex,fragment:fragment,blend:bm,fmt:fmt)
            }
        }
        func createPipeline(renderpass rp:RenderPass) -> Tin.Pipeline? {
            let st = Tin.Pipeline.States()
            // TODO: fill states
            return Tin.Pipeline(renderpass:rp.renderPass,vertex:vertex!,fragment:fragment!,states:st)
        }
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
    public class ProgramLibrary : NodeUI {  // not used with vulkan
        public init(parent:NodeUI,filename:String="default") {
            super.init(parent:parent)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Buffers : NodeUI {
    let lock=Lock()
    var bl=[Int:Set<Buffer>]()
    init(viewport:Viewport) {
        super.init(parent:viewport)
    }
    public override func detach() {
        super.detach()
    }
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
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
