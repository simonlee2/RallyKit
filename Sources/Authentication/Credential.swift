//
//  Credential.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

protocol Credential {
    var header: [String: String] { get }
    var parameters: [String: String] { get }
}

public struct RallyUsernameCredential {
    var securityToken: String
}

extension RallyUsernameCredential: Credential {
    var header: [String: String] {
        return [:]
    }
    
    var parameters: [String: String] {
        return ["key" : securityToken]
    }
}

public struct RallyAPICredential {
    var key: String
}

extension RallyAPICredential: Credential {
    var header: [String: String] {
        return ["zsessionid" : key]
    }
    
    var parameters: [String: String] {
        return [:]
    }
}