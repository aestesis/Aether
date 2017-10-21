import CZip

public class Zip {
    public init?(path:String) {
        strm.zalloc = Z_NULL
        strm.zfree = Z_NULL
        strm.opaque = Z_NULL
        if deflateInit(&strm, level) != Z_OK {
            return nil
        }
}