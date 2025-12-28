//
//  WeekView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Constants
private let kMondayFirstWeekday = 2 // Calendar.firstWeekday: 1=Sunday, 2=Monday

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var retrospectives: [WeeklyRetrospective]

    @State private var currentWeek = Date()
    @State private var activeSheet: SheetType?
    @Binding var selectedTab: Int
    @State private var showingNewHabit = false

    enum SheetType: Identifiable {
        case retrospective
        case weekDetails
        case widgetInstructions

        var id: Int {
            switch self {
            case .retrospective: return 0
            case .weekDetails: return 1
            case .widgetInstructions: return 2
            }
        }
    }

    private var isCurrentWeek: Bool {
        Calendar.current.isDate(currentWeek, equalTo: Date(), toGranularity: .weekOfYear)
    }

    private var isFutureWeek: Bool {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeek) else {
            return false
        }
        return weekInterval.start > Date()
    }

    private var sortedHabits: [Habit] {
        habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }
    }

    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeek) else {
            return []
        }

        var dates: [Date] = []
        var date = weekInterval.start

        for _ in 0..<7 {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return dates
    }
    
    private var weekStartDate: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        return calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start ?? currentWeek
    }
    
    private var currentWeekRetrospective: WeeklyRetrospective? {
        let calendar = Calendar.current
        return retrospectives.first { retro in
            calendar.isDate(retro.weekStartDate, inSameDayAs: weekStartDate)
        }
    }
    
    private var weeklyCompletionData: [(String, Double)] {
        return weekDates.map { date in
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let completedCount = habits.filter { habit in
                habit.isScheduledForDate(date) && habit.isCompletedOnDate(date)
            }.count
            let scheduledCount = habits.filter { habit in
                habit.isScheduledForDate(date)
            }.count

            let percentage = scheduledCount > 0 ? Double(completedCount) / Double(scheduledCount) * 100 : 0
            return (dayName, percentage)
        }
    }

    // Calculate weekly stats (similar to habit.calculateCompletionRate but for all habits in a week)
    private var weeklyStats: (completed: Int, total: Int, notCompletedExcludingToday: Int, potentialTotal: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var completedIncludingToday = 0  // Completed including today
        var notCompletedExcludingToday = 0  // Not completed excluding today
        var potentialTotal = 0  // Total for potential calculation (all week)

        for date in weekDates {
            let isPast = date < today  // Only past dates, not including today

            for habit in habits {
                if habit.isScheduledForDate(date) {
                    potentialTotal += 1  // Always count for potential total

                    if habit.isCompletedOnDate(date) {
                        // Count all completed (including today)
                        completedIncludingToday += 1
                    } else if isPast {
                        // Only count not completed if it's in the past (excluding today)
                        notCompletedExcludingToday += 1
                    }
                }
            }
        }

        // total = completed + not completed for the actual rate formula
        let total = completedIncludingToday + notCompletedExcludingToday
        return (completedIncludingToday, total, notCompletedExcludingToday, potentialTotal)
    }

    private var actualPercentage: Int {
        guard weeklyStats.total > 0 else { return 0 }
        return Int(Double(weeklyStats.completed) / Double(weeklyStats.total) * 100)
    }

    private var potentialPercentage: Int {
        guard weeklyStats.potentialTotal > 0 else { return 100 }
        let rate = 1.0 - (Double(weeklyStats.notCompletedExcludingToday) / Double(weeklyStats.potentialTotal))
        return Int(rate * 100)
    }

    var body: some View {
        NavigationStack {
            if habits.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.checkmark",
                    title: "Track Your Week",
                    description: "Create identities to see your weekly progress and trends",
                    primaryButtonTitle: "Create First Identity",
                    primaryAction: {
                        showingNewHabit = true
                    },
                    selectedTab: $selectedTab
                )
            } else {
            ScrollView {
                VStack(spacing: 16) {
                        // Week Days Header
                        WeekDaysHeader(weekDates: weekDates)
                            .padding(.horizontal, 16)

                        // Weekly Retrospective Section
                        Button {
                            activeSheet = .retrospective
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .center) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.blue)

                                    Text("Weekly Retrospective")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: currentWeekRetrospective != nil ? "chevron.right" : "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(currentWeekRetrospective != nil ? Color.secondary : Color.blue)
                                }

                                if let retro = currentWeekRetrospective, !retro.notes.isEmpty {
                                    Text(retro.notes)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.blue.opacity(0.6))
                                        Text("Reflect on what worked and what didn't")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)

                        // Habit Rows with Completion Circles
                        VStack(spacing: 0) {
                            ForEach(sortedHabits) { habit in
                                HabitWeekRow(habit: habit, weekDates: weekDates)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                Divider()
                                    .padding(.horizontal, 12)
                            }

                            // Legend
                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                    Text("Completed")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                    Text("Missed")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                    Text("Future")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
                                        .foregroundStyle(Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                    Text("Not scheduled")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 12)

                        // Stats Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Actual Rate
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("Actual Rate")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("\(actualPercentage)%")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.primary)
                                }

                                Text("Completed (incl. today) ÷ (Completed + Not Completed excl. today)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                Text("\(actualPercentage)% = \(weeklyStats.completed) / (\(weeklyStats.completed) + \(weeklyStats.total - weeklyStats.completed))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.systemGray6))
                                    )
                            }

                            // Potential Rate
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("Potential Rate")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("\(potentialPercentage)%")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.gray.opacity(0.8))
                                }

                                Text("1 - (Not Completed excl. today ÷ All scheduled this week)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                Text("\(potentialPercentage)% = 1 - (\(weeklyStats.notCompletedExcludingToday) / \(weeklyStats.potentialTotal))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.systemGray6))
                                    )
                            }

                            // Try Widgets Button
                            Button {
                                activeSheet = .widgetInstructions
                            } label: {
                                HStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Try Widgets")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, 8)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        activeSheet = .weekDetails
                    } label: {
                        WeekHeaderView(weekStartDate: weekStartDate, stats: weeklyStats)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                            // Only navigate if next week is not in the future
                            if !Calendar.current.isDate(nextWeek, equalTo: Date(), toGranularity: .weekOfYear) && nextWeek <= Date() {
                                currentWeek = nextWeek
                            } else if Calendar.current.isDate(nextWeek, equalTo: Date(), toGranularity: .weekOfYear) {
                                currentWeek = nextWeek
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isCurrentWeek ? .gray.opacity(0.3) : .primary)
                    }
                    .disabled(isCurrentWeek)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .retrospective:
                    WeeklyRetrospectiveView(
                        weekStartDate: weekStartDate,
                        existingRetrospective: currentWeekRetrospective
                    )
                case .weekDetails:
                    WeekDetailsView(
                        habits: habits,
                        weekDates: weekDates,
                        stats: weeklyStats
                    )
                case .widgetInstructions:
                    WidgetInstructionsView()
                }
            }
            }
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView()
        }
    }
}

