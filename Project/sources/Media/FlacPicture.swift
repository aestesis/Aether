//
//  FlacPicture.swift
//  Alib
//
//  Created by renan jegouzo on 16/07/2016.
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

// format: https://xiph.org/flac/format.html#metadata_block_picture

public class FlacPicture : NodeUI {
    public static func get(parent:NodeUI, base64 b64:String) -> Bitmap? {
        var base64 = b64
        let n = base64.length & 3
        if n != 0 {
            base64 += "===="[n...3]
        }
        if let data = Data(base64Encoded: base64) {
            let s = DataReader(data: data)
            let r = UTF8Reader(bigEndian: true)
            s.pipe(to: r)
            let type = PictureType(rawValue: r.readUInt32()!)!
            let ml = r.readUInt32()!
            let mt = r.read(Int(ml))!
            let mime = String(bytes: mt, encoding: .ascii)!
            let dl = r.readUInt32()!
            var desc = ""
            if dl>0 {
                let dt = r.read(Int(dl))!
                desc = String(bytes: dt, encoding: .ascii)!
            }
            let _ = Int(r.readUInt32()!)    // width or 0
            let _ = Int(r.readUInt32()!)    // height or 0
            let depth = r.readUInt32()!
            let cidx = r.readUInt32()!
            let pictsize = r.readUInt32()!
            let d = r.read(Int(pictsize))!
            let b = Bitmap(parent: parent, data: d)
            b["mime"] = mime
            b["description"] = desc
            b["depth"] = depth
            b["idx"] = cidx
            b["type"] = type
            return Bitmap(parent: parent, data: d)
        } else {
            Debug.error("not a base64 string",#file,#line)
        }
        return nil
    }
    public enum PictureType : UInt32
    {
        case other = 0
        case pngIcon = 1
        case otherIcon = 2
        case coverFront = 3
        case coverBack = 4
        case leaflet = 5
        case media = 6
        case leadArtist = 7
        case artist = 8
        case conductor = 9
        case band = 10
        case composer = 11
        case lyricist = 12
        case recordingLocation = 13
        case recording = 14
        case performance = 15
        case screenCapture = 16
        case fish = 17
        case illustration = 18
        case logo = 19
        case publisher = 20
    }
}

