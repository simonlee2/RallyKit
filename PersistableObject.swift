//
//  PersistableObject.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Freddy

class PersistableObject: Attributes, JSONDecodable {
    // Attributes
    var _rallyAPIMajor: String
    var _rallyAPIMinor: String
    var _ref: String
    var _refObjectName: String
    var _refObjectUUID: String
    var _type: String?
    
    // Persistable
    var creationDate: String //TODO: Use NSDate
    var objectID: Int64
    var objectUUID: String
    var versionID: String?
    
    required init(json: JSON) throws {
        _rallyAPIMajor = try json.string("_rallyAPIMajor")
        _rallyAPIMinor = try json.string("_rallyAPIMinor")
        _ref = try json.string("_ref")
        _refObjectName = try json.string("_refObjectName")
        _refObjectUUID = try json.string("_refObjectUUID")
        _type = try json.string("_type", ifNotFound: true)
        
        creationDate = try json.string("CreationDate")
        objectID = try Int64(json.int("ObjectID"))
        objectUUID = try json.string("ObjectUUID")
        versionID = try json.string("VersionId")
    }
}

protocol Attributes {
    var _rallyAPIMajor: String { get set }
    var _rallyAPIMinor: String { get set }
    var _ref: String { get set }
    var _refObjectName: String { get set }
    var _refObjectUUID: String { get set }
    var _type: String? { get set }
}
