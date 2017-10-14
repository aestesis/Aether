//
//  Renderer.swift
//  Alib
//
//  Created by renan jegouzo on 17/05/2017.
//  Copyright © 2017 aestesis. All rights reserved.
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
#else
    import Uridium
#endif

// TODO: add mouse/touch support http://antongerdelan.net/opengl/raycasting.html
// TODO: normal mapping https://learnopengl.com/#!Advanced-Lighting/Normal-Mapping  http://fabiensanglard.net/bumpMapping/index.php

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public protocol RenderNode {
    var renderer:Renderer? { get }
    var world:Node3D? { get set }
    var camera:Camera3D? { get set }
    var db:NodeUI { get }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Renderer : NodeUI {
    struct RenderInfo {
        var node:Node3D
        var g:Graphics
        var world:Mat4
    }
    public var db:NodeUI? {
        return self.parent as? NodeUI
    }
    public var world:Node3D?
    public var camera:Camera3D?
    public private(set) var lights=[Light]()
    public var lightsProgram : String {
        if lights.count == 0 {
            return ""
        }
        if lights.count>1 {
            return "point.\(lights.count)."
        }
        if lights[0] is DirectionalLight {
            return "directional."
        }
        return "point.1."
    }
    func perspective(scale s:Double=1) -> Mat4 {
        return Mat4.scale(Vec3(x:s,y:s,z:0.002))*Mat4.perspective(view:Size.unity,angleOfView:ß.π2,near:0.1,far:1000)
    }
    public init(parent:NodeUI) {
        super.init(parent:parent)
        if let db = self.db {
            db["material.default"] = Material(parent:db,name:"default")
        }
    }
    override public func detach() {
        camera = nil
        if let world=world {
            world.detach()
            self.world = nil
        }
        super.detach()
    }
    public func render(to g:Graphics,size:Size) {
        if let world=self.world, let camera=self.camera {
            let lights:[Light]=world.children(recursive:true)
            if lights.count>1 {
                self.lights = lights.filter{$0 is PointLight}
            } else {
                self.lights = lights
            }
            let perspective = self.perspective(scale:size.length/1400)*Mat4.translation(Vec3(size.point(0.5,0.5)))
            let gview = Graphics(parent:g,matrix:camera.viewMatrix*perspective)
            let nodesTrans = self.render(to:gview,world:world.matrix,node:world,opaque:true)
            // TODO: z sort nodesTrans
            for n in nodesTrans {
                _ = n.node.render(to:n.g,world:n.world,opaque:false)
            }
        }
    }
    func render(to g:Graphics,world:Mat4,node:Node3D,opaque:Bool) -> [RenderInfo] {
        var infos=[RenderInfo]()
        if node.render(to:g,world:world,opaque:opaque) {
            infos.append(RenderInfo(node:node,g:g,world:world))
        }
        let mirrors = node.subnodes.filter { n -> Bool in
            return n is Mirror
        }
        if mirrors.count>0 {
            let nodes = node.subnodes.filter { n -> Bool in
                return !(n is Mirror)
            }
            for n in nodes {
                let gn = Graphics(parent:g,matrix:n.matrix)
                infos.append(contentsOf:self.render(to:gn,world:n.matrix*world,node:n,opaque:opaque))
            }
            for m in mirrors {
                let gm = Graphics(parent:g,matrix:m.matrix)
                let wm = m.matrix*world
                for n in nodes {
                    let gn = Graphics(parent:gm,matrix:n.matrix)
                    infos.append(contentsOf:self.render(to:gn,world:n.matrix*wm,node:n,opaque:opaque))
                }
            }
        } else {
            for n in node.subnodes {
                let gn = Graphics(parent:g,matrix:n.matrix)
                infos.append(contentsOf:self.render(to:gn,world:n.matrix*world,node:n,opaque:opaque))
            }
        }
        return infos
    }
    static func globals(_ viewport:Viewport) {
        viewport["3d.depth.all"] = DepthStencilState(viewport:viewport,mode:.all,write:true)
        viewport["3d.depth.lesser"] = DepthStencilState(viewport:viewport,mode:.lesser,write:true)
        viewport["3d.depth.greater"] = DepthStencilState(viewport:viewport,mode:.greater,write:true)
        viewport["3d.depth.all.nowrite"] = DepthStencilState(viewport:viewport,mode:.all,write:false)
        viewport["3d.depth.lesser.nowrite"] = DepthStencilState(viewport:viewport,mode:.lesser,write:false)
        viewport["3d.depth.greater.nowrite"] = DepthStencilState(viewport:viewport,mode:.greater,write:false)
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTextureFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.directional.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentDirectionalLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.directional.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTextureDirectionalLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.1.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentPointLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.1.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTexturePointLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.2.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentPoint2LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.2.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTexturePoint2LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.3.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentPoint3LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.3.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTexturePoint3LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.4.basic",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentPoint4LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.4.texture",library:viewport.gpu.library!,vertex:"vertex3DFunc",fragment:"fragmentTexturePoint4LightFunc",fmt:[.float3,.float4,.float2,.float3])

        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.directional.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentDirectionalLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.1.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentPointLightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.2.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentPoint2LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.3.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentPoint3LightFunc",fmt:[.float3,.float4,.float2,.float3])
        Program.populateDefaultBlendModes(store:viewport,key:"program.3d.point.4.height",library:viewport.gpu.library!,vertex:"vertex3DHeightFunc",fragment:"fragmentPoint4LightFunc",fmt:[.float3,.float4,.float2,.float3])
        
        
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])
        // TODO: implement the illuminations
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.directional.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.directional.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.1.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.1.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.2.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.2.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.3.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.3.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.4.basic",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointFunc",fmt:[.float3,.float,.float4])
        Program.populateDefaultBlendModes(store:viewport,key:"program.point.3d.point.4.texture",library:viewport.gpu.library!,vertex:"point3DFunc",fragment:"fragmentPointTextureFunc",fmt:[.float3,.float,.float4])

    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// http://www.codinglabs.net/article_world_view_projection_matrix.aspx
