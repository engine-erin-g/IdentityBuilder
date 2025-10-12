//
//  HabitWidget.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import WidgetKit
import SwiftUI

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
        HabitWidgetEntry(date: Date(), widgetData: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> ()) {
        let entry = HabitWidgetEntry(date: Date(), widgetData: .sample)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> ()) {
        let currentDate = Date()
        let widgetData = loadWidgetData(for: currentDate)
        let entry = HabitWidgetEntry(date: currentDate, widgetData: widgetData)

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadWidgetData(for date: Date) -> WidgetData {
        // Try to load real data from shared UserDefaults
        if let savedData = SharedData.shared.loadWidgetData() {
            return savedData
        }
        
        // Fallback to sample data
        return .sample
    }
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

struct HabitWidgetEntryView: View {
    var entry: HabitWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Week \(entry.widgetData.weekNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(entry.widgetData.currentWeekCompletion)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("/")
                        .foregroundColor(.gray)
                    
                    Text("\(entry.widgetData.lastWeekCompletion)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Habits
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.widgetData.habits, id: \.identity) { habit in
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
    let habit: WidgetHabit
    
    var body: some View {
        HStack {
            Text("\(habit.identity) (\(habit.streak))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
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
        let currentDayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1 // Convert to 0-based
        let isPastDay = dayIndex < currentDayOfWeek
        
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
        let currentDayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1
        let isPastDay = dayIndex < currentDayOfWeek
        
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
    HabitWidgetEntry(date: Date(), widgetData: .sample)
}