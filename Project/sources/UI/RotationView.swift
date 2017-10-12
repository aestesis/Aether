//
//  RotationView.swift
//  Alib
//
//  Created by renan jegouzo on 10/12/2016.
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
public class RotationView : View {
    enum Mode {
        case rotation
        case orientation
        case device
    }
    var mode:Mode
    var rotation:Rotation = .none
    var realRot:Rotation = .none
    var _orientation:Orientation = .undefined
    public override var orientation: Orientation {
        if let superview=superview {
            return superview.orientation.rotate(realRot)
        }
        return Orientation.undefined
    }
    public init(superview:View,rotation:Rotation) {
        self.mode = .rotation
        self.rotation = rotation
        super.init(superview:superview,layout:Layout(align:.fullCenter))
        initialize()
    }
    public init(superview:View,orientation:Orientation) {
        self.mode = .orientation
        self._orientation = orientation
        super.init(superview:superview,layout:Layout(align:.fullCenter))
        initialize()
    }
    public init(superview:View) {
        mode = .device
        super.init(superview:superview,layout:Layout(align:.fullCenter))
        initialize()
    }
    func initialize() {
        var mo = Orientation.undefined
        viewport?.pulse.alive(self) {
            if self.superview!.orientation != mo {
                mo = self.superview!.orientation
                self.updateRot()
            }
        }
        superview?.onResize.alive(self) { sz in
            mo = self.superview!.orientation
            self.updateRot()
        }
        self.onResize.alive(self) { sz in
            Debug.warning("RotationView resize:\(sz)")
        }
        Device.onOrientationChanged.alive(self) { o in
            if self.mode == .device {
                self.ui {
                    self.updateRot()
                }
            }
        }
        self.updateRot();
    }
    func updateRot() {
        var rot = Rotation.none
        switch mode {
        case .rotation:
            rot = rotation
        case .orientation:
            rot = superview!.orientation.rotation(to: _orientation)
        case .device:
            rot = superview!.orientation.rotation(to: Device.orientation)
        }
        self.transform.rotation = Vec3(z:rot.angle)
        self.size = rot.rotate(superview!.size)
        self.realRot = rot
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
