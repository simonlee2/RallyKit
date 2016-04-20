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
    
    static func authenticateAsync(encodedCredentials: String?) -> Future<NSData, NSError> {
        let header = basicAuthenticationHeader(encodedCredentials)
        return Alamofire
            .request(.GET, RallyService.authenticateURL, headers: header)
            .responseData()
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
    
    func authenticateIfNeededAsync() -> Future<Credential, NSError> {
        if let credential = credential {
            return Future(value: credential)
        } else {
            return authType.requestCredientialAsync()
        }
    }
    
    // MARK: Request wrapper with credentials
    func request(method: Method, _ endPoint: String, credential: Credential) -> Request {
        let requestURL = RallyService.baseURL + endPoint
        return Alamofire
            .request(method, requestURL, parameters: credential.parameters, headers: credential.header)
    }
    
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
    
    func get(endPoint: String, completion: Response<NSData, NSError> -> ()) {
        request(.GET, endPoint, completion: completion)
    }
    
    func getAsync(endPoint: String) -> Future<NSData, NSError> {
        return requestAsync(.GET, endPoint)
    }
}

enum DefectState: CustomStringConvertible {
    case Submitted
    case Open
    case Fixed
    case Closed
    case ReOpened
    case WontFix
    case Approved
    case Deferred
    case KeepWatch
    case CannotReproduce
    
    var description: String {
        switch self {
        case .Submitted:
            return "Submitted"
        case .Open:
            return "Open"
        case .Fixed:
            return "Fixed"
        case .Closed:
            return "Closed"
        case .ReOpened:
            return "Re-Opened"
        case .WontFix:
            return "Won't Fix"
        case .Approved:
            return "Approved"
        case .Deferred:
            return "Deferred"
        case .KeepWatch:
            return "Keep Watch"
        case .CannotReproduce:
            return "Cannot Reproduce"
        }
    }
}

extension RallyService {
    func fetchProjects(completion: Response<NSData, NSError> -> ()) {
        get("/project", completion: completion)
    }
    
    func fetchProjects() -> Future<NSData, NSError> {
        return getAsync("/project")
    }
    
    func fetchDefects(queryString: String?, projectString: String?, completion: Response<NSData, NSError> -> ()) {
        let string = "?" + [queryString, projectString].flatMap({$0}).joinWithSeparator("&")
        let endpointWithQuery = "/defect" + string
        get(endpointWithQuery.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!, completion: completion)
    }
    
    func fetchDefectsAsync(queryString: String?, projectString: String?) -> Future<NSData, NSError> {
        let string = "?" + [queryString, projectString].flatMap({$0}).joinWithSeparator("&")
        let endpointWithQuery = "/defect" + string
        return getAsync(endpointWithQuery.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    func fetchDefect(defectID: String, completion: Response<NSData, NSError> -> ()) {
        get("/defect/\(defectID)", completion: completion)
    }
    
    func fetchDefectAsync(defectID: String) -> Future<NSData, NSError> {
        return getAsync("/defect/\(defectID)")
    }
}

extension Request {
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