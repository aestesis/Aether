//
//  Font.swift
//  Aether
//
//  Created by renan jegouzo on 27/03/2016.
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

#if os(macOS)
    import CoreGraphics
    import AppKit
#elseif os(iOS) || os(tvOS)
    import CoreGraphics
    import UIKit
#else
    import CFreeType
    import CPango
#endif

#if os(iOS) || os(tvOS)
    public class Font : NodeUI {
        static var registred=[String:Bool]()
        static let nsOptions:NSStringDrawingOptions = [.usesFontLeading,.usesDeviceMetrics,.usesLineFragmentOrigin,.truncatesLastVisibleLine]
        var uifont:UIFont
        public var name:String {
            return uifont.fontName
        }
        public var familly:String {
            return uifont.familyName
        }
        public var size:Double {
            return Double(uifont.pointSize)
        }
        public var ascender:Double {
            return Double(abs(uifont.ascender))
        }
        public var descender:Double {
            return Double(abs(uifont.descender))
        }
        public var leading:Double {
            return Double(abs(uifont.leading))
        }
        public var height:Double {
            let attr = [
                NSAttributedStringKey.font: self.uifont
            ]
            return Size(NSAttributedString(string:"a",attributes:attr).size()).height
        }
        public func mask(text:String,align:Align=Align.left,width:Double=0,lines:Int=0) -> Bitmap {
            let attr = [
                NSAttributedStringKey.font: self.uifont,
                NSAttributedStringKey.paragraphStyle: Font.paragraphStyle(align:align),
                NSAttributedStringKey.foregroundColor: Color.white.system,
                NSAttributedStringKey.backgroundColor: Color.black.system,
                NSAttributedStringKey.baselineOffset: NSNumber(value:0)
            ]
            let hf = Size(NSAttributedString(string:"a",attributes:attr).size()).height
            let s=NSAttributedString(string:text,attributes:attr)
            var r = Rect.zero
            let cspace=CGColorSpaceCreateDeviceGray()
            if width>0 {
                let h = (lines == 0) ? Double(CGFloat.greatestFiniteMagnitude) : hf * Double(lines)
                r = Rect(s.boundingRect(with:CGSize(width:CGFloat(ceil(width)),height:CGFloat(h)),options:Font.nsOptions,context:nil))
                let nlines = ceil(r.bottom / hf)
                r.width = ceil(width)
                let ht = nlines * hf
                r.height = ht
                r.x = 0
                r.y = 0
            } else {
                r = Rect(o:.zero,s:Size(s.size())).ceil
            }
            if let ctx=CGContext(data: nil, width: Int(r.right), height: Int(r.bottom), bitsPerComponent: 8, bytesPerRow: 0, space: cspace, bitmapInfo: 0) {
                ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: CGFloat(r.bottom)))
                UIGraphicsPushContext(ctx)
                s.draw(with:r.system,options:Font.nsOptions,context:nil)
                UIGraphicsPopContext()
                if let cgi=ctx.makeImage() {
                    return Bitmap(parent:self.viewport!,cg:cgi)
                }
            }
            let b = Bitmap(parent:self.viewport!,size:Size(8,8))
            Debug.error("error Font.Mask  size:\(r.bottomRight)  text:\(text)")
            b["error"] = Error("error Font.Mask  size:\(r.bottomRight)  text:\(text)",#file,#line)
            return b
        }
        public func color(text:String,align:Align=Align.left,width:Double=0,lines:Int=0) -> Bitmap {
            let attr = [
                NSAttributedStringKey.font: self.uifont,
                NSAttributedStringKey.paragraphStyle: Font.paragraphStyle(align:align),
                NSAttributedStringKey.foregroundColor: Color.white.system,
                NSAttributedStringKey.backgroundColor: Color.black.system,
                NSAttributedStringKey.baselineOffset: NSNumber(value:0)
            ]
            let hf = Size(NSAttributedString(string:"a",attributes:attr).size()).height
            let s=NSAttributedString(string:text,attributes:attr)
            var r = Rect.zero
            let cspace=CGColorSpaceCreateDeviceRGB()
            if width>0 {
                let h = (lines == 0) ? Double(CGFloat.greatestFiniteMagnitude) : hf * Double(lines)
                r = Rect(s.boundingRect(with:CGSize(width:CGFloat(ceil(width)),height:CGFloat(h)),options:Font.nsOptions,context:nil))
                let nlines = ceil(r.bottom / hf)
                r.width = ceil(width)
                let ht = nlines * hf
                r.height = ht
                r.x = 0
                r.y = 0
            } else {
                r = Rect(o:.zero,s:Size(s.size())).ceil
                let nlines = text.split("\n").count
                let h = ceil(Double(nlines) * self.height)
                r.bottom = max(h,r.bottom)
            }
            if let ctx = CGContext.init(data: nil, width: Int(r.right), height: Int(r.bottom), bitsPerComponent: 8, bytesPerRow: 0, space: cspace, bitmapInfo: 0) {
                ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: CGFloat(r.bottom)))
                UIGraphicsPushContext(ctx)
                s.draw(with:r.system,options:Font.nsOptions,context:nil)
                UIGraphicsPopContext()
                if let cgi=ctx.makeImage() {
                    return Bitmap(parent:self.viewport!,cg:cgi)
                }
            }
            let b = Bitmap(parent:self.viewport!,size:Size(8,8))
            Debug.error("error Font.Mask  size:\(r.bottomRight)  text:\(text)")
            b["error"] = Error("error Font.Mask  size:\(r.bottomRight)  text:\(text)",#file,#line)
            return b
        }
        /*
         
         // TODO: from mask
        public func color(text:String,align:Align=Align.left,width:Double=0) -> Bitmap {
            let attr = [
                NSFontAttributeName: self.uifont,
                NSParagraphStyleAttributeName: Font.paragraphStyle(align:align),
                NSForegroundColorAttributeName: Color.white.system,
                NSBackgroundColorAttributeName: Color.black.system
            ]
            let s=NSAttributedString(string:text, attributes:attr)
            var sz=Size(s.size()).ceil
            sz.width = max(sz.width,8)
            let cspace=CGColorSpaceCreateDeviceRGB()
            if let ctx = CGContext.init(data: nil, width: Int(sz.w), height: Int(sz.h), bitsPerComponent: 8, bytesPerRow: 0, space: cspace, bitmapInfo: 0) {
                ctx.translateBy(x: CGFloat(0),y: CGFloat(sz.height))
                ctx.scaleBy(x: 1,y: -1)
                UIGraphicsPushContext(ctx)
                s.draw(in:Rect(o:Point.zero,s:sz).system)
                UIGraphicsPopContext()
                if let cgi=ctx.makeImage() {
                    return Bitmap(parent:self.viewport!,cg:cgi)
                }
            }
            let b = Bitmap(parent:self.viewport!,size:Size(8,8))
            b["error"] = Error("error Font.Color  size:\(sz)  text:\(text)",#file,#line)
            return b
        }
 */
        public func bitmap(text:String,align:Align=Align.left,width:Double=0,color:Color=Color.white,_ bitmap:@escaping (Bitmap)->())  {
            if text.length==0  {
                Debug.info("no text")
                return
            }
            bg {
                let bf=self.mask(text:text,align:align,width:width)
                let b=Bitmap(parent:self.viewport!,size:bf.size)
                let g=Graphics(image:b,clear:color)
                g.draw(rect:b.bounds,image:bf,blend:.setAlpha,color:color)
                g.done {_ in
                    bitmap(b)
                }
            }
        }
        public func colorBitmap(text:String,align:Align=Align.left,width:Double=0,_ bitmap:@escaping (Bitmap)->())  {
            if text.length==0  {
                Debug.info("no text")
                return
            }
            bg {
                let bf=self.color(text:text,align:align,width:width)
                bitmap(bf)
            }
        }
        public func size(_ text:String) -> Size {
            let attr = [
                NSAttributedStringKey.font: uifont
            ]
            let s=NSAttributedString(string:text,attributes:attr)
            return Size(s.size())
        }
        /*
        public func bounds(_ text:String, width:Double? = nil) -> Rect {
            let attr = [
                NSFontAttributeName: uifont
            ]
            let s=NSAttributedString(string:text,attributes:attr)
            let r=s.boundingRect(with:CGSize(width:CGFloat(width ?? Double(CGFloat.greatestFiniteMagnitude)),height:Double(CGFloat.greatestFiniteMagnitude)),options:Font.nsOptions,context:nil)
            return Rect(r)
        }
 */
        public func bounds(_ text:String, width:Double? = nil, lines:Int = 0) -> Rect {
            let attr = [
                NSAttributedStringKey.font: uifont
            ]
            let hf = Size(NSAttributedString(string:"a",attributes:attr).size()).height
            let w = ceil(width ?? Double(CGFloat.greatestFiniteMagnitude))
            let h = (lines == 0) ? Double(CGFloat.greatestFiniteMagnitude) : hf * Double(lines)
            let s=NSAttributedString(string:text,attributes:attr)
            var r=Rect(s.boundingRect(with:CGSize(width:CGFloat(w),height:CGFloat(h)),options:Font.nsOptions,context:nil))
            let nlines = ceil(r.bottom / hf)
            r.width = (width == 0) ? ceil(r.width) + ceil(r.x) * 2 :ceil(width!)
            r.height = ceil(nlines * hf)
            r.x = 0
            r.y = 0
            return r
        }
        public func wordWrap(text:String,width:Double) -> [String] {
            let paraf = text.split("\n")
            var lines = [String]()
            var l = ""
            for p in paraf {
                let words = p.split(" ")
                for w in words {
                    let n = (l.length>0) ? (l+" "+w) : (w)
                    if size(l).width > width {
                        lines.append(l)
                        l = w
                    } else {
                        l = n
                    }
                }
                if l.length>0 {
                    lines.append(l)
                    l = ""
                }
            }
            return lines
        }
        private static func paragraphStyle(align:Align) -> NSMutableParagraphStyle {
            let attr=NSMutableParagraphStyle()
            switch Align(rawValue: align.rawValue & Align.maskHorizontal.rawValue)! {
            case Align.middle:
                attr.alignment = .center
                break
            case Align.right:
                attr.alignment = .right
                break
            default:
                attr.alignment = .left
                break
            }
            return attr
        }
        public init(parent:NodeUI,name:String,size:Double) {
            uifont = UIFont(name: "Helvetica", size: CGFloat(Float(size)))!
            if name.contains(".otf") || name.contains(".ttf") {
                var fname=name
                if let i=fname.lastIndexOf("/") {
                    fname=fname[(i+1)..<fname.length]
                }
                if let i=fname.lastIndexOf(".") {
                    fname=fname[0..<i]
                }
                fname = fname.lowercased()
                if Font.registred[name]==nil {
                    let url=NSURL(fileURLWithPath: Application.resourcePath(name))
                    if CTFontManagerRegisterFontsForURL(url,CTFontManagerScope.none,nil) {
                        Font.registred[name]=true
                    } else {
                        Debug.error("error, can't register font \(url.absoluteString!)")
                    }
                }
                let z=uifont
                for fn in Font.availableFonts {
                    //Debug.info(fn)
                    if fn.lowercased().contains(fname) {
                        uifont=UIFont(name: fn, size: CGFloat(Float(size)))!
                    }
                }
                if z==uifont {
                    Debug.error("font \(name) not found!")
                }
            } else {
                uifont=UIFont(name: name, size: CGFloat(Float(size)))!
            }
            super.init(parent:parent)
        }
        public init(font:Font,size:Double) {
            uifont=UIFont(name: font.name, size: CGFloat(Float(size)))!
            super.init(parent:font.parent)
        }
        public convenience init(parent:NodeUI,name:String,size:Int) {
            self.init(parent:parent,name:name,size:Double(size))
        }
        public convenience init(font:Font,size:Int) {
            self.init(font:font,size:Double(size))
        }
        public static var availableFonts:[String] {
            var fonts=[String]()
            for fam in UIFont.familyNames {
                for fn in UIFont.fontNames(forFamilyName:fam) {
                    fonts.append(fn)
                }
            }
            return fonts
        }
    }