struct WeekHeaderView: View {
    let weekStartDate: Date
    let stats: (completed: Int, total: Int, notCompletedExcludingToday: Int, potentialTotal: Int)

    private var yearWeekText: String {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let weekNum = calendar.component(.weekOfYear, from: weekStartDate)
        let totalWeeks = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: weekStartDate)?.count ?? 52
        return String(format: "CW%d/%d", weekNum, totalWeeks)
    }

    private var percentage: Int {
        guard stats.total > 0 else { return 0 }
        return Int(Double(stats.completed) / Double(stats.total) * 100)
    }

    private var potentialPercentage: Int {
        guard stats.potentialTotal > 0 else { return 100 }
        // Potential rate = 1 - (not completed excl. today / all scheduled this week)
        let rate = 1.0 - (Double(stats.notCompletedExcludingToday) / Double(stats.potentialTotal))
        return Int(rate * 100)
    }

    private var percentageColor: Color {
        let pct = Double(percentage)
        if pct >= 80 { return .green }
        if pct >= 50 { return .orange }
        return .red
    }

    private var showPotential: Bool {
        return potentialPercentage > percentage
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(yearWeekText)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            Text("|")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)

            Text("\(percentage)%")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(percentageColor)

            if showPotential {
                Text("|")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Text("\(potentialPercentage)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(UIColor.tertiarySystemFill))
        )
    }
}

