import CZlib
import Foundation

public class Zip {
    let file : FileScanner?
    public init?(path:String) {
        file = FileScanner(path:path)
    }
}

public class FileScanner {
    public enum Origin {
        case begin
        case current
        case end
    }
    var path:String
    var file:UnsafeMutablePointer<FILE>!
    var current : Int {
        return ftell(file)
    }
    public init?(path:String) {
        self.path = path
        file=fopen(path, "r")
        if file == nil {
            return nil
        }
        seek(offset:0,origin:.begin)
    }
    public func close() {
        if file != nil  {
            fclose(file)
            file = nil
        }
    }
    public func seek(offset:Int,origin:Origin) {
        switch origin {
            case .begin:
                fseek(file, offset, SEEK_SET)
            case .current:
                fseek(file, offset, SEEK_CUR)
            case .end:
                fseek(file, offset, SEEK_END)
        }
    }
    public func read(count:Int) -> [UInt8] {
        var data = [UInt8](repeating:0,count:count)
        let r = fread(&data, count, 1, file)
        if r == count {
            return data
        } else if r>0 {
            return Array(data[0..<r])
        }
        return [UInt8]()
    }
    public func readUInt32() -> UInt32? {
        let dr = read(count:4)
        let end = dr.count / 4
        if end != 1 {
            return nil
        }
        let d = UnsafeRawPointer(dr).assumingMemoryBound(to:UInt32.self)
        return d[0]
    }
    public func readUInt32(count:Int) -> [UInt32] {
        let dr = read(count:count*4)
        let end = dr.count / 4
        let d = UnsafeRawPointer(dr).assumingMemoryBound(to:UInt32.self)
        if end>0  {
            var data = [UInt32](repeating:0,count:end)
            for i in 0..<end {
                data[i] = d[i]
            }
            return data
        }
        return [UInt32]()
    }
    public func readUInt16() -> UInt16? {
        var dr = read(count:2)
        let end = dr.count / 2
        if end != 1 {
            return nil
        }
        let d = UnsafeRawPointer(dr).assumingMemoryBound(to:UInt16.self)
        return d[0]
    }
    public func readUInt16(count:Int) -> [UInt16] {
        var dr = read(count:count*2)
        let end = dr.count / 2
        let d = UnsafeRawPointer(dr).assumingMemoryBound(to:UInt16.self)
        if end>0  {
            var data = [UInt16](repeating:0,count:end)
            for i in 0..<end {
                data[i] = d[i]
            }
            return data
        }
        return [UInt16]()
    }
}