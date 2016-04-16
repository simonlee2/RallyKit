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
        
        rally.get("/subscription") { response in
            guard case .Success(let value) = response.result else { return }
            
            let json = try? JSON(JSON(data: value).dictionary("Subscription"))
            let subscription = try? Subscription(json: json!)
        }
        
        // Get all workspaces
        rally.get("/workspace", completion: handleResponse)
        
        // Get workspace with id
//        rally.get("/workspace/2952460547/projects", completion: handleResponse)
        
//        rally.get("/project/31939943023", completion: handleResponse)
        
        // Get defects
//        rally.get("/defect", completion: handleResponse)
        
//        rally.get("/defect?project=\(RallyService.baseURL)/project/35472160948", completion: handleResponse)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        guard let endPoint = textField.text else { return }
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
