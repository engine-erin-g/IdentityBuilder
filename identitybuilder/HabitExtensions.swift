//
//  HabitExtensions.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation

// Extension to convert main app data to widget data
extension Array where Element == Habit {
    func toWidgetData() -> WidgetData {
        let calendar = Calendar.current
        let today = Date()
        let weekNumber = calendar.component(.weekOfYear, from: today)
        
        // Get current week dates
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return WidgetData(
                weekNumber: weekNumber,
                currentWeekCompletion: 0,
                lastWeekCompletion: 0,
                habits: []
            )
        }
        
        var weekDates: [Date] = []
        var date = weekInterval.start
        for _ in 0..<7 {
            weekDates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        // Convert habits to widget format
        let widgetHabits = self.map { habit in
            let weeklyCompletions = weekDates.map { date in
                habit.isScheduledForDate(date) && habit.isCompletedOnDate(date)
            }
            
            return WidgetHabit(
                identity: habit.identity,
                streak: habit.streak,
                weeklyCompletions: weeklyCompletions
            )
        }
        
        // Calculate current week completion
        let totalScheduled = weekDates.reduce(0) { total, date in
            return total + self.filter { $0.isScheduledForDate(date) }.count
        }
        
        let totalCompleted = weekDates.reduce(0) { total, date in
            return total + self.filter { $0.isScheduledForDate(date) && $0.isCompletedOnDate(date) }.count
        }
        
        let currentWeekCompletion = totalScheduled > 0 ? Int(Double(totalCompleted) / Double(totalScheduled) * 100) : 0
        
        // Calculate last week completion
        guard let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, 
                                                            for: calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today) else {
            return WidgetData(
                weekNumber: weekNumber,
                currentWeekCompletion: currentWeekCompletion,
                lastWeekCompletion: 0,
                habits: widgetHabits
            )
        }
        
        var lastWeekDates: [Date] = []
        var lastWeekDate = lastWeekInterval.start
        for _ in 0..<7 {
            lastWeekDates.append(lastWeekDate)
            lastWeekDate = calendar.date(byAdding: .day, value: 1, to: lastWeekDate) ?? lastWeekDate
        }
        
        let lastWeekTotalScheduled = lastWeekDates.reduce(0) { total, date in
            return total + self.filter { $0.isScheduledForDate(date) }.count
        }
        
        let lastWeekTotalCompleted = lastWeekDates.reduce(0) { total, date in
            return total + self.filter { $0.isScheduledForDate(date) && $0.isCompletedOnDate(date) }.count
        }
        
        let lastWeekCompletion = lastWeekTotalScheduled > 0 ? Int(Double(lastWeekTotalCompleted) / Double(lastWeekTotalScheduled) * 100) : 0
        
        return WidgetData(
            weekNumber: weekNumber,
            currentWeekCompletion: currentWeekCompletion,
            lastWeekCompletion: lastWeekCompletion,
            habits: widgetHabits
        )
    }
}