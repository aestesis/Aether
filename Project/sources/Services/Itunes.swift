//
//  Itunes.swift
//  Alib
//
//  Created by renan jegouzo on 05/03/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

// https://affiliate.itunes.apple.com/resources/documentation/itunes-store-web-service-search-api/#searchexamples

public class Itunes {
    public static var key = ""
    public static var secret = ""
    static let apiSearch="https://itunes.apple.com/search?term="
    static let apiLookup="https://itunes.apple.com/lookup?id="
    static var qKeySecret:String {
        return "&key=\(Itunes.key)&secret=\(Itunes.secret)"
    }
    public static func search(query:String,entity:String="musicArtist",limit:Int=1,fn:@escaping ((Any?)->())) {
        var q = ""
        for s in query.trim().split(" ") {
            if s.length>0 {
                if q.length>0 {
                    q += "+"
                }
                q += s
            }
        }
        let url = Itunes.apiSearch+q+"&limit=\(limit)&entity=\(entity)"
        //Debug.warning("itunes: request \(url)")
        Web.getJSON(url, { r in
            if let json = r as? JSON {
                //Debug.warning("itunes: response \(json.rawString()!)")
                fn(json)
            } else if let err = r as? Alib.Error {
                Debug.warning("itunes: errror \(err)")
                fn(Error(err))
            }
        })
    }
    public static func lookup(id:Int,entity:String="song",limit:Int=1,fn:@escaping ((Any?)->())) {
        let url = "\(Itunes.apiLookup)\(id)&limit=\(limit)&entity=\(entity)"
        //Debug.warning("itunes: request \(url)")
        Web.getJSON(url, { r in
            if let json = r as? JSON {
                //Debug.warning("itunes: response \(json.rawString()!)")
                fn(json)
            } else if let err = r as? Alib.Error {
                Debug.warning("itunes: errror \(err)")
                fn(Error(err))
            }
        })
    }
    public static func artist(name:String,fn:@escaping ((Any?)->())) {
        Itunes.search(query:name.addingPercentEncoding(withAllowedCharacters:.alphanumerics)!) { r in
            if let json = r as? JSON {
                if let id = json["results"][0]["artistId"].int {
                    Itunes.lookup(id:id,limit:1) { r in
                        if let json = r as? JSON {
                            fn(json)
                        } else if let error = r as? Alib.Error {
                            fn(Error(error))
                        }
                    }
                } else {
                    fn(Error("bad itunes response"))
                }
            } else if let error = r as? Alib.Error {
                fn(Error(error))
            }
        }
    }
    public static func setCredentials(key:String,secret:String) {
        Itunes.key = key
        Itunes.secret = secret
    }
}
