//
//  Flickr.swift
//  Alib
//
//  Created by renan jegouzo on 04/11/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//

import Foundation

// https://www.flickr.com/services/api/flickr.photos.search.html

public class Flickr {
    public static var key = ""
    public static var secret = ""
    static let api="https://api.flickr.com/services/rest/"
    static let apiSearch = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=$key&text=$query&license=1&safe_search=1&content_type=1&per_page=5&format=json"
    public static func search(query:String,fn:@escaping ((Any?)->())) {
        var api = Flickr.apiSearch
        api = api.replacingOccurrences(of: "$key", with: Flickr.key)
        api = api.replacingOccurrences(of: "$query", with: query)
        Web.getJSON(api, { r in
            if let json = r as? JSON {
                fn(json)
            } else if let err = r as? Alib.Error {
                fn(Error(err))
            }
        })
    }
    public static func setCredentials(key:String,secret:String) {
        Flickr.key = key
        Flickr.secret = secret
    }
}
