//
//  WidgetModels.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation

// Simple models for the widget to avoid SwiftData complexities in widgets
struct WidgetHabit: Codable {
    let identity: String
    let streak: Int
    let weeklyCompletions: [Bool] // Array of 7 bools for each day of the week
}

struct WidgetData: Codable {
    let weekNumber: Int
    let currentWeekCompletion: Int
    let lastWeekCompletion: Int
    let habits: [WidgetHabit]
    
    static let sample = WidgetData(
        weekNumber: 41,
        currentWeekCompletion: 66,
        lastWeekCompletion: 94,
        habits: [
            WidgetHabit(identity: "Reader", streak: 25, weeklyCompletions: [true, true, true, false, false, false, false]),
            WidgetHabit(identity: "Athlete", streak: 1, weeklyCompletions: [true, false, true, false, false, false, false]),
            WidgetHabit(identity: "Temperance", streak: 0, weeklyCompletions: [true, false, false, false, false, false, false]),
            WidgetHabit(identity: "Present", streak: 4, weeklyCompletions: [true, true, false, false, false, false, false]),
            WidgetHabit(identity: "Entrepreneur", streak: 4, weeklyCompletions: [true, true, false, false, false, false, false])
        ]
    )
}