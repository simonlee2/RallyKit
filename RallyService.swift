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
    func request(method: Alamofire.Method, _ endPoint: String, credential: Credential, completion: Response<NSData, NSError> -> ()) {
        let requestURL = RallyService.baseURL + endPoint
        Alamofire
            .request(method, requestURL, parameters: credential.parameters, headers: credential.header)
            .responseData(completionHandler: completion)
    }
    
    // MARK: Request wrapper around credentials
    func request(method: Alamofire.Method, _ endPoint: String, completion: Response<NSData, NSError> -> ()) {
        authenticateIfNeeded { credential in
            guard let credential = credential else { return }
            self.request(method, endPoint, credential: credential, completion: completion)
        }
    }    
    
    func get(endPoint: String, completion: Response<NSData, NSError> -> ()) {
        request(.GET, endPoint, completion: completion)
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
    
    func fetchDefects(queryString: String?, projectString: String?, completion: Response<NSData, NSError> -> ()) {
        let string = "?" + [queryString, projectString].flatMap({$0}).joinWithSeparator("&")
        let endpointWithQuery = "/defect" + string
        get(endpointWithQuery.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!, completion: completion)
    }
    
    func fetchDefect(defectID: String, completion: Response<NSData, NSError> -> ()) {
        get("/defect/\(defectID)", completion: completion)
    }
}