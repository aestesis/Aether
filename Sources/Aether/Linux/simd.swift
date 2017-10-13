//
//  simd.swift (linux)
//  Aether
//
//  Created by renan jegouzo on 10/10/2017.
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

// TODO: https://gcc.gnu.org/onlinedocs/gcc/Vector-Extensions.html

public struct float2 {
    public var x:Float
    public var y:Float
    public init() {
        x=0
        y=0
    }
    public init(_ x:Float,_ y:Float) {
        self.x=x
        self.y=y
    }
    public init(x:Float,y:Float) {
        self.x=x
        self.y=y
    }
    public init(_ scalar:Float) {
        self.x=scalar
        self.y=scalar
    }
    public init(_ array:[Float]) {
        self.x=array[0]
        self.y=array[1]
    }
    public subscript(index:Int) -> Float {
        switch index {
            case 0:
            return x
            case 1:
            return y
            default:
            return 0
        }
    }
}

public struct float3 {
    public var x:Float
    public var y:Float
    public var z:Float
    public init() {
        x=0
        y=0
        z=0
    }
    public init(_ x:Float,_ y:Float,_ z:Float) {
        self.x=x
        self.y=y
        self.z=z
    }
    public init(x:Float,y:Float,z:Float) {
        self.x=x
        self.y=y
        self.z=z
    }
    public init(_ scalar:Float) {
        self.x=scalar
        self.y=scalar
        self.z=scalar
    }
    public init(_ array:[Float]) {
        self.x=array[0]
        self.y=array[1]
        self.z=array[2]
    }
    public subscript(index:Int) -> Float {
        switch index {
            case 0:
            return x
            case 1:
            return y
            case 2:
            return z
            default:
            return 0
        }
    }
}

public struct float4 {
    public var x:Float
    public var y:Float
    public var z:Float
    public var w:Float
    public init() {
        x=0
        y=0
        z=0
        w=0
    }
    public init(_ x:Float,_ y:Float,_ z:Float,_ w:Float) {
        self.x=x
        self.y=y
        self.z=z
        self.w=w
    }
    public init(x:Float,y:Float,z:Float,w:Float) {
        self.x=x
        self.y=y
        self.z=z
        self.w=w
    }
    public init(_ scalar:Float) {
        self.x=scalar
        self.y=scalar
        self.z=scalar
        self.w=scalar
    }
    public init(_ array:[Float]) {
        self.x=array[0]
        self.y=array[1]
        self.z=array[2]
        self.w=array[3]
    }
    public subscript(index:Int) -> Float {
        switch index {
            case 0:
            return x
            case 1:
            return y
            case 2:
            return z
            case 3:
            return w
            default:
            return 0
        }
    }
}

public struct float3x3 {
    public var columns=(float3(0),float3(0),float3(0))
    public init(_ scalar:Float) {
        columns.0=float3(scalar)
        columns.1=float3(scalar)
        columns.2=float3(scalar)
    }
    public init(diagonal d:float3) {
        columns=(float3(d.x,0,0),float3(0,d.y,0),float3(0,0,d.z))
    }
    public init(_ columns:[float3]) {
        self.columns.0=columns[0]
        self.columns.1=columns[1]
        self.columns.2=columns[2]
    }
}

public struct float4x4 {
    public var columns=(float4(0),float4(0),float4(0),float4(0))
    public init(_ scalar:Float) {
        columns=(float4(scalar),float4(scalar),float4(scalar),float4(scalar))
    }
    public init(diagonal d:float4) {
        columns=(float4(d.x,0,0,0),float4(0,d.y,0,0),float4(0,0,d.z,0),float4(0,0,0,d.w))
    }
    public init(_ columns:[float4]) {
        self.columns.0=columns[0]
        self.columns.1=columns[1]
        self.columns.2=columns[2]
        self.columns.3=columns[3]
    }
}

public struct double4x4 {
    public var columns=(double4(0),double4(0),double4(0),double4(0))
    public init(_ scalar:Double) {
        columns=(double4(scalar),double4(scalar),double4(scalar),double4(scalar))
    }
    public init(diagonal d:double4) {
        columns=(double4(d.x,0,0,0),double4(0,d.y,0,0),double4(0,0,d.z,0),double4(0,0,0,d.w))
    }
    public init(_ columns:[double4]) {
        self.columns.0=columns[0]
        self.columns.1=columns[1]
        self.columns.2=columns[2]
        self.columns.3=columns[3]
    }
}

public struct double2 {
    public var x:Double
    public var y:Double
    public init() {
        x=0
        y=0
    }
    public init(_ x:Double,_ y:Double) {
        self.x=x
        self.y=y
    }
    public init(x:Double,y:Double) {
        self.x=x
        self.y=y
    }
    public init(_ scalar:Double) {
        self.x=scalar
        self.y=scalar
    }
    public init(_ array:[Double]) {
        self.x=array[0]
        self.y=array[1]
    }
    public subscript(index:Int) -> Double {
        switch index {
            case 0:
            return x
            case 1:
            return y
            default:
            return 0
        }
    }
}

public struct double3 {
    public var x:Double
    public var y:Double
    public var z:Double
    public init() {
        x=0
        y=0
        z=0
    }
    public init(_ x:Double,_ y:Double,_ z:Double) {
        self.x=x
        self.y=y
        self.z=z
    }
    public init(x:Double,y:Double,z:Double) {
        self.x=x
        self.y=y
        self.z=z
    }
    public init(_ scalar:Double) {
        self.x=scalar
        self.y=scalar
        self.z=scalar
    }
    public init(_ array:[Double]) {
        self.x=array[0]
        self.y=array[1]
        self.z=array[2]
    }
    public subscript(index:Int) -> Double {
        switch index {
            case 0:
            return x
            case 1:
            return y
            case 2:
            return z
            default:
            return 0
        }
    }
}

public struct double4 {
    public var x:Double
    public var y:Double
    public var z:Double
    public var w:Double
    public init() {
        x=0
        y=0
        z=0
        w=0
    }
    public init(_ x:Double,_ y:Double,_ z:Double,_ w:Double) {
        self.x=x
        self.y=y
        self.z=z
        self.w=w
    }
    public init(x:Double,y:Double,z:Double,w:Double) {
        self.x=x
        self.y=y
        self.z=z
        self.w=w
    }
    public init(_ scalar:Double) {
        self.x=scalar
        self.y=scalar
        self.z=scalar
        self.w=scalar
    }
    public init(_ array:[Double]) {
        self.x=array[0]
        self.y=array[1]
        self.z=array[2]
        self.w=array[3]
    }
    public subscript(index:Int) -> Double {
        switch index {
            case 0:
            return x
            case 1:
            return y
            case 2:
            return z
            case 3:
            return w
            default:
            return 0
        }
    }
}


