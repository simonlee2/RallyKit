//
//  RallyAuthentication.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Foundation
import Alamofire
import Freddy

public enum RallyAuthType {
    case Username(username: String, password: String)
    case APIKey(key: String)
    
    private var encodedBasicAuthentication: String? {
        guard case .Username(username: let username, password: let password) = self else { return nil }
        
        return encodedBasicAuthentication(username: username, password: password)
    }
    
    private func encodedBasicAuthentication(username username: String, password: String) -> String {
        let raw = username + ":" + password
        let encoded = raw.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
        return "Basic \(encoded!)"
    }
    
    func requestCredential(completion: (Credential?) -> ()) {
        switch self {
        case .APIKey(key: let key):
            completion(RallyAPICredential(key: key))
        case .Username(_):
            RallyService.authenticate(encodedBasicAuthentication, completion: { self.authenticationHandler($0, completion: completion) })
        }
    }
    
    func authenticationHandler(response: Response<NSData, NSError>, completion: (Credential?) -> ()) {
        guard case .Success(let data) = response.result,
            let json = try? JSON(data: data),
            let token = try? json.string("OperationResult", "SecurityToken") else {
                completion(nil)
                return
        }
        
        completion(RallyUsernameCredential(securityToken: token))
    }
}