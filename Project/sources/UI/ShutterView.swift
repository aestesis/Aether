//
//  ShutterView.swift
//  Alib
//
//  Created by renan jegouzo on 27/09/2016.
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


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class ShutterView : View {
    public enum Overlay {
        case none
        case dots
        case squares
    }
    var direction : Direction
    public var current : Int {
        get {
            return _current
        }
        set(c) {
            switch direction {
            case .horizontal:
                self.touch.animateTo(position:Point(-Double(c)*self.size.w,0))
            case .vertical:
                self.touch.animateTo(position:Point(0,-Double(c)*self.size.h))
            }
        }
    }
    public var currentView : View {
        return content.subviews[current]
    }
    var _current : Int = 0
    public var content : View {
        return _content!
    }
    var _content : View?
    var overlay:Overlay
    var lastmove:Double=ß.time
    var alpha:Double
    let fading:Bool
    public init(superview:View,layout:Layout,direction:Direction = .horizontal,overlay:Overlay = .none,fading:Bool=false) {
        self.fading=fading
        self.alpha=fading ? 0.0 : 1.0
        self.overlay=overlay
        self.direction = direction
        super.init(superview:superview,layout:layout)
        self.swipe = (direction == .horizontal) ? .horizontal : .vertical
        _content=View(superview:self)
        self.onResize.alive(self) { sz in
            switch direction {
            case .horizontal:
                let csz = self.size * Size(Double(self.content.subviews.count),1)
                self.content.size = csz
                let w = csz.w - sz.w
                self.touch.bounds = Rect(x:-w,y:0,w:w,h:0)
                self.touch.magnet = Size(sz.w,0)
            case .vertical:
                let csz = sz * Size(1,Double(self.content.subviews.count))
                self.content.size = csz
                let h = csz.h - sz.h
                self.touch.bounds = Rect(x:0,y:-h,w:0,h:h)
                self.touch.magnet = Size(0,sz.h)
            }
        }
        self.touch.onVirtualMoved.alive(self) { p in
            self.lastmove = ß.time
            if self.touch.bounds != Rect.zero { // no move in only one content
                switch direction {
                case .horizontal:
                    self.content.position = Point(p.x,0)
                    self._current = -Int(p.x/self.size.w)
                case . vertical:
                    self.content.position = Point(0,p.y)
                    self._current = -Int(p.y/self.size.h)
                }
                //Debug.warning("current \(self.current)  position \(self.content.position)")
            }
        }
        self.content.onSubviewsChanged.alive(self) {
            switch direction {
            case .horizontal:
                var n = 0
                for v in self.content.subviews {
                    v.layout?.placement = Rect(x:Double(n),y:0,w:1,h:1)
                    n += 1
                }
            case .vertical:
                var n = 0
                for v in self.content.subviews {
                    v.layout?.placement = Rect(x:0,y:Double(n),w:1,h:1)
                    n += 1
                }
            }
        }
    }
    override public func overlay(to g: Graphics) {
        if fading {
            let dt = ß.time-lastmove
            if dt<1 {
                alpha = 1-((1-alpha)*0.9)
            } else if dt>3 {
                alpha = alpha*0.9
            }
        }
        let color = Color(a:alpha,l:1)*self.computedColor
        switch overlay {
        case .dots:
            if content.subviews.count>1 {
                let r = self.size.length * (Device.kind != .tv ? 0.003 : 0.005)
                switch direction  {
                case .horizontal:
                    let c = self.bounds.point(px: 0.5, py: 0.92)
                    let dw = r*5
                    var x = c.x-dw*Double(content.subviews.count-1)*0.5
                    for i in 0..<content.subviews.count {
                        let v = 2 - min(abs(Double(i) + self.content.position.x / self.size.width),1)
                        g.circle(center: Point(x,c.y), radius: r*v, color: color)
                        x += dw
                    }
                case .vertical:
                    let c = self.bounds.point(px: 0.92, py: 0.5)
                    let dh = r*5
                    var y = c.y-dh*Double(content.subviews.count-1)*0.5
                    for i in 0..<content.subviews.count {
                        let v = 2 - min(abs(Double(i) + self.content.position.y / self.size.height),1)
                        g.circle(center: Point(c.x,y), radius: r*v, color: color)
                        y += dh
                    }
                    return
                }
            }
        case .squares:
            if content.subviews.count>1 {
                if alpha > 0.01 {
                    switch direction  {
                    case .horizontal:
                        Debug.notImplemented()
                        // TODO:
                        return
                    case .vertical:
                        let r = self.bounds.percent(px:0.05,py:0.05,pw:0.05,ph:0.05)
                        let current = self.content.position.y/self.size.h
                        let x = self.size.width - 2*r.width
                        var y = r.width + current * r.height
                        g.fill(rect:Rect(x:x,y:r.w,w:r.w,h:r.h),blend:.alpha,color:Color(a:alpha,rgb:color))
                        for _ in 0..<content.subviews.count {
                            g.fill(rect:Rect(x:x,y:y,w:r.w,h:r.h).scale(0.75),blend:.alpha,color:color*Color.grey)
                            y += r.height
                        }
                    }
                }
            }
        default:
            break
        }
    }
    override public func arrange() {
        switch direction {
        case .horizontal:
            self.content.grid.size=SizeI(Int(self.content.subviews.count),1)
        case .vertical:
            self.content.grid.size=SizeI(1,Int(self.content.subviews.count))
        }
        super.arrange()
    }
    override public func key(_ k: Key) {
        if let pad = k as? Keypad {
            touch.swipe(state:pad.state,swipe:pad.swipe)
        } else {
            super.key(k)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class CarouselView : View {
    public let onCurrentChanged=Event<Int>()
    public var current : Int {
        get {
            return _current
        }
        set(c) {
            let v = content.subviews[c]
            switch content.direction {
            case .horizontal:
                self.touch.animateTo(position:Point(-v.position.x,0))
            case .vertical:
                self.touch.animateTo(position:Point(0,-v.position.y))
            }
        }
    }
    public var currentView : View {
        return content.subviews[current]
    }
    var _current : Int = 0
    public var content : StackView {
        return _content!
    }
    var _content : StackView?
    public init(superview:View,layout:Layout,direction:Direction = .horizontal) {
        super.init(superview:superview,layout:layout)
        self.swipe = (direction == .horizontal) ? .horizontal : .vertical
        _content=StackView(superview:self,direction:direction)
        self.touch.onVirtualMoved.alive(self) { p in
            if self.touch.bounds != Rect.zero { // no move in only one content
                switch direction {
                case .horizontal:
                    self.content.position = Point(p.x,0)
                    let i = ß.nearest(array:self.touch.magnetsH!,value:p.x).index
                    if i>=0 && i != self._current {
                        self._current = i
                        self.onCurrentChanged.dispatch(self.current)
                    }
                case . vertical:
                    self.content.position = Point(0,p.y)
                    let i = ß.nearest(array:self.touch.magnetsV!,value:p.x).index
                    if i>=0 && i != self._current {
                        self._current = i
                        self.onCurrentChanged.dispatch(self.current)
                    }
                }
                //Debug.warning("current \(self.current)  position \(self.content.position)")
            }
        }
    }
    override public func arrange() {
        super.arrange()
        let sz = ((content.unitSize-Size(1,1))*self.size).ceil
        switch content.direction {
        case .horizontal:
            self.touch.bounds = Rect(-sz.w,0,sz.w,0)
            self.touch.magnetsH = content.subviews.map { v -> Double in
                return -v.position.x
            }
        case .vertical:
            self.touch.bounds = Rect(-sz.h,0,sz.h,0)
            self.touch.magnetsV = content.subviews.map { v -> Double in
                return -v.position.y
            }
        }
    }
    override public func key(_ k: Key) {
        if let pad = k as? Keypad {
            touch.swipe(state:pad.state,swipe:pad.swipe)
        } else {
            super.key(k)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
