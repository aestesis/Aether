//
//  Crypto.swift
//  Alib
//
//  Created by renan jegouzo on 17/03/2017.
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
import CommonCrypto

public class Crypto {
    static func hmacSHA256(string:String,key:String) -> String {
        let stringData = string.data(using:.utf8)!
        let keyData = key.data(using:.utf8)!
        let stringBytes = [UInt8](stringData)
        let keyBytes = [UInt8](keyData)
        let hash = NSMutableData(length:Int(CC_SHA256_DIGEST_LENGTH))!
        CCHmac(UInt32(kCCHmacAlgSHA256), keyBytes, keyBytes.count, stringBytes, stringBytes.count, hash.mutableBytes)
        return hash.base64EncodedString(options:NSData.Base64EncodingOptions(rawValue:0))
    }
    static func SHA256(string:String) -> String {
        let data = string.data(using:.utf8)!
        let bytes = [UInt8](data)
        let digest = NSMutableData(length:Int(CC_SHA256_DIGEST_LENGTH))!
        CC_SHA256(bytes, CC_LONG(bytes.count), digest.mutableBytes.assumingMemoryBound(to:UInt8.self))
        return digest.base64EncodedString(options:NSData.Base64EncodingOptions(rawValue:0))
    }
}
