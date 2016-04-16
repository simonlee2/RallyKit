//
//  RallyService.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Alamofire

class RallyService {
    var authType: RallyAuthType
    var credential: Credential?
    var securityToken: String?
    
    init(authType: RallyAuthType) {
        self.authType = authType
    }
    
    static let baseURL = "https://rally1.rallydev.com/slm/webservice/v2.0"
    static var authenticateURL: String {
        return baseURL + "/security/authorize"
    }
    
    // MARK: Authentication
    
    private static func basicAuthenticationHeader(encodedCredentials: String?) -> [String: String] {
        guard let encodedCredentials = encodedCredentials else { return [:] }
        
        return ["Authorization": encodedCredentials]
    }
    
    static func authenticate(encodedCredentials: String?, completion: (Response<NSData, NSError> -> ())) {
        let header = basicAuthenticationHeader(encodedCredentials)
        Alamofire
            .request(.GET, RallyService.authenticateURL, headers: header)
            .responseData(completionHandler: completion)
    }
    
    func authenticateIfNeeded(completion: (Credential?) -> ()) {
        if let credential = credential {
            completion(credential)
        } else {
            self.authType.requestCredential() { credential in
                self.credential = credential
                completion(credential)
            }
        }
    }
    
    // MARK: Request wrapper with credentials
    func request(method: Alamofire.Method, _ endPoint: String, credential: Credential, completion: (Response<NSData, NSError> -> ())) {
        let requestURL = RallyService.baseURL + endPoint
        Alamofire
            .request(method, requestURL, parameters: credential.parameters, headers: credential.header)
            .responseData(completionHandler: completion)
    }
    
    // MARK: Request wrapper around credentials
    func request(method: Alamofire.Method, _ endPoint: String, completion: (Response<NSData, NSError>) -> ()) {
        authenticateIfNeeded { credential in
            guard let credential = credential else { return }
            self.request(method, endPoint, credential: credential, completion: completion)
        }
    }    
    
    func get(endPoint: String, completion: (Response<NSData, NSError> -> ())) {
        request(.GET, endPoint, completion: completion)
    }
}