#elseif os(OSX)
    public class Font : NodeUI {
        static var registred=[String:Bool]()
        static let nsOptions:NSString.DrawingOptions = [.usesFontLeading,.usesDeviceMetrics,.usesLineFragmentOrigin,.truncatesLastVisibleLine]
        var nsfont:NSFont
        public var name:String {
            return nsfont.fontName
        }
        public var familly:String {
            return nsfont.familyName!
        }
        public var size:Double {
            return Double(nsfont.pointSize)
        }
        public var ascender:Double {
            return Double(abs(nsfont.ascender))
        }
        public var descender:Double {
            return Double(abs(nsfont.descender))
        }
        public var leading:Double {
            return Double(abs(nsfont.leading))
        }
        public var height:Double {
            let attr = [
                NSAttributedStringKey.font: self.nsfont
            ]
            return Size(NSAttributedString(string:"a",attributes:attr).size()).height
        }
        public func mask(text:String,align:Align=Align.left,width:Double=0,lines:Int=0) -> Bitmap {
            let attr = [
                NSAttributedStringKey.font: self.nsfont,
                NSAttributedStringKey.paragraphStyle: Font.paragraphStyle(align),
                NSAttributedStringKey.foregroundColor: Color.white.system,
                NSAttributedStringKey.backgroundColor: Color.black.system,
                NSAttributedStringKey.baselineOffset: NSNumber(value:0)
            ]
            let hf = Size(NSAttributedString(string:"a",attributes:attr).size()).height
            let s=NSAttributedString(string:text,attributes:attr)
            var r = Rect.zero
            let decal = 0.0
            let cspace=CGColorSpaceCreateDeviceGray()
            if width>0 {
                let h = (lines == 0) ? Double(CGFloat.greatestFiniteMagnitude) : hf * Double(lines)
                r = Rect(s.boundingRect(with:CGSize(width:CGFloat(ceil(width)),height:CGFloat(h)),options:Font.nsOptions,context:nil))
                let nlines = ceil(r.bottom / hf)
                r.width = ceil(width)
                let ht = nlines * hf
                //decal = self.height - self.size
                r.height = ht
                r.x = 0
                r.y = 0
                if let ctx=CGContext(data: nil, width: Int(r.right), height: Int(r.bottom), bitsPerComponent: 8, bytesPerRow: 0, space: cspace, bitmapInfo: 0) {
                    NSGraphicsContext.saveGraphicsState()
                    ctx.translateBy(x: 0, y: CGFloat(decal))
                    let nsg=NSGraphicsContext(cgContext:ctx,flipped:false)
                    NSGraphicsContext.current = nsg
                    //NSGraphicsContext.setCurrent(nsg)
                    s.draw(with:r.system,options:Font.nsOptions)
                    NSGraphicsContext.restoreGraphicsState()
                    if let cgi=ctx.makeImage() {
                        return Bitmap(parent:self.viewport!,cg:cgi)
                    }
                }
            } else {
                r = Rect(o:.zero,s:Size(s.size())).ceil
                //let nlines = text.split("\n").count
                //let h = ceil(Double(nlines) * self.height)
                //decal = r.bottom - h
                //r.bottom = max(h,r.bottom)
                if let ctx=CGContext(data: nil, width: Int(r.right), height: Int(r.bottom), bitsPerComponent: 8, bytesPerRow: 0, space: cspace, bitmapInfo: 0) {
                    NSGraphicsContext.saveGraphicsState()
                    ctx.translateBy(x: 0, y: CGFloat(decal))
                    let nsg=NSGraphicsContext(cgContext:ctx,flipped:false)
                    NSGraphicsContext.current = nsg
                    s.draw(with:Rect(0,0,r.right,r.bottom).system,options:Font.nsOptions)
                    NSGraphicsContext.restoreGraphicsState()
                    if let cgi=ctx.makeImage() {
                        return Bitmap(parent:self.viewport!,cg:cgi)
                    }
                }
            }
            let b = Bitmap(parent:self.viewport!,size:Size(8,8))
            Debug.error("error Font.Mask  size:\(r.bottomRight)  text:\(text)")
            b["error"] = Error("error Font.Mask  size:\(r.bottomRight)  text:\(text)",#file,#line)
            return b
        }
        public func bitmap(text:String,align:Align=Align.left,width:Double=0,color:Color=Color.white,_ bitmap:@escaping (Bitmap)->())  {
            if text.length==0  {
                Debug.info("no text")
                return
            }
            bg {
                let bf=self.mask(text:text,align:align,width:width)
                let b=Bitmap(parent:self.viewport!,size:bf.size)
                let g=Graphics(image:b,clear:color)
                g.draw(rect:b.bounds,image:bf,blend:.setAlpha,color:color)
                g.done {_ in
                    bitmap(b)
                }
            }
        }
        public func size(_ text:String) -> Size {
            let attr = [
                NSAttributedStringKey.font: nsfont
            ]
            let s=NSAttributedString(string:text,attributes:attr)
            return Size(s.size())
        }
        public func bounds(_ text:String, width:Double? = nil, lines:Int = 0) -> Rect {
            let attr = [
                NSAttributedStringKey.font: nsfont
            ]
            let hf = Size(NSAttributedString(string:"a",attributes:attr).size()).height
            let w = ceil(width ?? Double(CGFloat.greatestFiniteMagnitude))
            let h = (lines == 0) ? Double(CGFloat.greatestFiniteMagnitude) : hf * Double(lines)
            let s=NSAttributedString(string:text,attributes:attr)
            var r=Rect(s.boundingRect(with:CGSize(width:CGFloat(w),height:CGFloat(h)),options:Font.nsOptions,context:nil))
            let nlines = ceil(r.bottom / hf)
            r.width = (width == 0) ? ceil(r.width) + ceil(r.x) * 2 :ceil(width!)
            r.height = ceil(nlines * hf)
            r.x = 0
            r.y = 0
            return r
        }
        public func wordWrap(text:String,width:Double) -> [String] {
            let paraf = text.split("\n")
            var lines = [String]()
            var l = ""
            for p in paraf {
                let words = p.split(" ")
                for w in words {
                    let n = (l.length>0) ? (l+" "+w) : (w)
                    if size(l).width>width {
                        lines.append(l)
                        l = w
                    } else {
                        l = n
                    }
                }
                if l.length>0 {
                    lines.append(l)
                    l = ""
                }
            }
            return lines
        }
        private static func paragraphStyle(_ align:Align) -> NSMutableParagraphStyle {
            let attr=NSMutableParagraphStyle()
            switch Align(rawValue: align.rawValue & Align.maskHorizontal.rawValue)! {
            case Align.middle:
                attr.alignment = .center
                break
            case Align.right:
                attr.alignment = .right
                break
            default:
                attr.alignment = .left
                break
            }
            return attr
        }
        public init(parent:NodeUI,name:String,size:Double) {
            nsfont=NSFont(name:"Helvetica", size: CGFloat(Float(size)))!
            if name.contains(".otf") || name.contains(".ttf") {
                var fname=name
                if let i=fname.lastIndexOf("/") {
                    fname=fname[(i+1)..<fname.length]
                }
                if let i=fname.lastIndexOf(".") {
                    fname=fname[0..<i]
                }
                fname = fname.lowercased()
                if Font.registred[name]==nil {
                    let url=Foundation.URL(fileURLWithPath: Application.resourcePath(name))
                    if CTFontManagerRegisterFontsForURL(url as CFURL,CTFontManagerScope.process,nil) {
                        Font.registred[name]=true
                    } else {
                        Font.registred[name]=false
                        //Debug.error("error, can't register font \(url.absoluteString)")
                    }
                }
                let z=nsfont
                for fn in NSFontManager.shared.availableFonts {
                    if fn.lowercased().contains(fname) {
                        nsfont=NSFont(name: fn, size: CGFloat(Float(size)))!
                    }
                }
                if z==nsfont {
                    Debug.error("font \(name) not found!")
                }
            } else {
                nsfont=NSFont(name: name, size: CGFloat(Float(size)))!
            }
            super.init(parent:parent)
        }
        public init(font:Font,size:Double) {
            nsfont=NSFont(name: font.name, size: CGFloat(Float(size)))!
            super.init(parent:font.parent)
        }
        public convenience init(parent:NodeUI,name:String,size:Int) {
            self.init(parent:parent,name:name,size:Double(size))
        }
        public convenience init(font:Font,size:Int) {
            self.init(font:font,size:Double(size))
        }
        public static var availableFonts:[String] {
            return NSFontManager.shared.availableFonts
        }
    }
#else
    public class Font : NodeUI {
        static var fmap : UnsafeMutablePointer<PangoFontMap>?
        static var families=[String:UnsafeMutablePointer<PangoFontFamily>?]()  
        var context : UnsafeMutablePointer<PangoContext>?
        var font:UnsafeMutablePointer<PangoFont>?
        var metrics:UnsafeMutablePointer<PangoFontMetrics>?
        public let name:String
        public var familly:String {
            return ""
        }
        public let size:Double
        public var ascender:Double {
            return Double(pango_font_metrics_get_ascent(metrics))
        }
        public var descender:Double {
            return Double(pango_font_metrics_get_descent(metrics))
        }
        public var leading:Double {
            return 0    // TODO: do better
        }
        public var height:Double {
            return size // TODO: do better
        }
        func glyphs(text s:String) -> UnsafeMutablePointer<PangoGlyphString>? {
            let unicode = Array(s.unicodeScalars)
            let gs = pango_glyph_string_new()
            pango_glyph_string_set_size(gs,Int32(s.length))
            for i in 0..<s.length {
                gs![0].glyphs[i].glyph = UInt32(unicode[i].value)
            }
            return gs
        }
        public func mask(text:String,align:Align=Align.left,width:Double=0,lines:Int=0) -> Bitmap {
            // TODO: use width,lines options
            let size = self.size(text)
            var ftb = FT_Bitmap()
            FT_Bitmap_Init(&ftb)
            ftb.width = UInt32(size.width)
            ftb.pitch = Int32((ftb.width + 3) & ~3)
            ftb.rows = UInt32(size.height)
            let surface = Int(ftb.pitch)*Int(ftb.rows)
            let buffer = g_malloc(UInt(surface)).assumingMemoryBound(to:UInt8.self)
            ftb.buffer = buffer
            ftb.num_grays = 256
            ftb.pixel_mode = UInt8(FT_PIXEL_MODE_GRAY.rawValue)
            memset(ftb.buffer,0,surface)
            let gs = glyphs(text:text)
            // add FT_Matrix if needed
            pango_ft2_render_transformed(&ftb,nil,font,gs,0,0)
            var pixels = [UInt32](repeating:0,count:surface)
            for i in 0..<surface {
                let l = UInt32(buffer[i])
                var c:UInt32 = 255
                c |= l << 24
                c |= l << 16
                c |= l << 8
                pixels[i] = c
            }
            let b = Bitmap(parent:self.viewport!,size:Size(Double(ftb.width),Double(ftb.rows)),pixels:pixels)
            pango_glyph_string_free(gs)
            g_free(ftb.buffer)
            g_free(&ftb)
            return b
        }
        public func bitmap(text:String,align:Align=Align.left,width:Double=0,color:Color=Color.white,_ bitmap:@escaping (Bitmap)->())  {
            if text.length==0  {
                Debug.info("no text")
                return
            }
            bg {
                let bf=self.mask(text:text,align:align,width:width)
                let b=Bitmap(parent:self.viewport!,size:bf.size)
                let g=Graphics(image:b,clear:color)
                g.draw(rect:b.bounds,image:bf,blend:.setAlpha,color:color)
                g.done {_ in
                    bitmap(b)
                }
            }
        }
        public func size(_ text:String) -> Size {
            let gs = glyphs(text:text)
            let w = pango_glyph_string_get_width(gs)
            pango_glyph_string_free(gs)
            return Size(Double(w),height)
        }
        public func bounds(_ text:String, width:Double? = nil, lines:Int = 0) -> Rect {
            return Rect.zero
        }
        public func wordWrap(text:String,width:Double) -> [String] {
            let paraf = text.split("\n")
            var lines = [String]()
            var l = ""
            for p in paraf {
                let words = p.split(" ")
                for w in words {
                    let n = (l.length>0) ? (l+" "+w) : (w)
                    if size(l).width>width {
                        lines.append(l)
                        l = w
                    } else {
                        l = n
                    }
                }
                if l.length>0 {
                    lines.append(l)
                    l = ""
                }
            }
            return lines
        }
        public override func detach() {
            if let m = metrics {
                pango_font_metrics_unref(m)
                metrics = nil
            }
            if font != nil {
                g_free(&font)
                font = nil
            }
            if var context = context {
                g_object_unref(&context)
                self.context = nil
            }
            super.detach()
        }
        static func initGlobals() {
            // #define PANGO_RENDER_TYPE_FC "PangoRenderFc"
            if fmap == nil {
                fmap = pango_ft2_font_map_new ()
                var families:UnsafeMutablePointer<UnsafeMutablePointer<PangoFontFamily>?>?
                var nfam:Int32 = 0
                pango_font_map_list_families(fmap,&families,&nfam)
                for i in 0..<Int(nfam) {
                    let f = families![i]
                    let cname = pango_font_family_get_name(f)
                    let name = String(cString:cname!)
                    //Debug.warning("found font family: \(name)")
                    Font.families[name] = f
                }
                g_free(families)
            }
        }
        public init(parent:NodeUI,name:String,size:Double) {
            Font.initGlobals()
            self.size = size
            context = pango_font_map_create_context(Font.fmap)
            let fm = Font.fonts(matching:name)
            if fm.count > 0 {
                self.name = fm[0]
                let pattern = "\(name) [\(size)]"
                if let fd = pango_font_description_from_string(pattern.cString(using: .utf8)) {
                    font = pango_font_map_load_font (Font.fmap,context,fd)
                    metrics = pango_font_get_metrics(font,nil)
                    pango_font_description_free(fd)
                }
            } else {
                self.name = "error"
            }
            super.init(parent:parent)
        }
        public init(font:Font,size:Double) {
            self.size = size
            self.name = font.name
            let pattern = "\(name) [\(size)]"
            if let fd = pango_font_description_from_string(pattern.cString(using: .utf8)) {
                self.font = pango_font_map_load_font (Font.fmap,context,fd)
                metrics = pango_font_get_metrics(self.font,nil)
                pango_font_description_free(fd)
            }
            if let toto = font.parent as? NodeUI {
                super.init(parent:toto)
            } else {
                super.init(parent:font)
            }
        }
        public convenience init(parent:NodeUI,name:String,size:Int) {
            self.init(parent:parent,name:name,size:Double(size))
        }
        public convenience init(font:Font,size:Int) {
            self.init(font:font,size:Double(size))
        }
        public static var availableFonts:[String] {
            Font.initGlobals()
            return Array(Font.families.keys).sorted()
        }
        public static func fonts(matching s:String) -> [String] {
            let fonts = Font.availableFonts
            var matching = [String]()
            let m = s.lowercased()
            for f in fonts {
                if f.lowercased().contains(m) {
                    matching.append(f)
                }
            }
            return matching
        }
    }
#endif

#if os(macOS) || os(iOS) || os(tvOS)
// TODO:
public class FontMetrics : NodeUI {
    let font:Font
    public init(parent:NodeUI,name:String,size:Double) {
        self.font = Font(parent:parent,name:name,size:size)
        super.init(parent:parent)
        retrieveMetrics()
    }
    func retrieveMetrics() {    // http://stackoverflow.com/questions/20327980/getting-glyph-names-using-core-text
        let fname=font.name as NSString
        //let f=CGFontCreateWithFontName(fname)
        let f=CTFontCreateWithName(fname,CGFloat(font.size),nil)
        let count=CTFontGetGlyphCount(f)
        for i in 1...count {
            let gi=CTGlyphInfoCreateWithGlyph(CGGlyph(i),f, "(c)" as NSString)
            let gname=CTGlyphInfoGetGlyphName(gi)
            let gid=CTGlyphInfoGetCharacterIdentifier(gi)
            let glyph=CTFontGetGlyphWithName(f, gname!)
            //CTFontGetGlyphsForCharacters(<#T##font: CTFont##CTFont#>, characters: UnsafePointer<UniChar>, glyphs: UnsafeMutablePointer<CGGlyph>, <#T##count: CFIndex##CFIndex#>)
        }
    }
}
#endif