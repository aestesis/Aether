import Zlib
import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public class ZipBundle {
    // https://en.wikipedia.org/wiki/Zip_(file_format)
    struct FD {
        var offset:Int
        var sizeC:UInt32
        var sizeU:UInt32
        var method:UInt16
    }
    let path : String
    var fds = [String:FD]()
    public var files:[String] {
        return fds.keys.map { $0 }
    }
    public func contains(_ path:String) -> Bool {
        return fds[path] != nil
    }
    public init?(path:String) {
        self.path = path
        let file = FileScanner(path:path)
        if file == nil {
            return nil
        }
        file!.seek(offset:0)
        self.parse(file:file!)

    }
    func parse(file:FileScanner) {
        while true {
            if let magic = file.readUInt32() {
                //let h = String(format:"%2X", magic)
                //Debug.warning("magic: \(h)")
                if magic == 0x04034B50 {                // file
                    let _/*version*/ = file.readUInt16()
                    let _/*purpose*/ = file.readUInt16()
                    let method = file.readUInt16()
                    let _/*time**/ = file.readUInt16()
                    let _/*date*/ = file.readUInt16()
                    let _/*crc32*/ = file.readUInt32()
                    let csize = file.readUInt32()
                    let usize = file.readUInt32()
                    let namesize = file.readUInt16()
                    let xfieldsize = file.readUInt16()
                    let name = file.read(count:Int(namesize!))
                    let _/*xfield*/ = file.read(count:Int(xfieldsize!))
                    let n = Misc.string(from:name)
                    if csize! > 0 { // skip folders
                        self.fds[n] = FD(offset:file.cursor,sizeC:csize!,sizeU:usize!,method:method!)
                    }
                    //Debug.warning("file: \(n)  offset:\(file.cursor)")
                    file.seek(offset:Int(csize!),origin:.current)
                } else if magic == 0x02014b50 {        // file desc (directory)
                    break
                    /*
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
                    let sname = "" //toString(name)
                    //Debug.warning("dir : \(sname)  offset: \(offset) ")
                    */
                    
                } else if magic == 0x06054b50 {        // end
                    /*
                    let disk = file.readUInt16()
                    let distcentral = file.readUInt16()
                    let ndirectory = file.readUInt16()
                    let total = file.readUInt16()
                    let size = file.readUInt32()
                    let offset = file.readUInt32()  // from .begin
                    let commentsize = file.readUInt16()
                    let comment = file.read(count:Int(commentsize!))
                    Debug.warning("end: ")
                    */
                    break
                } else {
                    Debug.error("zip file broken")
                    break
                }
            } else {
                break
            }
        }
    }
    public func open(filename:String) -> Stream? {
        if let zf = ZipFile(bundle:self,filename:filename) {
            if !zf.compressed {
                return zf
            }
            let zz = UnzipStream()
            zf.pipe(to:zz,pipeError:true)
            return zz
        }
        return nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class ZipFile : Stream {
    var fd : ZipBundle.FD?
    var f : FileScanner? 
    var end : Int = 0
    override var available:Int {
        if let f = f {
            return end - f.cursor
        }
        return 0
    }
    var compressed : Bool {
        return fd!.method != 0
    }
    init?(bundle:ZipBundle,filename:String) {
        super.init()
        if let fd = bundle.fds[filename] {
            self.fd = fd
            self.end = fd.offset + Int(fd.sizeC)
            if let f = FileScanner(path:bundle.path) {
                self.f = f
                f.seek(offset:fd.offset)
                _ = self.wait(0.001) {
                    self.onData.dispatch(())
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    override func close() {
        f = nil
        super.close()
    }
    override func read(_ desired:Int) -> [UInt8]? {
        if let f = f {
            let r = f.read(count:min(desired,available))
            wait(0.001).then { _ in
                if self.available>0 {
                    self.onData.dispatch(())
                } else {
                    self.close()
                }
            }
            return r
        }
        return nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class UnzipStream : Stream {
    var data = [UInt8]()
    var strm = z_stream()
    public override var available:Int {
        return data.count
    }
    public override func read(_ desired:Int) -> [UInt8]? {
        if available<desired {
            self.onFreespace.dispatch(())
        }
        let m = min(desired,available)
        if m > 0 {
            let d = Array(data[0..<m])
            data.removeSubrange(0..<m)
            return d
        }
        return nil
    }
    public override func write(_ data:[UInt8],offset:Int,count:Int) -> Int {
        // https://www.zlib.net/manual.html
        // https://stackoverflow.com/questions/18700656/zlib-inflate-failing-with-3-z-data-error
        var out = [UInt8](repeating:0,count:8192)
        strm.avail_in = UInt32(data.count)
        strm.next_in = UnsafeMutablePointer(mutating:data)
        var running = true
        while running {
            strm.avail_out = UInt32(out.count)
            strm.next_out = UnsafeMutablePointer(mutating:out)
            let ret = inflate(&strm,Z_NO_FLUSH)
            switch ret {
                case Z_NEED_DICT:
                Debug.error("zip: need dict")
                case Z_STREAM_ERROR:
                Debug.error("zip: stream error")
                inflateEnd(&strm)
                running = false
                case Z_DATA_ERROR:
                Debug.error("zip: data error")
                inflateEnd(&strm)
                running = false
                case Z_MEM_ERROR:
                Debug.error("zip: mem error")
                inflateEnd(&strm)
                running = false
                default:
                let inflated = out.count - Int(strm.avail_out)
                //Debug.warning("zip: inflated \(inflated)")
                if inflated>0 {
                    self.data.append(contentsOf:out[0..<inflated])
                }
                if ret == Z_STREAM_END {
                    //Debug.warning("zip: end")
                    inflateEnd(&strm)
                    running = false
                }
            }
        }
        return data.count - Int(strm.avail_in)
    }
    public init() {
        super.init()
        strm.zalloc = nil
        strm.zfree = nil
        strm.opaque = nil
        strm.avail_in = 0
        strm.next_in = nil
        let c_version = zlibVersion()
        //let version = String(cString:c_version!)
        switch inflateInit2_(&strm, -MAX_WBITS, c_version, CInt(MemoryLayout<z_stream>.size)) {
            case Z_OK:
            //NSLog("zip: init OK")
            break
            default:
            Debug.error("zip: init error")
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class FileScanner {
    public enum Origin {
        case begin
        case current
        case end
    }
    var path:String
    var file:UnsafeMutablePointer<FILE>!
    var cursor : Int {
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
        let r = fread(&data, 1, count, file)
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
        let dr = read(count:2)
        let end = dr.count / 2
        if end != 1 {
            return nil
        }
        let d = UnsafeRawPointer(dr).assumingMemoryBound(to:UInt16.self)
        return d[0]
    }
    public func readUInt16(count:Int) -> [UInt16] {
        let dr = read(count:count*2)
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
