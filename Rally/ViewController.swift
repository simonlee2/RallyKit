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
import BrightFutures

class ViewController: UIViewController {
    @IBOutlet weak var endPointTextField: UITextField! {
        didSet {
            endPointTextField.delegate = self
        }
    }
    @IBOutlet weak var console: UITextView!
    
    let rally = Client(authType: RallyAuthType.Username(username: "slee@solstice-consulting.com", password: "Wayla87091"))
    
    func handleResponse(response: Response<NSData, NSError>) {
        guard case .Success(let value) = response.result else { return }
        
        guard let json = try? JSON(data: value) else { return }
        let prettyString = json.prettyString
        print(prettyString)
        self.console.text = self.console.text + "\n\n" + prettyString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defectString = "query=(State != \"Closed\")"
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        
        rally.fetchDefectsAsync(defectString, projectString: projectString)
            .flatMap({ data in self.futurify({try JSON(data: data)})})
            .flatMap(defectsAsync)
            .flatMap(defectURLsAsync)
            .map({$0.first!})
            .flatMap(defectDetail)
            .onSuccess { json in
                print(json.prettyString)
                let defectJson = try! json["Defect"]
                let defect = try? Defect(json: defectJson!)
                dump(defect)
        }
//            .flatMap({ $0.traverse(f: self.mapDefectURLToDefectNumberAsync)})
//            .onSuccess { numbers in
//                print(numbers)
//        }
    }
    
    func futurify<T>(f: () throws -> T) -> Future<T, NSError> {
        do {
            let value = try f()
            return Future(value: value)
        } catch let error as NSError {
            return Future(error: error)
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
    
    func mapDefectURLToDefectNumber(url: String, completion: (String) -> ()) {
        Alamofire
            .request(.GET, url)
            .responseData(completionHandler: parseResponse { json in
                let number = try self.defectNumber(json)
                completion(number)
                })
    }
    
    func defectDetail(url: String) -> Future<JSON, NSError> {
        return Alamofire
            .request(.GET, url)
            .responseData()
            .flatMap(parseReponseAsync)
    }
    
    func mapDefectURLToDefectNumberAsync(url: String) -> Future<String, NSError> {
        return defectDetail(url)
            .map { json in
                return try! self.defectNumber(json)
        }
    }
    
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
        rally.service.get(endPoint, completion: handleResponse)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension Request {
    func responseJSON() -> Future<JSON, NSError> {
        return responseData().flatMap { data in
            return self.futurify {
                return try JSON(data: data)
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
    
    func futurify<T>(f: () throws -> T) -> Future<T, NSError> {
        do {
            let value = try f()
            return Future(value: value)
        } catch let error as NSError {
            return Future(error: error)
        }
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
