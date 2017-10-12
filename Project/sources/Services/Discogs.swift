//
//  Discogs.swift
//  Alib
//
//  Created by renan jegouzo on 23/02/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

public class Discogs {
    public static var key = ""
    public static var secret = ""
    static let apiSearch="https://api.discogs.com/database/search?q="
    static var qKeySecret:String {
        return "&key=\(Discogs.key)&secret=\(Discogs.secret)"
    }
    public static func searchArtist(name:String,fn:@escaping ((Any?)->())) {
        let url = Discogs.apiSearch+name.addingPercentEncoding(withAllowedCharacters:.alphanumerics)!+"&artist"+Discogs.qKeySecret
        Web.getJSON(url, { r in
            if let json = r as? JSON {
                //Debug.warning("discogs: response: \(json.rawString()!)")
                fn(json)
            } else if let err = r as? Alib.Error {
                Debug.warning("discogs: error: \(err)")
                fn(Error(err))
            }
        })
    }
    public static func artist(name:String,fn:@escaping ((Any?)->())) {
        Discogs.searchArtist(name:name) { r in
            if let json = r as? JSON {
                if let ja = json["results"].array {
                    var found = false
                    for j in ja {
                        if j["type"].stringValue == "artist", let url = j["resource_url"].string {
                            found = true
                            Web.getJSON(url) { r in
                                if let error = r as? Error {
                                    fn(Error(error))
                                } else if let json = r as? JSON {
                                    fn(json)
                                }
                            }
                            break
                        }
                    }
                    if !found {
                        fn(Error("Discogs.artist(name:\(name))  not found"))
                    }
                } else {
                    fn(Error("Discogs.artist(name:\(name))  not found"))
                }
            } else if let error = r as? Alib.Error {
                fn(error)
            }
        }
    }
    public static func setCredentials(key:String,secret:String) {
        Discogs.key = key
        Discogs.secret = secret
    }
}
