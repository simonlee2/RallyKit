//
//  Client.swift
//  Client
//
//  Created by Shao-Ping Lee on 4/16/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Alamofire
import BrightFutures

/// Public interface to interact with Rally
public class Client {
    
    var authType: RallyAuthType
    var service: RallyService
    
    init(authType: RallyAuthType) {
        self.authType = authType
        self.service = RallyService(authType: authType)
    }
    
    func fetchProjects(completion: Response<NSData, NSError> -> ()) {
        service.get("/project", completion: completion)
    }
    
    func fetchProjects() -> Future<NSData, NSError> {
        return service.getAsync("/project")
    }
    
    func fetchDefects(queryString: String?, projectString: String?, completion: Response<NSData, NSError> -> ()) {
        let string = "?" + [queryString, projectString].flatMap({$0}).joinWithSeparator("&")
        let endpointWithQuery = "/defect" + string
        service.get(endpointWithQuery.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!, completion: completion)
    }
    
    func fetchDefectsAsync(queryString: String?, projectString: String?) -> Future<NSData, NSError> {
        let string = "?" + [queryString, projectString].flatMap({$0}).joinWithSeparator("&")
        let endpointWithQuery = "/defect" + string
        return service.getAsync(endpointWithQuery.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    func fetchDefect(defectID: String, completion: Response<NSData, NSError> -> ()) {
        service.get("/defect/\(defectID)", completion: completion)
    }
    
    func fetchDefectAsync(defectID: String) -> Future<NSData, NSError> {
        return service.getAsync("/defect/\(defectID)")
    }
}
