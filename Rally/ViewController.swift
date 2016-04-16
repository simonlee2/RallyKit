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
    var _rallyAPIMajor: String { get set }
    var _rallyAPIMinor: String { get set }
    var _ref: String { get set }
    var _refObjectName: String { get set }
    var _refObjectUUID: String { get set }
    var _type: String? { get set }
}

class PersistableObject: Attributes, JSONDecodable {
    // Attributes
    var _rallyAPIMajor: String
    var _rallyAPIMinor: String
    var _ref: String
    var _refObjectName: String
    var _refObjectUUID: String
    var _type: String?
    
    // Persistable
    var creationDate: String //TODO: Use NSDate
    var objectID: Int64
    var objectUUID: String
    var versionID: String?
    
    required init(json: JSON) throws {
        _rallyAPIMajor = try json.string("_rallyAPIMajor")
        _rallyAPIMinor = try json.string("_rallyAPIMinor")
        _ref = try json.string("_ref")
        _refObjectName = try json.string("_refObjectName")
        _refObjectUUID = try json.string("_refObjectUUID")
        _type = try json.string("_type", ifNotFound: true)
        
        creationDate = try json.string("CreationDate")
        objectID = try Int64(json.int("ObjectID"))
        objectUUID = try json.string("ObjectUUID")
        versionID = try json.string("VersionId")
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
