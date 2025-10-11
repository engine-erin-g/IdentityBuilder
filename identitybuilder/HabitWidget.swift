//
//  HabitWidget.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your weekly habit progress")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct HabitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(
            date: Date(),
            habits: sampleHabits(),
            weekNumber: Calendar.current.component(.weekOfYear, from: Date()),
            currentWeekCompletion: 66,
            lastWeekCompletion: 94
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> ()) {
        let entry = HabitWidgetEntry(
            date: Date(),
            habits: sampleHabits(),
            weekNumber: Calendar.current.component(.weekOfYear, from: Date()),
            currentWeekCompletion: 66,
            lastWeekCompletion: 94
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> ()) {
        // Load real data from SwiftData here if needed
        let currentDate = Date()
        let entry = HabitWidgetEntry(
            date: currentDate,
            habits: loadHabitsData(),
            weekNumber: Calendar.current.component(.weekOfYear, from: currentDate),
            currentWeekCompletion: calculateCurrentWeekCompletion(),
            lastWeekCompletion: calculateLastWeekCompletion()
        )

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadHabitsData() -> [HabitWidgetData] {
        // In a real implementation, you would load from SwiftData
        return sampleHabits()
    }
    
    private func calculateCurrentWeekCompletion() -> Int {
        // Calculate real completion percentage
        return 66
    }
    
    private func calculateLastWeekCompletion() -> Int {
        // Calculate real last week completion
        return 94
    }
    
    private func sampleHabits() -> [HabitWidgetData] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current week dates
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        
        var weekDates: [Date] = []
        var date = weekInterval.start
        
        for _ in 0..<7 {
            weekDates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return [
            HabitWidgetData(
                identity: "Reader",
                streak: 25,
                weeklyCompletions: [true, true, true, false, false, false, false]
            ),
            HabitWidgetData(
                identity: "Athlete",
                streak: 1,
                weeklyCompletions: [true, false, true, false, false, false, false]
            ),
            HabitWidgetData(
                identity: "Temperance",
                streak: 0,
                weeklyCompletions: [true, false, false, false, false, false, false]
            ),
            HabitWidgetData(
                identity: "Present",
                streak: 4,
                weeklyCompletions: [true, true, false, false, false, false, false]
            ),
            HabitWidgetData(
                identity: "Entrepreneur",
                streak: 4,
                weeklyCompletions: [true, true, false, false, false, false, false]
            )
        ]
    }
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [HabitWidgetData]
    let weekNumber: Int
    let currentWeekCompletion: Int
    let lastWeekCompletion: Int
}

struct HabitWidgetData {
    let identity: String
    let streak: Int
    let weeklyCompletions: [Bool] // Array of 7 bools for each day of the week
}

struct HabitWidgetEntryView: View {
    var entry: HabitWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Week \(entry.weekNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(entry.currentWeekCompletion)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("/")
                        .foregroundColor(.gray)
                    
                    Text("\(entry.lastWeekCompletion)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Habits
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.habits, id: \.identity) { habit in
                    HabitRowWidget(habit: habit)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}

struct HabitRowWidget: View {
    let habit: HabitWidgetData
    
    var body: some View {
        HStack {
            Text("\(habit.identity) (\(habit.streak))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<7) { dayIndex in
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundColor(completionColor(for: dayIndex))
                        .overlay(
                            completionSymbol(for: dayIndex)
                        )
                }
            }
        }
    }
    
    private func completionColor(for dayIndex: Int) -> Color {
        guard dayIndex < habit.weeklyCompletions.count else { return .gray }
        
        let isCompleted = habit.weeklyCompletions[dayIndex]
        let isPastDay = dayIndex < Calendar.current.component(.weekday, from: Date()) - 1
        
        if isCompleted {
            return .green
        } else if isPastDay {
            return .red
        } else {
            return .gray
        }
    }
    
    private func completionSymbol(for dayIndex: Int) -> some View {
        guard dayIndex < habit.weeklyCompletions.count else {
            return AnyView(EmptyView())
        }
        
        let isCompleted = habit.weeklyCompletions[dayIndex]
        let isPastDay = dayIndex < Calendar.current.component(.weekday, from: Date()) - 1
        
        if isCompleted {
            return AnyView(
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            )
        } else if isPastDay {
            return AnyView(
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

#Preview(as: .systemMedium) {
    HabitWidget()
} timeline: {
    HabitWidgetEntry(
        date: Date(),
        habits: [
            HabitWidgetData(identity: "Reader", streak: 25, weeklyCompletions: [true, true, true, false, false, false, false]),
            HabitWidgetData(identity: "Athlete", streak: 1, weeklyCompletions: [true, false, true, false, false, false, false]),
            HabitWidgetData(identity: "Temperance", streak: 0, weeklyCompletions: [true, false, false, false, false, false, false])
        ],
        weekNumber: 41,
        currentWeekCompletion: 66,
        lastWeekCompletion: 94
    )
}