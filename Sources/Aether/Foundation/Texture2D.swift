//
//  Texture2D.swift
//  Aether
//
//  Created by renan jegouzo on 01/03/2016.
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

#if os(OSX)
    import Metal
    import CoreGraphics
    import AppKit
#elseif os(iOS) || os(tvOS)
    import Metal
    import CoreGraphics
    import UIKit
#else
#endif


// camera: http://stackoverflow.com/questions/37445052/how-to-create-a-mtltexture-backed-by-a-cvpixelbuffer

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
open class Texture2D : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum Format {
        case alphaOnly
        case rgba
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
    public private(set) var texture:MTLTexture?
    #else
    public private(set) var texture:Tin.Texture?
    #endif
    public private(set) var pixels:Size=Size.zero
    public private(set) var pixel:Size=Size.unity
    public private(set) var border:Size=Size.zero
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var ready:Bool {
        return texture != nil
    }
    public var display:Size {
        return Size((pixels.width-border.width*2)*pixel.width,(pixels.height-border.height)*pixel.height)
    }
    public var scale:Size {
        get { return Size.unity/pixel }
        set(s) { pixel=Size.unity/s }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if os(macOS) || os(iOS) || os(tvOS)
    internal func initialize(from cg:CGImage) {
        let pixfmt = MTLPixelFormat.rgba8Unorm // (cg.colorSpace?.model == .rgb) ? MTLPixelFormat.rgba8Unorm : MTLPixelFormat.a8Unorm
        self.pixels = Size(Double(cg.width),Double(cg.height))
        let d=MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixfmt, width: cg.width, height: cg.height, mipmapped: false)
        self.texture=viewport!.gpu.device?.makeTexture(descriptor:d)
        let isize = cg.width * cg.height
        if let data = cg.dataProvider?.data {
            let len = CFDataGetLength(data)
            if len>=isize*4 {
                //let ptr = UnsafeMutableRawPointer(mutating:buf).assumingMemoryBound(to: UInt8.self)
                let bytes = CFDataGetBytePtr(data)
                switch cg.alphaInfo {
                case .noneSkipLast,.last:
                    self.set(raw:bytes!)
                case .premultipliedLast:
                    var buf = [UInt8](repeating:0,count:len)
                    var s = bytes!
                    var d = 0
                    for _ in 0..<isize {
                        let r:Int = Int(s[0])
                        let g:Int = Int(s[1])
                        let b:Int = Int(s[2])
                        let a:Int = Int(s[3])
                        if a>0 {
                            buf[d] = UInt8(min(r*255/a,255))
                            d += 1
                            buf[d] = UInt8(min(g*255/a,255))
                            d += 1
                            buf[d] = UInt8(min(b*255/a,255))
                            d += 1
                            buf[d] = UInt8(a)
                            d += 1
                        } else {
                            buf[d] = UInt8(r)
                            d += 1
                            buf[d] = UInt8(g)
                            d += 1
                            buf[d] = UInt8(b)
                            d += 1
                            buf[d] = UInt8(a)
                            d += 1
                        }
                        s = s.advanced(by: 4)
                    }
                    self.set(raw:UnsafeRawPointer(buf))
                    break
                default:
                    Debug.notImplemented(#file,#line)
                }
            } else if len == isize {    // 8 bits
                let bytes = CFDataGetBytePtr(data)
                var buf = [UInt8](repeating:0,count:len*4)
                var s = bytes!
                var d = 0
                for _ in 0..<isize {
                    let v:UInt8 = s[0]
                    buf[d] = v
                    d += 1
                    buf[d] = v
                    d += 1
                    buf[d] = v
                    d += 1
                    buf[d] = 255
                    d += 1
                    s = s.advanced(by: 1)
                }
                self.set(raw:UnsafeRawPointer(buf))
            } else {
                Debug.error("image source error: expected \(isize*4) or \(isize) and got \(len) bytes")
            }
        }
    }
    #else
    // TODO:
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    internal func load(_ filename:String) {
        #if os(iOS) || os(tvOS)
            if let ui = UIImage(contentsOfFile: Application.resourcePath(filename)), let cg=ui.cgImage {
                if viewport != nil && ui.size.width != 0 && ui.size.height != 0 {
                    initialize(from: cg)
                } else if viewport == nil {
                    Debug.error("can't load texture: \(filename), Texture already detached (no viewport)",#file,#line)
                } else {
                    Debug.error("can't load texture: \(filename), file not found)",#file,#line)
                }
            } else {
                Debug.error("can't load texture: \(filename), file not found)",#file,#line)
            }
        #else
            if let ns=NSImage(contentsOfFile: Application.resourcePath(filename)), let cg=ns.cgImage(forProposedRect: nil,context:nil,hints:nil) {
                if viewport != nil && ns.size.width != 0 && ns.size.height != 0 {
                    initialize(from: cg)
                } else if viewport == nil {
                    Debug.error("can't load texture: \(filename), Texture detached (no viewport)",#file,#line)
                } else {
                    Debug.error("can't load texture: \(filename), file not found)",#file,#line)
                }
            } else {
                Debug.error("can't load texture: \(filename), file not found)",#file,#line)
            }
        #endif
        // decode displaysize&scale from filename eg:  filename.134x68.png -> display=Size(134,68)
        let m=filename.split(".")
        var n = 2
        while m.count > n {
            let s=m[m.count-n]
            //Debug.info(s)
            let ss=s.split("x")
            if ss.count == 2 {
                if let w=Int(ss[0]), let h=Int(ss[1]) {
                    pixel.width=Double(w)/pixels.width
                    pixel.height=Double(h)/pixels.height
                }
            }
            n += 1
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    internal func load(_ data:Foundation.Data) {
        // https://developer.apple.com/reference/coregraphics/cgimage/1455149-init load image without premutiplied alpha
        #if os(iOS) || os(tvOS)
            if let ui = UIImage(data:data), let cg=ui.cgImage {
                if viewport != nil {
                    initialize(from: cg)
                } else {
                    Debug.error("can't load texture: Texture detached (no viewport)",#file,#line)
                }
            }
        #else
            if let ns=NSImage(data:data), let cg=ns.cgImage(forProposedRect: nil,context:nil,hints:nil) {
                if viewport != nil {
                    initialize(from: cg)
                } else {
                    Debug.error("can't load texture: Texture detached (no viewport)",#file,#line)
                }
            }
        #endif
    }
    static var memoCG=[[UInt32]]()
    public var cg : CGImage? {
        var data = self.get()
        for i in 0..<data!.count {
            var c = Color(abgr:data![i])
            c.r *= c.a
            c.g *= c.a
            c.b *= c.a
            data![i] = c.rgba
        }
        Texture2D.memoCG.append(data!)
        let cs = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue:CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let selftureSize = self.pixels.width * self.pixels.height * 4
        let rowBytes = self.pixels.width * 4
        let provider = CGDataProvider(dataInfo: nil, data: UnsafeMutablePointer(mutating:Texture2D.memoCG.last!)!, size: Int(selftureSize), releaseData: { u,d,c in
            for i in 0..<Texture2D.memoCG.count {
                if &Texture2D.memoCG[i] == d {
                    Texture2D.memoCG.remove(at: i)
                    break
                }
            }
        })
        return CGImage(width: Int(self.pixels.width), height: Int(self.pixels.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(rowBytes), space: cs, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
    #if os(iOS) || os(tvOS)
    public var system : UIImage? {
        get {
            if let cg = self.cg {
                return UIImage(cgImage: cg)
            }
            return nil
        }
    }
    #elseif os(OSX)
    public var system : NSImage? {
        get {
            if let cg = self.cg {
                return NSImage(cgImage: cg, size: NSSize(width: CGFloat(cg.width), height: CGFloat(cg.height)))
            }
            return nil
        }
    }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if DEBUG
        let dbgInfo:String
        override public var debugDescription: String {
            return dbgInfo
        }
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent:NodeUI,texture:Texture2D,file:String=#file,line:Int=#line) {
        #if DEBUG
            self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
        #endif
        self.pixels = texture.pixels
        if texture.texture == nil {
            Debug.error("Texture2D from texture, nil value")
        }
        self.texture = texture.texture
        super.init(parent:parent)
        self.scale = texture.scale
    }
    public init(parent:NodeUI,size:Size,scale:Size=Size(1,1),texture:MTLTexture,file:String=#file,line:Int=#line) {
        #if DEBUG
            self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
        #endif
        self.pixels = size * scale
        self.texture = texture
        super.init(parent:parent)
        self.scale = scale
    }
    public init(parent:NodeUI,size:Size,scale:Size=Size(1,1),border:Size=Size.zero,format:Format = .rgba,file:String=#file,line:Int=#line) {
        #if DEBUG
            self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
        #endif
        let pixfmt = (format == .rgba) ? MTLPixelFormat.rgba8Unorm : MTLPixelFormat.a8Unorm
        self.pixels=size*scale
        super.init(parent: parent)
        self.scale=scale
        let d=MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixfmt, width: Int(self.pixels.width), height: Int(self.pixels.height), mipmapped: false)
        //d.textureType = .Type2DMultisample // TODO: implement multisampled texture http://stackoverflow.com/questions/36227209/multi-sampling-jagged-edges-in-metalios
        d.usage = .renderTarget
        self.texture=viewport!.gpu.device?.makeTexture(descriptor:d)
    }
    public init(parent:NodeUI,path:String,border:Size=Size.zero,file:String=#file,line:Int=#line) {
        #if DEBUG
            self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
        #endif
        self.border=border
        super.init(parent: parent)
        load(path)
    }
    #if os(macOS) || os(iOS) || os(tvOS)
        public init(parent:NodeUI,cg:CGImage,file:String=#file,line:Int=#line) {
            #if DEBUG
                self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
            #endif
            super.init(parent:parent)
            do {
                try self.texture=viewport!.gpu.loader!.newTexture(cgImage:cg,options:nil)
                pixels.width=Double(texture!.width)
                pixels.height=Double(texture!.height)
            } catch  {
                Debug.error("can't create texture from CGImage",#file,#line)
            }
        }
    #endif
    public init(parent:NodeUI,data:[UInt8],file:String=#file,line:Int=#line) {
        #if DEBUG
            self.dbgInfo = "Texture.init(file:'\(file)',line:\(line))"
        #endif
        super.init(parent:parent)
        let d = Data(bytesNoCopy: UnsafeMutablePointer(mutating:data), count: data.count, deallocator: Data.Deallocator.none)
        load(d)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override open func detach() {
        texture = nil
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func get() -> [UInt32]? {
        if let t=texture {
            let data=[UInt32](repeating: 0,count: t.width*t.height)
            t.getBytes(UnsafeMutablePointer(mutating:data), bytesPerRow: t.width*4, from: MTLRegion(origin:MTLOrigin(x:0,y:0,z:0),size:MTLSize(width:t.width,height:t.height,depth:1)), mipmapLevel: 0)
            return data
        } else {
            Debug.error(Error("no texture",#file,#line))
        }
        return nil
    }
    public func get(pixel p:Point) -> Color {
        if let t=texture {
            let data=[UInt32](repeating: 0,count: 1)
            t.getBytes(UnsafeMutablePointer(mutating:data), bytesPerRow: t.width*4, from: MTLRegion(origin:MTLOrigin(x:Int(p.x),y:Int(p.y),z:0),size:MTLSize(width:1,height:1,depth:1)), mipmapLevel: 0)
            return Color(abgr:data[0])
        } else {
            Debug.error(Error("no texture",#file,#line))
        }
        return Color.transparent
    }
    public func set(pixels data:[UInt32]) {
        if let t=texture {
            t.replace(region: MTLRegion(origin:MTLOrigin(x:0,y:0,z:0),size:MTLSize(width:t.width,height:t.height,depth:1)), mipmapLevel: 0, withBytes: UnsafePointer(data), bytesPerRow: t.width*4)
        } else {
            Debug.error(Error("no texture",#file,#line))
        }
    }
    public func set(raw data:UnsafeRawPointer) {
        if let t=texture {
            if t.pixelFormat == .rgba8Unorm {
                t.replace(region: MTLRegion(origin:MTLOrigin(x:0,y:0,z:0),size:MTLSize(width:t.width,height:t.height,depth:1)), mipmapLevel: 0, withBytes: data, bytesPerRow: t.width*4)
            } else {    // MTLPixelFormat.a8Unorm
                t.replace(region: MTLRegion(origin:MTLOrigin(x:0,y:0,z:0),size:MTLSize(width:t.width,height:t.height,depth:1)), mipmapLevel: 0, withBytes: data, bytesPerRow: t.width)
            }
        } else {
            Debug.error(Error("no texture",#file,#line))
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
