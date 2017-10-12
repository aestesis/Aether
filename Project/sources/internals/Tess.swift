//
//  Tess.swift
//  libtess
//
//  Created by renan jegouzo on 31/03/2016.
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
    import tessOSX
#elseif os(iOS)
    import tessIOS
#elseif os(tvOS)
    import tessTV
#endif

// sample: https://www.opengl.org/archives/resources/code/samples/redbook/tess.c

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Tess {
    public class Primitive {
        public enum Kind : UInt32 {
            case triangles = 0x0004
            case triangle_STRIP = 0x0005
            case triangle_FAN = 0x0006
        }
        public var vertices=Path.Contour.verticeArray
        public private(set) var kind:Kind
        init(_ i:UInt32) {
            kind=Kind(rawValue:i)!
        }
        public var description:String {
            switch kind {
            case .triangles:
                return "triangles, vertices: \(vertices.count)"
            case .triangle_STRIP:
                return "triangles strip, vertices: \(vertices.count)"
            case .triangle_FAN:
                return "triangles fan, vertices: \(vertices.count)"
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    let tess:UnsafeMutableRawPointer
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public private(set) var shapes=[Primitive]()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func begin(_ m:UInt32) {  // TODO: in libtess, try to set swift callback directly in  multithread, and remove all static callbacks, if it work
        shapes.append(Primitive(m))
    }
    func draw(_ v:UnsafeMutableRawPointer) {
        let tv = v.assumingMemoryBound(to: Path.Contour.Vertice.self)
        shapes[shapes.count-1].vertices.append(tv[0])
    }
    func end() {
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init() {
        let b:@convention(c) (UInt32) -> () = { (m:UInt32) in
            Tess.current.begin(m)
        }
        let d:@convention(c) (UnsafeMutableRawPointer?) -> () = { v in
            Tess.current.draw(v!)
        }
        let e:@convention(c) () -> () = {
            Tess.current.end()
        }
        tess = tessInit(b, d, e)
        Tess.current=self
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    static var current:Tess {
        get { return Thread.current["aestesis.alib.tess"] as! Tess }
        set(t) { Thread.current["aestesis.alib.tess"]=t }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func beginPolygon() {
        shapes.removeAll()
        tessBeginPolygon(tess)
    }
    public func endPolygon() {
        tessEndPolygon(tess)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func beginContour() {
        tessBeginContour(tess)
    }
    public func endContour() {
        tessEndContour(tess)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func sendVertex(_ vertex:[Path.Contour.Vertice]) {
        let ptr = unsafeBitCast(vertex, to: UnsafeMutableRawPointer.self)
        let pv = ptr.advanced(by: 32).assumingMemoryBound(to: TessVertex.self)  // WTF? apple bug, advance by 32 to override it...  // fragile
        tessSendVertex(tess, pv, Int32(vertex.count))
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////