//
//  BoopLiveActivityAttributes.swift
//  boop-ios
//
//  Created by Aparna Natarajan on 02/09/26.
//

import Foundation
import ActivityKit

public struct BoopLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var boopTime: Date
        
        public init(boopTime: Date) {
            self.boopTime = boopTime
        }
    }
    
    public init() {}
}
