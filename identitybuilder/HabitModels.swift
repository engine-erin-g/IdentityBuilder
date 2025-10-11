//
//  Models.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String
    var identity: String
    var experiments: [String] = []
    var selectedDays: Set<Int> = [] // 0 = Sunday, 1 = Monday, etc.
    var createdDate: Date = Date()
    var streak: Int = 0
    var lastCompletedDate: Date?
    
    // Relationship to completions
    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion] = []
    
    init(name: String, identity: String, experiments: [String] = [], selectedDays: Set<Int> = []) {
        self.name = name
        self.identity = identity
        self.experiments = experiments
        self.selectedDays = selectedDays
        self.createdDate = Date()
    }
    
    func isScheduledForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-based
        return selectedDays.contains(weekday)
    }
    
    func completionForDate(_ date: Date) -> HabitCompletion? {
        let calendar = Calendar.current
        return completions.first { completion in
            calendar.isDate(completion.date, inSameDayAs: date)
        }
    }
    
    func isCompletedOnDate(_ date: Date) -> Bool {
        return completionForDate(date) != nil
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        var currentStreak = 0
        var checkDate = today
        
        // Count backwards from today
        while true {
            if isScheduledForDate(checkDate) {
                if isCompletedOnDate(checkDate) {
                    currentStreak += 1
                } else {
                    break
                }
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
            
            // Don't go back more than 100 days for performance
            if calendar.dateInterval(from: today, to: checkDate)?.duration ?? 0 > 100 * 24 * 3600 {
                break
            }
        }
        
        self.streak = currentStreak
    }
}

@Model
final class HabitCompletion {
    var id: UUID = UUID()
    var date: Date
    var habit: Habit?
    
    init(date: Date, habit: Habit) {
        self.date = date
        self.habit = habit
    }
}

@Model
final class WeeklyRetrospective {
    var id: UUID = UUID()
    var weekStartDate: Date
    var notes: String
    var createdDate: Date = Date()
    
    init(weekStartDate: Date, notes: String = "") {
        self.weekStartDate = weekStartDate
        self.notes = notes
        self.createdDate = Date()
    }
}