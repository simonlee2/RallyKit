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
        
        let allMappings = KanbanState.allValues
        
//        let defectString = "query=((State = \"Open\") and (ScheduleState = \"In-Progress\"))"
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        
//        allMappings.forEach { kanbanState in
//            self.defects(kanbanState: kanbanState, projectQuery: projectString).onSuccess { defects in
//                self.consoleLog("\(defects.count) in \(kanbanState.rawValue) where (\(kanbanState.mapping.0), \(kanbanState.mapping.1))")
//                defects.forEach({print($0.formattedID)})
//            }.onFailure { error in
//                self.consoleLog("\(error)")
//            }
//        }
        
//        let defectString = defectQuery(.DevInProgress)
//        client.defects(defectString, projectQuery: projectString).onSuccess { defects in
//            print("\(defects.count) open defects")
//            defects.forEach({print($0.formattedID)})
//        }.onFailure { error in
//            print(error)
//        }
    }
    
    func consoleLog(log: String) {
        print(log)
        self.console.text = self.console.text + "\n\n" + log
    }
    
    func defectsInKanbanState(kanbanState: KanbanState) {
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        
        self.defects(kanbanState: kanbanState, projectQuery: projectString).onSuccess { defects in
            self.consoleLog("\(defects.count) in \(kanbanState.rawValue) where (\(kanbanState.mapping.0), \(kanbanState.mapping.1))")
            defects.forEach({self.consoleLog($0.formattedID)})
        }.onFailure { error in
            self.consoleLog("\(error)")
        }
    }
    
    func defects(kanbanState kanbanState: KanbanState, projectQuery: String) -> Future<[Defect], NSError> {
        consoleLog("Fetching Defects in: \(kanbanState.rawValue)")
        let defectString = defectQuery(kanbanState)
        return client.defects(defectString, projectQuery: projectQuery)
    }
    
    func defectQuery(kanbanState: KanbanState) -> String {
        let (scheduleState, defectState) = kanbanState.mapping
        return defectQuery(scheduleState, defectState: defectState)
    }
    
    func defectQuery(scheduleState: ScheduleState, defectState: DefectState) -> String {
        return "query=((State = \"\(defectState.rawValue)\") and (ScheduleState = \"\(scheduleState.rawValue)\"))"
    }
}

enum KanbanState: String {
    case Undefined = "Undefined"
    case Defined = "Defined"
    case DevInProgress = "Dev In-Progress"
    case DevComplete = "Dev Complete"
    case QAReady = "QA Ready"
    case QAInProgress = "QA In-Progress"
    case QAComplete = "QA Complete"
    case Approved = "Approved"
    
    static var allValues: [KanbanState] {
        return [.Undefined, .Defined, .DevInProgress, .DevComplete, .QAReady, .QAInProgress, .QAComplete, .Approved]
    }
    
    var mapping: (ScheduleState, DefectState) {
        switch self {
        case .Undefined:
            return (.Undefined, .Submitted)
        case .Defined:
            return (.Defined, .Submitted)
        case .DevComplete:
            return (.Completed, .Open)
        case .DevInProgress:
            return (.InProgress, .Open)
        case .QAReady:
            return (.Completed, .Fixed)
        case .QAInProgress:
            return (.InProgress, .Fixed)
        case .QAComplete:
            return (.Completed, .Closed)
        case .Approved:
            return (.Completed, .Approved)
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        guard let text = textField.text else { return }
        guard let kanbanState = KanbanState(rawValue: text) else { return }
        
        defectsInKanbanState(kanbanState)
        
//        guard let endPoint = textField.text else { return }
//        self.console.text = self.console.text + "\n\n" + "Getting: \(textField.text)"
//        client.service.getAsync(endPoint).flatMap { data in
//            return self.client.futurify {
//                try JSON(data: data)
//            }
//        }.onSuccess{ json in
//            let prettyString = json.prettyString
//            self.consoleLog(prettyString)
//            
//        }.onFailure { error in
//            print(error)
//        }
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
