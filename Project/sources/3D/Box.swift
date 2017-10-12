//
//  Box.swift
//  Alib
//
//  Created by renan jegouzo on 08/06/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Attenuation {
    public var constant:Double
    public var linear:Double
    public var quadratic:Double
    public init(constant:Double=0,linear:Double=0,quadratic:Double=0) {
        self.constant = constant
        self.linear = linear
        self.quadratic = quadratic
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Rot3 {
    public var phi:Double
    public var theta:Double
    public init(phi:Double=0,theta:Double=0) {
        self.phi = phi
        self.theta = theta
    }
    public func lerp(to:Rot3,coef:Double) -> Rot3 {
        return Rot3(phi:Rot3.lerpModulo(a:self.phi,b:to.phi,coef:coef),theta:Rot3.lerpModulo(a:self.theta,b:to.theta,coef:coef))
    }
    public var modulo : Rot3 {
        return Rot3(phi:Rot3.modulo(self.phi),theta:Rot3.modulo(self.theta))
    }
    public var matrix : Mat4 {
        return Mat4.rotZ(phi)*Mat4.rotX(theta)  // TODO: not sure, need to be tested...
    }
    public static var random : Rot3 {
        return Rot3(phi:ß.rnd*ß.π*2,theta:ß.rnd*ß.π*2)
    }
    static let pi2 = ß.π*2
    static func modulo(_ a:Double) -> Double {
        return ß.modulo(a,Rot3.pi2)
    }
    static func lerpModulo(a:Double,b:Double,coef:Double) -> Double {
        let ma = Rot3.modulo(a)
        let mb = Rot3.modulo(b)
        let sub = mb - ß.π*2
        let sup = mb + ß.π*2
        let dif = abs(mb-ma)
        if ma-sub<dif {
            return Rot3.modulo(sub*coef + ma*(1-coef))
        } else if sup-ma<dif {
            return Rot3.modulo(sup*coef + ma*(1-coef))
        }
        return mb*coef + ma*(1-coef)
    }
}
public func ==(a: Rot3, b: Rot3) -> Bool {
    return a.phi == b.phi && a.theta == b.theta
}
public func !=(a: Rot3, b: Rot3) -> Bool {
    return a.phi != b.phi || a.theta != b.theta
}
public prefix func - (v: Rot3) -> Rot3 {
    return Rot3(phi:-v.phi,theta:-v.theta)
}
public func +(a:Rot3,b:Rot3)->Rot3 {
    return Rot3(phi:a.phi+b.phi,theta:a.theta+b.theta)
}
public func -(a:Rot3,b:Rot3)->Rot3 {
    return Rot3(phi:a.phi-b.phi,theta:a.theta-b.theta)
}
public func +(a:Rot3,b:Double)->Rot3 {
    return Rot3(phi:a.phi+b,theta:a.theta+b)
}
public func -(a:Rot3,b:Double)->Rot3 {
    return Rot3(phi:a.phi-b,theta:a.theta-b)
}
public func *(a:Rot3,b:Rot3)->Rot3 {
    return Rot3(phi:a.phi*b.phi,theta:a.theta*b.theta)
}
public func *(a:Rot3,b:Double)->Rot3 {
    return Rot3(phi:a.phi*b,theta:a.theta*b)
}
public func /(a:Rot3,b:Rot3)->Rot3 {
    return Rot3(phi:a.phi/b.phi,theta:a.theta/b.theta)
}
public func /(a:Rot3,b:Double)->Rot3 {
    return Rot3(phi:a.phi/b,theta:a.theta/b)
}
public func +=(a:inout Rot3,b:Rot3) {
    a = a + b
}
public func -=(a:inout Rot3,b:Rot3) {
    a = a - b
}
public func +=(a:inout Rot3,b:Double) {
    a = a + b
}
public func -=(a:inout Rot3,b:Double) {
    a = a - b
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// http://www.sedris.org/wg8home/Documents/WG80485.pdf
public struct Euler { // Tait–Bryan angles
    public var pitch:Double
    public var roll:Double
    public var yaw:Double
    public var matrix : Mat4 {
        let cp = cos(pitch)
        let sp = sin(pitch)
        let cr = cos(roll)
        let sr = sin(roll)
        let cy = cos(yaw)
        let sy = sin(yaw)
        return Mat4(r0:Vec4(x:cp*cy,y:cp*sy,z:-sp),
                     r1:Vec4(x:sr*sp*cy,y:sr*sp*sy,z:cp*sr),
                     r2:Vec4(x:cr*sp*cy,y:cr*sp*sy,z:cp*cr),
                     r3:Vec4(w:1))
        // aka -> return Mat4.rotZ(yaw)*Mat4.rotY(pitch)*Mat4.rotX(roll)
    }
    public init(pitch:Double=0,roll:Double=0,yaw:Double=0) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
    public init(_ q:Quaternion) {
        let ysqr = q.y * q.y
        // roll (x-axis)
        let t0 = 2.0 * (q.w * q.x + q.y * q.z)
        let t1 = 1.0 - 2.0 * (q.x * q.x + ysqr)
        roll = atan2(t0,t1)
        // pitch (y-axis)
        var t2 = 2.0 * (q.w * q.y - q.z * q.x)
        t2 = ((t2 > 1.0) ? 1.0 : t2)
        t2 = ((t2 < -1.0) ? -1.0 : t2)
        pitch = asin(t2)
        // yaw (z-axis)
        let t3 = 2.0 * (q.w * q.z + q.x * q.y)
        let t4 = 1.0 - 2.0 * (ysqr + q.z * q.z)
        yaw = atan2(t3,t4)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// https://github.com/mono/opentk/blob/master/Source/OpenTK/Math/Quaternion.cs
public struct Quaternion {
    var q:Vec4
    public var x: Double {
        get { return q.x }
        set(x){ q.x=x }
    }
    public var y: Double {
        get { return q.y }
        set(y){ q.y=y }
    }
    public var z: Double {
        get { return q.z }
        set(z){ q.z=z }
    }
    public var w: Double {
        get { return q.w }
        set(w){ q.w=w }
    }
    public var xyz:Vec3 {
        get { return q.xyz }
        set(xyz) { q.xyz=xyz }
    }
    public var axisAngle : Vec4 {
        var q=self.q
        if(abs(q.w)>1) {
            q=q.normalized
        }
        var r=Vec4.zero
        r.w = 2.0 * acos(q.w)
        let den = sqrt(1-q.w*q.w)
        if den>0.0001 {
             r.xyz = q.xyz/den
        } else {
            r.xyz = Vec3(x:1)
        }
        return r
    }
    public var conjugated : Quaternion {
        return Quaternion(xyz:-q.xyz,w:q.w)
    }
    public var lenght : Double {
        return q.length
    }
    public func lerp(to:Quaternion,coef:Double) -> Quaternion { // TODO: verify if OK
        var q1 = self
        var q2 = to
        if self.lenght == 0 {
            if to.lenght == 0 {
                return Quaternion.identity
            }
            return to
        } else if to.lenght == 0 {
            return self
        }
        var cosHalfAngle = q1.w*q2.w+Vec3.dot(q1.xyz,q2.xyz)
        if cosHalfAngle >= 1 || cosHalfAngle <= -1 {
            return self
        } else if cosHalfAngle<0 {
            q2 = -q2
            cosHalfAngle = -cosHalfAngle
        }
        if cosHalfAngle<0.99 {
            let halfAngle = acos(cosHalfAngle)
            let sinHalfAngle=sin(halfAngle)
            let oneOverSinHalfAngle=1/sinHalfAngle
            let a = sin(halfAngle*(1-coef))*oneOverSinHalfAngle
            let b = sin(halfAngle*coef)*oneOverSinHalfAngle
            let q = q1 * a + q2 * b
            if q.lenght>0 {
                return q.normalized
            }
            return Quaternion.identity
        }
        let q = q1 * (1-coef) + q2 * coef
        if q.lenght>0 {
            return q.normalized
        }
        return Quaternion.identity
    }
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/
    public var matrix : Mat4 {
        return Mat4(r0: Vec4(x:1-2*y*y-2*z*z,
                             y:2*x*y-2*z*w,
                             z:2*x*z+2*y*w),
                    r1: Vec4(x:2*x*y+2*z*w,
                             y:1-2*x*x-2*z*z,
                             z:2*y*z-2*x*w),
                    r2: Vec4(x:2*x*z-2*y*w,
                             y:2*y*z+2*x*w,
                             z:1-2*x*x-2*y*y),
                    r3: Vec4(w:1))
    }
    public var normalized : Quaternion {
        return Quaternion(q.normalized)
    }
    public init(_ v:Vec4) {
        self.q=v
    }
    public init(x:Double=0,y:Double=0,z:Double=0,w:Double=0) {
        q=Vec4(x:x,y:y,z:z,w:w)
    }
    public init(_ xyz:Vec3,_ w:Double) {
        q = Vec4(xyz:xyz,w:w)
    }
    public init(xyz:Vec3,w:Double) {
        q = Vec4(xyz:xyz,w:w)
    }
    public init(axis:Vec3,angle:Double) {
        if axis.length > 0 {
            let a = angle*0.5
            self.q = Vec4(xyz:axis.normalized*sin(a),w:cos(a)).normalized
        } else {
            self.q = Quaternion.identity.q
        }
    }
    public init(_ e:Euler) {
        let cy = cos(e.yaw*0.5)
        let sy = sin(e.yaw*0.5)
        let cr = cos(e.roll*0.5)
        let sr = sin(e.roll*0.5)
        let cp = cos(e.pitch*0.5)
        let sp = sin(e.pitch*0.5)
        q=Vec4(x:cy * sr * cp - sy * cr * sp,
               y:cy * cr * sp + sy * sr * cp,
               z:sy * cr * cp - cy * sr * sp,
               w:cy * cr * cp + sy * sr * sp)
    }
    public static var identity : Quaternion {
        return Quaternion(xyz:.zero,w:1)
    }
}
public func ==(a: Quaternion, b: Quaternion) -> Bool {
    return a.x==b.x&&a.y==b.y&&a.z==b.z&&a.w==b.w
}
public func !=(a: Quaternion, b: Quaternion) -> Bool {
    return a.x != b.x || a.y != b.y || a.z != b.z || a.w != b.w
}
public prefix func - (v: Quaternion) -> Quaternion {
    return Quaternion(x:-v.x,y:-v.y,z:-v.z,w:-v.w)
}
public func +(a:Quaternion,b:Quaternion)->Quaternion {
    return Quaternion(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z,w:a.w+b.w)
}
public func -(a:Quaternion,b:Quaternion)->Quaternion {
    return Quaternion(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z,w:a.w-b.w)
}
public func *(q:Quaternion,r:Quaternion)->Quaternion {
    return Quaternion(x:r.x*q.x-r.y*q.y-r.z*q.z-r.w*q.w,
                      y:r.x*q.y+r.y*q.x-r.z*q.w+r.w*q.z,
                      z:r.x*q.z+r.y*q.w+r.z*q.x-r.w*q.y,
                      w:r.x*q.w-r.y*q.z+r.z*q.y+r.w*q.x)
}
public func *(a:Quaternion,b:Double)->Quaternion {
    return Quaternion(x:a.x*b,y:a.y*b,z:a.z*b,w:a.w*b)
}
public func /(q:Quaternion,r:Quaternion)->Quaternion {
    let m = q*r
    let d = r.x*r.x+r.y*r.y+r.z*r.z+r.w*r.w
    return Quaternion(x:m.x/d,y:m.y/d,z:m.z/d,w:m.w/d)
}
public func /(a:Quaternion,b:Double)->Quaternion {
    return Quaternion(x:a.x/b,y:a.y/b,z:a.z/b,w:a.w/b)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Sphere {
    public var center:Vec3
    public var radius:Double
    public init(bounding box:Box) {
        self.center = box.origin.lerp(vector:box.opposite,coef:0.5)
        self.radius = (box.opposite-box.origin).length*0.5
    }
    public init(center:Vec3=Vec3.zero,radius:Double=1) {
        self.center = center
        self.radius = radius
    }
    public static var unity : Sphere {
        return Sphere()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Cylinder {
    public var center:Vec3
    public var direction:Vec3
    public var radius:Double
    public init(center:Vec3=Vec3.zero,direction:Vec3=Vec3(y:1),radius:Double=1) {
        self.center = center
        self.direction = direction
        self.radius = radius
    }
    public init(base:Vec3,direction:Vec3=Vec3(y:1),radius:Double=1) {
        self.center = base + direction * 0.5
        self.direction = direction
        self.radius = radius
    }
    public static var unity : Cylinder {
        return Cylinder()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct Box {
    public var origin : Vec3
    public var size: Vec3
    public var x: Double {
        get { return origin.x }
        set(x){ origin.x=x }
    }
    public var y: Double {
        get { return origin.y }
        set(y){ origin.y=y }
    }
    public var z: Double {
        get { return origin.z }
        set(z){ origin.z=z }
    }
    public var w: Double {
        get { return size.x }
        set(width){ size.x=width }
    }
    public var h: Double {
        get { return size.y }
        set(height){ size.y=height }
    }
    public var d: Double {
        get { return size.z }
        set(depth){ size.z=depth }
    }
    public var width: Double {
        get { return size.x }
        set(width){ size.x=width }
    }
    public var height: Double {
        get { return size.y }
        set(height){ size.y=height }
    }
    public var depth: Double {
        get { return size.z }
        set(depth){ size.z=depth }
    }
    public var left: Double {
        get { return x }
        set(l) { w+=x-l; x=l }
    }
    public var right: Double {
        get { return x+width }
        set(r) { width=r-x }
    }
    public var top: Double {
        get { return y }
        set(t) { h+=y-t; y=t }
    }
    public var bottom: Double {
        get { return y+h }
        set(b) { h=b-y }
    }
    public var front: Double {
        get { return z }
        set(t) { d+=z-t; z=t }
    }
    public var back: Double {
        get { return z+d }
        set(t) { depth=t-z }
    }
    public var opposite : Vec3 {
        return origin+size
    }
    public var center : Vec3 {
        return origin + size * 0.5
    }
    public func point(_ px:Double,_ py:Double,_ pz:Double) -> Vec3 {
        return Vec3(x:x+width*px,y:y+height*py,z:z+depth*pz)
    }
    public var diagonale : Double {
        return sqrt(width*width+height*height+depth*depth)
    }
    public var random : Vec3 {
        return Vec3(x:x+width*ß.rnd,y:y+height*ß.rnd,z:z+depth*ß.rnd)
    }
    public func union(_ r:Box) -> Box {
        if self == Box.zero {
            return r
        } else if r == Box.zero {
            return self
        } else {
            var rr = Box.zero
            rr.left = min(self.left,r.left)
            rr.right = max(self.right,r.right)
            rr.top = min(self.top,r.top)
            rr.bottom = max(self.bottom,r.bottom)
            rr.front = min(self.front,r.front)
            rr.back = max(self.back,r.back)
            return rr
        }
    }
    public func union(_ o:Vec3,_ s:Vec3=Vec3.zero) -> Box {
        return self.union(Box(o:o,s:s))
    }
    public func wrap(_ p:Vec3) -> Vec3 {
        return Vec3(x:ß.modulo(p.x-left,width)+left,y:ß.modulo(p.y-top,height)+top,z:ß.modulo(p.z-front,depth)+front)
    }
    public init(origin:Vec3,size:Vec3) {
        self.origin=origin
        self.size=size
    }
    public init(o:Vec3,s:Vec3) {
        self.origin=o
        self.size=s
    }
    public init(x:Double=0,y:Double=0,z:Double=0,w:Double=0,h:Double=0,d:Double=0)
    {
        origin=Vec3(x:x,y:y,z:z)
        size=Vec3(x:w,y:h,z:d)
    }
    public init(center:Vec3,size:Vec3)
    {
        self.origin=center-size*0.5
        self.size=size
    }
    public static var zero: Box {
        return Box(o:Vec3.zero,s:Vec3.zero)
    }
    public static var infinity: Box {
        return Box(o:-Vec3.infinity,s:Vec3.infinity)
    }
    public static var unity: Box {
        return Box(o:Vec3.zero,s:Vec3(x:1,y:1,z:1))
    }
    
}
public func ==(lhs: Box, rhs: Box) -> Bool {
    return (lhs.origin==rhs.origin)&&(lhs.size==rhs.size)
}
public func !=(lhs: Box, rhs: Box) -> Bool {
    return (lhs.origin != rhs.origin)||(lhs.size != rhs.size)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
