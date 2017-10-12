//
//  OsView.swift
//  Alib
//
//  Created by renan jegouzo on 17/03/2016.
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
import GameController
import CloudKit
import UserNotifications

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class OsView : MTKView,SystemView {
    var viewport:Viewport?
    var mTouches=[[TouchLocation]]()
    var keys=[Key]()
    let lock=Lock()
    var padAccel=Point.zero
    var tapgest:UITapGestureRecognizer?
    override init(frame:CGRect,device:MTLDevice?) {
        super.init(frame:frame,device:device)
        let nc=NotificationCenter.default
        nc.addObserver(self, selector: #selector(controllerConnected), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        nc.addObserver(self, selector: #selector(controllerDisconnected), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
        self.becomeFirstResponder()
        self.depthStencilPixelFormat = .depth32Float
        /*
        let tapRecognizer = UITapGestureRecognizer(target:self,action:#selector(playpause_alt_version)) // pressesbegan...ended no more working for play/pause aka buttonX
        tapRecognizer.allowedPressTypes = [NSNumber(value:UIPressType.playPause.rawValue)]
        self.addGestureRecognizer(tapRecognizer)
 */
    }
    /*
    @objc public func playpause_alt_version() {
        Debug.warning("play/pause")
        self.touches(device:-1,name:.buttonX,pressed:true)
        self.touches(device:-1,name:.buttonX,pressed:false)
    }
 */
    @objc public required init(coder:NSCoder) {
        super.init(coder:coder)
    }
    func remoteUp() {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var captureBackButton = false
    public func captureBackButton(_ capture:Bool) {
        captureBackButton = capture
        //Debug.warning("capture back button: \(capture)")
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func focus() {
        self.becomeFirstResponder()
    }
    public func toggleFullScreen() {
    }
    public var title : String {
        get { return "mainscreen" }
        set { }
    }
    public var orientation : Orientation {
        get { return Device.orientation }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func start() {
        // TODO:
    }
    public func stop() {
        if let vp=viewport {
            vp.detach()
            viewport = nil
        }
    }
    public func pause() {
        self.isPaused=true
    }
    public func resume() {
        self.isPaused=false
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    /*
    func tap() {
        Debug.info("tapped")
        self.lock.synced {
            self.keys.enqueue(Keybutton(device:0,name: .buttonBack,pressed: true))
            self.keys.enqueue(Keybutton(device:0,name: .buttonBack,pressed: false))
        }
    }
 */
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    @objc public func controllerConnected() {
        scanController()
    }
    @objc public func controllerDisconnected() {
        scanController()
    }
    var startPosition = Point.zero
    var lastPosition = Point.zero
    func scanController() {
        Debug.info("scan controllers")
        var used=Set<GCControllerPlayerIndex>()
        var idx = GCControllerPlayerIndex.index1
        for c in GCController.controllers() {
            var device = 0
            Debug.info("found a controller: \(c)")
            if c.playerIndex == GCControllerPlayerIndex.indexUnset {
                while used.contains(idx) {
                    idx = GCControllerPlayerIndex(rawValue: idx.rawValue + 1)!
                }
                c.playerIndex = idx
                device = idx.rawValue
                used.insert(idx)
            } else {
                device = c.playerIndex.rawValue
                used.insert(c.playerIndex)
            }
            if let mgp=c.microGamepad {
                var mgpState = TouchLocation.State.cancelled
                mgp.reportsAbsoluteDpadValues = true
                mgp.valueChangedHandler = { (pad, element) in
                    if let dir=element as? GCControllerDirectionPad, let viewport=self.viewport {
                        let p=(Point(Double(dir.xAxis.value),Double(dir.yAxis.value))*Point(0.5,-0.5)+Point(0.5,0.5))*viewport.size
                        var t:Keypad?
                        if dir.xAxis.value == 0 && dir.yAxis.value == 0 {
                            if mgpState == TouchLocation.State.moved {
                                mgpState = .cancelled
                                t=Keypad(device:device,state:.released,position:p,swipe:self.lastPosition-self.startPosition)
                            } else {
                                // fast click ?? do nothing, we only use swipe infos
                            }
                        } else if mgpState == .cancelled {
                            mgpState = .moved
                            self.startPosition = p
                            t=Keypad(device: device, state: .pressed,position: p,swipe: Point.zero)
                        } else {
                            t=Keypad(device: device, state: .moved,position: p, swipe: p-self.startPosition)
                        }
                        if let t=t {
                            self.lock.synced {
                                self.keys.enqueue(t)
                            }
                        }
                        self.lastPosition = p
                    }
                }
                /*
                mgp.buttonX.pressedChangedHandler = { button, value, pressed in
                    Debug.warning("\(button) -> \(pressed)")
                }
                mgp.buttonA.pressedChangedHandler = { button, value, pressed in
                    Debug.warning("\(button) -> \(pressed)")
                }
                 */
            }
            if let gp=c.gamepad {
                Debug.info("gamepad found")
                gp.valueChangedHandler = { (pad, element) in
                    // TODO:
                }
            }
            if let egp=c.extendedGamepad {
                Debug.info("extended gamepad found")
                egp.valueChangedHandler = { (pad, element) in
                    // TODO:
                }
            }
            if let motion=c.motion {
                motion.valueChangedHandler = { m in
                    let g=m.gravity
                    let a=m.userAcceleration
                    let k=Keymotion(device:device,gravity:Vec3(x:g.x,y:g.y,z:g.z),acceleration:Vec3(x:a.x,y:a.y,z:a.z))
                    self.lock.synced {
                        self.keys.enqueue(k)
                    }
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func keyname(t:UIPressType) -> Keybutton.Name {
        if t == .upArrow {
            return .arrowUp
        } else if t == .downArrow {
            return .arrowDown
        } else if t == .rightArrow {
            return .arrowRight
        } else if t == .leftArrow {
            return .arrowLeft
        } else if t == .menu {
            return .buttonBack
        } else if t == .select {
            return .buttonA
        } else if t == .playPause {
            return .buttonX
        }
        return .unknown
    }
    var tickKey : Timer?
    func touches(device:Int,name:Keybutton.Name,pressed:Bool) { // TODO: fix, remote iOS send buttonA pressed before position received... :/
        self.lock.synced {
            if let viewport=self.viewport, name == .buttonA {
                let l = self.lastPosition / viewport.size - Point(0.5,0.5)
                let s = self.startPosition / viewport.size - Point(0.5,0.5)
                if abs(l.x)>0.4 && abs(s.x)>0.3 && ß.sign(s.x)==ß.sign(l.x) {
                    if l.x<0 {
                        self.keys.enqueue(Keybutton(device:device,name: .buttonLeft,pressed: pressed))
                    } else {
                        self.keys.enqueue(Keybutton(device:device,name: .buttonRight,pressed: pressed))
                    }
                } else if abs(l.y)>0.4 && abs(s.y)>0.3 && ß.sign(s.y)==ß.sign(l.y) {
                    if l.y<0 {
                        self.keys.enqueue(Keybutton(device:device,name: .buttonTop,pressed: pressed))
                    } else {
                        self.keys.enqueue(Keybutton(device:device,name: .buttonBottom,pressed: pressed))
                    }
                } else {
                    let k = Keybutton(device:device,name: .buttonA,pressed: pressed)
                    self.keys.enqueue(k)
                }
            } else  {
                let k = Keybutton(device:device,name: name,pressed: pressed)
                self.keys.enqueue(k)
            }
        }
        
    }
    @objc override public func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for p in presses {
            let kbn = keyname(t: p.type)
            Debug.warning("pressesBegan: \(kbn)")
            if kbn != .unknown {
                if kbn == .buttonBack && !captureBackButton {
                    let sp:Set<UIPress> = [ p ]
                    super.pressesBegan(sp, with: event)
                } else {
                    self.touches(device:-1,name:kbn,pressed:true)
                    if kbn.isArrow {
                        let st = ß.time
                        tickKey = Timer(period:0.1,tick:{   // repeat
                            if (ß.time-st)>0.25 {
                                self.lock.synced {
                                    self.keys.enqueue(Keybutton(device:-1,name:kbn,pressed:false))
                                    self.keys.enqueue(Keybutton(device:-1,name:kbn,pressed:true))
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    @objc override public func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for p in presses {
            let kbn = keyname(t: p.type)
            if kbn != .unknown {
                if kbn == .buttonBack && !captureBackButton {
                    let sp:Set<UIPress> = [ p ]
                    super.pressesEnded(sp, with: event)
                } else {
                    if let tickKey = tickKey {
                        tickKey.stop()
                        self.tickKey = nil
                    }
                    self.touches(device:-1,name:kbn,pressed:false)
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    @objc override public var canBecomeFirstResponder: Bool {
        return true
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class OsViewController : UIViewController, MTKViewDelegate {
    public var keepSplash = false
    public init(splash:String?=nil) {
        super.init(nibName:nil,bundle:nil)
        if let splash=splash, let v=self.view {
            let splashview = Splash(frame:view.bounds,asset:splash)
            v.addSubview(splashview)
            var waitSplash : (()->())? = nil
            waitSplash = {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                    if !self.keepSplash {
                        UIView.animate(withDuration:1, animations: {
                            splashview.alpha = 0
                            }, completion: { ok in
                                splashview.removeFromSuperview()
                        })
                    } else {
                        waitSplash?()
                    }
                })
            }
            waitSplash?()
        }
    }
    @objc public required init?(coder:NSCoder) {
        super.init(coder:coder)
    }
    @objc public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    @objc public func draw(in view: MTKView) {
        if let v=view as? OsView, let device=view.device, Application.db.loaded {
            if v.viewport == nil {
                v.viewport=Viewport(systemView:v,device:device,size:Size(v.bounds.size))
                v.lastPosition = Point(Rect(v.bounds).center)
                v.startPosition = Point(Rect(v.bounds).center)
                v.viewport?.ui {
                    self.startUI(viewport:v.viewport!)
                }
            }
            if let vp=v.viewport {
                vp.size=Size(v.bounds.size)
                v.lock.synced {
                    if self.presentedViewController != nil {
                        v.mTouches.removeAll()
                        v.keys.removeAll()
                    } else {
                        while let t=v.mTouches.dequeue() {
                            vp.touches(t)
                        }
                        while let k=v.keys.dequeue() {
                            vp.key(k)
                        }
                    }
                }
                vp.update()
                if let desc=v.currentRenderPassDescriptor, let drawable=v.currentDrawable {
                    vp.draw(desc,drawable:drawable)
                }
            }
        }
    }
    open func start() {
    }
    open func startUI(viewport:Viewport) {
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class OsAppDelegate: UIResponder, UIApplicationDelegate {
    public let onQueryNotification=Event<CKQueryNotification>()
    public let onRecordZoneNotification=Event<CKRecordZoneNotification>()
    public var window:UIWindow?
    var view:OsView?
    var viewController:OsViewController?
    @nonobjc open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Debug.info("************* OsAppDelegate.application()")
        if #available(tvOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { granted, error in
                if let error = error {
                    Debug.error(error.localizedDescription,#file,#line)
                }
                Atom.main {
                    application.registerForRemoteNotifications()
                }
            }
        } else {
            Atom.main {
                application.registerForRemoteNotifications()
            }
        }
        viewController=controller()
        window = UIWindow(frame:UIScreen.main.bounds);
        window?.autoresizesSubviews=true
        view = OsView(frame: window!.bounds, device:MTLCreateSystemDefaultDevice())
        view?.autoresizingMask=[.flexibleWidth,.flexibleHeight]
        view!.delegate=viewController
        window!.rootViewController=viewController
        window!.addSubview(view!)
        viewController!.start()
        window?.makeKeyAndVisible()
        return true
    }
    @objc public func applicationWillEnterForeground(_ application: UIApplication) {  // revive from background
        Debug.info("************* OsAppDelegate.applicationWillEnterForeground()")
        if let image = Application.live["splash"] as? UIImage, let view=view  {
            let splashview = Splash(frame:view.bounds,image:image)
            view.addSubview(splashview)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                UIView.animate(withDuration:1, animations: {
                    splashview.alpha = 0
                    }, completion: { ok in
                        splashview.removeFromSuperview()
                })
            })
        }
        if let v=view {
            v.resume()
        }
        Application.resume()
    }
    @objc public func applicationDidEnterBackground(_ application: UIApplication) {
        Debug.info("************* OsAppDelegate.applicationDidEnterBackground()")
        if let v=view {
            v.pause()
        }
        Application.pause()
    }
    @objc public func applicationDidBecomeActive(_ application: UIApplication) {
        Debug.info("************* OsAppDelegate.applicationDidBecomeActive()")
        Application.launches += 1
    }
    @objc public func applicationWillResignActive(_ application: UIApplication) {
        Debug.info("************* OsAppDelegate.applicationWillResignActive()")
    }
    @objc public func applicationWillTerminate(_ application: UIApplication) {
        Debug.info("************* OsAppDelegate.applicationWillTerminate()")
        if let v=view {
            v.stop()
        }
        Application.stop()
    }
    public override init() {
        super.init()
    }
    open func controller() -> OsViewController {
        return OsViewController()
    }
    @objc public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        Debug.warning("application.didReceiveRemoteNotification", #file, #line)
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        switch(notification.notificationType) {
        case .database:
            Debug.warning("CKDatabaseNotification", #file, #line)
            return
        case .query:
            if let not = notification as? CKQueryNotification {
                onQueryNotification.dispatch(not)
            }
        case .readNotification:
            Debug.warning("read notification", #file, #line)
            return
        case .recordZone:
            if let not = notification as? CKRecordZoneNotification {
                onRecordZoneNotification.dispatch(not)
            }
        }
        completionHandler(.newData)
    }
    @objc public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        Debug.warning("old notification", #file, #line)
    }
    @objc public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Debug.warning("application.didRegisterForRemoteNotificationsWithDeviceToken",#file,#line)
    }
    @objc public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        Debug.warning("application.didFailToRegisterForRemoteNotificationsWithError",#file,#line)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Splash : UIView {
    var image:UIImage?
    @objc override func draw(_ in: CGRect) {
        if let img=image {
            let scale = max(Double(self.bounds.width/img.size.width),Double(self.bounds.height/img.size.height))
            let r = Rect(self.bounds).center.rect(Size(img.size)).scale(scale,scale)
            img.draw(in: r.system)
        }
    }
    init(frame:CGRect,asset:String) {
        super.init(frame:frame)
        image = UIImage(contentsOfFile:Application.resourcePath(asset))
    }
    init(frame:CGRect,image:UIImage) {
        super.init(frame:frame)
        self.image = image
    }
    @objc required init?(coder:NSCoder) {
        super.init(coder:coder)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
