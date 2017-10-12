//
//  ImageView.swift
//  Alib
//
//  Created by renan jegouzo on 07/10/2016.
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

public class ImageView : View {
    public enum Aspect {
        case centered
        case fill
        case fit
        case distort
    }
    public var aspect:Aspect
    public var align:Align
    public var image:Bitmap? {
        didSet {
            if image != oldValue, let old = oldValue {
                old.detach()
            }
        }
    }
    public var imageName:String?=nil
    public var blend:BlendMode
    public var ratio = 1.0
    public init(superview:View,layout:Layout,image:Bitmap,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview,layout:layout)
        self.color = color
        self.image = image
    }
    public init(superview:View,image:Bitmap,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview)
        self.color = color
        self.image = image
    }
    public init(superview:View,layout:Layout,image:String,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview,layout:layout)
        self.color = color
        self.image = nil
        self.imageName = image
    }
    public init(superview:View,image:String,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview)
        self.color = color
        self.image = nil
        self.imageName = image
    }
    public init(superview:View,layout:Layout,path:String,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview,layout:layout)
        self.color = color
        self.io {
            self.image = Bitmap(parent:self,path:path)
        }
    }
    public init(superview:View,path:String,aspect:Aspect = .fill,align:Align = .centerMiddle,blend:BlendMode = .alpha,color:Color = .white) {
        self.blend = blend
        self.aspect = aspect
        self.align = align
        super.init(superview:superview)
        self.color = color
        self.io {
            self.image = Bitmap(parent:self,path:path)
        }
    }
    override public func detach() {
        if let b=image {
            b.detach()
            self.image = nil
        }
        super.detach()
    }
    func doAlign(_ rect:Rect) -> Rect {
        var r=rect
        switch align.horizontalPart {
        case .left:
            r.x = 0
        case .right:
            r.x = bounds.w - r.w
        default:
            break
        }
        switch align.verticalPart {
        case .top:
            r.y = 0
        case .bottom:
            r.y = bounds.h - r.h
        default:
            break
        }
        return r
    }
    override public func draw(to g: Graphics) {
        let c = self.computedColor
        if let img = imageName, let b = self[img] as? Bitmap {
            switch aspect {
            case .centered:
                let r = doAlign(bounds.center.rect(b.size))
                g.draw(rect:r,image:b,blend:blend,color:c)
            case .fill:
                g.draw(rect:bounds,image:b,from:b.bounds.crop(bounds.ratio*self.ratio),blend:blend,color:c)
            case .fit:
                let r = doAlign(bounds.crop(b.size.ratio*self.ratio))
                g.draw(rect:r,image:b,blend:blend,color:c)
            case .distort:
                g.draw(rect:bounds,image:b,from:b.bounds.crop(b.bounds.ratio*self.ratio),blend:blend,color:c)
            }
        } else if let b = image {
            switch aspect {
            case .centered:
                let r = doAlign(bounds.center.rect(b.size))
                g.draw(rect:r,image:b,blend:blend,color:c)
            case .fill:
                g.draw(rect:bounds,image:b,from:b.bounds.crop(bounds.ratio*self.ratio),blend:blend,color:c)
            case .fit:
                let r = doAlign(bounds.crop(b.size.ratio*self.ratio))
                g.draw(rect:r,image:b,blend:blend,color:c)
            case .distort:
                g.draw(rect:bounds,image:b,from:b.bounds.crop(b.bounds.ratio*self.ratio),blend:blend,color:c)
            }
        }
    }
}
