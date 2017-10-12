//
//  StackView.swift
//  Alib
//
//  Created by renan jegouzo on 08/01/2017.
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

public class StackView : View {
    public let direction:Direction
    public init(superview:View,direction:Direction) {  //
        self.direction = direction
        super.init(superview:superview)
        superview.onResize.alive(self) { sz in
            self.size = self.unitSize * sz / Size(self.grid.size)
        }
    }
    override public func arrange() {
        let csz = superview!.size / Size(self.grid.size)
        self.size = self.unitSize * csz
        let m = grid.marginAbs+grid.marginFloat*csz
        let c = (superview!.size-Size(grid.spaces)*m)/Size(grid.size)
        let d = direction.point
        var p = Point.zero
        for v in subviews {
            if let l=v.layout {
                if l.align != Align.none {
                    let lp=l.placement
                    var f = Rect (x:m.w + lp.x * (m.w + c.w) + l.marginLeft, y:m.h + lp.y * (m.h + c.h) + l.marginTop, w:lp.w * c.w + (lp.w - 1) * m.w - (l.marginLeft + l.marginRight), h:lp.h * c.h + (lp.h - 1) * m.h - (l.marginTop + l.marginBottom));
                    // TODO: calc f using other Grid.Disposition
                    if l.align.hasFlag(.fill) && l.aspect > 0 {
                        if l.aspect > f.size.ratio {
                            let o=f.height
                            f.height = f.width / l.aspect
                            f.y = f.y + ( o - f.height) * 0.5
                        }
                    }
                    if !l.align.hasFlag(.fillHeight) {
                        if l.align.hasFlag(.center) {
                            f.y = f.y + (f.height - v.size.height) * 0.5
                        } else if l.align.hasFlag(.bottom) {
                            f.y = f.bottom - v.size.height
                        }
                    }
                    if !l.align.hasFlag(.fillWidth) {
                        if l.align.hasFlag(.middle) {
                            f.x = f.x + (f.width - v.size.width) * 0.5
                        } else if l.align.hasFlag(.right) {
                            f.x = f.right - v.size.width
                        }
                    }
                    v.frame = viewport!.pixPerfect(f.translate(p))
                    p = p + d * csz * l.size
                }
            }
        }
    }
    public var ceilSize : Size {
        return superview!.size / Size(self.grid.size)
    }
    public var unitSize : Size {
        var n = 0.0
        switch direction {
        case .horizontal:
            for v in subviews {
                if let l = v.layout {
                    n += l.size.width
                } else {
                    n += 1
                }
            }
            return Size(n,1)
        case .vertical:
            for v in subviews {
                if let l = v.layout {
                    n += l.size.height
                } else {
                    n += 1
                }
            }
            return Size(1,n)
        }
    }
}
