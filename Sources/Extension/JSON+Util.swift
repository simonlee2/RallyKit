//
//  JSON+Util.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//
import Foundation
import Freddy

extension JSON {
    var prettyString: Swift.String {
        let data = try! self.serialize()
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        let prettyData = try! NSJSONSerialization.dataWithJSONObject(json, options: [.PrettyPrinted])
        let string = NSString(data: prettyData, encoding: NSUTF8StringEncoding) ?? ""
        return string as Swift.String
    }
}
