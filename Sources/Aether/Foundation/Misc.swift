//
//  Misc.swift
//  Aether
//
//  Created by renan jegouzo on 22/02/2016.
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
import SwiftyJSON


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class ß : Misc {
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Misc {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static func find(file:String) -> String? {
        let fm = FileManager.default
        var path:String? = fm.currentDirectoryPath 
        while path != nil {
            do {
                let files = try fm.contentsOfDirectory(atPath: path!)
                if files.contains(file) {
                    return "\(path!)/\(file)"
                }
            } catch _ {
            }
            path = path?.parentPath 
        }
        return nil
    }
    public static var alphaID:String {
        let data:String="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        var id:String="";
        for _ in 1...12 {
            #if os(macOS) || os(iOS) || os(tvOS)
                let n:Int=Int(arc4random_uniform(UInt32(UInt(data.characters.count))))
            #else
                let n:Int=Int(rand())%data.characters.count
            #endif
            id+=data[n];
        }
        return id;
    }
    public static func daysHoursMinutesSeconds(_ seconds:Int) -> (d:Int,h:Int,m:Int,s:Int) {
        var s=seconds
        let d:Int=s/(60*60*24)
        s -= d * 60*60*24
        let h:Int = s/(60*60)
        s -= h * 60*60
        let m:Int = s/60
        s -= m*60
        return (d:d,h:h,m:m,s:s)
    }
    public static func nearest(array:[Double],value:Double) -> (index:Int,value:Double) {
        var dm = Double.greatestFiniteMagnitude
        var n = -1
        var i = 0
        for v in array {
            let d=abs(v-value)
            if d<dm {
                dm = d
                n = i
            }
            i += 1
        }
        if i>=0 {
            return (index:n,value:array[n])
        }
        return (index:-1,value:value)
    }
    public static func daysHoursMinutesSecondsInText(_ seconds:Int) -> String {
        let t=ß.daysHoursMinutesSeconds(seconds)
        var r=""
        if t.d>0 {
            r += " \(t.d)d"
        }
        if t.h>0 {
            r += " \(t.h)h"
        }
        if t.m>0 {
            r += " \(t.m)m"
        }
        if t.s>0 && t.d == 0 {
            r += " \(t.s)s"
        }
        return r.trim()
    }
    public static var rnd:Double {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Double(arc4random_uniform(UInt32.max))/Double(UInt32.max)
        #else
            return Double(rand())/Double(RAND_MAX)
        #endif
    }
    public static var time:Double {
        return Double(Date.timeIntervalSinceReferenceDate)
    }
    public static var hour:String {
        let pub = DateFormatter()
        pub.dateFormat="HH:mm:ss"
        return pub.string(from: Date())
    }
    public static var hourMinutes:String {
        let pub = DateFormatter()
        pub.dateFormat="HH:mm"
        return pub.string(from: Date())
    }
    public static var date:String {
        let pub = DateFormatter()
        pub.locale = Locale(identifier:"en_US_POSIX")
        pub.dateFormat="yyyy-MM-dd'T'HH:mm:ssZ"
        return pub.string(from: Date())
        //return NSDate().description
    }
    public static func date(_ date:String) -> Date? {
        let pub = DateFormatter()
        pub.dateFormat="yyyy-MM-dd'T'HH:mm:ssZ"     // maybe: "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return pub.date(from: date)
    }
    public static var dateISO8601:String {
        let pub = ISO8601DateFormatter()
        return pub.string(from:Date())
    }
    public static func dateISO8601(_ date:String) -> Date? {
        let pub = ISO8601DateFormatter()
        return pub.date(from: date)
    }
    public static func hasFlag(_ value:Int,_ flag:Int) -> Bool {
        return (value & flag) == flag
    }
    public static func hasFlag(_ value:UInt,_ flag:UInt) -> Bool {
        return (value & flag) == flag
    }
    public static func lerp(array:[Double],coef:Double) -> Double {
        let nf = coef*Double(array.count)*0.9999999
        let n = Int(nf)
        let f = nf-Double(n)
        if n<array.count-1 {
            let v = array[n]
            let vn = array[n+1]
            return vn*f + v*(1-f)
        }
        return array.last!
    }
    public static func lerp(array:[Float],coef:Double) -> Float {
        let nf = coef*Double(array.count)*0.9999999
        let n = Int(nf)
        let f = nf-Double(n)
        if n<array.count-1 {
            let v = array[n]
            let vn = array[n+1]
            return Float(Double(vn)*f + Double(v)*(1-f))
        }
        return array.last!
    }
    public static func modulo(_ value:Int,_ mod:Int) -> Int {
        return ((value % mod) + mod) % mod
    }
    public static func modulo(_ value:Double,_ mod:Double) -> Double {
        return (value.truncatingRemainder(dividingBy: mod) + mod).truncatingRemainder(dividingBy: mod)
    }
    public static var π:Double {
        return Double.pi
    }
    public static var π2:Double {
        return Double.pi/2
    }
    public static var π4:Double {
        return Double.pi/4
    }
    public static func sign(_ a:Double) -> Double {
        if a == 0 {
            return 0
        }
        return a<0 ? -1 : 1
    }
    #if os(Linux) 
        public static let clocksPerSeconds = CLOCKS_PER_SEC
    #else
        public static let clocksPerSeconds = NSEC_PER_SEC
    #endif
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public protocol JsonConvertible {
    var json: JSON { get }
    init(json:JSON)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public extension Array {
    public mutating func push(_ newElement: Element) {
        self.append(newElement)
    }
    public mutating func pop() -> Element? {
        return self.removeLast()
    }
    public func peekAtStack() -> Element? {
        return self.last
    }
    public mutating func enqueue(_ newElement: Element) {
        self.append(newElement)
    }
    public mutating func dequeue() -> Element? {
        if count>0 {
            return self.remove(at: 0)
        } else {
            return nil
        }
    }
    public func peekAtQueue() -> Element? {
        return self.first
    }
    public mutating func appendIndex(_ e:Element) -> Index {
        let n = self.count
        self.append(e)
        return n
    }
}
public extension Array where Element : Equatable {
    public func contains(element e:Element) -> Bool {
        return self.contains(where: { ei in
            return e == ei
        })
    }
}
public extension String {
    public subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    public subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    public subscript (r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = characters.index(start, offsetBy: r.count)
        return String(self[start..<end])
    }
    public subscript (r: ClosedRange <Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = characters.index(start, offsetBy: r.count-1)
        return String(self[start...end])
    }
    public subscript (r: PartialRangeFrom<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = characters.index(startIndex, offsetBy: self.length-1)
        return String(self[start...end])
    }
    public subscript (r: PartialRangeThrough<Int>) -> String {
        let start = startIndex
        let end = characters.index(startIndex, offsetBy: min(r.upperBound,self.length-1))
        return String(self[start...end])
    }
    public subscript (r: PartialRangeUpTo<Int>) -> String {
        let start = startIndex
        let end = characters.index(startIndex, offsetBy: min(r.upperBound,self.length))
        return String(self[start..<end])
    }
    public var length:Int {
        return self.characters.count;
    }
    public func contains(_ s:String) -> Bool {
        return self.range(of:s) != nil
    }
    public func matches(_ pattern:String) -> [CountableRange<Int>] {
        var ranges=[CountableRange<Int>]()
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            ranges = regex.matches(in: self, options: [], range: NSMakeRange(0, self.characters.count)).map {CountableRange(Range($0.range)!)}
        } catch {
            ranges = []
        }
        return ranges
    }
    public func split(_ pattern:String) -> [String] {
        return self.components(separatedBy: pattern)
    }
    public func splitByEach(_ characters:String) -> [String] {
        let ch=CharacterSet(charactersIn: characters)
        return self.components(separatedBy: ch)
    }
    public func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    public func indexOf(_ s: String) -> Int? {
        if let r: Range<Index> = self.range(of: s) {
            return self.characters.distance(from: self.startIndex, to: r.lowerBound)
        }
        return nil
    }
    public func lastIndexOf(_ s: String) -> Int? {
        if let r: Range<Index> = self.range(of: s, options: .backwards) {
            return self.characters.distance(from: self.startIndex, to: r.lowerBound)
        }
        return nil
    }
    public var urlEncoded : String? {
        return self.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)
    }
    public var parentPath : String? {
        if self.length>1 {
            var s = self
            if s.last == "/" {
                s = s[0..<s.length-1]
            }
            if let i = s.lastIndexOf("/") {
                return s[0..<i]
            }
        }
        return nil
    }
}
public extension Float {
    public func string(_ fractionDigits:Int) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value:self)) ?? "\(self)"
    }
}
public extension Double {
    public func string(_ fractionDigits:Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value:self)) ?? "\(self)"
    }
}
public extension Date {
    /// Returns the amount of years from another date
    public func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    public func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    public func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    public func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    public func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    public func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    public func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
class QueueNode<T>  {
    var next:QueueNode?
    var value:T
    init(value:T) {
        self.value=value
    }
}
public struct Queue<T> {
    typealias Node = QueueNode<T>
    var first : Node?
    var last : Node?
    public private(set) var count : Int = 0
    public mutating func enqueue(_ item:T) {
        let i = Node(value:item)
        if let l = last {
            l.next = i
            last = i
        } else {
            first = i
            last = i
        }
        count += 1
    }
    public mutating func dequeue() -> T? {
        if let i=first {
            first = i.next
            if first == nil {
                last = nil
            }
            count -= 1
            return i.value
        }
        return nil
    }
    public init() {
    }
}
*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


