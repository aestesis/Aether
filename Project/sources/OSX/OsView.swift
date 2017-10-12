//
//  SystemView.swift
//  Alib
//
//  Created by renan jegouzo on 11/03/2016.
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
import MetalKit

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class OsView : MTKView,SystemView {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var orientation: Orientation {
        return Device.orientation
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var viewport:Viewport?
    var del:OsViewDelegate?
    let lock=Lock()
    var mTouches=[[TouchLocation]]()
    var mMouseOver=[MouseOver]()
    var mKeys=[Key]()
    var mousePos = Point.zero
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override init(frame:CGRect,device:MTLDevice?) {
        del=OsViewDelegate()
        super.init(frame:frame,device:device)
        self.delegate=del;
    }
    public required init(coder:NSCoder) {
        super.init(coder:coder)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var title : String {
        get { return self.window!.title }
        set(t) { self.window!.title=t }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override public var acceptsFirstResponder: Bool {
        return true
    }
    public func focus() {
        self.becomeFirstResponder()
    }
    public func toggleFullScreen() {
        if let w=self.window {
            w.toggleFullScreen(self)
        }
    }
    public func captureBackButton(_ capture:Bool) {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func pause() {
        self.isPaused=true
        self.enableSetNeedsDisplay=true
    }
    public func resume() {
        self.isPaused=false
        self.enableSetNeedsDisplay=false
    }
    override public func viewDidMoveToSuperview() {
        if superview==nil {
            if let vp=viewport {
                vp.detach()
                viewport = nil
            }
            Application.stop()
        } else {
            let ta = NSTrackingArea(rect:CGRect(x:CGFloat.leastNormalMagnitude,y:CGFloat.leastNormalMagnitude,width:CGFloat.greatestFiniteMagnitude,height:CGFloat.greatestFiniteMagnitude), options: [NSTrackingArea.Options.activeInKeyWindow, NSTrackingArea.Options.mouseEnteredAndExited , NSTrackingArea.Options.mouseMoved], owner: self, userInfo: nil)
            self.addTrackingArea(ta)
            self.becomeFirstResponder()
        }
    }
    override public func viewWillStartLiveResize() {
        pause()
    }
    override public func viewDidEndLiveResize() {
        resume()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func memoTouch(_ evt:NSEvent,state:TouchLocation.State) {
        let pressure:Double = ((state == .moved) || (state == .pressed)) ? 1: 0
        var p = Point(evt.locationInWindow)
        p.y = Double(self.bounds.height) - p.y
        let tloc=[TouchLocation(state:state,position:p,pressure:pressure)]
        lock.synced { 
            self.mTouches.enqueue(tloc)
        }
    }
    func memoMouseOver(_ evt:NSEvent,state:MouseOver.State,buttons:MouseOver.Button = .none) {
        var p = Point(evt.locationInWindow)
        p.y = Double(self.bounds.height) - p.y
        mousePos = p
        lock.synced { 
            self.mMouseOver.enqueue(MouseOver(state:state,position:p,delta:Point(Double(evt.deltaX),Double(evt.deltaY)),buttons:buttons))
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func mouseDown(with theEvent: NSEvent) {
        self.memoTouch(theEvent, state: .pressed)
    }
    public override func mouseDragged(with theEvent: NSEvent) {
        self.memoTouch(theEvent, state: .moved)
    }
    public override func mouseUp(with theEvent: NSEvent) {
        self.memoTouch(theEvent, state: .released)
    }
    public override func mouseMoved(with theEvent: NSEvent) {
        self.memoMouseOver(theEvent, state: .moved)
    }
    public override func mouseEntered(with theEvent: NSEvent) {
        self.memoMouseOver(theEvent, state: .entered)
    }
    public override func mouseExited(with theEvent: NSEvent) {
        self.memoMouseOver(theEvent, state: .exited)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func scrollWheel(with theEvent: NSEvent) {
        if theEvent.momentumPhase == NSEvent.Phase() {
            self.memoMouseOver(theEvent, state: .wheel)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func rightMouseDown(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved, buttons: .right)
    }
    public override func rightMouseDragged(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved, buttons: .right)
    }
    public override func rightMouseUp(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func otherMouseDown(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved, buttons: .middle)
    }
    public override func otherMouseDragged(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved, buttons: .middle)
    }
    public override func otherMouseUp(with event: NSEvent) {
        self.memoMouseOver(event, state: .moved)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override func keyDown(with theEvent: NSEvent) {
        let k=Keyboard(device:0,text:theEvent.characters!,keyCode:Int(theEvent.keyCode),pressed:true)
        lock.synced { 
            self.mKeys.enqueue(k)
        }
    }
    public override func keyUp(with theEvent: NSEvent) {
        let k=Keyboard(device:0,text:theEvent.characters!,keyCode:Int(theEvent.keyCode),pressed:false)
        lock.synced {
            self.mKeys.enqueue(k)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class OsViewDelegate : NSViewController, MTKViewDelegate {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func draw(in view: MTKView) {
        if let v=view as? OsView, let device=view.device {
            if v.viewport == nil {
                view.depthStencilPixelFormat = .depth32Float
                v.viewport=Viewport(systemView:v,device:device,size:Size(v.bounds.size))
                if let w = v.window as? OsWindow {
                    w.onStartUI.dispatch(v.viewport!)
                }
            }
            if let vp=v.viewport, let w=v.window, !w.isMiniaturized && w.isOnActiveSpace  {
                vp.size=Size(v.bounds.size)
                v.lock.synced {
                    if v.mMouseOver.count>0 {
                        while let mo=v.mMouseOver.dequeue() {
                            //Debug.info("\(mo)")
                            vp.mouse(mo)
                        }
                    } else {
                        vp.mouse(MouseOver(state: .moved, position:v.mousePos))
                    }
                    while let t=v.mTouches.dequeue() {
                        vp.touches(t)
                    }
                    while let k=v.mKeys.dequeue() {
                        vp.key(k)
                    }
                }
                vp.update()
                if let desc=v.currentRenderPassDescriptor, let drawable=v.currentDrawable {
                    vp.draw(desc,drawable:drawable,depth:v.depthStencilTexture)
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

