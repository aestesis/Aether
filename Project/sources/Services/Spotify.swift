//
//  Spotify.swift
//  Alib
//
//  Created by renan jegouzo on 18/03/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

public class Spotify {
    static let apiSearch="https://api.spotify.com/v1/search?q=$artist&type=artist"
    public static func searchArtist(name:String,fn:@escaping ((Any?)->())) {
        let url = apiSearch.replacingOccurrences(of:"$artist",with:name.addingPercentEncoding(withAllowedCharacters:.alphanumerics)!)
        Web.getJSON(url, { r in
            if let json = r as? JSON {
                fn(json)
            } else if let err = r as? Alib.Error {
                fn(Error(err))
            }
        })
    }
}
