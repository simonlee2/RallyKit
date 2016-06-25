//
//  Defect.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Freddy

class Artifact: JSONDecodable {
    var artifactDescription: String?
    var displayColor: String?
    var formattedID: String
    var name: String
    var notes: String?
    var owner: String?
    var ready: Bool?
    
    required init(json: JSON) throws {
        self.artifactDescription = try json.string("Description")
        self.displayColor = try json.string("DisplayColor", alongPath: [.NullBecomesNil])
        self.formattedID = try json.string("FormattedID")
        self.name = try json.string("Name")
        self.notes = try json.string("Notes", alongPath: [.NullBecomesNil])
        self.owner = try json.string("Owner", "_refObjectName", alongPath: [.NullBecomesNil])
        self.ready = try json.bool("Ready", alongPath: [.NullBecomesNil])
    }
}

class SchedulableArtifact: Artifact {
    var blocked: Bool?
    var blockedReason: String?
    var iteration: Iteration?
    var scheduleState: ScheduleState?
    
    required init(json: JSON) throws {
        self.blocked = try json.bool("Blocked", alongPath: [.NullBecomesNil])
        self.blockedReason = try json.string("BlockedReason", alongPath: [.NullBecomesNil])
        self.iteration = Iteration()
        self.scheduleState = ScheduleState(rawValue: try json.string("ScheduleState", alongPath: [.NullBecomesNil]) ?? "")
        
        try super.init(json: json)
    }
}

class Defect: SchedulableArtifact {
    var environment: String?
    var fixedInBuild: String?
    var foundInBuild: String?
    var priority: Priority?
    var severity: Severity?
    var state: DefectState?
    var submittedBy: User
    
    required init(json: JSON) throws {
        self.environment = try json.string("Environment", alongPath: [.NullBecomesNil])
        self.fixedInBuild = try json.string("FixedInBuild", alongPath: [.NullBecomesNil])
        self.foundInBuild = try json.string("FoundInBuild", alongPath: [.NullBecomesNil])
        self.priority = Priority(rawValue: try json.string("Priority"))
        self.severity = Severity(rawValue: try json.string("Severity"))
        self.state = DefectState(rawValue: try json.string("State"))
        self.submittedBy = User()
        
        try super.init(json: json)
    }
}
//
//extension Defect: JSONDecodable {
//    init(json: JSON) throws {
//        <#code#>
//    }
//}

enum ScheduleState: String {
    case Undefined = "Undefined"
    case Defined = "Defined"
    case InProgress = "In-Progress"
    case Completed = "Completed"
    case Accepted = "Accepted"
}

enum Priority: String {
    case ResolveImmediately = "Resolve Immediately"
    case HighAttention = "High Attention"
    case Normal = "Normal"
    case Low = "Low"
}

enum Severity: String {
    case Critical = "Critical"
    case Major = "Major Problem"
    case Medium = "Medium Problem"
    case Minor = "Minor Problem"
    case Cosmetic = "Cosmetic"
}

struct Iteration {}

struct User {}
