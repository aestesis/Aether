//
//  Device.swift
//  Aether
//
//  Created by renan jegouzo on 13/03/2016.
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

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: add ppi etc.. for iOS devices https://en.wikipedia.org/wiki/List_of_iOS_devices

public class Device {
    public static let onOrientationChanged=Event<Orientation>()
    public enum Kind {
        case undefined
        case computer
        case tablet
        case handset
        case tv
    }
    public static var kind:Kind {
        #if os(iOS)
            switch UIDevice.current.userInterfaceIdiom {
            case UIUserInterfaceIdiom.phone:
                return Kind.handset
            case UIUserInterfaceIdiom.pad:
                return Kind.tablet
            case UIUserInterfaceIdiom.tv:
                return Kind.tv
            default:
                return Kind.undefined
            }
        #elseif os(tvOS)
            return Kind.tv
        #elseif os(OSX)
            return Kind.computer
        #else
            Debug.notImplemented()
            return Kind.undefined
        #endif
    }
    public static var model:String {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.model
        #else
            Debug.notImplemented()
            return "undefined"
        #endif
    }
    public static var systemName:String {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.systemName
        #elseif os(OSX)
            return "OSX"
        #else
            Debug.notImplemented()
            return "undefined"
        #endif
    }
    public static var systemVersion:String {
        #if os(iOS) || os(tvOS)
            return UIDevice.current.systemVersion
        #elseif os(OSX)
            return "\(NSAppKitVersion.current)"
        #else
            Debug.notImplemented()
            return "undefined"
        #endif
    }
    public static var sysVersion:Double {
        #if os(iOS) || os(tvOS)
            let s = UIDevice.current.systemVersion.split(".")
            var v = 0.0
            var u = 1.0
            for k in s {
                if let i = Double(k) {
                    v += i*u
                }
                u /= 100
            }
            return v
        #elseif os(OSX)
            return Double(NSAppKitVersion.current.rawValue)
        #else
            Debug.notImplemented()
            return 0
        #endif
    }
    public static var orientation:Orientation {
        #if os(iOS)
            return Orientation(device:UIDevice.current.orientation)
        #else
            return Orientation.portraitBottom
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func initialize() {
        #if os(iOS)
        update = DeviceUpdate()
        #endif
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(iOS)
    class DeviceUpdate : NSObject {
        override init() {
            super.init()
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self,selector:#selector(orientation),name:NSNotification.Name.UIDeviceOrientationDidChange,object:nil)
        }
        @objc func orientation() {
            Device.onOrientationChanged.dispatch(Device.orientation)
        }
    }
    static var update:DeviceUpdate?
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
