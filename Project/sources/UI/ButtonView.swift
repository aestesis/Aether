//
//  ButtonView.swift
//  Alib
//
//  Created by renan jegouzo on 08/02/2017.
//  Copyright © 2017 aestesis. All rights reserved.
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

public class ButtonView : View {
    public enum Kind {
        case square
        case rectangle
    }
    public private(set) var label:TextView?
    public private(set) var image:ImageView?
    var scale = Size(1,1)
    let animated:Bool
    public init(superview:View,layout:Layout,label:String?=nil,labelColor:Color=Color.white,image:String,kind:Kind = .square,animated:Bool=true) {
        self.animated = animated
        super.init(superview:superview,layout:layout)
        switch kind {
        case .square:
            if let label = label {
                self.grid.size = SizeI(1,3)
                self.image = ImageView(superview:self,layout:Layout(placement:Rect(0,0,1,2),align:.fill),image:image,aspect:.fit,blend:.alpha)
                self.label = TextView(superview:self,layout:Layout(placement:Rect(0,2,1,1),align:.fill),text:label,align:.fullCenter,fontSize:0.5)
            } else {
                self.image = ImageView(superview:self,layout:Layout(placement:Rect(0,0,1,1),align:.fill),image:image,aspect:.fit,blend:.alpha)
            }
        case .rectangle:
            self.grid.size = SizeI(5,1)
            self.image = ImageView(superview:self,layout:Layout(placement:Rect(0,0,1,1),align:.fill),image:image,aspect:.fit,blend:.alpha)
            if let label = label {
                self.label = TextView(superview:self,layout:Layout(placement:Rect(1,0,4,1),align:.fill),text:label,align:.centerLeft,fontSize:0.7)
            } else {
                self.label = TextView(superview:self,layout:Layout(placement:Rect(1,0,4,1),align:.fill),text:"",align:.centerLeft,fontSize:0.7)
            }
        }
        self.label?.color = labelColor
        if animated {
            viewport!.pulse.alive(self) {
                self.transform.scale = self.transform.scale.lerp(self.scale,coef:0.1)
            }
            self.touch.onPressed.alive(self) {_ in
                //Debug.warning("@@@@@@@@@@@@@@@@@@@@@ pressed")
                self.scale = Size(1.1,1.1)
            }
            self.touch.onReleased.alive(self) {_ in
                //Debug.warning("@@@@@@@@@@@@@@@@@@@@@ released")
                if Device.kind == .computer {
                    self.scale = Size(1.05,1.05)
                } else {
                    self.scale = Size(1.0,1.0)
                }
            }
        }
    }
    override public func mouse(_ mo:MouseOver) {
        switch mo.state {
        case .entered:
            self.scale = Size(1.05,1.05)
        case .exited:
            self.scale = Size(1,1)
        default:
            break
        }
        super.mouse(mo)
    }
    
}
