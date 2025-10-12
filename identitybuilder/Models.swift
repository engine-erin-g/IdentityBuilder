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
    @Attribute(.unique) var id: UUID
    var name: String
    var identity: String
    var experiments: [String]
    var experimentHistory: [String] // All experiments ever added (including current and past)
    var selectedDays: Set<Int> // 0 = Sunday, 1 = Monday, etc.
    var createdDate: Date
    var isCompleted: Bool
    var streak: Int
    var lastCompletedDate: Date?

    // Relationship to completions
    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion]

    init(name: String, identity: String, experiments: [String] = [], selectedDays: Set<Int> = []) {
        self.id = UUID()
        self.name = name
        self.identity = identity
        self.experiments = experiments
        self.experimentHistory = experiments // Initialize history with current experiments
        self.selectedDays = selectedDays
        self.createdDate = Date()
        self.isCompleted = false
        self.streak = 0
        self.completions = []
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
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today

        // Count backwards from today
        while true {
            // Only check scheduled days
            if isScheduledForDate(checkDate) {
                if isCompletedOnDate(checkDate) {
                    currentStreak += 1
                    // Continue checking previous days
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = previousDay
                } else {
                    // If this scheduled day is not completed, streak ends
                    break
                }
            } else {
                // If day is not scheduled, skip it and continue
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            }

            // Don't go back more than 365 days for performance
            let daysDiff = calendar.dateComponents([.day], from: checkDate, to: today).day ?? 0
            if daysDiff > 365 {
                break
            }
        }

        self.streak = currentStreak
    }
}

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = date
        self.habit = habit
    }
}

@Model
final class WeeklyRetrospective {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var notes: String
    var createdDate: Date

    init(weekStartDate: Date, notes: String = "") {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.notes = notes
        self.createdDate = Date()
    }
}