//
//  TextView.swift
//  Alib
//
//  Created by renan jegouzo on 25/12/2016.
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

public class TextView : View {
    var bitmap:Bitmap?
    public var text:String {
        didSet(t) {
            if text != t {
                if let b = self.bitmap {
                    b.detach()
                    self.bitmap = nil
                }
            }
        }
    }
    public var font:String {
        didSet(f) {
            if font != f {
                if let b = self.bitmap {
                    b.detach()
                    self.bitmap = nil
                }
            }
        }
    }
    public var align:Align {
        didSet(a) {
            if align != a {
                if let b = self.bitmap {
                    b.detach()
                    self.bitmap = nil
                }
            }
        }
    }
    public var fontSize:Double {
        didSet(fs) {
            if fontSize != fs {
                if let b = self.bitmap {
                    b.detach()
                    self.bitmap = nil
                }
            }
        }
    }
    override public var size: Size {
        get {
            return super.size
        }
        set(sz) {
            if sz.ceil != super.size {
                if let b = self.bitmap {
                    b.detach()
                    self.bitmap = nil
                }
            }
            super.size = sz.ceil
        }
    }
    public init(superview:View,layout:Layout?=nil,text:String="",align:Align=Align.topLeft,font:String="font.regular",fontSize:Double=0.8,color:Color=Color.white) {
        self.text = text
        self.font = font
        self.align = align
        self.fontSize = fontSize
        if let l = layout {
            super.init(superview:superview,layout:l)
        } else {
            super.init(superview:superview)
        }
        self.color = color
    }
    override public func draw(to g: Graphics) {
        if self.bitmap == nil, let font = self[font] as? Font {
            var f:Font?
            if fontSize == 0 {
                f = Font(font:font,size:font.size)
            } else if fontSize <= 1 {
                f = Font(font:font,size:self.size.height*fontSize)
            } else {
                f = Font(font:font,size:fontSize)
            }
            self.bitmap = f!.mask(text:text,align:align,width:self.size.width,lines:1)
        }
        if let b = self.bitmap {
            let r = b.bounds.aligned(in:self.bounds,align:align)
            //g.fill(rect:r,color:.aeBlue)    // 4debug
            g.draw(rect:r,image:b,blend:.color,color:self.computedColor)
        }
    }
}

public class FlexTextView : View {
    var fontSize:Double
    var font:String
    var text:String
    var bitmap:Bitmap?=nil
    var maxLines:Int = 0
    public init(superview:View,layout:Layout,text:String,font:String="font.regular",fontSize:Double=0,maxLines:Int=0) {
        self.fontSize = fontSize
        self.font = font
        self.text = text
        self.maxLines = maxLines
        super.init(superview:superview,layout:layout)
        self.onResize.alive(self) { sz in
            if let b = self.bitmap {
                if b.size != sz {
                    b.detach()
                    self.bitmap=nil
                }
            }
        }
    }
    override public func detach() {
        if let b=self.bitmap {
            b.detach()
            self.bitmap = nil
        }
        super.detach()
    }
    override public var size: Size {
        get {
            return super.size
        }
        set(sz) {
            if let f = self[font] as? Font {
                if fontSize>0 {
                    let f0 = Font(font:f,size:fontSize)
                    super.size = f0.bounds(text,width:sz.width,lines:self.maxLines).size.ceil
                } else {
                    super.size = f.bounds(text,width:sz.width,lines:self.maxLines).size.ceil
                }
            } else {
                super.size = sz.ceil
            }
        }
    }
    override public func draw(to g: Graphics) {
        if bitmap == nil, let f = self[font] as? Font {
            if fontSize>0 {
                let f0 = Font(font:f,size:fontSize)
                self.bitmap = f0.mask(text:text,width:self.size.width,lines:self.maxLines)
            } else {
                self.bitmap = f.mask(text:text,width:self.size.width,lines:self.maxLines)
            }
        }
        if let b = self.bitmap {
            g.draw(rect:b.bounds,image:b,blend:.color,color:color)
        }
    }
    
}