struct WeeklyRetrospectiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    let weekStartDate: Date
    let existingRetrospective: WeeklyRetrospective?

    @State private var notes: String = ""

    private var sortedHabits: [Habit] {
        habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }
    }

    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartDate) else {
            return []
        }

        var dates: [Date] = []
        var date = weekInterval.start
        for _ in 0..<7 {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return dates
    }

    private var yearWeekText: String {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let weekNum = calendar.component(.weekOfYear, from: weekStartDate)
        let totalWeeks = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: weekStartDate)?.count ?? 52
        return String(format: "CW%d/%d", weekNum, totalWeeks)
    }

    // Calculate stats for specific week (mirrors habit.calculateCompletionRate logic)
    private var weekStats: (completed: Int, total: Int, notCompletedExcludingToday: Int, potentialTotal: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var completedIncludingToday = 0
        var notCompletedExcludingToday = 0
        var potentialTotal = 0

        for date in weekDates {
            let isPast = date < today

            for habit in habits {
                if habit.isScheduledForDate(date) {
                    potentialTotal += 1

                    if habit.isCompletedOnDate(date) {
                        // Count completed (including today)
                        completedIncludingToday += 1
                    } else if isPast {
                        // Count not completed (only past days, excluding today)
                        notCompletedExcludingToday += 1
                    }
                }
            }
        }

        // total = completed + notCompleted for the actual rate formula
        let total = completedIncludingToday + notCompletedExcludingToday
        return (completedIncludingToday, total, notCompletedExcludingToday, potentialTotal)
    }

    private var actualPercentage: Int {
        guard weekStats.total > 0 else { return 0 }
        return Int(Double(weekStats.completed) / Double(weekStats.total) * 100)
    }

    private var potentialPercentage: Int {
        guard weekStats.potentialTotal > 0 else { return 100 }
        // Potential rate = 1 - (not completed excl. today / all scheduled this week)
        let rate = 1.0 - (Double(weekStats.notCompletedExcludingToday) / Double(weekStats.potentialTotal))
        return Int(rate * 100)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Retrospective notes - centered and focused
                VStack(alignment: .leading, spacing: 12) {
                    Text("How did this week go?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Reflect on your habits, wins, and lessons learned")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))

                        if notes.isEmpty {
                            Text("Start typing...")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 18)
                        }

                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(6)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(yearWeekText)
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveRetrospective()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let existing = existingRetrospective {
                notes = existing.notes
            } else {
                // Set template for new retrospectives
                notes = """
                1. Which experiments worked well?


                2. Which didn't?


                """
            }
        }
    }

    private func saveRetrospective() {
        if let existing = existingRetrospective {
            existing.notes = notes
        } else {
            let newRetro = WeeklyRetrospective(weekStartDate: weekStartDate, notes: notes)
            modelContext.insert(newRetro)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving retrospective: \(error)")
        }
    }
}

struct HabitWeekRow: View {
    let habit: Habit
    let weekDates: [Date]

    var body: some View {
        HStack(spacing: 8) {
            // Habit name and streak
            HStack(spacing: 4) {
                Text(habit.identity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("(\(habit.streak))")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Day circles
            HStack(spacing: 4) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                    DayCircle(habit: habit, date: date)
                }
            }
        }
    }
}

struct DayCircle: View {
    let habit: Habit
    let date: Date

    private var isScheduled: Bool {
        habit.isScheduledForDate(date)
    }

    private var isCompleted: Bool {
        habit.isCompletedOnDate(date)
    }

    private var isFuture: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ZStack {
            if !isScheduled {
                // Not scheduled - dotted circle
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .frame(width: 28, height: 28)
            } else if isCompleted {
                // Completed - green with checkmark
                Circle()
                    .fill(Color.green)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            } else if isFuture {
                // Future - light grey stroke only
                Circle()
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 28, height: 28)
            } else {
                // Missed - red stroke
                Circle()
                    .strokeBorder(Color.red, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }
        }
    }
}

// Weekly Progress Chart Component
struct WeeklyProgressChart: View {
    let habits: [Habit]
    let weekDates: [Date]

    @State private var showingDataTable = false

    private var habitColors: [String: Color] {
        HabitColors.colorMapping(for: habits)
    }

