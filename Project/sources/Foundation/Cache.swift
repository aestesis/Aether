//
//  Cache.swift
//  Alib
//
//  Created by renan jegouzo on 28/01/2017.
//  Copyright © 2017 aestesis. All rights reserved.
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

public class Cache : NodeUI {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public var capacity:Int
    var pulse:Future?=nil
    var lock=Lock()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent:NodeUI,capacity:Int=100) {
        self.capacity = capacity
        super.init(parent:parent)
        pulse=viewport!.pulse(1) {
            if self.prop.count>capacity*4/3 {
                self.lock.synced {
                    let psort = self.prop.map({ k,v -> (time:Double,key:String) in
                        let p = v as! Property
                        if let t = p["time"] as? Double {
                            return (time:t,key:k)
                        } else {
                            return (time:0,key:k)
                        }
                    }).sorted(by: { a,b -> Bool in
                        return a.time > b.time
                    })
                    for i in capacity..<psort.count {
                        let k = psort[i].key
                        if let p = self.prop[k] as? Property {
                            p.detach()
                            self.prop.removeValue(forKey: k)
                        }
                    }
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override public func detach() {
        if let p=pulse {
            p.cancel()
            pulse = nil
        }
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public override subscript(k:String) -> Any? {
        get {
            var v:Any?=nil
            lock.synced {
                v = prop[k]
                if let p=v as? Property {
                    p["time"] = ß.time
                }
            }
            if let v=v {
                if let p = v as? Property {
                    return p.value
                }
                return v
            }
            if let p=parent {
                return p[k]
            }
            return nil
        }
        set(v) {
            lock.synced {
                let p = prop[k]
                if let p=p as? Node {
                    if let p = p as? Property {
                        p["time"] = ß.time
                        p.value = v
                        return
                    } else if let pv = v as? Node {
                        if pv != p {
                            p.detach()
                        }
                    } else {
                        p.detach()
                    }
                }
                if let v = v {
                    let p = Property(value:v)
                    p["time"] = ß.time
                    prop[k]=p
                } else {
                    Debug.error("must not happening!!")
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
