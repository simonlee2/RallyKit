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
    
    let client = Client(authType: RallyAuthType.KeyFile(filePath: "Keys"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let defectString = "query=((State = \"Open\") and (ScheduleState = \"In-Progress\"))"
        let projectString = "project=https://rally1.rallydev.com/slm/webservice/v2.0/project/35472160948"
        DefectState.allValues.forEach { state in
            self.client.defects(defectQuery(state), projectQuery: projectString).onSuccess { defects in
                self.consoleLog("\(defects.count) in \(state.rawValue)")
                defects.forEach({print($0.formattedID)})
            }
        }
        
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
    
    func defectQuery(defectState: DefectState) -> String {
        return "query=(State = \"\(defectState.rawValue)\")"
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

