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
import CloudKit
import UserNotifications

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class OsView : MTKView,SystemView {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var viewport:Viewport?
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override init(frame:CGRect,device:MTLDevice?) {
        super.init(frame:frame,device:device)
        self.isMultipleTouchEnabled = true
        self.depthStencilPixelFormat = .depth32Float
    }
    public required init(coder:NSCoder) {
        super.init(coder:coder)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override public var canBecomeFirstResponder: Bool {
        return true
    }
    public func focus() {
        self.becomeFirstResponder()
    }
    public func toggleFullScreen() {
    }
    public func captureBackButton(_ capture:Bool) {
    }
    public var title : String {
        get { return "" }
        set { }
    }
    public var orientation : Orientation {
        get {
            return Orientation(interface: UIApplication.shared.statusBarOrientation)
        }
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
        Application.pause()
    }
    public func resume() {
        self.isPaused=false
        Application.resume()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class OsViewController : UIViewController, MTKViewDelegate {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    let lock=Lock()
    var mTouches=[[TouchLocation]]()
    var scale : Double = 1
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.view = view
    }
    public func draw(in view: MTKView) {
        if let v=view as? OsView, let device=view.device {
            if v.viewport == nil {
                let screen = UIScreen.main
                scale = Double(screen.scale)
                let size = (Size(v.bounds.size)*scale).round
                /*
                let pixsize = Size(Double(screen.nativeScale)/scale)
                Debug.warning("scale native: \(screen.nativeScale)   natural: \(screen.scale)  pixsize: \(pixsize)")
                Debug.warning("view bounds: \(v.bounds.size)   native: \(screen.nativeBounds.size)   natural: \(screen.bounds.size)  viewport: \(size)")
                */
                v.viewport=Viewport(systemView:v,device:device,size:size)
                startUI(viewport:v.viewport!)
            }
            if let vp=v.viewport {
                vp.size=(Size(v.bounds.size)*scale).round
                lock.synced {
                    while let t=self.mTouches.dequeue() {
                        vp.touches(t)
                    }
                }
                vp.update()
                if let desc=v.currentRenderPassDescriptor, let drawable=v.currentDrawable {
                    vp.draw(desc,drawable:drawable)
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    open func start() {
    }
    open func startUI(viewport:Viewport) {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func convertState(phase:UITouchPhase) -> TouchLocation.State {
        switch phase {
        case .began:
            return TouchLocation.State.pressed
        case .moved,.stationary:
            return TouchLocation.State.moved
        case .ended,.cancelled:
            return TouchLocation.State.released
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func memoTouches(touches:Set<UITouch>,event:UIEvent) {
        if let se = event.touches(for:self.view) {
            var tloc=[TouchLocation]()
            for t in se {
                let state = convertState(phase:t.phase)
                let pressure:Double = ((state == .moved) || (state == .pressed)) ? 1 : 0
                let p = Point(t.location(in:self.view))*scale
                tloc.append(TouchLocation(state:state,position:p,pressure:pressure))
            }
            lock.synced {
                self.mTouches.enqueue(tloc)
            }
        }
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        memoTouches(touches:touches,event:event!)
    }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        memoTouches(touches:touches,event:event!)
    }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        memoTouches(touches:touches,event:event!)
    }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class OsAppDelegate: UIResponder, UIApplicationDelegate {
    public let onQueryNotification=Event<CKQueryNotification>()
    public let onRecordZoneNotification=Event<CKRecordZoneNotification>()
    public var window:UIWindow?
    public private(set) var view:OsView?
    public private(set) var viewController:OsViewController?
    // @objc open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    @objc open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { granted, error in
                if let error = error {
                    Debug.error(error.localizedDescription,#file,#line)
                }
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        } else {
            application.registerForRemoteNotifications()
        }
        viewController=controller()
        window = UIWindow(frame:UIScreen.main.bounds);
        window?.autoresizesSubviews=true
        view = OsView(frame: window!.bounds, device:MTLCreateSystemDefaultDevice())
        view!.autoresizingMask=[.flexibleWidth,.flexibleHeight]
        view!.delegate=viewController
        view!.autoresizesSubviews = true
        window!.rootViewController=viewController
        window!.addSubview(view!)
        viewController!.start()
        window?.makeKeyAndVisible()
        view!.becomeFirstResponder()
        return true
    }
    @objc public func applicationWillResignActive(_ application: UIApplication) {
    }
    @objc public func applicationDidEnterBackground(_ application: UIApplication) {
        if let v=view {
            v.pause()
        }
    }
    @objc public func applicationWillEnterForeground(_ application: UIApplication) {
        if let v=view {
            v.resume()
        }
    }
    @objc public func applicationDidBecomeActive(_ application: UIApplication) {
        Application.launches += 1
    }
    @objc public func applicationWillTerminate(_ application: UIApplication) {
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
    @objc  public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
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
public class Splash : UIView {
    var image:UIImage?
    @objc override public func draw(_ rect: CGRect) {
        if let img=image {
            let s = Double(max(self.bounds.width/img.size.width,self.bounds.height/img.size.height))
            let r = Rect(self.bounds).center.rect(Size(img.size)).scale(s)
            img.draw(in:r.system)
        }
    }
    public init(frame:CGRect,asset:String) {
        super.init(frame:frame)
        image = UIImage(contentsOfFile:Application.resourcePath(asset))
    }
    @objc  required public init?(coder:NSCoder) {
        super.init(coder:coder)
    }
 
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

