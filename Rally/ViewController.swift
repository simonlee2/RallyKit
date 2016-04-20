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
    @IBOutlet weak var endPointTextField: UITextField! {
        didSet {
            endPointTextField.delegate = self
        }
    }
    @IBOutlet weak var console: UITextView!
    
    let rally = RallyService(authType: RallyAuthType.Username(username: "slee@solstice-consulting.com", password: "Wayla87091"))
    
    func handleResponse(response: Response<NSData, NSError>) {
        guard case .Success(let value) = response.result else { return }
        
        guard let json = try? JSON(data: value) else { return }
        let prettyString = json.prettyString
        print(prettyString)
        self.console.text = self.console.text + "\n\n" + prettyString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        
//        rally.get("/subscription") { response in
//            guard case .Success(let value) = response.result else { return }
//            
//            let json = try? JSON(JSON(data: value).dictionary("Subscription"))
//            let subscription = try? Subscription(json: json!)
//        }
//        
        // Get all workspaces
//        rally.fetchProjects { response in
//            guard case .Success(let value) = response.result else { return }
//            
//            do {
//                let json = try JSON(data: value)
////                print(json.prettyString)
//                let projects = try json.array("QueryResult", "Results")
//                let projectRefs = try self.projectsReferences(projects)
//                print(projectRefs)
//            } catch let error {
//                print(error)
//            }
//        }
        
        let defectString = "query=(State != \"Closed\")"
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        
        rally.fetchDefects(defectString, projectString: projectString, completion: parseResponse { json in
                let urls = try self.defectURLs(try self.defects(json))
                urls.forEach { url in
                    self.mapDefectURLToDefectNumber(url) { number in
                        print(number)
                    }
                }
            })
        
        
        
        
        // Get workspace with id
//        rally.get("/workspace/2952460547/projects", completion: handleResponse)
        
//        rally.get("/project/31939943023", completion: handleResponse)
        
        // Get defects
//        rally.get("/defect", completion: handleResponse)
        
//        rally.get("/defect?project=\(RallyService.baseURL)/project/35472160948", completion: handleResponse)
    }
    
    func mapDefectURLToDefectNumber(url: String, completion: (String) -> ()) {
        Alamofire
            .request(.GET, url)
            .responseData(completionHandler: parseResponse { json in
                let number = try self.defectNumber(json)
                completion(number)
                })
    }
    
    func defects(json: JSON) throws -> [JSON] {
        return try json.array("QueryResult", "Results")
    }
    
    func defectURLs(defects: [JSON]) throws -> [String] {
        return try defects.map { defect in
            try defect.string("_ref")
        }
    }
    
    func defectNumber(json: JSON) throws -> String {
        return try json.string("Defect", "FormattedID")
    }
    
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

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        guard let endPoint = textField.text else { return }
        self.console.text = self.console.text + "\n\n" + "Getting: \(textField.text)"
        rally.get(endPoint, completion: handleResponse)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension JSON {
    var prettyString: Swift.String {
        let data = try! self.serialize()
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        let prettyData = try! NSJSONSerialization.dataWithJSONObject(json, options: [.PrettyPrinted])
        let string = NSString(data: prettyData, encoding: NSUTF8StringEncoding) ?? ""
        return string as Swift.String
    }
}
