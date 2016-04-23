//
//  DefectState.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

enum DefectState: CustomStringConvertible {
    case Submitted
    case Open
    case Fixed
    case Closed
    case ReOpened
    case WontFix
    case Approved
    case Deferred
    case KeepWatch
    case CannotReproduce
    
    var description: String {
        switch self {
        case .Submitted:
            return "Submitted"
        case .Open:
            return "Open"
        case .Fixed:
            return "Fixed"
        case .Closed:
            return "Closed"
        case .ReOpened:
            return "Re-Opened"
        case .WontFix:
            return "Won't Fix"
        case .Approved:
            return "Approved"
        case .Deferred:
            return "Deferred"
        case .KeepWatch:
            return "Keep Watch"
        case .CannotReproduce:
            return "Cannot Reproduce"
        }
    }
}