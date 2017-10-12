//
//  View.swift
//  Alib
//
//  Created by renan jegouzo on 27/02/2016.
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
open class View : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum DrawMode {
        //case device
        case superview
        case surface
    }
    public struct Grid {
        public struct Disposition {
            public var begin:Bool
            public var between:Bool
            public var end:Bool
            public var count:Int {
                return (begin ? 1 : 0) + (end ? 1 : 0)
            }
            public init(begin:Bool=true,between:Bool=true,end:Bool=true) {
                self.begin = begin
                self.between = between
                self.end = end
            }
        }
        public var marginFloat:Size=Size.zero
        public var marginAbs:Size=Size.zero
        public var size:SizeI=SizeI(1,1)
        public var horizontal:Disposition=Disposition()
        public var vertical:Disposition=Disposition()
        public var spaces:PointI {
            return PointI(x:horizontal.count+(horizontal.between ? size.width-1 : 0),y:vertical.count+(vertical.between ? size.height-1 : 0))
        }
    }
    public struct Layout {
        public static var marginMultiplier:Double = 1.0
        public var placement:Rect=Rect(x:0,y:0,w:1,h:1)
        public var align:Align=Align.none
        public var marginLeft:Double=0
        public var marginRight:Double=0
        public var marginTop:Double=0
        public var marginBottom:Double=0
        public var aspect:Double=0
        public var margin: Double {
            get { return marginLeft }
            set(m) {
                marginLeft=m
                marginRight=m
                marginTop=m
                marginBottom=m
            }
        }
        public var origin:Point {
            get { return placement.origin }
            set(p) {
                placement.origin = p
                if placement.width == 0 {
                    placement.width = 1
                }
                if placement.height == 0 {
                    placement.height = 1
                }
            }
        }
        public var size : Size {
            get { return placement.size }
            set(s) {
                placement.size=s
            }
        }
        public init(placement:Rect?=nil,origin:Point?=nil,size:Size?=nil,align:Align?=nil,margin:Double?=nil,marginLeft:Double?=nil,marginRight:Double?=nil,marginTop:Double?=nil,marginBottom:Double?=nil,aspect:Double=0)
        {
            if let p=placement {
                self.placement=p
            }
            if let o=origin {
                self.placement.origin=o
            }
            if let s=size {
                self.placement.size=s
            }
            if let a=align {
                self.align=a
            }
            if let m=margin {
                self.margin=m*Layout.marginMultiplier
            }
            if let m=marginLeft {
                self.marginLeft=m*Layout.marginMultiplier
            }
            if let m=marginRight {
                self.marginRight=m*Layout.marginMultiplier
            }
            if let m=marginTop {
                self.marginTop=m*Layout.marginMultiplier
            }
            if let m=marginBottom {
                self.marginBottom=m*Layout.marginMultiplier
            }
            self.aspect=aspect
        }
        public static var none:Layout {
            return Layout(align:Align.none)
        }
    }
    public struct Transform {
        public var position:Vec3
        var _scale:Vec3
        public var rotation:Vec3
        public var scale : Size {
            get { return Size(_scale.x,_scale.y) }
            set(s) {
                _scale.x = s.width
                _scale.y = s.height
            }
        }
        public var perspective:Double
        public var offset:Vec3
        public var matrix:Mat4 {
            return Mat4.scale(_scale)*Mat4.rotX(rotation.x)*Mat4.rotY(rotation.y)*Mat4.rotZ(rotation.z)*Mat4.translation(position+offset)
        }
        public func matrixCentered(_ p:Point) -> Mat4 {
            let v=Vec3(p)
            return Mat4.translation(-v)*Mat4.scale(_scale)*Mat4.rotX(rotation.x)*Mat4.rotY(rotation.y)*Mat4.rotZ(rotation.z)*Mat4.translation(position+v+offset)
        }
        public func matrixCenteredRender(_ p:Point) -> Mat4 {
            let v=Vec3(p)
            if perspective>0 {
                let mp = Mat4.localPerspective(perspective)
                return Mat4.translation(-v)*Mat4.scale(_scale)*Mat4.rotX(rotation.x)*Mat4.rotY(rotation.y)*Mat4.rotZ(rotation.z)*mp*Mat4.translation(position+v+offset)
            }
            return Mat4.translation(-v)*Mat4.scale(_scale)*Mat4.rotX(rotation.x)*Mat4.rotY(rotation.y)*Mat4.rotZ(rotation.z)*Mat4.translation(position+v+offset)
        }
        static var identity:Transform {
            return Transform(position:Vec3.zero, _scale:Vec3(x:1,y:1,z:1), rotation:Vec3.zero, perspective:0, offset:Vec3.zero)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _layouts=[String:Layout]()
    var _size:Size=Size.zero
    var _needsLayout:Bool=false
    var swipeStart=TouchLocation()
    var swipeCurrent=Swipe.none
    var swipeOK = false
    var nframe:Int=0
    var surface:Bitmap? = nil
    var _effect:Effect? = nil
    var touchCaptured:View?=nil
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onEnterRendering=Event<Void>()
    public let onDraw=Event<Graphics>()
    public let onOverlay=Event<Graphics>()
    public let onResize=Event<Size>()
    public let onSubviewAttached=Event<View>()
    public let onSubviewDetached=Event<View>()
    public let onSubviewsChanged=Event<Void>()
    public let onFocus=Event<Bool>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var id:String
    public var background:Color?
    public var color:Color=Color.white {
        didSet {
            if oldValue != color {
                self.needsRedraw = true
            }
        }
    }
    public var enabled:Bool=true
    public var grid:Grid=Grid()
    public var swipe:Swipe=Swipe.none
    public var edgeSwipe = false
    public var transform:Transform=Transform.identity
    public var visible:Bool=true
    public var opaque:Bool=false
    public var clipping = true
    public private(set) var subviews:[View]=[View]()
    public var needsRedraw = true
    public var drawMode:DrawMode = .superview
    public var depthOrdering = false
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var bounds:Rect {
        return Rect(o:Point.zero,s:size)
    }
    public var center : Point {
        get { return frame.origin+localCenter }
        set(p) { frame.origin = p-localCenter }
    }
    public var computedColor:Color {
        var a = self.color.a
        var v:View? = self.superview
        while v != nil {
            a *= v!.color.a
            v = v!.superview
        }
        return Color(a:a,rgb:color)
    }
    func dispatchLayout() {
        if needsLayout {
            needsLayout=false
            arrange()
            for v in subviews {
                v.dispatchLayout()
            }
        }
    }
    var memoDrawMode = DrawMode.superview
    public var afterEffect : Effect? {
        get { return _effect }
        set(e) {
            if _effect != e, let oe = _effect {
                oe.detach()
            } else if e != nil {
                self.memoDrawMode = self.drawMode
                self.drawMode = .surface
            }
            _effect = e
            if e == nil {
                self.drawMode = self.memoDrawMode
            }
        }
    }
    open func arrange() {
        let m=grid.marginAbs+grid.marginFloat*size/Size(grid.size)
        let c=(size-Size(grid.spaces)*m)/Size(grid.size)
        let mb = Size(grid.horizontal.begin ? m.w : 0,grid.vertical.begin ? m.h : 0)
        for v in subviews {
            if let l=v.layout {
                if l.align != Align.none {
                    let lp=l.placement
                    var f = Rect (x:mb.w + lp.x * (m.w + c.w) + l.marginLeft, y:mb.h + lp.y * (m.h + c.h) + l.marginTop, w:lp.w * c.w + (lp.w - 1) * m.w - (l.marginLeft + l.marginRight), h:lp.h * c.h + (lp.h - 1) * m.h - (l.marginTop + l.marginBottom));
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
                    v.frame = viewport!.pixPerfect(f)
                }
            }
        }
    }
    open func draw(to g:Graphics) {
        onDraw.dispatch(g)
    }
    open func overlay(to g:Graphics) {
        onOverlay.dispatch(g)
    }
    public func focus(_ focused:Bool) {
        if let viewport = viewport {
            viewport.setFocus(self,focus:focused)
        }
    }
    public var focused : Bool {
        if let viewport = viewport {
            return viewport.focusedView == self
        }
        return false
    }
    public var frame:Rect {
        get { return Rect(o:Point(transform.position.x,transform.position.y),s:size) }
        set(r) {
            self.transform.position.x=r.x
            self.transform.position.y=r.y
            self.size=r.size
        }
    }
    open func getSubview(ref:View,increment:Int) -> View? {
        for i in 0..<subviews.count {
            if subviews[i] == ref {
                let n = i + increment
                if n>=0 && n<subviews.count {
                    return subviews[n]
                }
                return nil
            }
        }
        return nil
    }
    public func child<T:View>(recursive:Bool=false) -> T? {
        for v0 in subviews  {
            if let v=v0 as? T {
                return v
            }
            if recursive, let s = v0.child(recursive:true) as T? {
                return s
            }
        }
        return nil
    }
    public func children<T:View>(recursive:Bool=false) -> [T] {
        var s=[T]()
        for v0 in subviews  {
            if let v=v0 as? T {
                s.append(v)
            }
            if recursive {
                s += v0.children(recursive:true) as [T]
            }
        }
        return s
    }
    public func find(key:String) -> [View] {
        var views=[View]()
        if(self.classes.contains(key: key)) {
            views.append(self);
        }
        for v in subviews {
            views.append(contentsOf: v.find(key:key))
        }
        return views;
    }
    public func find(keys:[String]) -> [View] {
        var views=[View]()
        if(self.classes.contains(keys: keys)) {
            views.append(self);
        }
        for v in subviews {
            views.append(contentsOf: v.find(classes: classes))
        }
        return views;
    }
    public func find(classes:Classes) -> [View] {
        return self.find(keys:classes.keys)
    }
    open func key(_ k: Key) {
        superview?.key(k)
    }
    public var layout:Layout? {
        get {
            if let s=superview {
                return s._layouts[self.id]
            }
            return nil
        }
        set(l) {
            if let s=superview {
                if l == nil {
                    s._layouts.removeValue(forKey: self.id)
                } else {
                    s._layouts[self.id]=l
                    s.needsLayout = true
                }
            }
        }
    }
    open var localCenter : Point {
        return self.bounds.center   // rotation center, can be overridden
    }
    public func localTo(_ subview:View,_ p:Point) -> Point {          // superview coord to subview coord
        let m = self.matrix(subview).inverted   // why inverted ??
        let v = m.transform(Vec4(x:p.x,y:p.y,z:0,w:1))
        return Point(v.x,v.y)
    }
    public func localFrom(_ subview:View,_ p:Point) -> Point {        // superview coord from subview coord
        let m = self.matrix(subview)            // should be inverted..
        let v = m.transform(Vec4(x:p.x,y:p.y,z:0,w:1))
        return Point(v.x,v.y)
    }
    public func matrix(_ subview:View) -> Mat4 {
        var v:View?=subview
        var m = Mat4.identity
        while v != nil && v != self {       // inverted path
            m = m * v!.matrix   // inverted mul
            v = v!.superview
        }
        return m    // inverted + inverted = normal ?
    }
    public var matrix : Mat4 {
        return transform.matrixCentered(localCenter)
    }
    public var matrixRender : Mat4 {
        return transform.matrixCenteredRender(localCenter)
    }
    #if os(OSX)
    var viewOver=Set<View>()
    open func mouse(_ mo:MouseOver) {
        switch mo.state {
        case .exited:
            for v in viewOver {
                v.mouse(MouseOver(state:.exited))
            }
            viewOver.removeAll()
            //Debug.info("exited \(self.className)")
            break
        case .wheel:
            if let touch = _touch {
                switch swipe {
                case .both:
                    if touch.magnetSwipe(mo.delta) {
                        return
                    }
                    break
                case .horizontal:
                    if abs(mo.delta.x) > abs(mo.delta.y) && touch.magnetSwipe(mo.delta) {
                        return
                    }
                    break
                case .vertical:
                    if abs(mo.delta.x) < abs(mo.delta.y) && touch.magnetSwipe(mo.delta) {
                        return
                    }
                    break
                default:
                    break
                }
            }
            fallthrough
        case .entered,.moved:
            let rvo=viewOver
            for v in rvo {
                let p=localTo(v, mo.position)
                if !v.bounds.contains(p) {
                    v.mouse(MouseOver(state:.exited))
                    viewOver.remove(v)
                }
            }
            var i=subviews.count-1
            for _ in subviews {
                let v=subviews[i]
                if !viewOver.contains(v) {
                    let p=localTo(v,mo.position)
                    if v.visible && v.color.a>0.01 && v.bounds.contains(p) {
                        viewOver.insert(v)
                        v.mouse(MouseOver(state:.entered,position:p,buttons:mo.buttons))
                    }
                }
                i -= 1
            }
            if mo.state == .wheel || mo.state == .moved {
                for v in viewOver {
                    v.mouse(MouseOver(state:mo.state,position:localTo(v,mo.position),delta:mo.delta,buttons:mo.buttons))
                }
            }
            break
        default:
            break
        }
    }
    #else
    open func mouse(_ mo:MouseOver) {
        Debug.notImplemented()
    }
    #endif
    public func order(before v:View) {
        if let superview = superview, v != self {
            superview.subviews.remove(at:superview.subviews.index(of:self)!)
            superview.subviews.insert(self,at:superview.subviews.index(of:v)!)
        }
    }
    public func order(after v:View) {
        if let superview = superview, v != self {
            superview.subviews.remove(at:superview.subviews.index(of:self)!)
            superview.subviews.insert(self,at:superview.subviews.index(of:v)!+1)
        }
    }
    public var needsLayout : Bool {
        get { return _needsLayout }
        set(b) {
            if b {
                if let s=superview  {
                    s.needsLayout=true
                } else if let viewport = viewport {
                    viewport.needsLayout=true
                }
            }
            _needsLayout=b
        }
    }
    public var orientation : Orientation {
        if let s=superview {
            return s.orientation
            
        }
        return viewport!.orientation
    }
    public var position : Point {
        get { return frame.origin }
        set(p) { frame.origin = p }
    }
    public var rendered:Bool {
        return ((viewport!.nframes-nframe) <= 1)
    }
    open var size: Size {
        get { return _size }
        set(s) {
            if s != _size {
                if s.width<=0 || s.height<=0 {
                    Debug.warning("warning, view \(self.className), size set to empty area \(s)")
                }
                _size=s;
                needsLayout=true
                onResize.dispatch(s)
            }
        }
    }
    public func snapshot(_ fn:@escaping (Bitmap)->()) {
        if let viewport = viewport {
            viewport.snapshot(view:self, { b in
                if let b=b {
                    fn(b)
                }
            })
        }
    }
    public func snapshotDepth(_ fn:@escaping (Bitmap)->()) {    // returning bitmap["depth"] contains [Float32]
        if let viewport = viewport {
            viewport.snapshotDepth(view:self) { b in
                if let b=b {
                    fn(b)
                }
            }
        }
    }
    public func subview(_ p:Point,recursive:Bool=false) -> View? {
        var i=subviews.count-1
        for _ in 0..<subviews.count {
            let v=subviews[i]
            let pl=localTo(v,p)
            if v.bounds.contains(pl) {
                if recursive && v.subviews.count>0 {
                    if let vs=v.subview(pl,recursive:true) {
                        return vs
                    }
                }
                return v
            }
            i -= 1
        }
        return nil
    }
    public var superview:View? {
        if let v = parent as? View {
            return v
        }
        return nil
    }
    public func touches(_ touches:[TouchLocation]) -> Bool {
        let dispatch:([TouchLocation])->(View?) = { touches in
            var i=self.subviews.count - 1
            for _ in 0..<self.subviews.count {
                let v=self.subviews[i]
                if v.visible && v.enabled && v.color.a > 0.9 {
                    let p=self.localTo(v, touches[0].position)
                    if v.bounds.contains(p) {
                        if v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix)) {
                            return v
                        }
                    }
                }
                i -= 1
            }
            return nil
        }
        if !visible || !enabled {
            return false
        }
        if let touch=_touch {
            if swipe == .horizontal || swipe == .vertical  {
                if touches.count == 1 {
                    let t = touches[0]
                    switch t.state {
                    case .pressed:
                        swipeStart = t
                        swipeCurrent = Swipe.none
                        //Debug.warning("\(self.className): swipe pressed")
                        touchCaptured = dispatch(touches)
                        swipeOK = false
                        if edgeSwipe {
                            var p = t.position / self.size
                            p.x = p.x.truncatingRemainder(dividingBy: 1)
                            p.y = p.y.truncatingRemainder(dividingBy: 1)
                            //Debug.warning("edgeSwipe start: \(p)")
                            switch swipe {
                            case .horizontal:
                                if p.x<0.07 || p.x>0.93 {
                                    swipeOK = true
                                }
                            case .vertical:
                                if p.y<0.07 || p.y>0.93 {
                                    swipeOK = true
                                }
                            case .both:
                                if p.x<0.07 || p.x>0.93 {
                                    swipeOK = true
                                }
                                if p.y<0.07 || p.y>0.93 {
                                    swipeOK = true
                                }
                            default:
                                break
                            }
                        } else {
                            swipeOK = true
                        }
                        //Debug.warning("edgeSwipe: \(swipeOK)")
                        return true
                    case .moved:
                        //Debug.warning("\(self.className): swipe moved")
                        if swipeCurrent == Swipe.none && swipeOK {
                            let d = (t.position-swipeStart.position).length
                            if d > touch.distanceAcceptMove {
                                swipeCurrent = (abs(t.position.x-swipeStart.position.x) > abs(t.position.y-swipeStart.position.y)) ? Swipe.horizontal : Swipe.vertical
                                if swipeCurrent.match(swipe:swipe) {
                                    let _ = touch.touches([swipeStart])
                                    if let v=touchCaptured {
                                        let _ = v.touches([TouchLocation(state:.cancelled,position:t.position,pressure:0)])
                                        touchCaptured = nil
                                    }
                                }
                            }
                        }
                        if swipeCurrent.match(swipe:swipe) {
                            return touch.touches(touches)
                        }
                        if let v = touchCaptured {
                            //Debug.info("touchCaptured, moved: \(v.className)")
                            return v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                        }
                    case .released,.cancelled:
                        //Debug.warning("\(self.className): swipe released")
                        if swipeCurrent.match(swipe: swipe) {
                            return touch.touches(touches)
                        } else if let v=touchCaptured {
                            let _ = v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                            touchCaptured = nil
                            //Debug.info("touchCaptured, \(t.state): \(v.className)")
                        } else if touch.onClick.count>0 {    // fast click
                            if touch.touches([swipeStart]) {
                                let _ = touch.touches(touches)
                            }
                        }
                        swipeCurrent = Swipe.none
                        swipeOK = false
                        break
                    }
                    return true
                } else {
                    let _ = dispatch(touches)   // multitouch       TODO: must be done better
                }
            } else {    // no swipe hook
                let t = touches[0]
                switch t.state {
                case .pressed:
                    touchCaptured = dispatch(touches)
                    if touchCaptured == nil {
                        return touch.touches(touches)
                    }
                    return touchCaptured != nil
                case .moved:
                    if let v=touchCaptured {
                        //Debug.info("touchCaptured, \(t.state): \(v.className)")
                        return v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                    } else {
                        return touch.touches(touches)
                    }
                case .released,.cancelled:
                    if let v=touchCaptured {
                        //Debug.info("touchCaptured, \(t.state): \(v.className)")
                        let r = v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                        touchCaptured = nil
                        return r
                    } else {
                        return touch.touches(touches)
                    }
                }
            }
        } else {    // no TouchManager
            let t = touches[0]
            switch t.state {
            case .pressed:
                touchCaptured = dispatch(touches)
                return touchCaptured != nil
            case .moved:
                if let v=touchCaptured {
                    //Debug.info("touchCaptured, \(t.state): \(v.className)")
                    return v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                }
            case .released,.cancelled:
                if let v=touchCaptured {
                    let r = v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
                    //Debug.info("touchCaptured, \(t.state): \(v.className)")
                    touchCaptured = nil
                    return r
                }
            }
        }
        return false
    }
    private var _touch:TouchManager?
    public var touch:TouchManager {
        if let t=_touch {
            return t
        } else {
            let t=TouchManager(view:self)
            _touch=t
            return t
        }
    }
    open func add(view:View) {
        self.subviews.append(view)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(viewport:Viewport) {
        self.id = ß.alphaID
        super.init(parent: viewport)
        if !viewport.uiThread {
            Debug.error("error, View added outside UI thread",#file,#line)
        }
        viewport.rootView=self
        self._size=viewport.size
        self.needsLayout=true
        self.viewport!.pulse.once {
            self.onResize.dispatch(self.bounds.size)
        }
    }
    public init(superview:View,layout:Layout=Layout.none,id:String=ß.alphaID) {
        self.id = id
        super.init(parent: superview)
        if let viewport=viewport, !viewport.uiThread {
            Debug.error("error, View added outside UI thread",#file,#line)
        }
        self._size=superview.size
        superview.add(view:self)
        superview._layouts[self.id]=layout
        self.needsLayout=true
        self.viewport!.pulse.once {
            self.onResize.dispatch(self.bounds.size)
        }
        superview.onSubviewAttached.dispatch(self)
        superview.onSubviewsChanged.dispatch(())
    }
    open override func detach() {
        if let viewport=viewport, !viewport.uiThread {
            Debug.error("error, View detached outside UI thread")
        }
        self.sui {
            self.onSubviewAttached.removeAll()
            self.onSubviewsChanged.removeAll()
            self.onEnterRendering.removeAll()
            self.onDraw.removeAll()
            self.onOverlay.removeAll()
            self.onResize.removeAll()
            self.onFocus.removeAll()
            for v in self.subviews {
                v.detach()
            }
            self.onSubviewDetached.removeAll()
            if let superview=self.superview {
                if superview.touchCaptured == self {
                    superview.touchCaptured = nil
                }
                superview.subviews=superview.subviews.filter({ (v) -> Bool in
                    return v != self
                })
            } else if let viewport = self.viewport {
                viewport.rootView=nil
            }
            self.afterEffect = nil
            if let b = self.surface {
                b.detach()
                self.surface = nil
            }
            let superview = self.superview
            super.detach()
            if let superview = superview {
                superview.onSubviewDetached.dispatch(self)
                superview.onSubviewsChanged.dispatch(())
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public enum Align : Int  {
    case none = 0
    case left = 1
    case middle = 2
    case right = 4
    case justified = 8
    case top = 128
    case center = 256
    case bottom = 512
    case topLeft = 129
    case topMiddle = 130
    case topRight = 132
    case centerLeft = 257
    case centerMiddle = 258
    case centerRight = 260
    case bottomLeft = 513
    case bottomMiddle = 514
    case bottomRight = 516
    case fillWidth = 5
    case fillHeight = 640
    case fill = 645
    case maskHorizontal = 15
    case maskVertical = 896
    public static var horizontalCenter:Align {
        return .middle
    }
    public static var verticalCenter:Align {
        return .center
    }
    public static var fullCenter:Align {
        return .centerMiddle
    }
    public var horizontalPart:Align {
        return Align(rawValue:self.rawValue&Align.maskHorizontal.rawValue)!
    }
    public var verticalPart:Align {
        return Align(rawValue:self.rawValue&Align.maskVertical.rawValue)!
    }
    public func hasFlag(_ flag:Align) -> Bool {
        return (self.rawValue & flag.rawValue) == flag.rawValue
    }
    public var point:Point {
        var p = Point.zero
        switch(Align(rawValue: self.rawValue & Align.maskHorizontal.rawValue)!) {
        case .right:
            p.x = 1
        case .middle,.fillWidth:
            p.x = 0.5
        //case .left:
        default:
            p.x = 0.0
        }
        switch(Align(rawValue: self.rawValue & Align.maskVertical.rawValue)!) {
        case .bottom:
            p.y = 1
        case .center,.fillHeight:
            p.y = 0.5
        //case .top:
        default:
            p.y = 0
        }
        return p
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public enum Orientation : Int
{
    case undefined=0
    case portraitBottom=1
    case portraitUpsideDown=2
    case landscapeRight=4
    case landscapeLeft=8
    // bas du telephone a droite sur android (TODO; make it the same on iOS)
    case portrait=3
    case landscape=12
    case all=15
    public var isLandscape : Bool {
        return self==Orientation.landscapeLeft||self==Orientation.landscapeRight||self==Orientation.landscape
    }
    public var isPortrait : Bool {
        return self==Orientation.portrait||self==Orientation.portraitBottom||self==Orientation.portraitUpsideDown
    }
    public var isSingle : Bool {
        return self==Orientation.portraitBottom||self==Orientation.portraitUpsideDown||self==Orientation.landscapeLeft||self==Orientation.landscapeRight
    }
    public func rotation(from:Orientation) -> Rotation {
        if self==Orientation.undefined||from==Orientation.undefined||self==Orientation.all||from==Orientation.all {
            return Rotation.none
        } else if self==Orientation.landscape&&from.isLandscape || self==Orientation.portrait&&from.isPortrait || from==Orientation.landscape&&self.isLandscape || from==Orientation.portrait && self.isPortrait {
            return Rotation.none
        }
        return Rotation(rawValue: (self.rotation.rawValue-from.rotation.rawValue)&3)!
    }
    public func rotation(to:Orientation) -> Rotation {
        if self==Orientation.undefined||to==Orientation.undefined||self==Orientation.all||to==Orientation.all {
            return Rotation.none
        } else if self==Orientation.landscape&&to.isLandscape || self==Orientation.portrait&&to.isPortrait || to==Orientation.landscape&&self.isLandscape || to==Orientation.portrait && self.isPortrait {
            return Rotation.none
        }
        return Rotation(rawValue: (to.rotation.rawValue-self.rotation.rawValue)&3)!
    }
    public var rotation : Rotation {
        switch self {
        case Orientation.landscape:
            return Rotation.clockwise
        case Orientation.landscapeLeft:
            return Rotation.clockwise
        case Orientation.landscapeRight:
            return Rotation.anticlockwise
        case Orientation.portraitUpsideDown:
            return Rotation.upSideDown
        default:
            return Rotation.none
        }
    }
    public func rotate(_ rotation:Rotation) -> Orientation {
        return Rotation(rawValue: (self.rotation.rawValue+rotation.rawValue)&3)!.orientation
    }
    #if os(iOS)
    public init(device:UIDeviceOrientation) {
        switch device {
        case UIDeviceOrientation.portrait:
            self = .portraitBottom
        case UIDeviceOrientation.portraitUpsideDown:
            self = .portraitUpsideDown
        case UIDeviceOrientation.landscapeLeft:
            self = .landscapeLeft
        case UIDeviceOrientation.landscapeRight:
            self = .landscapeRight
        default:
            self = .undefined
        }
    }
    public init(interface:UIInterfaceOrientation) {
        switch interface {
        case UIInterfaceOrientation.portrait:
            self = .portraitBottom
        case UIInterfaceOrientation.portraitUpsideDown:
            self = .portraitUpsideDown
        case UIInterfaceOrientation.landscapeLeft:
            self = .landscapeRight
        case UIInterfaceOrientation.landscapeRight:
            self = .landscapeLeft
        default:
            self = .undefined
        }
    }
    #endif
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public enum Rotation : Int
{
    case none=0
    case clockwise=1
    case upSideDown=2
    case anticlockwise=3
    public var angle : Double
        {
            switch self {
            case Rotation.anticlockwise:
                return -ß.π2
            case Rotation.clockwise:
                return ß.π2
            case Rotation.upSideDown:
                return ß.π
            default:
                return 0.0;
            }
    }
    public var isQuarter : Bool {
        return self==Rotation.clockwise||self==Rotation.anticlockwise
    }
    public func rotate(_ size:Size) -> Size {
        if isQuarter {
            return size.rotate
        }
        return size
    }
    public func rotate(_ rect:Rect) -> Rect {
        if isQuarter {
            return rect.rotate
        }
        return rect
    }
    public var invers : Rotation {
        return Rotation(rawValue: (4-self.rawValue)&3)!
    }
    public var orientation : Orientation
    {
        switch self {
            case Rotation.none:
                return Orientation.portraitBottom
            case Rotation.clockwise:
                return Orientation.landscapeLeft
            case Rotation.upSideDown:
                return Orientation.portraitUpsideDown
            case Rotation.anticlockwise:
                return Orientation.landscapeRight
            }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public enum Direction : Int {
    case vertical=1
    case horizontal=2
    public var point : Point {
        switch self {
        case .vertical:
            return Point(0,1)
        case .horizontal:
            return Point(1,0)
        }
    }
    public var size : Size {
        switch self {
        case .vertical:
            return Size(0,1)
        case .horizontal:
            return Size(1,0)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

