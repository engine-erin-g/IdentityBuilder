//
//  SampleData.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation
import SwiftData

@MainActor
class SampleData {
    static func createSampleHabits(modelContext: ModelContext) {
        // Clear existing data
        try? modelContext.delete(model: Habit.self)
        try? modelContext.delete(model: HabitCompletion.self)
        try? modelContext.delete(model: WeeklyRetrospective.self)
        
        // Sample habits
        let readerHabit = Habit(
            name: "Stay curious",
            identity: "Reader",
            experiments: ["Read during breaks", "Keep book visible"],
            selectedDays: [1, 2, 3, 4, 5, 6, 0] // All days
        )
        
        let athleteHabit = Habit(
            name: "1500 Active calories",
            identity: "Athlete",
            experiments: ["Morning workout", "Track with Apple Watch"],
            selectedDays: [1, 2, 3, 4, 5] // Weekdays
        )
        
        let temperanceHabit = Habit(
            name: "Control mouth",
            identity: "Temperance",
            experiments: ["No junk food in house", "Drink water first"],
            selectedDays: [1, 2, 3, 4, 5, 6, 0] // All days
        )
        
        let presentHabit = Habit(
            name: "Control feelings",
            identity: "Present",
            experiments: ["5-minute meditation", "Deep breathing"],
            selectedDays: [1, 2, 3, 4, 5] // Weekdays
        )
        
        let entrepreneurHabit = Habit(
            name: "Build build build",
            identity: "Entrepreneur",
            experiments: ["Daily coding session", "Ship small features"],
            selectedDays: [1, 2, 3, 4, 5] // Weekdays
        )
        
        // Insert habits
        let habits = [readerHabit, athleteHabit, temperanceHabit, presentHabit, entrepreneurHabit]
        for habit in habits {
            modelContext.insert(habit)
        }
        
        // Create some sample completions for the past week
        let calendar = Calendar.current
        let today = Date()
        
        for habit in habits {
            for dayOffset in -7...0 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                   habit.isScheduledForDate(date) {
                    
                    // Randomly complete some habits (80% completion rate)
                    if Bool.random() && Double.random(in: 0...1) < 0.8 {
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
        
        try? modelContext.save()
    }
}