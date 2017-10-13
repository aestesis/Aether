//
//  Bitmap.swift
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

#if os(OSX)
    import Metal
    import AppKit
#elseif os(iOS) || os(tvOS)
    import Metal
    import UIKit
#else
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

open class Bitmap : Texture2D {
    public var size:Size {
        return display
    }
    public var bounds:Rect {
        return Rect(x:0,y:0,w:size.w,h:size.h)
    }
    public func blur(_ sigma:Double,sampler smp:String="sampler.clamp",_ fn:@escaping ()->()) {
        bg {
            let b=Bitmap(parent:self,size:self.size)
            let g=Graphics(image:b)
            g.blurHorizontal(b.bounds,source:self,sigma:sigma,sampler:smp)
            g.done {_ in
                self.bg {
                    let g0=Graphics(image:self)
                    g0.blurVertical(b.bounds,source:b,sigma:sigma,sampler:smp)
                    g0.done {_ in
                        self.bg {
                            fn()
                        }
                        b.detach()
                    }
                }
            }
        }
    }
    public func blurFrom(destination rect:Rect?=nil,source:Bitmap,sigma:Double,sampler smp:String="sampler.clamp",_ fn:@escaping (Bool)->()) {  // TODO: debug it, seems keeping reference on self... (leek???)
        let r = rect ?? self.bounds
        bg {
            let b=Bitmap(parent:self,size:source.size)
            let g=Graphics(image:b)
            g.blurHorizontal(b.bounds,source:source,sigma:sigma,sampler:smp)
            g.done { ok in
                if ok == .success {
                    self.bg {
                        let g0=Graphics(image:self)
                        g0.blurVertical(r,source:b,sigma:sigma,sampler:smp)
                        g0.done {_ in
                            self.bg {
                                b.detach()
                                fn(true)
                            }
                        }
                    }
                    return
                } else if ok == .error {
                    Debug.error("Bitmap.blurFrom(), GPU process error")
                }
                self.bg {
                    b.detach()
                    fn(false)
                }
            }
        }
    }
    public func blurFrom(destination rect:Rect?=nil,source:Bitmap,sigma:Double,sampler smp:String="sampler.clamp") {
        let r = rect ?? self.bounds
        let b=Bitmap(parent:self,size:source.size)
        let g=Graphics(image:b)
        g.blurHorizontal(b.bounds,source:source,sigma:sigma,sampler:smp)
        let g0=Graphics(image:self)
        g0.blurVertical(r,source:b,sigma:sigma,sampler:smp)
        g0.done {_ in
            b.detach()
        }
    }
    public static func simpleGradient(parent:NodeUI,_ c0:Color,_ c1:Color) -> Bitmap {
        let b = Bitmap(parent:parent,size:Size(16,1))
        var v = [UInt32](repeating:0,count:16)
        for i in 0...15 {
            let p = Double(i)/15.0
            v[i] = c0.lerp(to:c1,coef:p).abgr
        }
        b.set(pixels:v)
        return b
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
