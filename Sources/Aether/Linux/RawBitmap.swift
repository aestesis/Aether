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
import Foundation

class RawBitmap : Atom {
    public let onLoaded = Event<Void>()
    public let onError = Event<Error>()
    public private(set) var size:SizeI
    public private(set) var pixels:[UInt32]
    public init(width:Int,height:Int) {
        self.size = SizeI(width,height)
        self.pixels = [UInt32](repeating:0,count:size.surface)
        super.init()
    }
    public init(path:String) {
        let p=Application.resourcePath(path)
        self.size = SizeI.zero
        self.pixels = [UInt32]()
        super.init()
        if FileManager.default.fileExists(atPath:p) {
            let f=FileReader(filename:p)
            let r=BufferedStream()
            r.onClose.once {
                self.readPNG(r)
            }
            r.onError.once { err in
                self.onError.dispatch(err)
            }
            f.pipe(to:r)
        } else {
            _ = self.wait(0.001) {
                self.onError.dispatch(Error("File not found: \(p)"))
            }
        }
    }
    func readPNG(_ stream:BufferedStream) {
        var r = stream
        let png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        let info = png_create_info_struct(png)
        png_set_read_fn(png, &r, { png, ptr, needed in
            let s = UnsafeRawPointer(png_get_io_ptr(png)).assumingMemoryBound(to:UTF8Reader.self)[0]
            if let data = s.read(needed) {
                memcpy(ptr!, data, data.count)
            }
        })
        png_read_info(png, info)
        var w: png_uint_32 = 0, h: png_uint_32 = 0, bitDepth: Int32 = 0, colorType: Int32 = -1
        png_get_IHDR(png, info, &w, &h, &bitDepth, &colorType, nil, nil, nil)
        self.size = SizeI(Int(w),Int(h))
        self.pixels = [UInt32](repeating:0,count:self.size.surface)
        let rowSize = png_get_rowbytes (png, info)
        var row = [UInt8](repeating:0,count:rowSize)
        var d = 0
        switch colorType {
            case PNG_COLOR_TYPE_RGB:
                for y in 0..<size.height {
                    png_read_row(png, &row, nil)
                    var s = 0
                    for x in 0..<size.width {
                        var c : UInt32 = 255
                        c |= UInt32(row[s]) << 8        // blue
                        s += 1
                        c |= UInt32(row[s]) << 16       // green
                        s += 1
                        c |= UInt32(row[s]) << 24       // red
                        s += 1
                        self.pixels[d] = c
                        d += 1
                    }
                }
            case PNG_COLOR_TYPE_RGBA:
                for y in 0..<size.height {
                    png_read_row(png, &row, nil)
                    var s = 0
                    for x in 0..<size.width {
                        var c : UInt32 = 0
                        c |= UInt32(row[s]) << 8        // blue
                        s += 1
                        c |= UInt32(row[s]) << 16       // green
                        s += 1
                        c |= UInt32(row[s]) << 24       // red
                        s += 1
                        c |= UInt32(row[s])             // alpha
                        s += 1
                        self.pixels[d] = c
                        d += 1
                    }
                }
            case PNG_COLOR_TYPE_GRAY:
                for y in 0..<size.height {
                    png_read_row(png, &row, nil)
                    var s = 0
                    for x in 0..<size.width {
                        let l = row[s]
                        s += 1
                        var c : UInt32 = 255
                        c |= UInt32(l) << 8
                        c |= UInt32(l) << 16
                        c |= UInt32(l) << 24
                        self.pixels[d] = c
                        d += 1
                    }
                }
            default:
            self.onError.dispatch(Error("color format not implemented"))
            return
        }
        self.onLoaded.dispatch(())
    }
}