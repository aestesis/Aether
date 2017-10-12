//
//  Wikipedia.swift
//  Alib
//
//  Created by renan jegouzo on 19/07/2016.
//  Copyright © 2016 aestesis. All rights reserved.
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

// https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvlimit=1&rvprop=content&format=json&titles=Michael%20Jackson
public class Wikipedia {
    static let api = "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvlimit=1&rvprop=content&format=json&titles="
    public static func search(query:String, _ fn:@escaping ((Any?)->())) {
        Web.getJSON(Wikipedia.api+query, { r in
            if let json = r as? JSON {
                fn(json)
            } else if let err = r as? Alib.Error {
                fn(Error(err))
            }
        })
    }
}
