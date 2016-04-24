//
//  KanbanState.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

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