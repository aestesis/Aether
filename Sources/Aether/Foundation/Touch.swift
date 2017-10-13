//
//  Touch.swift
//  Aether
//
//  Created by renan jegouzo on 21/04/2016.
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
public class TouchManager : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onPressed=Event<Point>()
    public let onReleased=Event<Point>()
    public let onClick=Event<Point>()
    public let onDblClick=Event<Point>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onVirtualMoveBegun=Event<Void>()
    public let onVirtualMoved=Event<Point>()
    public let onVirtualMoveEnded=Event<Void>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var coef:Double=0
    public var accel:Double
    public var decel = 0.9
    public var distanceCancelClick:Double
    public var distanceAcceptMove:Double
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var bounds=Rect.infinity {
        didSet {
            if !moving {
                acceptMove = true
            }
        }
    }
    public var page=Size(1,1)
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var position:Point {
        get { return pos }
        set(p) {
            let d = snapping(point:p) - pos
            pos += d
            apos += d
            mpos += d
            if pressed {
                onVirtualMoved.dispatch(pos)
            } else {
                vAccel=Point.zero
                iAccel=Point.zero
                onVirtualMoveBegun.dispatch(())
                onVirtualMoved.dispatch(pos)
                onVirtualMoveEnded.dispatch(())
            }
        }
    }
    public var unsnappedPosition:Point {
        get { return pos }
        set(p) {
            let d = p-pos
            pos += d
            apos += d
            mpos += d
            if pressed {
                onVirtualMoved.dispatch(pos)
            } else {
                onVirtualMoveBegun.dispatch(())
                onVirtualMoved.dispatch(pos)
                onVirtualMoveEnded.dispatch(())
            }
        }
    }
    func cancelAnimations() {
        if anims.count>0 {
            for a in anims {
                a.cancel()
            }
            anims.removeAll()
        }
    }
    public func animateTo(position p:Point) {
        fpos = snapping(point:p)
        forced = true
        moving = true
        cancelAnimations()
    }
    func snapping(point p0:Point) -> Point {
        var p = bounds.constrains(point: p0)
        if magnet.width != 0 {
            let e0 = round(p.x/magnet.w) * magnet.w + magnetOffset.x
            p.x = bounds.constrains(point:Point(e0,0)).x
        }
        if magnet.height != 0 {
            let e0 = round(p.y/magnet.h) * magnet.h + magnetOffset.y
            p.y = bounds.constrains(point:Point(0,e0)).y
        }
        if let magnets = magnetsH, magnets.count>0 {
            var dm = Double.greatestFiniteMagnitude
            var xr = p.x
            for x in magnets {
                let d = abs(x-p.x)
                if d<dm {
                    dm = d
                    xr = x
                }
            }
            p.x = bounds.constrains(point:Point(xr,0)).x
        }
        if let magnets = magnetsV, magnets.count>0 {
            var dm = Double.greatestFiniteMagnitude
            var yr = p.x
            for y in magnets {
                let d = abs(y-p.y)
                if d<dm {
                    dm = d
                    yr = y
                }
            }
            p.y = bounds.constrains(point:Point(0,yr)).y
        }
        return p
    }
    public var magnetOffset = Point.zero {
        didSet(o) {
            pos += magnetOffset - o
            apos = pos
        }
    }
    public var magnet:Size {
        get { return _magnet }
        set(m) {
            if _magnet != m {
                var dispatch=false
                if _magnet.w != 0 && m.w != 0 {
                    pos.x = round((pos.x - magnetOffset.x) / _magnet.w) * m.w + magnetOffset.x
                    pos.x = bounds.constrains(point: pos).x
                    apos.x = pos.x
                    dispatch = true
                } else if m.w != 0 {
                    pos.x = round((pos.x - magnetOffset.x) / m.w) * m.w + magnetOffset.x
                    pos.x = bounds.constrains(point: pos).x
                    apos.x = pos.x
                    dispatch = true
                }
                if _magnet.h != 0 && m.h != 0 {
                    pos.y = round((pos.y - magnetOffset.y) / _magnet.h) * m.h + magnetOffset.y
                    pos.y = bounds.constrains(point: pos).y
                    apos.y = pos.y
                    dispatch = true
                } else if m.h != 0 {
                    pos.y = round((pos.y - magnetOffset.y) / m.h) * m.h + magnetOffset.y
                    pos.y = bounds.constrains(point: pos).y
                    apos.y = pos.y
                    dispatch = true
                }
                _magnet = m
                if dispatch {
                    onVirtualMoveBegun.dispatch(())
                    onVirtualMoved.dispatch(pos)
                    onVirtualMoveEnded.dispatch(())
                }
            }
        }
    }
    public var magnetsH:[Double]?
    public var magnetsV:[Double]?
    public func reset(_ position:Point) {
        self.position = position
        fpos = position
        forced = true
        moving = true
    }
    public func reset() {
        let m = moving
        pos = Point.zero
        apos = Point.zero
        mpos = Point.zero
        moving = false
        acceptMove = false
        pressed = false
        if let c=click  {
            c.cancel()
            click=nil
        }
        if let n=nomove {
            n.cancel()
            nomove=nil
        }
        if m {
            onVirtualMoveEnded.dispatch(())
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var view:View {
        return parent as! View
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var viewPos=Point.zero
    var mtouch=Point.zero
    var ltouch=Point.zero
    var mpos=Point.zero
    var pos=Point.zero
    var apos=Point.zero
    public private(set) var pressed=false
    var click:Future?
    var nomove:Future?
    var iAccel=Point.zero
    var vAccel=Point.zero
    var moving=false
    var acceptMove=false
    var forced=false
    var fpos=Point.zero
    var _magnet:Size=Size.zero
    var anims=Set<Future>()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func pulse() {
        let iCoef = 1 - coef
        var outBounds = false
        
        iAccel = iAccel * 0.5
        vAccel = vAccel * decel
        pos = pos + vAccel
        
        if !pressed {
            if forced {
                pos = pos.lerp(fpos,coef:0.5)
                if vAccel.length < 0.1 {
                    vAccel = Point.zero
                    if (pos-fpos).length < 0.5 {
                        pos = fpos
                        forced = false
                    }
                } else {
                    vAccel = vAccel * 0.5
                }
            }
            if bounds != Rect.infinity {
                if pos.x < bounds.left {
                    pos.x = bounds.left * 0.5 + pos.x * 0.5
                    if abs(bounds.left-pos.x)<0.2 {
                        pos.x = bounds.left
                        vAccel.x = 0
                    } else {
                        outBounds = true
                    }
                } else if pos.x > bounds.right {
                    pos.x = bounds.right * 0.5 + pos.x * 0.5
                    if abs(bounds.right - pos.x) < 0.2 {
                        pos.x = bounds.right
                        vAccel.x = 0
                    } else {
                        outBounds = true
                    }
                }
                if pos.y < bounds.top {
                    pos.y = pos.y * 0.5 + bounds.top * 0.5
                    if abs(bounds.top - pos.y) < 0.2 {
                        pos.y = bounds.top
                        vAccel.y = 0
                    } else {
                        outBounds = true
                    }
                } else if pos.y > bounds.bottom {
                    pos.y = pos.y * 0.5 + bounds.bottom * 0.5
                    if abs(bounds.bottom - pos.y) < 0.2 {
                        pos.y = bounds.bottom
                        vAccel.y = 0
                    } else {
                        outBounds = true
                    }
                }
            }
        }
        if moving {
            apos = pos * coef + apos * iCoef
        }
        if (pos-apos).length>0.2 || outBounds {
            if !moving && acceptMove {
                moving = true
                onVirtualMoveBegun.dispatch(())
                //Debug.warning("start virtual moving: \(view.className) pos:\(pos)  apos:\(apos)")
            }
            if moving {
                onVirtualMoved.dispatch(apos)
                //Debug.warning("virtual moving: \(view.className) pos:\(pos)  apos:\(apos)")
            }
        } else if moving && !pressed && anims.count == 0 {
            apos = pos
            onVirtualMoved.dispatch(apos)
            moving = false
            onVirtualMoveEnded.dispatch(())
            //Debug.warning("end virtual moving: \(view.className) pos:\(pos)  apos:\(apos)")
        }
    }
    func addAnim(_ a:Future) {
        anims.insert(a)
        let _ = a.then { (fut) in
            if self.anims.contains(a) {
                self.anims.remove(a)
            }
        }
    }
    public func touches(_ touches:[TouchLocation]) -> Bool {
        let t=touches[0]
        //Debug.info("view:\(self.view.className) touches: \(t.state)  \(t.position)")
        switch t.state {
        case .pressed:
            onPressed.dispatch(t.position)
            viewPos = view.position
            pressed =  true
            ltouch = t.position
            mtouch = t.position
            mpos = pos
            if let c=click {
                Debug.info("will cancel click")
                c.cancel()
                click = nil
                if onDblClick.count>0 {
                    Debug.info("## \(self.view.className) ## dispatch dblclick (cancel click)")
                    onDblClick.dispatch(t.position)
                }
            } else if onClick.count>0 { // TODO: better case selection than that!!
                click = self.wait(0.8) { 
                    self.click = nil
                    if !self.pressed {
                        if (self.pos-self.mpos).length <= self.distanceCancelClick {
                            Debug.info("## \(self.view.className) ## dispatch click, pos:\(self.pos)")
                            self.onClick.dispatch(t.position)
                        } else {
                            Debug.info("## \(self.view.className) ## cancel click, pos:\(self.pos)")
                        }
                    } else {
                        Debug.info("## \(self.view.className) ## no dispatch click")
                    }
                }
                click!.onCancel { fut in
                    self.click = nil
                    Debug.info("## \(self.view.className) ## cancel click")
                }
                Debug.info("## \(self.view.className) ## create click, pos:\(pos)")
            }
            iAccel = Point.zero
            vAccel = Point.zero
            acceptMove = false
            //Debug.warning("touch pressed, view:\(self.view.className) pos:\(pos) apos:\(apos) touch:\(t.position)")
            break
        case .moved:
            let touch = t.position + view.position - viewPos
            if pressed && !acceptMove && (touch-mtouch).length > distanceAcceptMove {
                acceptMove = true
            }
            if acceptMove {
                pos = (touch-mtouch)+mpos
                //Debug.warning("touch moved, view:\(self.view.className) delta:\(pos-mpos)")
                iAccel = iAccel * 0.5 + (touch-ltouch) * 0.5
            }
            if let c=click, (touch-mtouch).length > distanceCancelClick {
                Debug.info("will cancel click")
                c.cancel()
            }
            ltouch = touch
            if let nm = nomove {
                nm.cancel()
            }
            nomove = wait(0.1) {
                self.nomove = nil
                self.iAccel = Point.zero
            }
            break
        case .released,.cancelled:
            let touch = t.position + view.position - viewPos
            if let nm=nomove {
                nm.cancel()
                nomove = nil
            }
            if pressed && !acceptMove && (touch-mtouch).length > distanceAcceptMove {
                acceptMove = true
            }
            if acceptMove {
                pos = (touch-mtouch)+mpos
                iAccel = iAccel * 0.5 + (touch-ltouch) * 0.5
                let mAccel = vAccel
                vAccel = iAccel*accel
                //Debug.warning("vAccel: \(vAccel)")
                var pm = pos
                if magnet.width != 0 {
                    if abs(vAccel.x)>0.5 && ß.sign(pos.x-mpos.x)==ß.sign(vAccel.x) && abs(vAccel.x) > abs(vAccel.y) {
                        let e0 = round(((mpos.x-magnetOffset.x)/magnet.w)+ß.sign(vAccel.x)*page.w) * magnet.w + magnetOffset.x
                        pm.x = bounds.constrains(point:Point(e0,0)).x
                    } else {
                        let e0 = round((pos.x-magnetOffset.x)/magnet.w)*magnet.w+magnetOffset.x
                        pm.x = bounds.constrains(point:Point(e0,0)).x
                    }
                }
                if magnet.height != 0 {
                    if abs(vAccel.y)>0.5 && ß.sign(pos.y-mpos.y)==ß.sign(vAccel.y) && abs(vAccel.y)>abs(vAccel.x) {
                        let e0 = round(((mpos.y-magnetOffset.y)/magnet.h)+ß.sign(vAccel.y)*page.h) * magnet.h + magnetOffset.y
                        pm.y = bounds.constrains(point:Point(0,e0)).y
                    } else {
                        let e0 = round((pos.y-magnetOffset.y)/magnet.h)*magnet.h+magnetOffset.y
                        pm.y = bounds.constrains(point:Point(0,e0)).y
                    }
                }
                if let magnets = magnetsH, magnets.count>0 {
                    if abs(vAccel.x)>0.5 && ß.sign(pos.x-mpos.x)==ß.sign(vAccel.x) && abs(vAccel.x) > abs(vAccel.y) {
                        if vAccel.x>0 {
                            pm.x = next(magnets:magnets,position:mpos.x)
                        } else   {
                            pm.x = previous(magnets:magnets,position:mpos.x)
                        }
                    }
                    pm=self.snapping(point:pm)
                }
                if let magnets = magnetsV, magnets.count>0 {
                    if abs(vAccel.y)>0.5 && ß.sign(pos.y-mpos.y)==ß.sign(vAccel.y) && abs(vAccel.y) > abs(vAccel.x) {
                        if vAccel.y>0 {
                            pm.y = next(magnets:magnets,position:mpos.y)
                        } else   {
                            pm.y = previous(magnets:magnets,position:mpos.y)
                        }
                    }
                    pm=self.snapping(point:pm)
                }
                if pm != pos {
                    addAnim(self.animate(0.2, { t in
                        let a=Signal(t).sin.value
                        self.pos = self.pos.lerp(pm,coef:a)
                    }))
                    vAccel = .zero
                }
                onReleased.dispatch(mAccel)
            } else {
                onReleased.dispatch(Point.zero)
            }
            pressed = false
            acceptMove = false
            if let c=click {
                if t.state == .released {
                    if (touch-mtouch).length <= self.distanceCancelClick {
                        if onDblClick.count == 0 {
                            c.done()
                        }
                    } else {
                        Debug.info("will cancel click, distance: \((touch-mtouch).length)")
                        c.cancel()
                    }
                } else {
                    Debug.info("will cancel click")
                    c.cancel()
                }
            }
            break
        }
        return true
    }
    func next(magnets:[Double],position:Double) -> Double {
        var dm = Double.greatestFiniteMagnitude
        var xr = position
        for x in magnets {
            if x>position && abs(x-position)<dm {
                dm = abs(x-position)
                xr = x
            }
        }
        return xr
    }
    func previous(magnets:[Double],position:Double) -> Double {
        var dm = Double.greatestFiniteMagnitude
        var xr = position
        for x in magnets {
            if x<position && abs(x-position)<dm {
                dm = abs(x-position)
                xr = x
            }
        }
        return xr
    }
    public func swipe(state:TouchLocation.State,swipe p:Point) {
        //Debug.info("swipe: \(state)   \(p)")
        switch state {
        case .pressed:
            mpos = pos
            self.cancelAnimations()
            acceptMove = true
            break
        case .moved:
            if acceptMove {
                pos = mpos + p
                if magnet.width != 0 {
                    pos.x = round((pos.x-magnetOffset.x)/magnet.w)*magnet.w+magnetOffset.x
                }
                if magnet.height != 0 {
                    pos.y = round((pos.y-magnetOffset.x)/magnet.h)*magnet.h+magnetOffset.y
                }
                pos = bounds.constrains(point: pos)
                //Debug.info("pos: \(pos)")
                iAccel = iAccel * 0.5 + p * 0.5
            }
            break
        case .released,.cancelled:
            if acceptMove && mpos == pos && (magnet.width != 0 || magnet.height != 0) {
                let start = pos
                var stop = mpos + p
                let d = stop - start
                if magnet.width != 0 {
                    //Debug.warning("delta: \(abs(d)/magnet.w)")
                    if abs(d.x)>(0.05*magnet.w) && abs(d.x)>abs(d.y) {
                        stop.x = round(((start.x-magnetOffset.x)+ß.sign(d.x)*magnet.w)/magnet.w)*magnet.w+magnetOffset.x
                    } else {
                        stop.x = start.x
                    }
                }
                if magnet.height != 0 {
                    //Debug.warning("delta: \(abs(d)/magnet.h)")
                    if abs(d.y)>(0.05*magnet.h) && abs(d.y)>abs(d.x) {
                        stop.y = round(((start.y-magnetOffset.y)+ß.sign(d.y)*magnet.h)/magnet.h)*magnet.h+magnetOffset.y
                    } else {
                        stop.y = start.y
                    }
                }
                stop = bounds.constrains(point: stop)
                if start != stop {
                    addAnim(self.animate(0.15, { t in
                        self.pos = start.lerp(stop,coef:t)
                    }))
                } else {
                    acceptMove = false
                }
            } else {
                acceptMove = false
            }
            break
        }
    }
    public func magnetSwipe(_ p:Point) -> Bool {
        var needsCancel=(anims.count > 0)
        let check:()->()={
            if needsCancel {
                self.cancelAnimations()
                needsCancel=false
            }
        }
        if magnet.w>0 && abs(p.x)>0 {
            let oe = (round(((pos.x-magnetOffset.x)/magnet.w)+ß.sign(p.x)*page.w)*magnet.w)+magnetOffset.x
            let e = bounds.constrains(point:Point(oe,0)).x
            if e != pos.x {
                check()
                addAnim(self.animate(0.2, { t in
                    let a=Signal(t).sin.value
                    self.pos.x = self.pos.x * (1-a) + e*a
                }))
                vAccel.x = 0
                acceptMove=true
                return true
            } else if oe != e { // border bounce
                check()
                addAnim(self.animate(0.2, { t in
                    let a=Signal(t).sin.value
                    self.pos.x = self.pos.x * (1-a) + oe*a
                }))
                vAccel.x = 0
                acceptMove=true
                return true
            }
        }
        if magnet.h>0 && abs(p.y)>0 {
            let oe = (round(((pos.y-magnetOffset.y)/magnet.h)+ß.sign(p.y)*page.h)*magnet.h)+magnetOffset.y
            let e = bounds.constrains(point:Point(0,oe)).y
            if e != pos.y {
                check()
                addAnim(self.animate(0.2, { t in
                    let a=Signal(t).sin.value
                    self.pos.y = self.pos.y * (1-a) + e*a
                }))
                vAccel.y = 0
                acceptMove=true
                return true
            } else if oe != e { // border bounce
                check()
                addAnim(self.animate(0.2, { t in
                    let a=Signal(t).sin.value
                    self.pos.y = self.pos.y * (1-a) + oe*a
                }))
                vAccel.y = 0
                acceptMove=true
                return true
            }
        }
        return false
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(view:View,coef:Double?=nil,accel:Double=1,distanceCancelClick:Double?=nil,distanceAcceptMove:Double=0) {
        self.accel=accel
        self.distanceAcceptMove=distanceAcceptMove
        if let d=distanceCancelClick {
            self.distanceCancelClick=d
        } else {
            #if os(iOS)
                self.distanceCancelClick = 32   // TODO: calculate it from screen DPI and pixels size (size of a finger)
            #else
                self.distanceCancelClick = 16
            #endif
        }
        super.init(parent: view)
        #if os(tvOS)
            self.coef = coef ?? 0.2
        #elseif os(iOS)
            self.coef = coef ?? 0.45
        #else
            self.coef = coef ?? 0.5
        #endif
        viewport!.pulse.alive(self, {
            self.pulse()
        })
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public protocol Key {
    var device:Int { get }
}
public struct Keyboard : Key {
    public var device:Int
    public var text:String
    public var keyCode:Int
    public var pressed:Bool
}
public struct Keybutton : Key {
    public var device:Int
    public enum Name {
        case unknown
        case buttonA
        case buttonX
        case buttonTop
        case buttonBottom
        case buttonLeft
        case buttonRight
        case buttonBack
        case arrowUp
        case arrowDown
        case arrowLeft
        case arrowRight
        public var isArrow : Bool {
            return (self == .arrowUp) || (self == .arrowDown) || (self == .arrowLeft) || (self == .arrowRight)
        }
        public func nearEqual(_ b:Name) -> Bool {
            let a = self
            if a == b {
                return true
            } else if (a == .buttonA || a == .buttonTop || a == .buttonBottom || a == .buttonLeft || a == .buttonRight) && (b == .buttonA || b == .buttonTop || b == .buttonBottom || b == .buttonLeft || b == .buttonRight) {
                return true
            }
            return false
        }
    }
    public var name:Name
    public var pressed:Bool
}
public struct Keypad : Key {
    public var device:Int
    public var state:TouchLocation.State
    public var position:Point
    public var swipe:Point
    public init(device:Int,state:TouchLocation.State,position:Point,swipe:Point) {
        self.device = device
        self.state = state
        self.position = position
        self.swipe = swipe
    }
}
public struct Keymotion : Key {
    public var device:Int
    public var gravity:Vec3
    public var acceleration:Vec3    // gravity substracted (relative accel)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct MouseOver : CustomStringConvertible {
    public enum Button : Int {
        case none = 0
        case left = 1
        case right = 2
        case middle = 4
    }
    public enum State {
        case invalid
        case entered
        case moved
        case wheel
        case exited
    }
    public var state:State
    public var buttons : Button
    public var position:Point
    public var delta:Point
    init(state:State=State.invalid,position:Point=Point.zero,delta:Point=Point.zero,buttons:Button = .none) {
        self.state=state
        self.position=position
        self.delta=delta
        self.buttons = buttons
    }
    public var description : String {
        return "s:\(state) p:\(position) d:\(delta) b:\(buttons)"
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct TouchLocation {
    public enum State {
        case cancelled
        case moved
        case pressed
        case released
    }
    public var state:State
    public var position:Point
    public var pressure:Double
    public init(state:State=State.cancelled,position:Point=Point.zero,pressure:Double=0) {
        self.state=state
        self.position=position
        self.pressure=pressure
    }
    static func transform(touches:[TouchLocation],matrix:Mat4) -> [TouchLocation] {
        let m = matrix.inverted
        var tr = [TouchLocation]()
        for t in touches {
            let v=m.transform(Vec3(t.position))
            tr.append(TouchLocation(state:t.state,position:Point(v.x,v.y),pressure:t.pressure))
        }
        return tr
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public enum Swipe : Int
{
    case none = 0
    case horizontal = 2
    case vertical = 1
    case both = 3
    case cancel = 4
    public func match(swipe:Swipe) -> Bool {
        if self == .both {
            return swipe == .both || swipe == .horizontal || swipe == .vertical
        } else if swipe == .both {
            return self == .both || self == .horizontal || self == .vertical
        }
        return self == swipe
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
