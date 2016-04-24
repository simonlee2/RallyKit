//
//  Subscription.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//
import Freddy

class Subscription: PersistableObject {
    var apiKeysEnabled: Bool?
    var emailEnabled: Bool?
    var expirationDate: String? //TODO: Use NSDate
    var JSONPEnabled: Bool?
    var maximumCustomUserFields: Int64
    var maximumProjects: Int64
    var modules: [String]?
    var name: String
    var passwordExpirationDays: Int64?
    var previousPasswordCount: Int64
    var projectHierarchyEnabled: Bool?
    var sessionTimeoutSeconds: Int?
    var storyHierarchyEnabled: Bool?
    var storyHierarchyType: String
    var subscriptionID: Int64
    var subscriptionType: String
    var workspaces: [Workspace]?
    
    required init(json: JSON) throws {
        
        apiKeysEnabled = try json.bool("ApiKeysEnabled")
        emailEnabled = try json.bool("EmailEnabled")
        expirationDate = try json.string("ExpirationDate", ifNull: true)
        JSONPEnabled = try json.bool("JSONPEnabled")
        maximumCustomUserFields = try Int64(json.int("MaximumCustomUserFields"))
        maximumProjects = try Int64(json.int("MaximumProjects"))
        let moduleArrays = try json.string("Modules")
        modules = moduleArrays.componentsSeparatedByString(",")
        name = try json.string("Name")
        passwordExpirationDays = try Int64(json.int("PasswordExpirationDays"))
        previousPasswordCount = try Int64(json.int("PreviousPasswordCount"))
        projectHierarchyEnabled = try json.bool("ProjectHierarchyEnabled")
        sessionTimeoutSeconds = try json.int("SessionTimeoutSeconds", ifNull: true)
        storyHierarchyEnabled = try json.bool("StoryHierarchyEnabled")
        storyHierarchyType = try json.string("StoryHierarchyType")
        subscriptionID = try Int64(json.int("SubscriptionID"))
        subscriptionType = try json.string("SubscriptionType")
        workspaces = [Workspace]()
        
        try super.init(json: json)
    }
}

class Workspace {}