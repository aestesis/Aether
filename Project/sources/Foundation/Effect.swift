//
//  Effect.swift
//  Alib
//
//  Created by renan jegouzo on 03/08/2016.
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
public class Effect : NodeUI {
    public var computing = false
    public func process(source:Bitmap) -> Future {
        let fut = Future(context:"process()")
        fut.error(Error("not implemented",#file,#line))
        return fut
    }
    public func process(source:Bitmap,destination:Bitmap) -> Future {
        let fut = Future(context:"process()")
        fut.error(Error("not implemented",#file,#line))
        return fut
    }
    static func globals(_ viewport:Viewport) {
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class GradientEffect : Effect {
    var _gradient:Bitmap? = nil
    public var color:Color
    public var gradient : Bitmap {
        get { return _gradient! }
        set(p) {
            if let b=_gradient, p != b {
                b.detach()
            }
            _gradient = p
        }
    }
    public override func process(source: Bitmap) -> Future {
        let fut = Future(context:"process()")
        if self.attached {
            let b = Bitmap(parent:source.viewport!,size:source.size)
            process(source:source,destination:b).then { f in
                if let b = f.result as? Bitmap {
                    fut.done(b)
                } else if let e = f.result as? Alib.Error {
                    fut.error(e,#file,#line)
                    b.detach()
                }
            }
        } else {
            let _ = Atom.wait(0) { 
                fut.error(Error("detached",#file,#line))
            }
        }
        return fut
    }
    public override func process(source:Bitmap, destination:Bitmap) -> Future {
        let fut = Future(context:"process()")
        if self.attached {
            let b = destination
            let g = Graphics(image:b)
            g.program("program.gradient",blend:BlendMode.opaque)
            g.uniforms(g.matrix)
            let vert=g.textureVertices(4)
            let strip=b.bounds.strip
            var uv = Rect(x:0,y:0,w:1,h:1).strip
            for i in 0...3 {
                vert[i]=TextureVertice(position:strip[i].infloat3,uv:uv[i].infloat2,color:color.infloat4)
            }
            g.sampler("sampler.clamp")
            g.render.use(texture:source)
            g.render.use(texture:gradient,atIndex:1)
            g.render.draw(trianglestrip:4)
            computing = true
            g.done { ok in
                self.computing = false
                if ok == .success {
                    fut.done(b)
                } else {
                    if ok == .error {
                        Debug.error("GradientEffect, gpu error: \(ok)",#file,#line)
                    }
                    fut.error(Error("GPU problem",#file,#line))
                }
            }
        } else {
            Debug.error("GradientEffect, detached",#file,#line)
            let _ = Atom.wait(0) {
                fut.error(Error("detached",#file,#line))
            }
        }
        return fut
    }
    public init(parent:NodeUI,gradient:Bitmap?=nil,color:Color = .white) {
        self.color = color
        super.init(parent:parent)
        self._gradient = gradient
    }
    public init(parent:NodeUI,gradient:ColorGradient,color:Color = .white) {
        self.color = color
        super.init(parent:parent)
        self.gradient = gradient.createBitmap(parent: self, width: 16)
    }
    public func set(gradient:ColorGradient,pixels:Double = 16) {
        self.gradient = gradient.createBitmap(parent: self, width: pixels)
    }
    override public func detach() {
        if let b = _gradient {
            b.detach()
        }
        super.detach()
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
