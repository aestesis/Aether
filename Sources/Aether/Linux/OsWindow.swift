//
//  OsWindow.swift
//  Aether
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

#if os(Linux)
import Uridium

public class OsWindow : Window,SystemView {
    public let onStartUI = Event<Viewport>()
    public let onMove = Event<Rect>()
    public let onResize = Event<Rect>()
    public var viewport:Viewport?
    public var orientation : Orientation {
        return Orientation.portraitBottom
    }
    public override var title:String {
        get {
            return super.title
        }
        set(t) {
            super.title = t
        }
    }
    public func focus() {
        // TODO:
    }
    public func toggleFullScreen() {
        // TODO:
    }
    public func captureBackButton(_ capture:Bool) {
    }
    public override func render() {
        if viewport == nil {
            viewport = Viewport(systemView:self,tin:engine!,size:Size(Double(width),Double(height)))
            self.onStartUI.dispatch(viewport!)
        }
        if let vp=viewport {
            let size = Size(Double(width),Double(height))
            vp.size = size
            // TODO: mouse/keyboard
            vp.update()
            vp.draw()
        }
    }
    public override init?(title:String,width:Int,height:Int) {
        super.init(title:title,width:width,height:height)
    }
}

#endif