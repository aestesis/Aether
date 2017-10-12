//
//  SystemWindow.swift
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
import AppKit
import CloudKit

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class OsWindow : NSWindow {
    public var keepSplash = false
    public var onResize=Event<Rect>()
    public var onMove=Event<Rect>()
    public var onStartUI=Event<Viewport>()
    var del:OsWindowDelegate?
    var view:OsView?
    public var rootView : View {
        get { return view!.viewport!.rootView! }
    }
    /*
    public required init?(coder:NSCoder) {
        super.init(coder:coder)
    }
 */
    public init(frame: NSRect,title:String,splash:String?=nil) {
        Application.launches += 1
        super.init(contentRect: frame, styleMask: [.resizable,.closable,.miniaturizable,.titled,.unifiedTitleAndToolbar], backing: .buffered, defer: true)
        del=OsWindowDelegate()
        self.delegate=del
        //this.AcceptsMouseMovedEvents=true;
        self.backgroundColor=NSColor.black
        self.title=title
        self.collectionBehavior=[.fullScreenPrimary, self.collectionBehavior]
        self.view=OsView(frame:CGRect(x:frame.origin.x,y:frame.origin.y,width:frame.width,height:frame.height),device:MTLCreateSystemDefaultDevice())
        self.view!.autoresizingMask=[.width,.height]
        self.contentView=view
        if let filename=splash {
            let s=Splash(frame:CGRect(x:0,y:0,width:frame.width,height:frame.height),asset:filename)
            self.view!.addSubview(s)
            var waitSplash:(()->())? = nil
            waitSplash = {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    if !self.keepSplash {
                        NSAnimationContext.runAnimationGroup({ (ctx) in
                            ctx.duration=1
                            s.animator().alphaValue=0
                            }, completionHandler: {
                                s.removeFromSuperview()
                        })
                    } else {
                        waitSplash!()
                    }
                })
            }
            waitSplash!()
        }
    }
    override public func close() {
        super.close()
    }
    public var isFullScreen:Bool {
        return (styleMask.rawValue & NSWindow.StyleMask.fullScreen.rawValue) == NSWindow.StyleMask.fullScreen.rawValue
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class OsWindowNoViewport : NSWindow {
    public var keepSplash = false
    public var onResize=Event<Rect>()
    public var onMove=Event<Rect>()
    public var onStartUI=Event<Viewport>()
    var del:OsWindowDelegate?
    var view:OsView?
    public var rootView : View {
        get { return view!.viewport!.rootView! }
    }
    public init(frame: NSRect,title:String,splash:String?=nil) {
        Application.launches += 1
        //let style = NSWindowStyleMask.resizable.rawValue | NSWindowStyleMask.closable.rawValue | NSWindowStyleMask.miniaturizable.rawValue | NSWindowStyleMask.titled.rawValue | NSWindowStyleMask.unifiedTitleAndToolbar.rawValue
        super.init(contentRect: frame, styleMask: [.resizable,.closable,.miniaturizable,.titled,.unifiedTitleAndToolbar], backing: .buffered, defer: true)
        del=OsWindowDelegate()
        self.delegate=del
        self.appearance = NSAppearance(named:.vibrantDark)
        //self.titlebarAppearsTransparent = true
        //self.backgroundColor = Color(html:"#353535").system
        self.title=title
        self.collectionBehavior=[.fullScreenPrimary, self.collectionBehavior]
        //self.view=OsView(frame:CGRect(x:frame.origin.x,y:frame.origin.y,width:frame.width,height:frame.height),device:MTLCreateSystemDefaultDevice())
        self.contentView!.autoresizingMask=[.width,.height]
        //self.contentView=view
        if let filename=splash {
            let s=Splash(frame:CGRect(x:0,y:0,width:frame.width,height:frame.height),asset:filename)
            self.contentView!.addSubview(s)
            var waitSplash:(()->())? = nil
            waitSplash = {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    if !self.keepSplash {
                        NSAnimationContext.runAnimationGroup({ (ctx) in
                            ctx.duration=1
                            s.animator().alphaValue=0
                        }, completionHandler: {
                            s.removeFromSuperview()
                        })
                    } else {
                        waitSplash!()
                    }
                })
            }
            waitSplash!()
        }
    }
    override public func close() {
        super.close()
    }
    public var isFullScreen:Bool {
        return (styleMask.rawValue & NSWindow.StyleMask.fullScreen.rawValue) == NSWindow.StyleMask.fullScreen.rawValue
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Splash : NSView {
    var image:NSImage?
    override func draw(_ dirtyRect: NSRect) {
        if let img=image {
            let s = Double(max(self.bounds.width/img.size.width, self.bounds.height/img.size.height))
            let r = Rect(self.bounds).center.rect(Size(img.size)).scale(s)
            img.draw(in: r.system)
        } else {
            NSColor.gray.setFill()
            __NSRectFill(dirtyRect)
        }
    }
    init(frame:CGRect,asset:String) {
        super.init(frame:frame)
        image = NSImage(contentsOfFile:Application.resourcePath(asset))
    }
    required init?(coder:NSCoder) {
        super.init(coder:coder)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class OsWindowDelegate : NSObject,NSWindowDelegate {
    var minSize=CGSize(width:600,height:400)
    @objc func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    @objc func windowWillClose(_ notification: Notification) {
        Debug.info("called twice ??")
        if let w=notification.object as? OsWindow {
            if let v=w.view {
                v.removeFromSuperview()
            }
        }
    }
    @objc func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        return CGSize(width:max(frameSize.width,minSize.width),height: max(frameSize.height,minSize.height))
    }
    @objc func windowDidMove(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            w.onMove.dispatch(Rect(w.contentRect(forFrameRect: w.frame)))
        }
    }
    @objc func windowDidResize(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            w.onResize.dispatch(Rect(w.contentRect(forFrameRect: w.frame)))
        }
    }
    @objc func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions) -> NSApplication.PresentationOptions {
        return NSApplication.PresentationOptions(rawValue: proposedOptions.rawValue|NSApplication.PresentationOptions.autoHideToolbar.rawValue)
    }
    @objc func windowWillEnterFullScreen(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            if let v=w.view {
                v.pause()
            }
        }
    }
    @objc func windowDidEnterFullScreen(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            if let v=w.view {
                v.resume()
            }
        }
    }
    @objc func windowWillExitFullScreen(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            if let v=w.view {
                v.pause()
            }
        }
    }
    @objc func windowDidExitFullScreen(_ notification: Notification) {
        if let w=notification.object as? OsWindow {
            if let v=w.view {
                v.resume()
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
@objc open class OsAppDelegate : NSObject, NSApplicationDelegate {
    public let onQueryNotification=Event<CKQueryNotification>()
    public let onRecordZoneNotification=Event<CKRecordZoneNotification>()
    var callback:(OsAppDelegate)->()
    public init(_ callback:@escaping (OsAppDelegate)->()) {
        self.callback=callback;
    }
    open func applicationDidFinishLaunching(_ notification: Notification) {
        self.callback(self)
    }
    /*
    public func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
     */
    @objc public func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
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
    }
    @objc public func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Debug.warning("application.didRegisterForRemoteNotificationsWithDeviceToken",#file,#line)
    }
    @objc public func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Swift.Error) {
        Debug.warning("application.didFailToRegisterForRemoteNotificationsWithError",#file,#line)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
