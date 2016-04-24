//
//  DefectState.swift
//  Rally
//
//  Created by Shao-Ping Lee on 4/23/16.
//  Copyright © 2016 Simon Lee. All rights reserved.
//

enum DefectState: String {
    case Submitted = "Submitted"
    case Open = "Open"
    case Fixed = "Fixed"
    case Closed = "Closed"
    case ReOpened = "Re-Opened"
    case WontFix = "Won't Fix"
    case Approved = "Approved"
    case Deferred = "Deferred"
    case KeepWatch = "Keep Watch"
    case CannotReproduce = "Cannot Reproduce"
    
    static var allValues: [DefectState] {
        return [.Submitted, .Open, .Fixed, .Closed, .ReOpened, .WontFix, .Approved, .Deferred, .KeepWatch, .CannotReproduce]
    }
}