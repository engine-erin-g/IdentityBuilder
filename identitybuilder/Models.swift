//
//  Models.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation
import SwiftData

// MARK: - Constants

/// Maximum number of habits (inspired by Benjamin Franklin's 13 virtues)
private let kMaxHabitsLimit = 13

/// Monday as first day of week (Calendar.firstWeekday uses 1=Sunday, 2=Monday)
private let kMondayFirstWeekday = 2

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
    var sortOrder: Int // Used for custom ordering of habits

    // Relationship to completions
    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion]

    init(name: String, identity: String, experiments: [String] = [], selectedDays: Set<Int> = [], sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.identity = identity
        self.experiments = experiments
        self.experimentHistory = experiments // Initialize history with current experiments
        self.selectedDays = selectedDays
        self.createdDate = Date()
        self.isCompleted = false
        self.streak = 0
        self.sortOrder = sortOrder
        self.completions = []
    }

    // Cached completion rate calculation
    func calculateCompletionRate(from startDate: Date? = nil, to endDate: Date? = nil) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let habitStart = calendar.startOfDay(for: startDate ?? createdDate)
        let endDay = calendar.startOfDay(for: endDate ?? today)

        var completedIncludingToday = 0
        var notCompletedExcludingToday = 0
        var checkDate = habitStart

        // Use a set for faster completion lookups
        let completionDates = Set(completions.map { calendar.startOfDay(for: $0.date) })

        while checkDate <= endDay {
            if isScheduledForDate(checkDate) {
                if completionDates.contains(checkDate) {
                    completedIncludingToday += 1
                } else if checkDate < today {
                    notCompletedExcludingToday += 1
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }

        let denominator = completedIncludingToday + notCompletedExcludingToday
        guard denominator > 0 else { return 0 }

        return Int(Double(completedIncludingToday) / Double(denominator) * 100)
    }

    // Fast best streak calculation
    func calculateBestStreak(lookbackDays: Int = 365) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var bestStreak = 0
        var currentStreak = 0
        var checkDate = today

        // Use a set for faster completion lookups
        let completionDates = Set(completions.map { calendar.startOfDay(for: $0.date) })

        for _ in 0..<lookbackDays {
            if isScheduledForDate(checkDate) {
                if completionDates.contains(checkDate) {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return bestStreak
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

        // Check if today is scheduled and completed - if so, count it
        if isScheduledForDate(today) && isCompletedOnDate(today) {
            currentStreak = 1
            // Start checking from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                self.streak = currentStreak
                return
            }
            checkDate = yesterday
        } else {
            // Today is not completed, start from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                self.streak = 0
                return
            }
            checkDate = yesterday
        }

        // Count backwards from checkDate
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

// MARK: - Sample Data Extension

@MainActor
extension Habit {
    /// Creates sample habits with 3 months of completion data for demo purposes
    static func createSampleData(in modelContext: ModelContext) {
        // Clear existing data
        let habitDescriptor = FetchDescriptor<Habit>()
        let completionDescriptor = FetchDescriptor<HabitCompletion>()
        let retrospectiveDescriptor = FetchDescriptor<WeeklyRetrospective>()

        if let existingHabits = try? modelContext.fetch(habitDescriptor) {
            for habit in existingHabits {
                modelContext.delete(habit)
            }
        }

        if let existingCompletions = try? modelContext.fetch(completionDescriptor) {
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
        }

        if let existingRetrospectives = try? modelContext.fetch(retrospectiveDescriptor) {
            for retrospective in existingRetrospectives {
                modelContext.delete(retrospective)
            }
        }

        let calendar = Calendar.current
        let today = Date()
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) ?? today

        // Sample habits with varied completion rates
        let sampleHabits = [
            (name: "Stay curious", identity: "Reader", experiments: ["Read during breaks", "Keep book visible"], days: [1, 2, 3, 4, 5, 6, 0], rate: 0.85),
            (name: "1500 Active calories", identity: "Athlete", experiments: ["Morning workout", "Track with Apple Watch"], days: [1, 2, 3, 4, 5], rate: 0.75),
            (name: "Control mouth", identity: "Temperance", experiments: ["No junk food in house", "Drink water first"], days: [1, 2, 3, 4, 5, 6, 0], rate: 0.70),
            (name: "Control feelings", identity: "Present", experiments: ["5-minute meditation", "Deep breathing"], days: [1, 2, 3, 4, 5], rate: 0.80),
            (name: "Build build build", identity: "Entrepreneur", experiments: ["Daily coding session", "Ship small features"], days: [1, 2, 3, 4, 5], rate: 0.65)
        ]

        for sample in sampleHabits {
            let habit = Habit(
                name: sample.name,
                identity: sample.identity,
                experiments: sample.experiments,
                selectedDays: Set(sample.days)
            )
            habit.createdDate = threeMonthsAgo
            modelContext.insert(habit)

            // Create 90 days of completion data with improving trend
            for dayOffset in -90...0 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                   habit.isScheduledForDate(date) {
                    let progressFactor = Double(dayOffset + 90) / 90.0 // 0 to 1
                    let adjustedRate = sample.rate + (progressFactor * 0.15) // Gradual improvement

                    if Double.random(in: 0...1) < adjustedRate {
                        let completion = HabitCompletion(date: date, habit: habit)
                        modelContext.insert(completion)
                        habit.completions.append(completion)
                    }
                }
            }

            habit.updateStreak()
        }

        // Add a sample retrospective
        if let lastWeekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today)?.start {
            let retrospective = WeeklyRetrospective(
                weekStartDate: lastWeekStart,
                notes: "Great week! I managed to stay consistent with most habits. Need to work on better sleep schedule."
            )
            modelContext.insert(retrospective)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving sample data: \(error)")
        }
    }
}