//
//  Amazon.swift
//  Alib
//
//  Created by renan jegouzo on 08/03/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

// doc:         http://docs.aws.amazon.com/AWSECommerceService/latest/DG/ItemSearch.html
// sign:        http://docs.aws.amazon.com/AWSECommerceService/latest/DG/rest-signature.html
// try sign:    http://associates-amazon.s3.amazonaws.com/signed-requests/helper/index.html

public class Amazon {
    public static var key = ""
    public static var secret = ""
    public static var tag = ""
    static let service="http://webservices.amazon.com/onca/xml?"
    static let apiSearch="Service=AWSECommerceService&AWSAccessKeyId=$key&AssociateTag=$tag&Operation=ItemSearch&Keywords=$query&SearchIndex=Music&Timestamp=$time"
    public static func searchArtist(name:String,fn:@escaping ((Any?)->())) {
        var api = apiSearch
        api = api.replacingOccurrences(of:"$query",with:rfc3986(name))
        api = api.replacingOccurrences(of:"$key",with:key)
        api = api.replacingOccurrences(of:"$tag",with:tag)
        api = api.replacingOccurrences(of:"$time",with:rfc3986(ß.dateISO8601))
        //Debug.warning("amamzon unsigned request: "+service+api)
        api = api.split("&").sorted { a,b -> Bool in
            return a<b
        }.joined(separator:"&")
        let st = "GET\nwebservices.amazon.com\n/onca/xml\n"+api
        let signature = Crypto.hmacSHA256(string:st,key:secret).addingPercentEncoding(withAllowedCharacters:.alphanumerics)!
        let url = service+api+"&Signature=\(signature)"
        //Debug.warning("Amazon: request \(url)")
        Web.getText(url) { r in
            let btag = "<MoreSearchResultsUrl>"
            let etag = "</MoreSearchResultsUrl>"
            if let text = r as? String, let b = text.indexOf(btag), let e = text.indexOf(etag), b<e {
                let url = text[(b+btag.length)..<e].trim().replacingOccurrences(of:"&amp;",with:"&")
                //Debug.warning("amazon: \(url)")
                fn(url)
            } else if let err = r as? Error {
                fn(Error(err))
            } else {
                fn(Error("bad amazon response"))
            }
        }
        /*
        Web.getXML(url, { r in
            if let xdoc = r as? AEXMLDocument {
                Debug.warning("Amazon: response: \(xdoc.xml)")
                fn(xdoc)
            } else if let err = r as? Alib.Error {
                Debug.warning("Amazon: error: \(err)")
                fn(Error(err))
            }
        })
         */
    }
    static func rfc3986(_ s:String) -> String {   // RFC 3986
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: "-._~/?")
        return s.addingPercentEncoding(withAllowedCharacters:allowed as CharacterSet)!
    }
    public static func setCredentials(key:String,secret:String,tag:String) {
        Amazon.key = key
        Amazon.secret = secret
        Amazon.tag = tag
    }
}