    private var habitData: [(habit: Habit, data: [Double])] {
        let sortedHabits = habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }
        return sortedHabits.map { habit in
            let data = weekDates.enumerated().map { index, date -> Double in
                // Calculate completion percentage up to this day
                let datesUpToThisDay = Array(weekDates.prefix(index + 1))

                var totalScheduled = 0
                var totalCompleted = 0

                for d in datesUpToThisDay {
                    if habit.isScheduledForDate(d) {
                        totalScheduled += 1
                        if habit.isCompletedOnDate(d) {
                            totalCompleted += 1
                        }
                    }
                }

                return totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
            }
            return (habit, data)
        }
    }

    private var overallData: [Double] {
        weekDates.enumerated().map { index, date -> Double in
            // Calculate overall completion percentage up to this day
            let datesUpToThisDay = Array(weekDates.prefix(index + 1))

            var totalScheduled = 0
            var totalCompleted = 0

            for d in datesUpToThisDay {
                for habit in habits {
                    if habit.isScheduledForDate(d) {
                        totalScheduled += 1
                        if habit.isCompletedOnDate(d) {
                            totalCompleted += 1
                        }
                    }
                }
            }

            return totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
        }
    }

    private var habitAverages: [(habit: Habit, average: Double)] {
        let todayIndex = weekDates.firstIndex(where: { Calendar.current.isDateInToday($0) }) ?? (weekDates.count - 1)
        let datesUpToToday = Array(weekDates.prefix(todayIndex + 1))

        return habits.map { habit in
            var totalScheduled = 0
            var totalCompleted = 0

            for date in datesUpToToday {
                if habit.isScheduledForDate(date) {
                    totalScheduled += 1
                    if habit.isCompletedOnDate(date) {
                        totalCompleted += 1
                    }
                }
            }

            let average = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
            return (habit, average)
        }
    }

    private var overallAverage: Double {
        let todayIndex = weekDates.firstIndex(where: { Calendar.current.isDateInToday($0) }) ?? (weekDates.count - 1)
        let overallUpToToday = Array(overallData.prefix(todayIndex + 1))
        return overallUpToToday.isEmpty ? 0 : overallUpToToday.reduce(0, +) / Double(overallUpToToday.count)
    }

    private var tableLabels: [String] {
        return weekDates.map { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private var tableValues: [String] {
        overallData.map { value in
            String(format: "%.0f%%", value)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .onTapGesture {
                    showingDataTable = true
                }

            // Chart
            ZStack(alignment: .topLeading) {
                let todayIndex = weekDates.firstIndex(where: { Calendar.current.isDateInToday($0) }) ?? (weekDates.count - 1)
                let allValues = habitData.flatMap { Array($0.data.prefix(todayIndex + 1)) } + Array(overallData.prefix(todayIndex + 1))
                let minValue = floor((allValues.min() ?? 0) / 10) * 10
                let maxValue = ceil((allValues.max() ?? 100) / 10) * 10
                let range = maxValue - minValue
                let yAxisValues: [Int] = {
                    if range <= 20 {
                        return stride(from: Int(maxValue), through: Int(minValue), by: -5).map { $0 }
                    } else {
                        let step = ceil(range / 4 / 10) * 10
                        return stride(from: Int(maxValue), through: Int(minValue), by: -Int(step)).map { $0 }
                    }
                }()

                // Grid lines
                VStack(spacing: 0) {
                    ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, value in
                        HStack {
                            Spacer()
                        }
                        .frame(height: 1)
                        .background(Color.gray.opacity(0.2))
                        if index < yAxisValues.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(height: 160)

                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, value in
                        Text("\(value)")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                        if index < yAxisValues.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(height: 160)

                // Line charts
                GeometryReader { geometry in
                    let chartWidth = geometry.size.width - 40
                    let chartHeight: CGFloat = 160
                    let xSpacing = chartWidth / CGFloat(weekDates.count - 1)

                    // Draw each habit - lines only, no markers
                    ForEach(habitData, id: \.habit.id) { item in
                        let dataUpToToday = Array(item.data.prefix(todayIndex + 1))

                        LinePath(data: dataUpToToday, chartHeight: chartHeight, xSpacing: xSpacing, minValue: minValue, maxValue: maxValue)
                            .stroke(habitColors[item.habit.id.uuidString] ?? .gray, lineWidth: 2)
                            .offset(x: 40)
                    }

                    // Draw overall (dashed line) - no markers
                    let overallUpToToday = Array(overallData.prefix(todayIndex + 1))

                    LinePath(data: overallUpToToday, chartHeight: chartHeight, xSpacing: xSpacing, minValue: minValue, maxValue: maxValue)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(Color(UIColor.label).opacity(0.7))
                        .offset(x: 40)
                }
                .frame(height: 160)
            }

            // X-axis labels
            HStack(spacing: 0) {
                Spacer().frame(width: 40)
                ForEach(weekDates.indices, id: \.self) { index in
                    Text(weekDates[index].formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US"))))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Legend - 3 columns
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                ForEach(habitAverages, id: \.habit.id) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(habitColors[item.habit.id.uuidString] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(item.habit.identity)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(UIColor.label).opacity(0.7))
                        .frame(width: 8, height: 8)
                    Text("Overall")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.leading, 40)
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDataTable) {
            ChartDataTable(
                title: "Weekly Trend Data",
                labels: tableLabels,
                values: tableValues
            )
        }
    }
}

// 14-Week Trend Chart Component
struct WeekTrendChart: View {
    let habits: [Habit]
    let currentWeek: Date

    @State private var showingDataTable = false

    private var habitColors: [String: Color] {
        HabitColors.colorMapping(for: habits)
    }

    private var firstHabitDate: Date {
        guard !habits.isEmpty else { return Date() }
        return habits.map { $0.createdDate }.min() ?? Date()
    }

    private var weeksSinceFirstHabit: Int {
        guard !habits.isEmpty else { return 1 }
        let calendar = Calendar.current

        // Get the start of the week for both dates
        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: firstHabitDate)?.start,
              let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start else {
            return 1
        }

        let components = calendar.dateComponents([.weekOfYear], from: firstWeek, to: currentWeekStart)
        let weeks = (components.weekOfYear ?? 0) + 1

        return max(1, min(weeks, 10))
    }

    private var habitWeeklyData: [(habit: Habit, data: [Double])] {
        let calendar = Calendar.current
        let weeksToShow = weeksSinceFirstHabit

        let sortedHabits = habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }

        return sortedHabits.map { habit in
            var data: [Double] = []

            // Pre-compute completion dates as a set for O(1) lookup
            let completionDates = Set(habit.completions.map { calendar.startOfDay(for: $0.date) })

            for weekOffset in (0..<weeksToShow).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeek) else {
                    data.append(0)
                    continue
                }

                var totalScheduled = 0
                var totalCompleted = 0

                for dayOffset in 0..<7 {
                    guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                    if habit.isScheduledForDate(date) {
                        totalScheduled += 1
                        if completionDates.contains(date) {
                            totalCompleted += 1
                        }
                    }
                }

                let percentage = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
                data.append(percentage)
            }

            return (habit, data)
        }
    }

    private var weeklyTrendData: [Double] {
        var data: [Double] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weeksToShow = weeksSinceFirstHabit

        // Pre-compute completion dates for all habits as a single set
        var allCompletionDates = Set<Date>()
        for habit in habits {
            for completion in habit.completions {
                allCompletionDates.insert(calendar.startOfDay(for: completion.date))
            }
        }

        for weekOffset in (0..<weeksToShow).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeek) else {
                data.append(0)
                continue
            }

            var completedIncludingToday = 0
            var notCompletedExcludingToday = 0

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                for habit in habits {
                    if habit.isScheduledForDate(date) {
                        if allCompletionDates.contains(date) && habit.isCompletedOnDate(date) {
                            completedIncludingToday += 1
                        } else if date < today {
                            notCompletedExcludingToday += 1
                        }
                    }
                }
            }

            let denominator = completedIncludingToday + notCompletedExcludingToday
            let percentage = denominator > 0 ? Double(completedIncludingToday) / Double(denominator) * 100 : 0
            data.append(percentage)
        }

        return data
    }

    private var movingAverage: [Double] {
        guard weeklyTrendData.count >= 3 else { return weeklyTrendData }

        var averages: [Double] = []
        for i in 0..<weeklyTrendData.count {
            if i < 2 {
                let sum = weeklyTrendData[0...i].reduce(0, +)
                averages.append(sum / Double(i + 1))
            } else {
                let sum = weeklyTrendData[i-2...i].reduce(0, +)
                averages.append(sum / 3.0)
            }
        }
        return averages
    }

    private var averageRate: Int {
        guard !weeklyTrendData.isEmpty else { return 0 }
        let sum = weeklyTrendData.reduce(0, +)
        return Int(sum / Double(weeklyTrendData.count))
    }

    private var weekNumbers: [String] {
        let calendar = Calendar.current
        var numbers: [String] = []

        for weekOffset in (0..<weeksSinceFirstHabit).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeek) else {
                numbers.append("")
                continue
            }
            let weekNum = calendar.component(.weekOfYear, from: weekStart)
            numbers.append("\(weekNum)")
        }

        return numbers
    }

    private var tableLabels: [String] {
        weekNumbers.map { "Week \($0)" }
    }

    private var tableValues: [String] {
        weeklyTrendData.map { value in
            String(format: "%.0f%%", value)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("10-Week Trend")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        showingDataTable = true
                    }

                Spacer()

                Text("Avg: \(averageRate)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            DetailedChart(
                data: weeklyTrendData,
                movingAvg: movingAverage,
                periodLabels: weekNumbers,
                color: Color(UIColor.label),
                height: 120
            )
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDataTable) {
            ChartDataTable(
                title: "10-Week Trend Data",
                labels: tableLabels,
                values: tableValues
            )
        }
    }
}

