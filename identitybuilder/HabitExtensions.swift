//
//  HabitExtensions.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation

// MARK: - Constants
private let kMondayFirstWeekday = 2 // Calendar.firstWeekday: 1=Sunday, 2=Monday

// Extension to convert main app data to widget data
extension Array where Element == Habit {
    func toWidgetData() -> WidgetData {
        // Force-load all habit attributes to prevent fault errors
        self.forEach { habit in
            _ = habit.selectedDays
            _ = habit.completions
        }

        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let today = Date()
        let weekNumber = calendar.component(.weekOfYear, from: today)

        // Get current week dates starting from Monday
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return WidgetData(
                weekNumber: weekNumber,
                currentWeekCompletion: 0,
                lastWeekCompletion: 0,
                actualRate: 0,
                potentialRate: 0,
                habits: []
            )
        }
        
        var weekDates: [Date] = []
        var date = weekInterval.start
        for _ in 0..<7 {
            weekDates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        // Sort habits by sortOrder before converting to widget format
        let sortedHabits = self.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }

        // Convert habits to widget format
        let widgetHabits = sortedHabits.map { habit in
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
            return total + sortedHabits.filter { $0.isScheduledForDate(date) }.count
        }

        let totalCompleted = weekDates.reduce(0) { total, date in
            return total + sortedHabits.filter { $0.isScheduledForDate(date) && $0.isCompletedOnDate(date) }.count
        }
        
        let currentWeekCompletion = totalScheduled > 0 ? Int(Double(totalCompleted) / Double(totalScheduled) * 100) : 0
        
        // Calculate last week completion
        guard let lastWeekInterval = calendar.dateInterval(of: .weekOfYear,
                                                            for: calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today) else {
            return WidgetData(
                weekNumber: weekNumber,
                currentWeekCompletion: currentWeekCompletion,
                lastWeekCompletion: 0,
                actualRate: 0,
                potentialRate: 0,
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
            return total + sortedHabits.filter { $0.isScheduledForDate(date) }.count
        }

        let lastWeekTotalCompleted = lastWeekDates.reduce(0) { total, date in
            return total + sortedHabits.filter { $0.isScheduledForDate(date) && $0.isCompletedOnDate(date) }.count
        }
        
        let lastWeekCompletion = lastWeekTotalScheduled > 0 ? Int(Double(lastWeekTotalCompleted) / Double(lastWeekTotalScheduled) * 100) : 0

        // Calculate actual and potential rates (mirrors habit.calculateCompletionRate logic for widget)
        let todayStart = calendar.startOfDay(for: today)
        var completedIncludingToday = 0  // Completed including today
        var notCompletedExcludingToday = 0  // Not completed excluding today
        var potentialTotal = 0  // All scheduled this week

        for date in weekDates {
            let isPast = date < todayStart  // Only past dates, not including today

            for habit in sortedHabits {
                if habit.isScheduledForDate(date) {
                    potentialTotal += 1

                    if habit.isCompletedOnDate(date) {
                        // Count all completed (including today)
                        completedIncludingToday += 1
                    } else if isPast {
                        // Count not completed (only past days, excluding today)
                        notCompletedExcludingToday += 1
                    }
                }
            }
        }

        // Actual rate = completed (incl. today) / (completed + not completed excl. today)
        let actualRateDenominator = completedIncludingToday + notCompletedExcludingToday
        let actualRate = actualRateDenominator > 0 ? Int(Double(completedIncludingToday) / Double(actualRateDenominator) * 100) : 0

        // Potential rate = 1 - (not completed excl. today / all scheduled this week)
        let potentialRate = potentialTotal > 0 ? Int((1.0 - Double(notCompletedExcludingToday) / Double(potentialTotal)) * 100) : 100

        return WidgetData(
            weekNumber: weekNumber,
            currentWeekCompletion: currentWeekCompletion,
            lastWeekCompletion: lastWeekCompletion,
            actualRate: actualRate,
            potentialRate: potentialRate,
            habits: widgetHabits
        )
    }
}