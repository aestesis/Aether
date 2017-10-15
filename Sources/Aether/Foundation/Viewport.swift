
//
//  Viewport.swift
//  Aether
//
//  Created by renan jegouzo on 22/02/2016.
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

#if os(tvOS) || os(iOS) || os(macOS)
    import Metal
    import QuartzCore
    import MetalKit
#else
    import Dispatch
    import Uridium
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Viewport : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    class GPU {
        #if os(macOS) || os(iOS) || os(tvOS)
            var device:MTLDevice?
            var queue:MTLCommandQueue {
                let key="aestesis.alib.Viewport.GPU.queue"
                if let q=Thread.current[key] as? MTLCommandQueue {
                    return q;
                }
                Debug.info("Viewport.GPU: new command queue for thread")
                let q=device!.makeCommandQueue()
                Thread.current[key]=q
                return q!
            }
            var loader:MTKTextureLoader?
        #else
            var tin:Tin?
            // TODO:
        #endif
        var library:ProgramLibrary?
        var buffers:Buffers?
        var tess:Tess {
            let key="aestesis.alib.Viewport.GPU.libtess"
            if let t=Thread.current[key] as? Tess {
                return t;
            }
            Debug.info("Viewport.GPU: new libtess for thread")
            let t=Tess()
            Thread.current[key]=t
            return t
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var gpu=GPU()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let pulse=Event<Void>()
    public let onTouches=Event<[TouchLocation]>()
    public let onKey=Event<Key>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var orientation:Orientation {
        return systemView.orientation
    }
    public private(set) var scale:Size=Size(1,1)
    public private(set) var release=false
    public private(set) var focusedView:View?
    public private(set) var fps:Double = 0
    public private(set) var nframes:Int=0
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    let debugThread = true
    public let systemView:SystemView
    var keyframe:Double=ß.time
    var refreshers=[(owner:NodeUI,action:Action<Void>)]()
    var refreshLock=Lock()
    var lastFrame:Double=ß.time
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    private var _needsLayout : Bool = false
    public var needsLayout : Bool {
        get { return _needsLayout }
        set(b) {
            if b {
                _needsLayout=true
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    private var _rootView:View?
    public var rootView : View? {
        get { return _rootView }
        set(v) {
            _rootView=v
            if let vv=v {
                vv.size=self.size
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var pixsize : Size
    private var _size:Size = Size.zero
    public var size: Size {
        get { return _size }
        set(s) {
            if(s != _size) {
                Debug.warning("viewport resized:\(s) orientation:\(orientation)")
                _size=s
                if let v=rootView {
                    v.size=s
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    private func dispatchLayout() {
        var nloop=0
        while needsLayout {
            _needsLayout=false
            if let v=rootView {
                if v.needsLayout {
                    v.dispatchLayout()
                }
            }
            nloop += 1
            if nloop>10 {
                Debug.error("too many Viewport.dispatchLayout() recursions")
                break
            }
        }
        if nloop>0 {
            Debug.info("Viewport.dispatchLayout() recursion level: \(nloop)")
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func update() {
        dispatchLayout()
        pulse.dispatch(())
        dispatchLayout()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
        public func draw(_ descriptor:MTLRenderPassDescriptor,drawable:CAMetalDrawable,depth:MTLTexture?=nil) {
            nframes += 1
            if let v=rootView {
                let g=Graphics(viewport:self,descriptor:descriptor,drawable:drawable,depth:depth,clear:v.background)
                render(g,view:v)
                g.done { ok in
                    if ok == .error {
                        Debug.error("Viewport.draw(rootView): GPU error")
                    }
                }
            } else {
                let g=Graphics(viewport:self,descriptor:descriptor,drawable:drawable,clear:Color.aeMagenta)
                g.done { ok in
                    if ok == .error {
                        Debug.error("Viewport.draw(nil): GPU error")
                    }
                }
            }
            if (nframes & 255) == 0 {
                let t=ß.time
                let d=t-keyframe
                keyframe=t
                fps=256/d
                Debug.warning("fps: \(fps.string(2))")
            }
            let t=ß.time
            fps = 1 / (t-lastFrame)
            lastFrame = t
        }
    #else
        public func draw() {
            nframes += 1
            /*
            if let v=rootView {
                let g=Graphics(viewport:self,descriptor:descriptor,drawable:drawable,depth:depth,clear:v.background)
                render(g,view:v)
                g.done { ok in
                    if ok == .error {
                        Debug.error("Viewport.draw(rootView): GPU error")
                    }
                }
            } else {
                let g=Graphics(viewport:self,descriptor:descriptor,drawable:drawable,clear:Color.aeMagenta)
                g.done { ok in
                    if ok == .error {
                        Debug.error("Viewport.draw(nil): GPU error")
                    }
                }
            }
            */
            if (nframes & 255) == 0 {
                let t=ß.time
                let d=t-keyframe
                keyframe=t
                fps=256/d
                Debug.warning("fps: \(fps.string(2))")
            }
            let t=ß.time
            fps = 1 / (t-lastFrame)
            lastFrame = t
        }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func pixPerfect(_ r:Rect) -> Rect {
        return Rect(x: round(r.x / pixsize.w) * pixsize.w, y: round( r.y / pixsize.h) * pixsize.h, w: round(r.w / pixsize.w) * pixsize.w, h: round(r.h / pixsize.h) * pixsize.h)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func render(_ g:Graphics,view:View,forced:Bool=false) {
        if ((view.visible && view.color.a>0.01) || forced || view.drawMode == .surface) && view.size.width>0 && view.size.height>0  {
            var clipped = true
            if let sv=view.superview {
                clipped = sv.clipping
            }
            if !clipped || (g.clip.width>0.0001 && g.clip.height>0.0001) {
                if nframes-view.nframe>1 {
                    view.onEnterRendering.dispatch(())
                }
                view.nframe = nframes
                switch view.drawMode {
                case .surface:
                    var newb = false
                    if let bitmap = view.surface {
                        if bitmap.size != view.size || view.needsRedraw {
                            view.needsRedraw = false
                            newb = true
                        }
                        if view.visible {
                            g.draw(rect:bitmap.bounds,image:bitmap,blend:.alpha)
                        }
                    } else {
                        newb = true
                    }
                    if newb && view.size.width>0 && view.size.height>0 {
                        view.needsRedraw = false
                        if view.surface == nil {
                            view.draw(to:g)
                            var subviews = view.subviews
                            if view.depthOrdering {
                                subviews = Viewport.depthOrderedSubview(subviews)
                            }
                            for v in subviews {
                                render(Graphics(parent:g,matrix:v.matrixRender,clip:v.bounds,clipping:v.clipping),view:v)
                            }
                            view.overlay(to: g)
                        }
                        let b = Bitmap(parent:view,size:view.size)
                        //self.bg {
                            let gn = Graphics(image:b,clear:view.background ?? .transparent)
                            view.draw(to:gn)
                            var subviews = view.subviews
                            if view.depthOrdering {
                                subviews = Viewport.depthOrderedSubview(subviews)
                            }
                            for v in subviews {
                                self.render(Graphics(parent:gn,matrix:v.matrixRender,clip:v.bounds),view:v)
                            }
                            view.overlay(to: gn)
                            gn.done { ok in
                                if ok == .success {
                                    if let e = view.afterEffect {
                                        self.ui {
                                            if e.attached && !e.computing {
                                                e.process(source: b).then { f in
                                                    if let br=f.result as? Bitmap {
                                                        if let ob = view.surface {
                                                            self.ui {
                                                                ob.detach()
                                                            }
                                                        }
                                                        if view.parent != nil {
                                                            view.surface = br
                                                        } else {
                                                            self.ui {
                                                                br.detach()
                                                            }
                                                        }
                                                        self.ui {
                                                            b.detach()
                                                        }
                                                    } else if let err = f.result as? Error {
                                                        Debug.error(err,#file,#line)
                                                        self.ui {
                                                            b.detach()
                                                        }
                                                    }
                                                }
                                            } else {
                                                b.detach()
                                            }
                                        }
                                    } else {
                                        if let ob = view.surface {
                                            self.ui {
                                                ob.detach()
                                            }
                                        }
                                        if view.parent != nil {
                                            view.surface = b
                                        } else {
                                            b.detach()
                                        }
                                    }
                                } else {
                                    if ok == .error {
                                        Debug.error("View.surface rendering error.")
                                    }
                                    self.ui {
                                        b.detach()
                                    }
                                }
                            }
                        //}
                    }
                default:
                    if let s = view.surface {
                        s.detach()
                        view.surface = nil
                    }
                    // TODO: add hard clip
                    if let c = view.background {
                        if c.a == 1 {
                            g.fill(rect:view.frame,color:c)
                        } else {
                            g.fill(rect:view.frame,blend:.alpha,color:c)
                        }
                    }
                    view.draw(to: g)
                    
                    var opaques=[(rect:Rect,layer:Int)]()
                    var layer = 0
                    var subviews = view.subviews
                    if view.depthOrdering {
                        subviews = Viewport.depthOrderedSubview(subviews)
                    }
                    for v in subviews {
                        if v.opaque {
                            opaques.enqueue((rect:v.frame,layer:layer))
                        }
                        layer += 1
                    }
                    if opaques.count == 0 {
                        for v in subviews {
                            render(Graphics(parent:g,matrix:v.matrixRender,clip:v.bounds,clipping:v.clipping),view:v)
                        }
                    } else {
                        Debug.notImplemented()
                        // TODO: finish and fix
                        /*
                        var layer = 0
                        var opa = opaques.dequeue()
                        for v in view.subviews {
                            render(Graphics(parent:g,m:v.matrixRender),view:v)
                            layer += 1
                        }
                        */
                    }
                    view.overlay(to: g)
                    view.needsRedraw = false
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    static func depthOrderedSubview(_ views:[View]) -> [View] {
        return views.sorted(by: { a,b -> Bool in
            return a.transform.position.z>b.transform.position.z
        })
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func snapshot(view:View,_ fn:@escaping (Bitmap?)->()) {
        let b = Bitmap(parent:self,size:view.size)
        let g = Graphics(image:b,clear:view.background ?? Color.transparent)
        render(g,view:view,forced:true)
        g.done { ok in
            if ok == .success {
                fn(b)
                return
            } else if ok == .error {
                Debug.error("Viewport.snapshot(\(view.className)): GPU error")
            }
            fn(nil)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func snapshotDepth(view:View, _ fn:@escaping (Bitmap?)->()) {    // returns bitmap["depth"] with [Float32]
        let b = Bitmap(parent:self,size:view.size)
        let g = Graphics(image:b,clear:view.background ?? Color.transparent,depthClear:1.0,storeDepth:true)
        render(g,view:view,forced:true)
        g.done { ok in
            if ok == .success {
                fn(b)
                return
            } else if ok == .error {
                Debug.error("Viewport.snapshot(\(view.className)): GPU error")
            }
            fn(nil)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func setFocus(_ view:View,focus:Bool) {
        if view != focusedView {
            if let fv=focusedView, focus || ( !focus && fv == view) {
                fv.onFocus.dispatch(false)
            }
            if focus {
                focusedView = view
                view.onFocus.dispatch(true)
                self.systemView.focus()
            }
        } else if !focus && view == focusedView {
            focusedView = nil
            view.onFocus.dispatch(false)
        }
    }
    public func touches(_ touches:[TouchLocation]) {
        onTouches.dispatch(touches)
        // TODO: focusedView is for keyboard/keypad/remote focus, maybe need another kind of  focus (touch /mousecapture)
        if let v=rootView {
            //Debug.info("viewport: \(touches[0].state)")
            let _ = v.touches(TouchLocation.transform(touches:touches,matrix:v.matrix))
            //Debug.info("viewport: returns \(r)")
        }
    }
    public func mouse(_ mo:MouseOver) {
        if let v=rootView {
            v.mouse(mo)
        }
    }
    public func key(_ k:Key) {
        /*
        if let kb = k as? Keybutton {
            Debug.warning("key: \(kb.device) \(kb.name) \(kb.pressed)")
        }
         */
        onKey.dispatch(k)
        if let v=focusedView {
            v.key(k)
        } else if let v=rootView {
            v.key(k)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func toggleFullScreen() {
        systemView.toggleFullScreen()
    }
    public func captureBackButton(_ capture:Bool) {
        //Debug.warning("capture back button \(capture)")
        systemView.captureBackButton(capture)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
        init(systemView:SystemView,device:MTLDevice,size:Size,scale:Size=Size(1,1),pixsize:Size? = nil) {
            self.scale=scale
            self.systemView=systemView
            if let ps = pixsize {
                self.pixsize = ps
            } else {
                self.pixsize = Size(1,1)/scale
            }
            super.init(parent:nil)
            Debug.warning("Viewport.init(\(size))  orientation:\(self.orientation)")
            gpu.device=device
            gpu.loader=MTKTextureLoader(device:device)
            _size=size
            gpu.library=ProgramLibrary(parent:self,filename:"default")
            gpu.buffers=Buffers(viewport:self)
            Graphics.globals(self)
            Renderer.globals(self)
            Effect.globals(self)
            let nt = max(1,ProcessInfo.processInfo.activeProcessorCount/3)
            _bg = Worker(parent:self,threads: nt)
            _io = Worker(parent:self,threads: nt)
            _zz = Worker(parent:self,threads: 1)
            Debug.warning("Workers launched, bg:\(nt) io:\(nt) zz:1 cpus:\(ProcessInfo.processInfo.activeProcessorCount)")
            refreshThread()
            Alib.Thread.current["ui.thread"]=true
        }
    #else 
        init(systemView:SystemView,tin:Tin,size:Size,scale:Size=Size(1,1),pixsize:Size? = nil) {
            self.scale=scale
            self.systemView=systemView
            if let ps = pixsize {
                self.pixsize = ps
            } else {
                self.pixsize = Size(1,1)/scale
            }
            super.init(parent:nil)
            Debug.warning("Viewport.init(\(size))  orientation:\(self.orientation)")
            gpu.tin=tin
            _size=size
            //gpu.library=ProgramLibrary(parent:self,filename:"default")
            gpu.buffers=Buffers(viewport:self)
            Graphics.globals(self)
            Renderer.globals(self)
            Effect.globals(self)
            let nt = max(1,ProcessInfo.processInfo.activeProcessorCount/3)
            _bg = Worker(parent:self,threads: nt)
            _io = Worker(parent:self,threads: nt)
            _zz = Worker(parent:self,threads: 1)
            Debug.warning("Workers launched, bg:\(nt) io:\(nt) zz:1 cpus:\(ProcessInfo.processInfo.activeProcessorCount)")
            refreshThread()
            Thread.current["ui.thread"]=true
        }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func detach() {
        Debug.info("Viewport.detach()")
        self.io.stop()
        self.bg.stop()
        if let v=self.rootView {
            v.detach()
        }
        self.release = true
        //self.io.stop()        was here before
        //self.bg.stop()
        self.refreshLock.synced {
            self.refreshers.removeAll()
        }
        super.detach()
    }
    public var uiThread : Bool {
        if let b = Thread.current["ui.thread"] as? Bool {
            return b
        }
        return false
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func clean(_ inheritor:NodeUI) {
        if focusedView == inheritor {
            focusedView = nil
        }
        cancelJobs(inheritor)
        refreshLock.synced {
            self.refreshers = self.refreshers.filter({ (r:(owner: NodeUI, action: Action<Void>)) -> Bool in
                return r.owner != inheritor
            })
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _bg:Worker?=nil
    var _io:Worker?=nil
    var _zz:Worker?=nil
    public var bg:Worker {
        return _bg!
    }
    public var io:Worker {
        return _io!
    }
    public var zz:Worker {
        return _zz!
    }
    public func cancelJobs(_ owner:NodeUI) {
        bg.cancel(owner)
        io.cancel(owner)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func refresh(_ owner:NodeUI,action:@escaping ()->()) {
        if release {
            return
        }
        refreshLock.synced {
            if self.release {
                return
            }
            for r in self.refreshers {
                if r.owner == owner {
                    return
                }
            }
            self.refreshers.enqueue((owner:owner,action:Action<Void>(action)))
        }
    }
    func refreshThread() {
        let _=Thread {
            var frame:Int=0
            var bgCount:Int=0
            var ioCount:Int=0
            while !self.release {
                while self.nframes == frame {
                    Thread.sleep(0.01)
                    if self.release {
                        return
                    }
                }
                let mt = 0.5 / 60
                let t = ß.time
                
                bgCount = max(bgCount, self._bg!.count)
                ioCount = max(ioCount, self._io!.count)
                
                while ß.time-t<mt {
                    var todo = [(owner:NodeUI,action:Action<Void>)]()
                    self.refreshLock.synced {
                        if self.release {
                            return
                        }
                        if (frame & 255) == 0 {
                            //Debug.warning("refreshers: \(self.refreshers.count)    bg:\(bgCount)    io:\(ioCount)")
                            bgCount = 0
                            ioCount = 0
                        }
                        if let r=self.refreshers.dequeue() {
                            todo.append(r)
                        }
                    }
                    if todo.count==0 {
                        break
                    }
                    for r in todo {
                        r.action.invoke(())
                    }
                }
                frame=self.nframes
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public protocol SystemView {
    func focus()
    func toggleFullScreen()
    func captureBackButton(_ capture:Bool)
    var title : String {
        get
        set
    }
    var orientation : Orientation {
        get
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

