//
//  SearchView.swift
//  Alib
//
//  Created by renan jegouzo on 05/10/2016.
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

public class KeyboardView : View {
    let letters = "ABCDEFGHIJKLMNOPQRSTUVXYZ"
    var bletters = [Bitmap]()
    public init(superview:View,layout:Layout,font:Font) {
        super.init(superview: superview, layout: layout)
        for i  in 0..<letters.length {
            let l = letters[i..<i+1]
            font.bitmap(text: l, { b in
                self.bletters.append(b)
            })
        }
    }
    override public func draw(to g: Graphics) {
        var x = 0.0
        let w = self.bounds.w / Double(bletters.count)
        for b in bletters {
            g.draw(rect: b.bounds.translate(x:x,y:0),image:b)
            x += w
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
