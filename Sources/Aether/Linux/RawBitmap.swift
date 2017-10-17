//
//  RawBitmap.swift
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

import Cpng

class RawBitmap {
    public let size:SizeI
    public let pixels:[UInt32]
    public init(width:Int,height:Int) {
        self.size = SizeI(width,height)
        self.pixels = [UInt32](repeating:0,count:size.surface)
    }
}