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
import BrightFutures

public enum RallyAuthType {
    case Username(username: String, password: String)
    case APIKey(key: String)
    case KeyFile(filePath: String)
    
    // MARK: BA encoding
    
    private var encodedBasicAuthentication: String? {
        guard case .Username(username: let username, password: let password) = self else { return nil }
        
        return encodedBasicAuthentication(username: username, password: password)
    }
    
    private func encodedBasicAuthentication(username username: String, password: String) -> String {
        let raw = username + ":" + password
        let encoded = raw.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
        return "Basic \(encoded!)"
    }
    
    // MARK: Request Credential
    
    func requestCredential(completion: (Credential?) -> ()) {
        switch self {
        case .APIKey(key: let key):
            completion(RallyAPICredential(key: key))
        case .Username(_):
            RallyService.authenticate(encodedBasicAuthentication, completion: { self.authenticationHandler($0, completion: completion) })
        case .KeyFile(filePath: let filePath):
            if let key = NSBundle.mainBundle().pathForResource(filePath, ofType: "plist")
                .flatMap({NSDictionary(contentsOfFile: $0)})
                .flatMap({$0["APIKey"]}) as? String {
                completion(RallyAPICredential(key: key))
            } else {
                print("Cannot find a valid .plist file in \(filePath)")
            }
        }
    }
    
    func requestCredientialAsync() -> Future<Credential, NSError> {
        switch self {
        case .APIKey(key: let key):
            return Future(value: RallyAPICredential(key: key))
        case .Username(_):
            return RallyService.authenticateAsync(encodedBasicAuthentication).flatMap { (data) -> Future<Credential, NSError> in
                do {
                    let json = try JSON(data: data)
                    let token = try json.string("OperationResult", "SecurityToken")
                    let credential = RallyUsernameCredential(securityToken: token)
                    return Future(value: credential)
                } catch let error as NSError {
                    return Future(error: error)
                }
            }
        case .KeyFile(filePath: let filePath):
            if let key = NSBundle.mainBundle().pathForResource(filePath, ofType: "plist")
                .flatMap({NSDictionary(contentsOfFile: $0)})
                .flatMap({$0["APIKey"]}) as? String {
                return Future(value: RallyAPICredential(key: key))
            } else {
                return Future(error: NSError(domain: "Rally", code: 1, userInfo: nil))
            }
        }
    }
    
    // MARK: Create credential based on auth response
    
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