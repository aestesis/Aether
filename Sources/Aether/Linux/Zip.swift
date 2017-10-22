import CZlib
import Foundation

public class ZipBundle {
    // https://en.wikipedia.org/wiki/Zip_(file_format)
    let filename:String
    let file : FileScanner
    var _files = [String:Int]()
    var offsetDirectory:Int = 0
    var offsetData:Int = 0
    public var files:[String] {
        return _files.keys.map { $0 }
    }
    public init?(path:String) {
        filename=path
        let file = FileScanner(path:path)
        if file == nil {
            return nil
        }
        self.file = file!
        self.parse()
    }
    func parse() {
        file.seek(offset:0)
        let magic = file.readUInt32()
        if magic == 0x04034B50 {  
            let version = file.readUInt16()
            let purpose = file.readUInt16()
            let method = file.readUInt16()
            let time = file.readUInt16()
            let data = file.readUInt16()
            let crc32 = file.readUInt32()
            let csize = file.readUInt32()
            let usize = file.readUInt32()
            let namesize = file.readUInt16()
            let xfieldsize = file.readUInt16()
            let name = file.read(count:Int(namesize!))
            let xfield = file.read(count:Int(xfieldsize!))
            offsetData = file.current
            file.seek(offset:Int(csize!),origin:.current)
            offsetDirectory = file.current
            parseDirectory()
        }
    }
    func parseDirectory() {
        while true {
            let magic = file.readUInt32()
            if magic == 0x02014b50 {        // file desc
                let versionMade = file.readUInt16()
                let versionNeed = file.readUInt16()
                let purpose = file.readUInt16()
                let method = file.readUInt16()
                let time = file.readUInt16()
                let date = file.readUInt16()
                let crc32 = file.readUInt32()
                let csize = file.readUInt32()
                let usize = file.readUInt32()
                let namesize = file.readUInt16()
                let xfieldsize = file.readUInt16()
                let commentsize = file.readUInt16()
                let disk = file.readUInt16()
                let attrint = file.readUInt16()
                let attrext = file.readUInt32()
                let offset = file.readUInt32()
                let name = file.read(count:Int(namesize!))
                let xfield = file.read(count:Int(xfieldsize!))
                let comment = file.read(count:Int(commentsize!))
                let pn = UnsafeRawPointer(name).assumingMemoryBound(to:UInt8.self)
                let n = String(cString:pn)
                self._files[n] = Int(offset!)
            } else if magic == 0x06054b50 { // end
                let disk = file.readUInt16()
                let distcentral = file.readUInt16()
                let ndirectory = file.readUInt16()
                let total = file.readUInt16()
                let size = file.readUInt32()
                let offset = file.readUInt32()  // from .begin
                let commentsize = file.readUInt16()
                let comment = file.read(count:Int(commentsize!))
                if Int(offset!) == offsetDirectory {
                    Debug.warning("zip binding: \(filename) OK")
                }
            } else {
                Debug.error("zip file broken")
                break
            }
        }
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
    public func seek(offset:Int,origin:Origin=Origin.begin) {
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