public class RendererView : View,RenderNode {
    public var db: NodeUI {
        return self
    }
    public var camera: Camera3D? {
        get { return renderer?.camera }
        set { renderer?.camera = camera }
    }
    public var world: Node3D? {
        get { return renderer?.world }
        set { renderer?.world = world }
    }
    public var renderer:Renderer?
    public init(superview:View,layout:Layout) {
        super.init(superview:superview,layout:layout)
        renderer = Renderer(parent:self)
        self.clipping = true
    }
    override public func detach() {
        if let r = renderer {
            r.detach()
            renderer = nil
        }
        super.detach()
    }
    override public func draw(to g: Graphics) {
        renderer?.render(to:g,size:self.size)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class RendererBitmap : Bitmap,RenderNode {
    public var db : NodeUI {
        return self
    }
    public var camera: Camera3D? {
        get { return renderer?.camera }
        set { renderer?.camera = camera }
    }
    public var world: Node3D? {
        get { return renderer?.world }
        set { renderer?.world = world }
    }
    public var renderer:Renderer?
    public init(parent:NodeUI,size:Size) {
        super.init(parent:parent,size:size)
        renderer = Renderer(parent:self)
    }
    override public func detach() {
        if let r = renderer {
            r.detach()
            renderer = nil
        }
        super.detach()
    }
    public func render(_ fn:@escaping (()->())) {
        let g=Graphics(image:self)
        renderer?.render(to:g,size:self.size)
        g.done { ok in
            if ok == .success {
                self.sui {
                    fn()
                }
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class NodeGPU : NodeUI {
    public var renderer:Renderer? {
        return (self.ancestor() as RenderNode?)?.renderer
    }
    public var db:NodeUI? {
        return (self.ancestor() as RenderNode?) as? NodeUI
    }
    public func persitentBuffer(_ size:Int) -> Buffer {
        return viewport!.gpu.buffers!.get(size,persistent:true)
    }
    public init(parent:NodeUI) {
        super.init(parent:parent)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Node3D : NodeGPU {
    public var matrix:Mat4
    public var position:Vec3 {
        get { return matrix.translation }
        set(v) { matrix.translation = v }
    }
    public private(set) var subnodes=[Node3D]()
    public var supernode : Node3D? {
        return self.parent as? Node3D
    }
    public var worldMatrix:Mat4 {
        var m = self.matrix
        var n:Node3D? = self
        while n != nil {
            m = n!.matrix * m
            n = n!.supernode
        }
        return m
    }
    public init(parent:NodeUI,matrix:Mat4=Mat4.identity) {
        self.matrix = matrix
        super.init(parent:parent)
        if let supernode = self.supernode {
            supernode.subnodes.append(self)
        }
    }
    override open func detach() {
        for n in subnodes {
            n.detach()
        }
        if let supernode = self.supernode {
            supernode.subnodes=supernode.subnodes.filter({ (n) -> Bool in
                return n != self
            })
        }
        super.detach()
    }
    open func render(to g:Graphics,world:Mat4,opaque:Bool) -> Bool {
        return false
    }
    public func child<T:Node3D>(recursive:Bool=false) -> T? {
        for v0 in subnodes  {
            if let v=v0 as? T {
                return v
            }
            if recursive, let s = v0.child(recursive:true) as T? {
                return s
            }
        }
        return nil
    }
    public func children<T:Node3D>(recursive:Bool=false) -> [T] {
        var s=[T]()
        for v0 in subnodes  {
            if let v=v0 as? T {
                s.append(v)
            }
            if recursive {
                s += v0.children(recursive:true) as [T]
            }
        }
        return s
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Mirror : Node3D {  // case implemented in renderer
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// http://ksimek.github.io/2012/08/22/extrinsic/
public class Camera3D : Node3D {
    public var direction:Vec3
    public var up:Vec3
    public init(supernode:Node3D,position:Vec3=Vec3(z:-2),direction:Vec3=Vec3(z:1),up:Vec3=Vec3.zero) {
        self.direction = direction
        self.up = up
        super.init(parent:supernode,matrix:Mat4.translation(position))
    }
    public func lookAt(node:Node3D) {
        self.direction = node.worldMatrix.translation - self.worldMatrix.translation
    }
    var viewMatrix : Mat4 {
        get {
            if up == .zero {
                return (Mat4.lookAt(direction:direction)*self.worldMatrix).inverted
            }
            return (Mat4.lookAt(eye:.zero,target:direction,up:up)*self.worldMatrix).inverted    // // position must be expressed in transformed axis (fuck!!!) TODO: keep original axis
            
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// https://www.raywenderlich.com/146420/metal-tutorial-swift-3-part-4-lighting
public class Light : Node3D {
    var buffer:Buffer?
    var needsUpdate = true
    public init(parent:Node3D,position:Vec3) {
        super.init(parent:parent,matrix:Mat4.translation(position))
    }
    override public func detach() {
        if let b=buffer {
            b.detach()
            buffer=nil
        }
        super.detach()
    }
    public func use(g:Graphics,atIndex index:Int) {
        Debug.notImplemented()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class PointLight : Light {
    struct GPU {
        var color:float4
        var attenuationConstant:Float32
        var attenuationLinear:Float32
        var attenuationQuadratic:Float32
        var position:float3
    }
    public var color:Color {
        didSet {
            self.needsUpdate = true
        }
    }
    public var attenuation:Attenuation {
        didSet {
            self.needsUpdate = true
        }
    }
    public override var matrix: Mat4 {
        didSet {
            self.needsUpdate = true
        }
    }
    public init(parent:Node3D,position:Vec3,color:Color=Color.white,attenuation:Attenuation=Attenuation()) {
        self.color=color
        self.attenuation=attenuation
        super.init(parent:parent,position:position)
        self.buffer = self.persitentBuffer(MemoryLayout<GPU>.size)
        viewport?.pulse.alive(self) {
            self.needsUpdate=true
        }
    }
    public override func use(g:Graphics,atIndex index:Int) {
        if let b=buffer {
            if needsUpdate {
                needsUpdate=false
                let gpu = GPU(color:color.infloat4,attenuationConstant:Float32(attenuation.constant),attenuationLinear:Float32(attenuation.linear),attenuationQuadratic:Float32(attenuation.quadratic),position:self.worldMatrix.translation.infloat3)
                let ptr = b.ptr.assumingMemoryBound(to: GPU.self)
                ptr[0] = gpu
            }
            g.render.use(fragmentBuffer:b,atIndex:index)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class DirectionalLight : Light {
    struct GPU {
        var color:float4
        var intensity:Float32
        var direction:float3
    }
    public var color:Color {
        didSet {
            needsUpdate = true
        }
    }
    public var intensity:Double {
        didSet {
            needsUpdate = true
        }
    }
    public var direction:Vec3 {
        didSet {
            needsUpdate = true
        }
    }
    public init(parent:Node3D,direction:Vec3=Vec3(z:1),color:Color,intensity:Double) {
        self.color=color
        self.intensity=intensity
        self.direction=direction
        super.init(parent:parent,position:Vec3.zero)
        self.buffer = self.persitentBuffer(MemoryLayout<GPU>.size)
    }
    override public func detach() {
        if let b=buffer {
            b.detach()
            buffer=nil
        }
        super.detach()
    }
    public override func use(g:Graphics,atIndex index:Int) {
        if let b=buffer {
            if needsUpdate {
                needsUpdate=false
                let gpu = GPU(color:color.infloat4,intensity:Float32(intensity),direction:direction.infloat3)
                let ptr = b.ptr.assumingMemoryBound(to: GPU.self)
                ptr[0] = gpu
            }
            g.render.use(fragmentBuffer:b,atIndex:index)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Material : NodeGPU {
    var transparency : Bool {
        return blend != .opaque
    }
    public private(set) var blend:BlendMode
    var needsUpdate=true
    var ambient:Color {
        didSet {
            needsUpdate=true
        }
    }
    var diffuse:Color {
        didSet {
            needsUpdate=true
        }
    }
    var specular:Color {
        didSet {
            needsUpdate=true
        }
    }
    var shininess:Double {
        didSet {
            needsUpdate=true
        }
    }
    struct GPU {
        var ambient:float4
        var diffuse:float4
        var specular:float4
        var shininess:Float32
    }
    public private(set) var cull : RenderPass.CullMode
    public private(set) var material:Buffer?
    public private(set) var texture:Texture2D?
    public let name:String
    public init(parent:NodeUI,name:String,blend:BlendMode=BlendMode.opaque,cull:RenderPass.CullMode=RenderPass.CullMode.front,ambient:Color=Color(a:1,l:0.05),diffuse:Color=Color(a:1,l:0.8),specular:Color=Color.white,shininess:Double=40,texture:String="") {
        self.name = name
        self.blend = blend
        self.cull = cull
        self.ambient=ambient
        self.diffuse=diffuse
        self.specular=specular
        self.shininess=shininess
        super.init(parent:parent)
        self.material=self.persitentBuffer(MemoryLayout<GPU>.size)
        if texture.length > 0 {
            self.io {
                self.texture = Bitmap(parent:self,path:texture)
            }
        }
    }
    public init(parent:NodeUI,name:String,blend:BlendMode=BlendMode.opaque,cull:RenderPass.CullMode=RenderPass.CullMode.front,ambient:Color=Color(a:1,l:0.05),diffuse:Color=Color(a:1,l:0.8),specular:Color=Color.white,shininess:Double=40,texture:Size) {
        self.name = name
        self.blend = blend
        self.cull = cull
        self.ambient=ambient
        self.diffuse=diffuse
        self.specular=specular
        self.shininess=shininess
        super.init(parent:parent)
        self.material=self.persitentBuffer(MemoryLayout<GPU>.size)
        self.texture = Bitmap(parent:self,size:texture)
    }
    override open func detach() {
        if let m=material {
            m.detach()
            material=nil
        }
        if let t=texture {
            t.detach()
            texture = nil
        }
        super.detach()
    }
    public func setTexture(path:String) {
        self.io {
            if let o = self.texture {
                self.ui {
                    o.detach()
                }
            }
            self.texture = Bitmap(parent:self,path:path)
        }
    }
    open func render(to g:Graphics,world:Mat4,vertices:Buffer,faces:Buffer,count:Int) {
        if let material=material, let renderer=self.renderer, let camera=renderer.camera {
            self.updateBuffer()
            let prog = "program.3d.\(renderer.lightsProgram)"
            if let texture = texture, texture.ready {
                g.program("\(prog)texture",blend:blend)
                g.render.use(texture:texture)
            } else {
                g.program("\(prog)basic",blend:blend)
            }
            g.uniforms(view:g.matrix,world:world,eye:camera.worldMatrix.translation)
            self.lights(g:g,startIndex:2)
            g.render.use(fragmentBuffer:material,atIndex:0)
            g.render.use(vertexBuffer:vertices,atIndex:0)
            if blend == .opaque {
                g.depthStencil(state:"3d.depth.lesser")
            } else {
                g.depthStencil(state:"3d.depth.lesser.nowrite")
            }
            g.render.set(cull:self.cull)
            g.render.set(front:.counterClockwise)
            g.render.draw(triangle:count,index:faces)
            g.render.set(cull:.none)
            g.depthStencil(state:"3d.depth.all")
        }
    }
    open func render(to g:Graphics,world:Mat4,particles:Buffer,count:Int) {
        if let material=material, let renderer=self.renderer, let camera=renderer.camera {
            self.updateBuffer()
            let prog = "program.point.3d.\(renderer.lightsProgram)"
            if let texture = texture, texture.ready {
                g.program("\(prog)texture",blend:blend)
                g.render.use(texture:texture)
            } else {
                g.program("\(prog)basic",blend:blend)
            }
            g.uniforms(view:g.matrix,world:world,eye:camera.worldMatrix.translation)
            self.lights(g:g,startIndex:2)
            g.render.use(fragmentBuffer:material,atIndex:0)
            g.render.use(vertexBuffer:particles,atIndex:0)
            g.depthStencil(state:"3d.depth.lesser.nowrite")
            g.render.draw(sprite:count)
            g.depthStencil(state:"3d.depth.all")
        }
    }
    public func updateBuffer() {
        if let material=material, needsUpdate {
            needsUpdate=false
            let gpu = GPU(ambient:ambient.infloat4,diffuse:diffuse.infloat4,specular:specular.infloat4,shininess:Float32(shininess))
            let ptr = material.ptr.assumingMemoryBound(to: GPU.self)
            ptr[0] = gpu
        }
    }
    public func lights(g:Graphics,startIndex index:Int) {
        if let renderer = self.renderer {
            var i = index
            for l in renderer.lights {
                l.use(g:g,atIndex:i)
                i += 1
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Bone : Node3D {
    public var mesh:Mesh? {
        return self.ancestor() as Mesh?
    }
    public var name:String
    public init(name:String,parent:NodeUI,matrix:Mat4=Mat4.identity) {
        self.name=name
        super.init(parent:parent,matrix:matrix)
        if parent is Mesh {
            mesh?.bones.append(self)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Mesh : NodeGPU {
    public let onInitialized = Event<Void>()
    public struct Vertex {
        public var position:Vec3
        public var normal:Vec3
        public var uv:Point
        public var color:Color
        public init(position:Vec3=Vec3.zero,normal:Vec3=Vec3.zero,uv:Point=Point.zero,color:Color=Color.white) {
            self.position=position
            self.normal=normal
            self.uv=uv
            self.color=color
        }
    }
    struct GPUvertice {
        var position:float3
        var color:float4
        var uv:float2
        var normal:float3
    }
    struct GPUverticeBone {
        var position:float3
        var color:float4
        var uv:float2
        var normal:float3
        var bone0:Int32
        var bone1:Int32
        var weight0:Float32
    }
    var initialized=false
    var needsVerticesUpdate=true
    var bufferVertices:Buffer?
    var needsFacesUpdate=true
    var bufferFaces=[String:Buffer]()
    public var vertices=[Vertex]() {
        didSet {
            needsVerticesUpdate = true
        }
    }
    public var faces=[String:[Int32]]() {
        didSet {
            needsFacesUpdate = true
        }
    }
    var bones = [Bone]()
    public var facesCount : Int {
        var n = 0
        for m in faces.keys {
            if let f=faces[m] {
                n += f.count/3
            }
        }
        return n
    }
    public var verticesCount : Int {
        return vertices.count
    }
    override open func detach() {
        if let b=bufferVertices {
            b.detach()
            bufferVertices=nil
        }
        for m in bufferFaces.keys {
            if let b=bufferFaces[m] {
                b.detach()
            }
        }
        bufferFaces.removeAll()
        super.detach()
    }
    func index(vertice:Vertex) -> Int? {
        var i = 0
        for v in vertices {
            if v == vertice {
                return i
            }
            i += 1
        }
        return nil
    }
    public func dispatchInitialized() {
        self.initialized=true
        self.onInitialized.dispatch(())
    }
    public override init(parent:NodeUI) {
        super.init(parent:parent)
    }
    public init(parent:NodeUI,path:String) {
        super.init(parent:parent)
        self.io {
            if path.contains(".obj") {  // https://en.wikipedia.org/wiki/Wavefront_.obj_file
                Application.readText(path) { text in
                    var lvert=[Vec3]()
                    var lnorm=[Vec3]()
                    var luv=[Point]()
                    var mat = "alib.default"
                    self.faces[mat] = [Int32]()
                    let decodeVertice:((String)->(Int)) = { s in
                        let e=s.split("/")
                        switch e.count {
                        case 1:
                            if let iv=Int(s){
                                let v=Vertex(position:lvert[iv-1])
                                if let i = self.index(vertice:v) {
                                    return i
                                } else {
                                    self.vertices.append(v)
                                    return self.vertices.count-1
                                }
                            } else {
                                Debug.error("corrupted obj file")
                            }
                        case 2:
                            if let iv=Int(e[0]), let iuv=Int(e[1]) {
                                let v=Vertex(position:lvert[iv-1],uv:luv[iuv-1])
                                if let i = self.index(vertice:v) {
                                    return i
                                } else {
                                    self.vertices.append(v)
                                    return self.vertices.count-1
                                }
                            } else {
                                Debug.error("corrupted obj file")
                            }
                        case 3:
                            if let iv=Int(e[0]), let iuv=Int(e[1]), let inorm=Int(e[2]) {
                                let v=Vertex(position:lvert[iv-1],normal:lnorm[inorm-1],uv:luv[iuv-1])
                                if let i = self.index(vertice:v) {
                                    return i
                                } else {
                                    self.vertices.append(v)
                                    return self.vertices.count-1
                                }
                            } else if let iv=Int(e[0]), let inorm=Int(e[2]) {
                                let v=Vertex(position:lvert[iv-1],normal:lnorm[inorm-1])
                                if let i = self.index(vertice:v) {
                                    return i
                                } else {
                                    self.vertices.append(v)
                                    return self.vertices.count-1
                                }
                            } else {
                                Debug.error("corrupted obj file")
                            }
                        default:
                            Debug.error("corrupted obj file")
                        }
                        return 0
                    }
                    if let text=text {
                        while let t=text.readLine() {
                            if t.length>0 && t[0] != "#" {
                                let p = t.splitByEach(" \t")
                                let cmd = p[0]
                                let args = t[cmd.length..<t.length].trim()
                                if (cmd == "v") {
                                    if let x=Double(p[1]), let y=Double(p[2]), let z=Double(p[3]) {
                                        lvert.append(Vec3(x:x,y:y,z:z))
                                    } else {
                                        Debug.error("corrupted obj file")
                                        lvert.append(Vec3())
                                    }
                                } else if (cmd == "vn") {
                                    if let x=Double(p[1]), let y=Double(p[2]), let z=Double(p[3]) {
                                        lnorm.append(Vec3(x:x,y:y,z:z))
                                    } else {
                                        Debug.error("corrupted obj file")
                                        lnorm.append(Vec3())
                                    }
                                } else if (cmd == "vt") {
                                    if let x=Double(p[1]), let y=Double(p[2]) {
                                        luv.append(Point(x:x,y:y))
                                    } else {
                                        Debug.error("corrupted obj file")
                                        luv.append(Point.zero)
                                    }
                                } else if (cmd == "g") {
                                    //string gname = p[1];	// group
                                } else if(cmd=="mtllib") {
                                    let mtlfile = args	// fichier mtl
                                    let p = path[0...path.lastIndexOf("/")!]+mtlfile[mtlfile.lastIndexOf("/")!+1..<mtlfile.length]
                                    Application.readText(p) { reader in
                                        var skip = false
                                        var cmat:Material? = nil
                                        if let reader = reader {
                                            while let t = reader.readLine() {
                                                let p = t.splitByEach(" \t")
                                                let cmd = p[0]
                                                let args = t[cmd.length..<t.length].trim()
                                                if cmd == "newmtl" {
                                                    let name=args
                                                    mat = "material.\(path).\(name)"
                                                    if let m = self[mat] as? Material {
                                                        skip = true
                                                        cmat = m
                                                    } else {
                                                        skip = false
                                                        if let db = self.db {
                                                            cmat = Material(parent:db,name:"\(path).\(name)")
                                                            db[mat] = cmat
                                                        }
                                                    }
                                                    self.faces[mat] = [Int32]()
                                                } else if !skip {
                                                    if cmd == "Ka" {
                                                        cmat!.ambient = Color(a:1,rgb:Color(a:1,r:Double(p[1])!,g:Double(p[2])!,b:Double(p[3])!))
                                                    } else if cmd == "Kd" {
                                                        cmat!.diffuse = Color(a:1,r:Double(p[1])!,g:Double(p[2])!,b:Double(p[3])!)
                                                        cmat!.ambient = cmat!.diffuse * cmat!.ambient * 0.4
                                                        //Debug.info("material color: \(mat.diffuse)")
                                                    } else if cmd == "Ks" {
                                                        cmat!.specular = Color(a:1,r:Double(p[1])!,g:Double(p[2])!,b:Double(p[3])!)
                                                    } else if cmd == "Ns" {
                                                        cmat!.shininess = Double(p[1])!
                                                    } else if cmd == "map_Kd" {
                                                        var pt = args
                                                        if args.contains("/") {
                                                            pt = path[0...path.lastIndexOf("/")!]+args[mtlfile.lastIndexOf("/")!+1..<mtlfile.length]
                                                        } else {
                                                            pt = path[0...path.lastIndexOf("/")!]+args
                                                        }
                                                        cmat!.setTexture(path:pt)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else if (cmd == "usemtl") {
                                    mat = "material.\(path).\(args)"
                                } else if (cmd == "s") {
                                    //string v = p[1];      // smooth mode
                                } else if (cmd == "f") {
                                    switch p.count-1 {
                                    case 3: // triangle
                                        self.faces[mat]!.append(Int32(decodeVertice(p[1])))
                                        self.faces[mat]!.append(Int32(decodeVertice(p[2])))
                                        self.faces[mat]!.append(Int32(decodeVertice(p[3])))
                                    case 4: // quad
                                        let v0=Int32(decodeVertice(p[1]))
                                        let v1=Int32(decodeVertice(p[2]))
                                        let v2=Int32(decodeVertice(p[3]))
                                        let v3=Int32(decodeVertice(p[4]))
                                        self.faces[mat]!.append(v0)
                                        self.faces[mat]!.append(v1)
                                        self.faces[mat]!.append(v2)
                                        self.faces[mat]!.append(v2)
                                        self.faces[mat]!.append(v3)
                                        self.faces[mat]!.append(v0)
                                    default:
                                        Debug.error("corrupted obj file")
                                    }
                                }
                            }
                        }
                    } else {
                        Debug.error("obj file not found: \(path)")
                    }
                    if lnorm.count == 0 {
                        self.computeNormals()
                    }
                    Debug.info("obj \(path) initialized")
                }
            } else if path.contains(".md3") {   // https://www.icculus.org/homepages/phaethon/q3a/formats/md3format.html
                // TODO:
                Debug.notImplemented()
            } else if path.contains(".iqm") {   // http://sauerbraten.org/iqm/iqm.txt
                // TODO:
                Debug.notImplemented()
            } else {
                Debug.error("unknow 3d file format \(path)")
            }
        }
    }
    public init(parent:NodeUI,sphere:Sphere,factor:Int=16) {
        super.init(parent:parent)
        self.zz {
            for j in 0...factor {
                let theta = ß.π*Double(j)/Double(factor)
                let stheta = sin(theta)
                let ctheta = cos(theta)
                for i in 0..<factor {
                    let phi = 2*ß.π*Double(i)/Double(factor)
                    let p = Vec3(x:stheta*cos(phi),y:stheta*sin(phi),z:ctheta)
                    self.vertices.append(Vertex(position:p,normal:p.normalized,uv:Point(x:Double(i)/Double(factor),y:Double(j)/Double(factor))))
                }
            }
            let mat = "material.default"
            self.faces[mat] = [Int32]()
            for j in 0..<factor {
                for i in 0..<factor-1 {
                    let first = j*factor + i
                    let second = first + factor
                    let first1 = first+1
                    let second1 = second+1
                    self.faces[mat]!.append(Int32(first))
                    self.faces[mat]!.append(Int32(second))
                    self.faces[mat]!.append(Int32(first1))
                    self.faces[mat]!.append(Int32(second))
                    self.faces[mat]!.append(Int32(second1))
                    self.faces[mat]!.append(Int32(first1))
                }
                let first = j*factor + factor - 1
                let second = first + factor
                let first1 = j*factor
                let second1 = first1 + factor
                self.faces[mat]!.append(Int32(first))
                self.faces[mat]!.append(Int32(second))
                self.faces[mat]!.append(Int32(first1))
                self.faces[mat]!.append(Int32(second))
                self.faces[mat]!.append(Int32(second1))
                self.faces[mat]!.append(Int32(first1))
            }
            self.dispatchInitialized()
        }
    }
    public init(parent:NodeUI,cylinder:Cylinder,factor:Int=20) {
        super.init(parent:parent)
        self.zz {
            let mat = "material.default"
            self.faces[mat]=[Int32]()
            if cylinder.direction != Vec3(y:1) {
                Debug.notImplemented()
            }
            var y = cylinder.center - cylinder.direction*0.5
            let dy = cylinder.direction
            for _ in 0...1 {
                for ai in 0..<factor {
                    let a = ß.π * 2 * Double(ai) / Double(factor)
                    let n = Vec3(x:cos(a),y:0,z:sin(a))
                    let p = y + n * cylinder.radius
                    self.vertices.append(Vertex(position:p,normal:n))
                }
                y += dy
            }
            for ai in 0..<factor {
                let p0 = ai
                let p3 = ai + factor
                let p1 = (ai<factor-1) ? p0+1 : p0 - (factor - 1)
                let p2 = (ai<factor-1) ? p3+1 : p3 - (factor - 1)
                self.faces[mat]!.append(Int32(p0))
                self.faces[mat]!.append(Int32(p1))
                self.faces[mat]!.append(Int32(p2))
                self.faces[mat]!.append(Int32(p2))
                self.faces[mat]!.append(Int32(p3))
                self.faces[mat]!.append(Int32(p0))
            }
            y = cylinder.center - cylinder.direction*0.5
            var n = Vec3(y:-1)
            for _ in 0...1 {
                for ai in 0..<factor {
                    let a = ß.π * 2 * Double(ai) / Double(factor)
                    let p = y + Vec3(x:cos(a),y:0,z:sin(a)) * cylinder.radius
                    self.vertices.append(Vertex(position:p,normal:n))
                }
                y += dy
                n = Vec3(y:1)
            }
            let s0 = factor * 2
            let s1 = factor * 3
            let c0 = self.vertices.count
            self.vertices.append(Vertex(position:cylinder.center - cylinder.direction*0.5,normal:Vec3(y:-1)))
            let c1 = self.vertices.count
            self.vertices.append(Vertex(position:cylinder.center + cylinder.direction*0.5,normal:Vec3(y:1)))
            for i in 0..<factor {
                self.faces[mat]!.append(Int32(c0))
                self.faces[mat]!.append(Int32(s0+i))
                if i < factor-1 {
                    self.faces[mat]!.append(Int32(s0+i+1))
                } else {
                    self.faces[mat]!.append(Int32(s0))
                }
                self.faces[mat]!.append(Int32(c1))
                if i < factor-1 {
                    self.faces[mat]!.append(Int32(s1+i+1))
                } else {
                    self.faces[mat]!.append(Int32(s1))
                }
                self.faces[mat]!.append(Int32(s1+i))
            }
            self.dispatchInitialized()
        }
    }
    public init(parent:NodeUI,box:Box) {
        super.init(parent:parent)
        self.zz {
            let mat = "material.default"
            self.faces[mat]=[Int32]()
            let addfaces : ((Int,Int,Int,Int,Bool)->()) = { v0,v1,v2,v3,invers in
                if !invers {
                    self.faces[mat]!.append(Int32(v0))
                    self.faces[mat]!.append(Int32(v1))
                    self.faces[mat]!.append(Int32(v2))
                    self.faces[mat]!.append(Int32(v2))
                    self.faces[mat]!.append(Int32(v3))
                    self.faces[mat]!.append(Int32(v0))
                } else {
                    self.faces[mat]!.append(Int32(v2))
                    self.faces[mat]!.append(Int32(v1))
                    self.faces[mat]!.append(Int32(v0))
                    self.faces[mat]!.append(Int32(v0))
                    self.faces[mat]!.append(Int32(v3))
                    self.faces[mat]!.append(Int32(v2))
                }
            }
            for x in 0...1 {
                let dx = x*2 - 1
                let n = Vec3(x:Double(dx),y:0,z:0)
                let v0 = self.vertices.appendIndex(Vertex(position:box.point(Double(x),0,0),normal:n,color:.white))
                let v1 = self.vertices.appendIndex(Vertex(position:box.point(Double(x),1,0),normal:n,color:.white))
                let v2 = self.vertices.appendIndex(Vertex(position:box.point(Double(x),1,1),normal:n,color:.white))
                let v3 = self.vertices.appendIndex(Vertex(position:box.point(Double(x),0,1),normal:n,color:.white))
                addfaces(v0,v1,v2,v3,x==0)
            }
            for y in 0...1 {
                let dy = y*2 - 1
                let n = Vec3(x:0,y:Double(dy),z:0)
                let v0 = self.vertices.appendIndex(Vertex(position:box.point(0,Double(y),0),normal:n,color:.white))
                let v1 = self.vertices.appendIndex(Vertex(position:box.point(1,Double(y),0),normal:n,color:.white))
                let v2 = self.vertices.appendIndex(Vertex(position:box.point(1,Double(y),1),normal:n,color:.white))
                let v3 = self.vertices.appendIndex(Vertex(position:box.point(0,Double(y),1),normal:n,color:.white))
                addfaces(v0,v1,v2,v3,y==1)
            }
            for z in 0...1 {
                let dz = z*2 - 1
                let n = Vec3(x:0,y:0,z:Double(dz))
                let v0 = self.vertices.appendIndex(Vertex(position:box.point(0,0,Double(z)),normal:n,color:.white))
                let v1 = self.vertices.appendIndex(Vertex(position:box.point(1,0,Double(z)),normal:n,color:.white))
                let v2 = self.vertices.appendIndex(Vertex(position:box.point(1,1,Double(z)),normal:n,color:.white))
                let v3 = self.vertices.appendIndex(Vertex(position:box.point(0,1,Double(z)),normal:n,color:.white))
                addfaces(v0,v1,v2,v3,z==0)
            }
            self.dispatchInitialized()
        }
    }
    public func computeNormals() {
        var lfaces = [Int32:[(v1:Int32,v2:Int32)]]()
        for m in faces.keys {
            if let f = faces[m] {
                var i = 0
                while i<f.count {
                    let v0 = f[i]
                    i += 1
                    let v1 = f[i]
                    i += 1
                    let v2 = f[i]
                    i += 1
                    if lfaces[v0] == nil {
                        lfaces[v0] = [(v1:Int32,v2:Int32)]()
                    }
                    if lfaces[v1] == nil {
                        lfaces[v1] = [(v1:Int32,v2:Int32)]()
                    }
                    if lfaces[v2] == nil {
                        lfaces[v2] = [(v1:Int32,v2:Int32)]()
                    }
                    lfaces[v0]!.append((v1:v1,v2:v2))
                    lfaces[v1]!.append((v1:v2,v2:v0))
                    lfaces[v2]!.append((v1:v0,v2:v1))
                }
            }
        }
        for i in lfaces.keys {
            let v0 = vertices[Int(i)].position
            if let fl = lfaces[i] {
                var n = Vec3.zero
                for f in fl {
                    n = n + Vec3.cross(vertices[Int(f.v1)].position-v0,vertices[Int(f.v2)].position-v0)
                }
                let normal = (n/Double(fl.count)).normalized
                vertices[Int(i)].normal = normal
            }
        }
    }
    public func update() {
        if needsVerticesUpdate {
            needsVerticesUpdate=false
            if bufferVertices == nil {
                bufferVertices = self.persitentBuffer(MemoryLayout<GPUvertice>.size*vertices.count)
            }
            if let bv=bufferVertices {
                let pv = bv.ptr.assumingMemoryBound(to: GPUvertice.self)
                for i in 0..<vertices.count {
                    let v = vertices[i]
                    pv[i] = GPUvertice(position:v.position.infloat3,color:v.color.infloat4,uv:v.uv.infloat2,normal:v.normal.infloat3)
                }
            }
            boundingBox = _boundingBox
        }
        if needsFacesUpdate {
            needsFacesUpdate=false
            for m in faces.keys {
                if let f=faces[m] {
                    if bufferFaces[m] == nil {
                        bufferFaces[m] = self.persitentBuffer(MemoryLayout<Float32>.size*f.count)
                    }
                    if let bf = bufferFaces[m] {
                        let pv = bf.ptr.assumingMemoryBound(to: Float32.self)
                        memcpy(pv,f,MemoryLayout<Float32>.size*f.count)
                    }
                }
            }
        }
    }
    public func render(to g:Graphics,world:Mat4,library:NodeUI,opaque:Bool) -> Bool {
        var transparency = false
        if initialized {
            self.update()
            for kmat in faces.keys {
                var material = kmat
                while let m = library[material] as? String {
                    material = m
                }
                if let mat = library[material] as? Material {
                    if mat.transparency != opaque, let f=faces[kmat], let bv=bufferVertices, let bf=bufferFaces[kmat], f.count>0 {
                        mat.render(to:g,world:world,vertices:bv,faces:bf,count:f.count)
                        //Debug.warning("render mat(\(mat.name))  opaque:\(opaque) transparency:\(mat.transparency)")
                    }
                    transparency = transparency || mat.transparency
                } else  {
                    Debug.error("material \(material) not found. origin: \(kmat)")
                }
            }
        }
        return transparency
    }
    public var boundingBox = Box.zero
    var _boundingBox : Box {
        if vertices.count>0 {
            var b = Box(o:vertices[0].position,s:Vec3.zero)
            for v in vertices {
                b = b.union(v.position)
            }
            return b
        } else {
            return Box.zero
        }
    }
    public var boundingSphere : Sphere {
        return Sphere(bounding:self.boundingBox)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Object : Node3D {
    public var meshMatrix:Mat4 = Mat4.identity
    public let onInitialized = Event<Void>()
    public private(set) var mesh:String
    func dispatchInit() {
        if let m=self[mesh] as? Mesh {
            if m.initialized {
                self.ui {
                    self.onInitialized.dispatch(())
                }
            } else {
                m.onInitialized.once { _ in
                    self.onInitialized.dispatch(())
                }
            }
        }
    }
    public init(parent:Node3D,matrix:Mat4,path:String) {
        self.mesh = "mesh.\(path)"
        super.init(parent:parent,matrix:matrix)
        if self[mesh] is Mesh {
            dispatchInit()
        } else if let db = self.db {
            db[mesh] = Mesh(parent:db,path:path)
            dispatchInit()
        }
    }
    public init(parent:Node3D,matrix:Mat4,mesh:String,material:String="material.default") {
        self.mesh = mesh
        super.init(parent:parent,matrix:matrix)
        dispatchInit()
        if material != "material.default" {
            self["material.default"] = material
        }
    }
    public init(parent:Node3D,sphere:Sphere,material:String="material.default") {
        self.mesh = "mesh.sphere"
        self.meshMatrix = Mat4.scale(Vec3(x:sphere.radius,y:sphere.radius,z:sphere.radius))
        super.init(parent:parent,matrix:Mat4.translation(sphere.center))
        if self[mesh] is Mesh {
            dispatchInit()
        } else if let db = self.db {
            db[mesh] = Mesh(parent:db,sphere:Sphere.unity,factor:16)
            dispatchInit()
        }
        if material != "material.default" {
            self["material.default"] = material
        }
    }
    public init(parent:Node3D,cylinder:Cylinder,material:String="material.default") {
        self.mesh = "mesh.cylinder"
        self.meshMatrix = Mat4.scale(Vec3(x:cylinder.radius,y:cylinder.direction.length,z:cylinder.radius))*Mat4.rotation(cylinder.direction,angle:0)
        super.init(parent:parent,matrix:Mat4.translation(cylinder.center))
        if self[mesh] is Mesh {
            dispatchInit()
        } else if let db = self.db {
            db[mesh] = Mesh(parent:db,cylinder:Cylinder(radius:cylinder.radius/cylinder.direction.length),factor:16)
            dispatchInit()
        }
        if material != "material.default" {
            self["material.default"] = material
        }
    }
    public init(parent:Node3D,box:Box,material:String="material.default") {
        self.mesh = "mesh.box"
        self.meshMatrix = Mat4.scale(Vec3(x:box.w,y:box.h,z:box.d))
        super.init(parent:parent,matrix:Mat4.translation(box.center))
        if self[mesh] is Mesh {
            dispatchInit()
        } else if let db = self.db {
            db[mesh] = Mesh(parent:db,box:Box(x:-0.5,y:-0.5,z:-0.5,w:1,h:1,d:1))
            dispatchInit()
        }
        if material != "material.default" {
            self["material.default"] = material
        }
    }
    open override func render(to g0:Graphics,world:Mat4,opaque:Bool) -> Bool {
        var m = mesh
        while let n = self[m] as? String {
            m = n
        }
        if let mesh = self[m] as? Mesh {
            let g = Graphics(parent:g0,matrix:self.meshMatrix)
            return mesh.render(to:g,world:self.meshMatrix*world,library:self,opaque:opaque)
        }
        return false
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public func ==(l:Mesh.Vertex, r: Mesh.Vertex) -> Bool {
    return l.position == r.position && l.normal == r.normal && l.uv == r.uv && l.color == r.color
}
public func !=(l:Mesh.Vertex, r: Mesh.Vertex) -> Bool {
    return l.position != r.position || l.normal != r.normal || l.uv != r.uv || l.color != r.color
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
