//
//  HabitWidget.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import WidgetKit
import SwiftUI

// MARK: - Habits Overview Widget
struct HabitsOverviewWidget: Widget {
    let kind: String = "HabitsOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitsWidgetProvider()) { entry in
            HabitsOverviewWidgetView(entry: entry)
                .containerBackground(Color(UIColor.systemBackground), for: .widget)
        }
        .configurationDisplayName("Habits Overview")
        .description("View all your identities with 7-day completion dots")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Shared Timeline Provider
struct HabitsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsWidgetEntry {
        HabitsWidgetEntry(date: Date(), widgetData: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitsWidgetEntry) -> ()) {
        let entry = HabitsWidgetEntry(date: Date(), widgetData: .sample)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsWidgetEntry>) -> ()) {
        let currentDate = Date()
        let widgetData = loadWidgetData(for: currentDate)
        let entry = HabitsWidgetEntry(date: currentDate, widgetData: widgetData)

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

struct HabitsWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Habits Overview Widget View
struct HabitsOverviewWidgetView: View {
    var entry: HabitsWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("CW\(entry.widgetData.weekNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(entry.widgetData.actualRate)%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.green)
            }

            Divider()

            // Habits
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.widgetData.habits, id: \.identity) { habit in
                    HabitRowWidget(habit: habit)
                }
            }

            Spacer()
        }
        .padding(12)
        .widgetURL(URL(string: "identitybuilder://"))
    }
}

// MARK: - Habit Row Component
struct HabitRowWidget: View {
    let habit: WidgetHabit

    var body: some View {
        HStack(spacing: 6) {
            // Identity and streak
            HStack(spacing: 3) {
                Text(habit.identity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                Text("(\(habit.streak))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 7-day completion dots
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    completionCircle(for: dayIndex)
                }
            }
        }
    }

    @ViewBuilder
    private func completionCircle(for dayIndex: Int) -> some View {
        let isCompleted = dayIndex < habit.weeklyCompletions.count && habit.weeklyCompletions[dayIndex]
        let todayWeekday = getTodayWeekday()
        let isPast = dayIndex < todayWeekday

        Circle()
            .fill(isCompleted ? Color.green : Color.clear)
            .overlay(
                Circle()
                    .stroke(
                        isCompleted ? Color.green :
                        isPast ? Color.red.opacity(0.7) : Color.gray.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(isCompleted ? 1 : 0)
            )
    }

    private func getTodayWeekday() -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday + 5) % 7 // Convert to Monday=0
    }
}

// MARK: - Completion Rate Widget
struct CompletionRateWidget: Widget {
    let kind: String = "CompletionRateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitsWidgetProvider()) { entry in
            CompletionRateWidgetView(entry: entry)
                .containerBackground(Color(UIColor.systemBackground), for: .widget)
        }
        .configurationDisplayName("Completion Rate")
        .description("View your actual and potential completion rates")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CompletionRateWidgetView: View {
    var entry: HabitsWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            smallWidgetView
        } else {
            mediumWidgetView
        }
    }

    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            Text("CW\(entry.widgetData.weekNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("\(entry.widgetData.actualRate)%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.green)

                Text("Actual")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if entry.widgetData.potentialRate > entry.widgetData.actualRate {
                VStack(spacing: 2) {
                    Text("\(entry.widgetData.potentialRate)%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.7))

                    Text("Potential")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .widgetURL(URL(string: "identitybuilder://"))
    }

    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // Actual Rate
            VStack(spacing: 8) {
                Text("Actual Rate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(entry.widgetData.actualRate)%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.green)

                Text("CW\(entry.widgetData.weekNumber)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Potential Rate
            VStack(spacing: 8) {
                Text("Potential Rate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(entry.widgetData.potentialRate)%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.7))

                Text("If all completed")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .widgetURL(URL(string: "identitybuilder://"))
    }
}

#Preview("Habits Overview - Medium", as: .systemMedium) {
    HabitsOverviewWidget()
} timeline: {
    HabitsWidgetEntry(date: Date(), widgetData: .sample)
}

#Preview("Habits Overview - Large", as: .systemLarge) {
    HabitsOverviewWidget()
} timeline: {
    HabitsWidgetEntry(date: Date(), widgetData: .sample)
}

#Preview("Completion Rate - Small", as: .systemSmall) {
    CompletionRateWidget()
} timeline: {
    HabitsWidgetEntry(date: Date(), widgetData: .sample)
}

#Preview("Completion Rate - Medium", as: .systemMedium) {
    CompletionRateWidget()
} timeline: {
    HabitsWidgetEntry(date: Date(), widgetData: .sample)
}