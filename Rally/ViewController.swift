//
//  ViewController.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/14/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import UIKit
import Alamofire
import Freddy

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let auth = RallyAuthType.Username(username: "slee@solstice-consulting.com", password: "Wayla87091")
        let rally = Rally(authType: auth)
        rally.authenticateIfNeeded { credential in
            guard let credential = credential else { return }
            rally.request(.GET, "/subscription", credential: credential).responseData { response in
                guard case .Success(let value) = response.result else { return }
                
                let json = try? JSON(JSON(data: value).dictionary("Subscription"))
                let subscription = try? Subscription(json: json!)
                print(subscription)
            }
        }
    }
}

enum RallyError: ErrorType {
    case AuthenticationError
}

public class Rally {
    var authType: RallyAuthType
    var credential: Credential?
    var securityToken: String?
    
    init(authType: RallyAuthType) {
        self.authType = authType
    }
    
    // Authenticate if needed
    
    func authenticateIfNeeded(completion: (Credential?) -> ()) {
        if let credential = self.credential {
            completion(credential)
        } else {
            self.authType.requestCredential(authType) { credential in
                self.credential = credential
                completion(credential)
            }
        }
    }
    
    // build request
    
    func request(method: Alamofire.Method, _ endPoint: String, credential: Credential) -> Alamofire.Request {
        let requestURL = RallyService.baseURL + endPoint
        return Alamofire.request(.GET, requestURL, parameters: credential.parameters, headers: credential.header)
    }
    
    // cast from data to JSON
    
    // process JSON
    
    
    
}

protocol Attributes {
    var _rallyAPIMajor: Int { get set }
    var _rallyAPIMinor: Int { get set }
    var _ref: String { get set }
    var _refObjectName: String { get set }
    var _refObjectUUID: String { get set }
    var _type: String { get set }
}

class PersistableObject: Attributes, JSONDecodable {
    // Attributes
    var _rallyAPIMajor: Int
    var _rallyAPIMinor: Int
    var _ref: String
    var _refObjectName: String
    var _refObjectUUID: String
    var _type: String
    
    // Persistable
    var creationDate: String //TODO: Use NSDate
    var objectID: Int64
    var objectUUID: String
    var versionID: Int?
    
    required init(json: JSON) throws {
        _rallyAPIMajor = try json.int("_rallyAPIMajor")
        _rallyAPIMinor = try json.int("_rallyAPIMinor")
        _ref = try json.string("_ref")
        _refObjectName = try json.string("_refObjectName")
        _refObjectUUID = try json.string("_refObjectUUID")
        _type = try json.string("_type")
        
        creationDate = try json.string("creationDate")
        objectID = try Int64(json.int("objectID"))
        objectUUID = try json.string("objectUUID")
        versionID = try json.int("versionID")
    }
}

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
    var sessionTimeoutSeconds: Int64?
    var storyHierarchyEnabled: Bool?
    var storyHierarchyType: String
    var subscriptionID: Int64
    var subscriptionType: String
    var workspaces: [Workspace]?
    
    required init(json: JSON) throws {
        
        apiKeysEnabled = try json.bool("apiKeysEnabled")
        emailEnabled = try json.bool("emailEnabled")
        expirationDate = try json.string("expirationDate")
        JSONPEnabled = try json.bool("JSONPEnabled")
        maximumCustomUserFields = try Int64(json.int("maximumCustomUserFields"))
        maximumProjects = try Int64(json.int("maximumProjects"))
        let moduleArrays = try json.array("modules")
        modules = try moduleArrays.map({try $0.string("")})
        name = try json.string("name")
        passwordExpirationDays = try Int64(json.int("passwordExpirationDays"))
        previousPasswordCount = try Int64(json.int("previousPasswordCount"))
        projectHierarchyEnabled = try json.bool("projectHierarchyEnabled")
        sessionTimeoutSeconds = try Int64(json.int("sessionTimeoutSeconds"))
        storyHierarchyEnabled = try json.bool("storyHierarchyEnabled")
        storyHierarchyType = try json.string("storyHierarchyType")
        subscriptionID = try Int64(json.int("subscriptionID"))
        subscriptionType = try json.string("subscriptionType")
        workspaces = [Workspace]()
        
        try super.init(json: json)
    }
}

class Workspace {}

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

public enum RallyAuthType {
    case Username(username: String, password: String)
    case APIKey(key: String)
    
    func encodedBasicAuthentication(username username: String, password: String) -> String {
        let raw = username + ":" + password
        let encoded = raw.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
        return "Basic \(encoded!)"
    }
    
    func requestCredential(authType: RallyAuthType, completion: (Credential?) -> ()) {
        switch authType {
        case .APIKey(key: let key):
            completion(RallyAPICredential(key: key))
        case .Username(username: let username, password: let password):
            let header = ["Authorization": encodedBasicAuthentication(username: username, password: password)]
            let request = Alamofire.request(.GET, RallyService.authenticateURL, headers: header)
            authenticate(request) { credential in
                completion(credential)
            }
        }
    }
    
    private func authenticate(request: Alamofire.Request, completion: (Credential?) -> ()) {
        
        request.responseData { response in
            guard case .Success(let data) = response.result,
                let json = try? JSON(data: data),
                let token = try? json.string("OperationResult", "SecurityToken") else {
                    completion(nil)
                    return
            }
            
            
            completion(RallyUsernameCredential(securityToken: token))
        }
    }
}

struct RallyService {
    static let baseURL = "https://rally1.rallydev.com/slm/webservice/v2.0"
    static var authenticateURL: String {
        return baseURL + "/security/authorize"
    }
}
