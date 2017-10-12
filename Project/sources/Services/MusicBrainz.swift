//
//  MusicBrainz.swift
//  Alib
//
//  Created by renan jegouzo on 23/02/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class MusicBrainz {
    static let server = "http://musicbrainz.org/ws/2"
    static let coverserver = "http://coverartarchive.org/release/"
    public static func request(_ req:String,_ fn:@escaping (Any?)->())  {
        Web.getJSON(MusicBrainz.server+req) { r in
            fn(r)
        }
    }
    public static func artist(name:String,_ fn:@escaping (Any?)->()) {
        if name.length==0 {
            fn(Error("can't find artist without name",#file,#line))
        } else if let n=name.urlEncoded {
            MusicBrainz.request("/artist/?fmt=json&limit=1&&query="+n,fn)
        } else {
            fn(Error("incompatible artist name: \(name)",#file,#line))
        }
    }
    public static func release(_ name:String,_ fn:@escaping (Any?)->()) {
        if name.length==0 {
            fn(Error("can't find release without name",#file,#line))
        } else if let n=name.urlEncoded {
            MusicBrainz.request("/release/?fmt=json&query="+n,fn)
        } else {
            fn(Error("incompatible release name: \(name)",#file,#line))
        }
    }
    public static func releaseForArtist(_ mbid:String,_ fn:@escaping (Any?)->()) {
        if mbid.length==0 {
            fn(Error("can't find release without mbid",#file,#line))
        } else if let n=mbid.urlEncoded {
            MusicBrainz.request("/release?fmt=json&artist="+n,fn)
        } else {
            fn(Error("incompatible release mbid: \(mbid)",#file,#line))
        }
    }
    public static func cover(_ id:String,_ fn:@escaping (Any?)->()) {
        if id.length==0 {
            fn(Error("can't find cover without id",#file,#line))
        } else if let gid=id.urlEncoded {
            Web.getJSON(coverserver+gid) { r in
                fn(r)
            }
        } else {
            fn(Error("incompatible cover id: \(id)",#file,#line))
        }
    }
    public static func cover(artist:String,title:String,_ fn: @escaping (Any?)->()) {
        Debug.info("MusicBrainz: searching cover for \(artist) - \(title)")
        MusicBrainz.artist(name:artist) { r in
            if let ja=r as? JSON {
                if let jaa=ja["artists"].array {
                    if jaa.count>0 {
                        let aid=jaa[0]["id"].string!
                        MusicBrainz.releaseForArtist(aid) { r in
                            if let jr=r as? JSON {
                                if let releases=jr["releases"].array {
                                    var jrr:JSON?=nil
                                    for j in releases {
                                        if j["cover-art-archive"]["count"].doubleValue>0 {
                                            if j["title"].string==title {
                                                jrr = j
                                                break
                                            }
                                            if (jrr == nil) || ((jrr != nil) && (j["date"].string! > jrr!["date"].string!)) {
                                                jrr = j
                                            }
                                        }
                                    }
                                    if let jrr=jrr {
                                        if let rid = jrr["id"].string {
                                            MusicBrainz.cover(rid) { r in
                                                if let jc=r as? JSON {
                                                    var url:String?=nil
                                                    for j in jc["images"].array! {
                                                        url = j["thumbnails"]["small"].string
                                                        if j["front"].string != nil {   // TODO: check it
                                                            break
                                                        }
                                                    }
                                                    if let url = url {
                                                        Debug.info("cover: \(url)")
                                                        fn(url)
                                                    } else {
                                                        fn(Error("no cover",#file,#line))
                                                    }
                                                } else {
                                                    fn(r)
                                                }
                                            }
                                        } else {
                                            fn(Error("no cover",#file,#line))
                                        }
                                    } else {
                                        fn(Error("no cover",#file,#line))
                                    }
                                } else {
                                    fn(Error("release not found",#file,#line))
                                }
                            } else {
                                fn(r)
                            }
                        }
                    } else {
                        fn(Error("artist not found",#file,#line))
                    }
                } else {
                    fn(Error("artist not found",#file,#line))
                }
            } else if let err = r as? Alib.Error  {
                fn(Error(err,#file,#line))
            }
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
