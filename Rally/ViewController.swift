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
    
    let client = Client(authType: RallyAuthType.Username(username: "slee@solstice-consulting.com", password: "Wayla87091"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defectString = "query=(State != \"Closed\")"
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        
        client.defects(defectString, projectQuery: projectString).onSuccess { defects in
            print("\(defects.count) non-closed defects")
        }.onFailure { error in
            print(error)
        }
    }
    
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        guard let endPoint = textField.text else { return }
        self.console.text = self.console.text + "\n\n" + "Getting: \(textField.text)"
        client.service.getAsync(endPoint).flatMap { data in
            return self.client.futurify {
                try JSON(data: data)
            }
        }.onSuccess{ json in
            let prettyString = json.prettyString
            print(prettyString)
            self.console.text = self.console.text + "\n\n" + prettyString
        }.onFailure { error in
            print(error)
        }
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