// Week Details Popup View
struct WeekDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    let weekDates: [Date]
    let stats: (completed: Int, total: Int, notCompletedExcludingToday: Int, potentialTotal: Int)

    @State private var showingWidgetInstructions = false

    private var sortedHabits: [Habit] {
        habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }
    }

    private var actualPercentage: Int {
        guard stats.total > 0 else { return 0 }
        return Int(Double(stats.completed) / Double(stats.total) * 100)
    }

    private var potentialPercentage: Int {
        guard stats.potentialTotal > 0 else { return 100 }
        // Potential rate = 1 - (not completed excl. today / all scheduled this week)
        let rate = 1.0 - (Double(stats.notCompletedExcludingToday) / Double(stats.potentialTotal))
        return Int(rate * 100)
    }

    private let dayAbbreviations = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var weekNumberText: String {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let weekNum = calendar.component(.weekOfYear, from: weekDates.first ?? Date())
        let totalWeeks = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: weekDates.first ?? Date())?.count ?? 52
        return String(format: "CW%d/%d", weekNum, totalWeeks)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Habits list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sortedHabits) { habit in
                            WeekDetailsHabitRow(habit: habit, weekDates: weekDates)
                            Divider()
                        }

                        // Explanation section
                        VStack(alignment: .leading, spacing: 16) {
                            // Legend - single row
                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                    Text("Completed")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                    Text("Missed")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                    Text("Future")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 3) {
                                    Circle()
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
                                        .foregroundStyle(Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                    Text("Not scheduled")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("Actual Rate")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("\(actualPercentage)%")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.primary)
                                }

                                Text("Completed (incl. today) ÷ (Completed + Not Completed excl. today)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                Text("\(actualPercentage)% = \(stats.completed) / (\(stats.completed) + \(stats.total - stats.completed))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.systemGray6))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("Potential Rate")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("\(potentialPercentage)%")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.gray.opacity(0.8))
                                }

                                Text("1 - (Not Completed excl. today ÷ All scheduled this week)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                Text("\(potentialPercentage)% = 1 - (\(stats.notCompletedExcludingToday) / \(stats.potentialTotal))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.systemGray6))
                                    )
                            }

                            // Try Widgets Button
                            Button {
                                showingWidgetInstructions = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Try Widgets")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                            }
                            .padding(.top, 12)
                        }
                        .padding(16)
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(weekNumberText)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingWidgetInstructions) {
                WidgetInstructionsView()
            }
        }
    }
}

