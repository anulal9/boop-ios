//
//  BoopLiveActivityLiveActivity.swift
//  BoopLiveActivity
//
//  Created by Aparna Natarajan on 2/9/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Mirror of BoopLiveActivityAttributes from main app
public struct BoopLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var boopTime: Date
        
        public init(boopTime: Date) {
            self.boopTime = boopTime
        }
    }
    
    public init() {}
}

struct BoopLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BoopLiveActivityAttributes.self) { context in
            VStack {
                Text("Hello World")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Hello World")
                        .font(.headline)
                }
            } compactLeading: {
                Text("Boop")
            } compactTrailing: {
                Image(systemName: "hand.raised")
            } minimal: {
                Image(systemName: "hand.raised")
            }
        }
    }
}

extension BoopLiveActivityAttributes {
    fileprivate static var preview: BoopLiveActivityAttributes {
        BoopLiveActivityAttributes()
    }
}

extension BoopLiveActivityAttributes.ContentState {
    fileprivate static var preview: BoopLiveActivityAttributes.ContentState {
        BoopLiveActivityAttributes.ContentState(boopTime: Date())
    }
}

#Preview("Lock Screen", as: .content, using: BoopLiveActivityAttributes.preview) {
    BoopLiveActivityLiveActivity()
} contentStates: {
    BoopLiveActivityAttributes.ContentState.preview
}
