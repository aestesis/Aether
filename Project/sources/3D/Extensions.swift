//
//  Extensions.swift
//  Alib
//
//  Created by renan jegouzo on 13/07/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation
import Metal
import MetalKit

public class MaterialHeightMap : Material {
    struct GPUheight {
        var width:Float32;
        var height:Float32;
        var scale:Float32;
        var adjustNormals:Float32;
    }
    public private(set) var height:Texture2D? = nil
    var adjustNormals:Double
    var buffer:Buffer?
    public init(parent:NodeUI,name:String,blend:BlendMode=BlendMode.opaque,cull:RenderPass.CullMode=RenderPass.CullMode.front,ambient:Color=Color(a:1,l:0.05),diffuse:Color=Color(a:1,l:0.8),specular:Color=Color.white,shininess:Double=40,size:Size,scale:Double,adjustNormals:Double=1.0) {
        self.adjustNormals = adjustNormals
        super.init(parent:parent,name:name,blend:blend,cull:cull,ambient:ambient,diffuse:diffuse,specular:specular,shininess:shininess,texture:size)
        self.height = Bitmap(parent:self,size:size)
        self.setBuffer(size:size,scale:scale,adjustNormals:adjustNormals)
    }
    func setBuffer(size:Size,scale:Double,adjustNormals:Double) {
        let gpu = GPUheight(width:Float32(size.width),height:Float32(size.height),scale:Float32(scale),adjustNormals:Float32(adjustNormals));
        let buffer = self.persitentBuffer(MemoryLayout<GPUheight>.size)
        let b = buffer.ptr.assumingMemoryBound(to: GPUheight.self)
        b[0] = gpu
        self.buffer = buffer
    }
    override public func detach() {
        if let h = height {
            h.detach()
            height = nil
        }
        if let b = buffer {
            b.detach()
            buffer = nil
        }
        super.detach()
    }
    open override func render(to g:Graphics,world:Mat4,vertices:Buffer,faces:Buffer,count:Int) {
        if let material=material, let renderer=self.renderer, let camera=renderer.camera {
            self.updateBuffer()
            let prog = "program.3d.\(renderer.lightsProgram)"
            if let texture = texture, texture.ready, let height = height, height.ready, let buffer=self.buffer {
                g.program("\(prog)height",blend:blend)
                g.render.use(vertexTexture:texture)
                g.render.use(vertexTexture:height,atIndex:1)
                g.uniforms(buffer:buffer,atIndex:2)
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
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Particles : Node3D {
    public var box:Box
    public var direction = Vec3.zero
    var particles = [Particle]()
    var bufferParticles : Buffer?
    public init(parent:Node3D,matrix:Mat4,box:Box,count:Int=100,material:String) {
        self.box = box
        super.init(parent:parent,matrix:matrix)
        self.createParticles(count:count)
        if material != "material.default" {
            self["material.default"] = material
        }
    }
    override open func detach() {
        if let bp = bufferParticles {
            bp.detach()
            bufferParticles = nil
        }
        super.detach()
    }
    func createParticles(count:Int) {
        for _ in 0..<count {
            particles.append(Particle(position:box.random,size:box.diagonale*0.001,color:.white))
        }
    }
    open override func render(to g0:Graphics,world:Mat4,opaque:Bool) -> Bool {
        if !opaque {
            if direction != .zero {
                for i in 0..<particles.count {
                    particles[i].position = box.wrap(particles[i].position+direction)
                }
            }
            if bufferParticles == nil {
                bufferParticles = self.persitentBuffer(MemoryLayout<GPUparticle>.size*particles.count)
            }
            if let bp=bufferParticles {
                let pp = bp.ptr.assumingMemoryBound(to: GPUparticle.self)
                for i in 0..<particles.count {
                    let p = particles[i]
                    pp[i] = GPUparticle(position:p.position.infloat3,size:Float32(p.size),color:p.color.infloat4)
                }
                var m = "material.default"
                while let n = self[m] as? String {
                    m = n
                }
                if let material = self[m] as? Material {
                    material.render(to:g0,world:world,particles:bp,count:particles.count)
                }
            }
        }
        return true
    }
    struct Particle {
        var position : Vec3
        var size : Double
        var color : Color
    }
    struct GPUparticle {
        var position:float3
        var size:Float32
        var color:float4
    }
}