struct WeekDetailsHabitRow: View {
    let habit: Habit
    let weekDates: [Date]

    private var streakText: String {
        return "(\(habit.streak))"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Identity name and streak
                HStack(spacing: 4) {
                    Text(habit.identity)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(streakText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // 7 day completion circles
                HStack(spacing: 3) {
                    ForEach(weekDates.indices, id: \.self) { index in
                        let date = weekDates[index]
                        let isScheduled = habit.isScheduledForDate(date)
                        let isCompleted = habit.isCompletedOnDate(date)
                        let isPast = date < Calendar.current.startOfDay(for: Date())

                        if isScheduled {
                            Circle()
                                .fill(isCompleted ? Color.green : Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isCompleted ? Color.green :
                                            isPast ? Color.red : Color.gray.opacity(0.3),
                                            lineWidth: 2
                                        )
                                )
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .opacity(isCompleted ? 1 : 0)
                                )
                        } else {
                            // Dotted circle for unscheduled days
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
                                .foregroundStyle(Color.gray.opacity(0.3))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }
}

// Helper to draw line paths with dynamic scaling
struct LinePath: Shape {
    let data: [Double]
    let chartHeight: CGFloat
    let xSpacing: CGFloat
    let minValue: Double
    let maxValue: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard data.count > 1 else { return path }

        let range = maxValue - minValue
        guard range > 0 else {
            // If all values are the same, draw a horizontal line in the middle
            let y = chartHeight / 2
            path.move(to: CGPoint(x: 0, y: y))
            for index in 1..<data.count {
                let x = CGFloat(index) * xSpacing
                path.addLine(to: CGPoint(x: x, y: y))
            }
            return path
        }

        let firstY = chartHeight * (1 - (data[0] - minValue) / range)
        path.move(to: CGPoint(x: 0, y: firstY))

        for index in 1..<data.count {
            let x = CGFloat(index) * xSpacing
            let y = chartHeight * (1 - (data[index] - minValue) / range)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Week Days Header

struct WeekDaysHeader: View {
    let weekDates: [Date]

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                let dayDate = Calendar.current.startOfDay(for: date)
                let isToday = dayDate == today

                Text(dayName(for: date))
                    .font(.system(size: 12, weight: isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Week Number View

struct WeekNumberView: View {
    let weekStartDate: Date

    private var yearWeekText: String {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let weekNum = calendar.component(.weekOfYear, from: weekStartDate)
        let totalWeeks = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: weekStartDate)?.count ?? 52
        return String(format: "CW%d/%d", weekNum, totalWeeks)
    }

    var body: some View {
        Text(yearWeekText)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.primary)
    }
}

// MARK: - Week Percentage View

struct WeekPercentageView: View {
    let stats: (completed: Int, total: Int, notCompletedExcludingToday: Int, potentialTotal: Int)

    private var percentage: Int {
        guard stats.total > 0 else { return 0 }
        return Int(Double(stats.completed) / Double(stats.total) * 100)
    }

    private var potentialPercentage: Int {
        guard stats.potentialTotal > 0 else { return 100 }
        let rate = 1.0 - (Double(stats.notCompletedExcludingToday) / Double(stats.potentialTotal))
        return Int(rate * 100)
    }

    private var percentageColor: Color {
        let pct = Double(percentage)
        if pct >= 80 { return .green }
        if pct >= 50 { return .orange }
        return .red
    }

    private var showPotential: Bool {
        return potentialPercentage > percentage
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(percentage)%")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(percentageColor)

            if showPotential {
                Text("|")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Text("\(potentialPercentage)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
    }
}

// Widget Instructions View
struct WidgetInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon and Title
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("Add Widgets to Your Home Screen")
                            .font(.system(size: 28, weight: .bold))

                        Text("Stay motivated by seeing your habits at a glance")
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    // Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How to Add a Widget")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)

                        // Step 1
                        HStack(alignment: .top, spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("1")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Long press your Home Screen")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Press and hold any empty area on your Home Screen until the apps start jiggling")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Step 2
                        HStack(alignment: .top, spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("2")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap the + button")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Look for the plus button in the top-left corner of your screen")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Step 3
                        HStack(alignment: .top, spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("3")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Search for 'identitybuilder'")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Type 'identitybuilder' in the search bar or scroll to find it")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Step 4
                        HStack(alignment: .top, spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("4")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose a widget")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Select either 'Habits Overview' or 'Completion Rate', pick a size, and tap 'Add Widget'")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Step 5
                        HStack(alignment: .top, spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("5")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Position your widget")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Drag the widget to your desired location and tap 'Done'")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Divider()
                        .padding(.horizontal, 20)

                    // Available Widgets
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Widgets:")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)

                        // Widget 1: Habits Overview
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checklist.checked")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Habits Overview")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Shows all your identities with 7-day completion dots (Medium & Large sizes)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Widget 2: Completion Rate
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "percent")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Completion Rate")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Displays your actual and potential completion rates (Small & Medium sizes)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab = 1
    WeekView(selectedTab: $selectedTab)
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}
