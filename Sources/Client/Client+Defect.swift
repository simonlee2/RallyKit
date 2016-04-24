//
//  Client+Defect.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

import Alamofire
import Freddy
import BrightFutures

// MARK: Defects
extension Client {
    func futurify<T>(f: () throws -> T) -> Future<T, NSError> {
        do {
            let value = try f()
            return Future(value: value)
        } catch let error as NSError {
            return Future(error: error)
        }
    }

    func defects(defectQuery: String, projectQuery: String) -> Future<[Defect], NSError> {
        return fetchDefectsAsync(defectQuery, projectString: projectQuery)
            .flatMap(parseReponseAsync)
            .flatMap(defectsAsync)
            .flatMap(defectURLsAsync)
            .flatMap(mapURLSToDefects)
    }
    
    func mapDetailToDefect(json: JSON) -> Future<Defect, NSError> {
        return futurify {
            let defectJSON = json["Defect"]
            return try Defect(json: defectJSON ?? "")
        }
    }
    
    func mapURLSToDefects(urls: [String]) -> Future<[Defect], NSError> {
        let mapping: (String -> Future<Defect, NSError>) = { url in
            return self.defectDetail(url).flatMap(self.mapDetailToDefect)
        }
        return urls.traverse(f: mapping)
    }

    func defectDetail(url: String) -> Future<JSON, NSError> {
        return service.getURL(url).flatMap(parseReponseAsync)
    }
    
    // MARK: Fetch list of defect references
    
    func defects(json: JSON) throws -> [JSON] {
        return try json.array("QueryResult", "Results")
    }
    
    func defectsAsync(json: JSON) -> Future<[JSON], NSError> {
        do {
            let defectJSONs = try defects(json)
            return Future(value: defectJSONs)
        } catch let error as NSError {
            return Future(error: error)
        }
    }
    
    // MARK: Extract defect urls from references
    
    func defectURLs(defects: [JSON]) throws -> [String] {
        return try defects.map { defect in
            try defect.string("_ref")
        }
    }
    
    func defectURLsAsync(defects: [JSON]) -> Future<[String], NSError> {
        do {
            let urls = try defectURLs(defects)
            return Future(value: urls)
        } catch let error as NSError {
            return Future(error: error)
        }
    }
    
    // MARK: Parse NSData to JSON
    
    func parseResponse(completion: JSON throws -> ()) -> (Response<NSData, NSError> -> ()) {
        return { response in
            guard case .Success(let value) = response.result else {return }
            
            do {
                let json = try JSON(data: value)
                try completion(json)
            } catch let error {
                print(error)
            }
        }
    }
    
    func parseReponseAsync(data: NSData) -> Future<JSON, NSError> {
        do {
            let json = try JSON(data: data)
            return Future(value: json)
        } catch let error as NSError {
            return Future(error: error)
        }
    }
    
    // MARK: Grab list of projects
    
    func projectsReferences(projects: [JSON]) throws -> [String: String] {
        var projectMapping: [String: String] = [:]
        try projects.forEach { project in
            let projectName = try project.string("_refObjectName")
            let projectReference = try project.string("_ref")
            projectMapping[projectName] = projectReference
        }
        return projectMapping
    }
}