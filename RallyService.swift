//
//  RallyService.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Alamofire
import BrightFutures

class RallyService {
    var authType: RallyAuthType
    var credential: Credential?
    
    init(authType: RallyAuthType) {
        self.authType = authType
    }
    
    static let baseURL = "https://rally1.rallydev.com/slm/webservice/v2.0"
    static var authenticateURL: String {
        return baseURL + "/security/authorize"
    }
    
    // MARK: BA Header
    
    private static func basicAuthenticationHeader(encodedCredentials: String?) -> [String: String] {
        guard let encodedCredentials = encodedCredentials else { return [:] }
        
        return ["Authorization": encodedCredentials]
    }
    
    // MARK: Authentication
    
    static func authenticate(encodedCredentials: String?, completion: (Response<NSData, NSError> -> ())) {
        let header = basicAuthenticationHeader(encodedCredentials)
        Alamofire
            .request(.GET, RallyService.authenticateURL, headers: header)
            .responseData(completionHandler: completion)
    }
    
    static func authenticateAsync(encodedCredentials: String?) -> Future<NSData, NSError> {
        let header = basicAuthenticationHeader(encodedCredentials)
        return Alamofire
            .request(.GET, RallyService.authenticateURL, headers: header)
            .responseData()
    }
    
    // MARK: Request wrapper with credentials
    func request(method: Method, _ endPoint: String, credential: Credential) -> Request {
        let requestURL = RallyService.baseURL + endPoint
        return Alamofire
            .request(method, requestURL, parameters: credential.parameters, headers: credential.header)
    }
    
    // MARK: HTTP GET
    func get(endPoint: String, completion: Response<NSData, NSError> -> ()) {
        request(.GET, endPoint, completion: completion)
    }
    
    func getAsync(endPoint: String) -> Future<NSData, NSError> {
        return requestAsync(.GET, endPoint)
    }
}

/// Generic wrapper on top of Alamofire requests
extension RallyService {
    // MARK: Authenticate If Needed
    
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
    
    func authenticateIfNeededAsync() -> Future<Credential, NSError> {
        if let credential = credential {
            return Future(value: credential)
        } else {
            return authType.requestCredientialAsync()
        }
    }
    
    // MARK: Handle Request
    
    func requestCompletion(method: Method, _ endPoint: String, credential: Credential, completion: Response<NSData, NSError> -> ()) {
        request(method, endPoint, credential: credential).responseData(completionHandler: completion)
    }
    
    func requestAsync(method: Method, _ endPoint: String, credential: Credential) -> Future<NSData, NSError> {
        return request(method, endPoint, credential: credential).responseData()
    }
    
    // MARK: Request wrapper around credentials
    func request(method: Method, _ endPoint: String, completion: Response<NSData, NSError> -> ()) {
        authenticateIfNeeded { credential in
            guard let credential = credential else { return }
            self.requestCompletion(method, endPoint, credential: credential, completion: completion)
        }
    }
    
    func requestAsync(method: Method, _ endPoint: String) -> Future<NSData, NSError> {
        return authenticateIfNeededAsync().flatMap { credential in
            return self.requestAsync(method, endPoint, credential: credential)
        }
    }
}

/// Helper extension
extension Request {
    
    // MARK: NSData
    func responseData() -> Future<NSData, NSError> {
        let promise = Promise<NSData, NSError>()
        self.responseData { response in
            switch response.result {
            case .Failure(let error):
                promise.tryFailure(error)
            case .Success(let value):
                promise.trySuccess(value)
            }
        }
        return promise.future
    }
}
