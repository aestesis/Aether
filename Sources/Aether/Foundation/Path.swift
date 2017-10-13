//
//  Path.swift
//  Aether
//
//  Created by renan jegouzo on 01/04/2016.
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


/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Path : Atom
{
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public struct Contour {
        public struct Vertice {
            public var position:Vec3
            public var uv:Point
            public init() {
                self.position = Vec3.zero
                self.uv = Point.zero
            }
            public init(position:Vec3=Vec3.zero,uv:Point=Point.zero) {
                self.position = position
                self.uv = uv
            }
            public init(pos:Vec3=Vec3.zero,uv:Point=Point.zero) {
                self.position = pos
                self.uv = uv
            }
        }
        public var vertices=[Vertice]()
        public var closed:Bool=false
        static var verticeArray : [Vertice] {
            return [Vertice]()
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var segments=[Segment]()
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var interpolationStepCount=16
    var bounds=Rect.zero
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override init() {
        super.init()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func append(_ s:Segment) {
        segments.append(s)
    }
    public func append(moveTo p:Point) {
        segments.append(Path.Segment.moveTo(p))
    }
    public func append(lineTo p:Point) {
        segments.append(Path.Segment.lineTo(p))
    }
    public func clear() {
        segments.removeAll()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func parse(_ paint:Paint) -> [Contour] {
        let renderer=paint.renderer
        let steps=self.interpolationStepCount
        var points=[Contour]()
        var contour=Contour()
        var bb = Rect.zero
        var v=Vec3.zero
        for s in segments {
            let rel=(s.cmd.rawValue & PathAbsRel.relative.rawValue)==PathAbsRel.relative.rawValue
            switch PathSegment(rawValue: s.cmd.rawValue & ~1)! {
            case PathSegment.close_PATH:
                contour.closed=true
                break
            case  PathSegment.move_TO:
                if contour.vertices.count>0 {
                    points.append(contour)
                    contour=Contour()
                }
                let sp=s as! SegmentPoint
                v = rel ? (v+sp.p) : Vec3(sp.p)
                contour.vertices.append(Contour.Vertice(pos:v))
                bb = bb.union(Point(v.x,v.y))
                break
            case  PathSegment.line_TO:
                let sp=s as! SegmentPoint
                v = rel ? (v+sp.p) : Vec3(sp.p)
                contour.vertices.append(Contour.Vertice(pos:v))
                bb = bb.union(Point(v.x,v.y))
                break
            case  PathSegment.hline_TO:
                let sp=s as! SegmentPoint
                v = rel ? (v+sp.p) : Vec3(sp.p)
                contour.vertices.append(Contour.Vertice(pos:v))
                bb = bb.union(Point(v.x,v.y))
                break
            case  PathSegment.vline_TO:
                let sp=s as! SegmentPoint
                v = rel ? (v+sp.p) : Vec3(sp.p)
                contour.vertices.append(Contour.Vertice(pos:v))
                bb = bb.union(Point(v.x,v.y))
                break
            case PathSegment.quad_TO:
                let sc=s as! SegmentQuad
                let start=v
                let cp = rel ? (v+sc.p[0]) : Vec3(sc.p[0])
                let end = rel ? (v+sc.p[1]) : Vec3(sc.p[1])
                for i in 1...steps {
                    let t=Double(i)/Double(steps)
                    let c=1-t
                    v.x=((c*c*start.x)+(2*t*c*cp.x)+(t*t*end.x))
                    v.y=((c*c*start.y)+(2*t*c*cp.y)+(t*t*end.y))
                    contour.vertices.append(Contour.Vertice(pos:v))
                    bb = bb.union(Point(v.x,v.y))
                }
                break
            case PathSegment.cubic_TO:
                let sc=s as! SegmentCubic
                let start=v
                let cp1 = rel ? (v+sc.p[0]) : Vec3(sc.p[0])
                let cp2 = rel ? (v+sc.p[1]) : Vec3(sc.p[1])
                let end = rel ? (v+sc.p[2]) : Vec3(sc.p[2])
                for i in 1...steps {
                    let t=Double(i)/Double(steps)
                    let c=1-t
                    v.x=((start.x*c*c*c)+(cp1.x*3*t*c*c)+(cp2.x*3*t*t*c)+end.x*t*t*t);
                    v.y=((start.y*c*c*c)+(cp1.y*3*t*c*c)+(cp2.y*3*t*t*c)+end.y*t*t*t);
                    contour.vertices.append(Contour.Vertice(pos:v))
                    bb = bb.union(Point(v.x,v.y))
                }
                break
            default:
                Debug.notImplemented()
                break
            }
        }
        points.append(contour)
        if paint.mode == .fill {
            if let renderer=renderer, renderer.uv == .boundingBox {
                let s = renderer.scale(bb)/bb.size
                let o = renderer.offset(bb)
                for c in 0..<points.count {
                    for v in 0..<points[c].vertices.count {
                        points[c].vertices[v].uv = (Point(points[c].vertices[v].position)-bb.origin)*s+o
                    }
                }
            }
            return points
        }
        if let renderer=renderer, renderer.uv == .trace {
            for c in 0..<points.count {
                var d = 0.0
                var lv = points[c].vertices[0].position
                for v in 1..<points[c].vertices.count {
                    let dd = points[c].vertices[v].position-lv
                    d += dd.length
                    points[c].vertices[v].uv = Point(d,0)
                    lv = points[c].vertices[v].position
                }
                let di = 1 / d
                for v in 0..<points[c].vertices.count {
                    points[c].vertices[v].uv = Point(points[c].vertices[v].uv.x*di,0)
                }
            }
        }
        var stroke=[Contour]()  // TODO: add anti-aliasing  http://hhoppe.com/overdraw.pdf
        for c in points {
            var cs = Contour()
            var inv = Contour()
            var dv=Vec3()
            for i in 0..<c.vertices.count-1 {
                let v=c.vertices[i]
                let nv=c.vertices[i+1]
                dv = (nv.position - v.position).normalized * paint.strokeWidth * 0.5
                cs.vertices.append(Contour.Vertice(pos:v.position+Vec3(x:dv.y,y:-dv.x,z:0),uv:Point(v.uv.x,0)))
                inv.vertices.append(Contour.Vertice(pos:v.position+Vec3(x:-dv.y,y:dv.x,z:0),uv:Point(v.uv.x,1)))
            }
            let v=c.vertices[c.vertices.count-1]
            cs.vertices.append(Contour.Vertice(pos:v.position+Vec3(x:dv.y,y:-dv.x,z:0),uv:Point(1,0)))
            inv.vertices.append(Contour.Vertice(pos:v.position+Vec3(x:-dv.y,y:dv.x,z:0),uv:Point(1,1)))
            if c.closed {
                var i=inv.vertices.count-1
                while i>=0 {
                    cs.vertices.append(inv.vertices[i])
                    i -= 1
                }
                stroke.append(cs)
            } else {
                stroke.append(cs)
                cs=Contour()
                cs.vertices.append(contentsOf: inv.vertices)
                stroke.append(cs)
            }
        }
        if let renderer=renderer, renderer.uv == .boundingBox {
            let s = renderer.scale(bb)/bb.size
            let o = renderer.offset(bb)
            for c in 0..<stroke.count {
                for v in 0..<stroke[c].vertices.count {
                    stroke[c].vertices[v].uv = (Point(stroke[c].vertices[v].position)-bb.origin)*s+o
                }
            }
        }
        return stroke
    }

    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /*
     public bool Contains(PointF p)	// raycasting algo https://en.wikipedia.org/wiki/Point_in_polygon
     {
     if(this.Bounds.Contains(p)) {
     var vects=this.VectorList(3);
     var lv=vects[0];
     var ld=Math.Sign(lv.Y-p.Y);
     int ncount=0;
     for(int i=1; i<vects.Length; i++) {
     var v=vects[i];
     var d=Math.Sign(v.Y-p.Y);
     if(d!=ld&&(v.X<p.X||lv.X<p.X)) {
     ncount++;
     if(d==0)
     d=-ld;
     }
     ld=d;
     lv=v;
     }
     return (ncount&1)==1;   // ncount odd (impair)
     }
     return false;
     }
     */
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /*
     public RectangleF Bounds {	// compute bounding box
     get {
     if(bounds==RectangleF.Empty) {
     var vects=this.VectorList(2);
     var min=vects[0];
     var max=vects[0];
     foreach(var v in vects) {
     if(v.X<min.X)
     min.X=v.X;
     if(v.X>max.X)
     max.X=v.X;
     if(v.Y<min.Y)
     min.Y=v.Y;
     if(v.Y>max.Y)
     max.Y=v.Y;
     }
     bounds=new RectangleF(min.X,min.Y,max.X-min.X,max.Y-min.Y);
     }
     return bounds;
     }
     }
     */
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class Segment  {
        var cmd:PathCommand
        public init(_ command:PathCommand) {
            self.cmd=command
        }
        public static func close() -> Segment {
            return Segment(PathCommand.CLOSE_PATH)
        }
        public static func moveTo(_ x:Double,_ y:Double) -> Segment {
            return SegmentPoint(PathCommand.MOVE_TO_ABS,x,y)
        }
        public static func moveTo(_ p:Point) -> Segment {
            return SegmentPoint(PathCommand.MOVE_TO_ABS,p)
        }
        public static func moveRel(_ x:Double,_ y:Double) -> Segment {
            return SegmentPoint(PathCommand.MOVE_TO_REL,x,y)
        }
        public static func moveRel(_ p:Point) -> Segment {
            return SegmentPoint(PathCommand.MOVE_TO_REL,p)
        }
        public static func lineTo(_ x:Double,_ y:Double) -> Segment {
            return SegmentPoint(PathCommand.LINE_TO_ABS,x,y)
        }
        public static func lineTo(_ p:Point) -> Segment {
            return SegmentPoint(PathCommand.LINE_TO_ABS,p)
        }
        public static func lineRel(_ x:Double,_ y:Double) -> Segment {
            return SegmentPoint(PathCommand.LINE_TO_REL,x,y)
        }
        public static func lineRel(_ p:Point) -> Segment {
            return SegmentPoint(PathCommand.LINE_TO_REL,p)
        }
        public static func quadTo(_ x0:Double,y0:Double,x1:Double,y1:Double) -> Segment {
            return SegmentQuad(PathCommand.QUAD_TO_ABS,x0,y0,x1,y1)
        }
        public static func quadTo(_ p0:Point,_ p1:Point) -> Segment {
            return SegmentQuad(PathCommand.QUAD_TO_ABS,p0,p1)
        }
        public static func quadRel(_ x0:Double,y0:Double,x1:Double,y1:Double) -> Segment {
            return SegmentQuad(PathCommand.QUAD_TO_REL,x0,y0,x1,y1)
        }
        public static func quadRel(_ p0:Point,_ p1:Point) -> Segment {
            return SegmentQuad(PathCommand.QUAD_TO_REL,p0,p1)
        }
        public static func cubicTo(_ x0:Double,y0:Double,x1:Double,y1:Double,x2:Double,x3:Double) -> Segment {
            return SegmentCubic(PathCommand.CUBIC_TO_ABS,x0,y0,x1,y1,x2,x3)
        }
        public static func cubicTo(_ p0:Point,_ p1:Point,_ p2:Point) -> Segment {
            return SegmentCubic(PathCommand.CUBIC_TO_ABS,p0,p1,p2)
        }
        public static func cubicRel(_ x0:Double,y0:Double,x1:Double,y1:Double,x2:Double,x3:Double) -> Segment {
            return SegmentCubic(PathCommand.CUBIC_TO_REL,x0,y0,x1,y1,x2,x3)
        }
        public static func cubicRel(_ p0:Point,_ p1:Point,_ p2:Point) -> Segment {
            return SegmentCubic(PathCommand.CUBIC_TO_REL,p0,p1,p2)
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class SegmentPoint : Segment {
        public private(set) var p:Point
        public init(_ cmd:PathCommand,_ p:Point) {
            self.p = p
            super.init(cmd)
        }
        public init(_ cmd:PathCommand,_ x:Double,_ y:Double) {
            self.p=Point(x,y)
            super.init(cmd)
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class SegmentQuad : Segment {
        public private(set) var p=[Point]()
        public init(_ cmd:PathCommand,_ p0:Point,_ p1:Point) {
            super.init(cmd)
            p=[p0,p1]
        }
        public init(_ cmd:PathCommand,_ x0:Double,_ y0:Double,_ x1:Double,_ y1:Double) {
            super.init(cmd)
            p=[Point(x0,y0),Point(x1,y1)]
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class SegmentCubic : Segment {
        public private(set) var p=[Point]()
        public init(_ cmd:PathCommand,_ p0:Point,_ p1:Point,_ p2:Point) {
            super.init(cmd)
            p=[p0,p1,p2]
        }
        public init(_ cmd:PathCommand,_ x0:Double,_ y0:Double,_ x1:Double,_ y1:Double,_ x2:Double,_ y2:Double) {
            super.init(cmd)
            p=[Point(x0,y0),Point(x1,y1),Point(x2,y2)]
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    enum PathAbsRel : Int
    {
        case absolute=0
        case relative=1
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    enum PathSegment : Int {
        case close_PATH = 0
        case move_TO = 2
        case line_TO = 4
        case hline_TO = 6
        case vline_TO = 8
        case quad_TO = 10
        case cubic_TO = 12
        case squad_TO = 14
        case scubic_TO = 16
        case sccwarc_TO = 18
        case scwarc_TO = 20
        case lccwarc_TO = 22
        case lcwarc_TO = 24
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public struct PathCommand
    {
        public private(set) var rawValue : Int
        public init(rawValue:Int) {
            self.rawValue=rawValue
        }
        static var CLOSE_PATH : PathCommand { return PathCommand(rawValue:PathSegment.close_PATH.rawValue)}
        static var MOVE_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.move_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var MOVE_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.move_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var LINE_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.line_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var LINE_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.line_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var HLINE_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.hline_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var HLINE_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.hline_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var VLINE_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.vline_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var VLINE_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.vline_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var QUAD_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.quad_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var QUAD_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.quad_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var CUBIC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.cubic_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var CUBIC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.cubic_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var SQUAD_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.squad_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var SQUAD_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.squad_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var SCUBIC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.scubic_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var SCUBIC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.scubic_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var SCCWARC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.sccwarc_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var SCCWARC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.sccwarc_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var SCWARC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.scwarc_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var SCWARC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.scwarc_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var LCCWARC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.lccwarc_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var LCCWARC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.lccwarc_TO.rawValue|PathAbsRel.relative.rawValue)}
        static var LCWARC_TO_ABS : PathCommand { return PathCommand(rawValue:PathSegment.lcwarc_TO.rawValue|PathAbsRel.absolute.rawValue)}
        static var LCWARC_TO_REL : PathCommand { return PathCommand(rawValue:PathSegment.lcwarc_TO.rawValue|PathAbsRel.relative.rawValue)}
    }
    /*
     public func ==(lhs: PathCommand, rhs: PathCommand) -> Bool {
     return lhs.rawValue == rhs.rawValue
     }
     */
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
