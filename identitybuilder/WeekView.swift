//
//  WeekView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var retrospectives: [WeeklyRetrospective]
    
    @State private var currentWeek = Date()
    @State private var showingRetrospective = false

    private var isCurrentWeek: Bool {
        Calendar.current.isDate(weekStartDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)

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
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Year/Week and Percentages Header
                        HStack(alignment: .firstTextBaseline) {
                            let year = Calendar.current.component(.year, from: weekStartDate)
                            let weekNum = Calendar.current.component(.weekOfYear, from: weekStartDate)

                            Text(String(format: "%d/%d", year, weekNum))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.primary)

                            Spacer()

                            HStack(spacing: 3) {
                                let currentWeekPercentage = weeklyCompletionData.reduce(0.0) { $0 + $1.1 } / Double(weeklyCompletionData.count)

                                Text("\(Int(weeklyCompletionData.last?.1 ?? 0))%")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.orange)

                                Text("/")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.secondary)

                                Text("\(Int(currentWeekPercentage))%")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                        // Week Calendar View
                        HStack(spacing: 0) {
                            ForEach(weekDates.indices, id: \.self) { index in
                                let date = weekDates[index]
                                let isToday = Calendar.current.isDateInToday(date)

                                VStack(spacing: 3) {
                                    Text(date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US"))))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)

                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(isToday ? .white : .primary)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(isToday ? Color.blue : Color.clear)
                                        )
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Weekly Progress Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly Progress")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)

                            // Simple bar chart representation
                            HStack(alignment: .bottom, spacing: 6) {
                                ForEach(Array(weeklyCompletionData.enumerated()), id: \.offset) { index, data in
                                    VStack {
                                        Rectangle()
                                            .fill(.blue)
                                            .frame(width: 24, height: max(4, data.1 * 1.2))

                                        Text(data.0)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .frame(height: 140)
                            .background(
                                VStack {
                                    ForEach([100, 75, 50, 25], id: \.self) { value in
                                        HStack {
                                            Text("\(value)%")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.gray)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                            )
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)

                        // Weekly Retrospective Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weekly Retrospective")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    showingRetrospective = true
                                } label: {
                                    Image(systemName: currentWeekRetrospective != nil ? "pencil" : "plus")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.blue)
                                }
                            }

                            if let retro = currentWeekRetrospective {
                                Text(retro.notes.isEmpty ? "No notes added yet." : retro.notes)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.primary)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.systemGray5))
                                    )
                            } else {
                                Text("Tap + to add your weekly reflection")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.gray)
                                    .italic()
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Button {
                            withAnimation {
                                currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                        }

                        Button {
                            withAnimation {
                                currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isCurrentWeek ? .gray.opacity(0.3) : .primary)
                        }
                        .disabled(isCurrentWeek)

                        if !isCurrentWeek {
                            Button {
                                withAnimation {
                                    currentWeek = Date()
                                }
                            } label: {
                                Text("Today")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingRetrospective) {
            WeeklyRetrospectiveView(
                weekStartDate: weekStartDate,
                existingRetrospective: currentWeekRetrospective
            )
        }
    }
}

struct WeeklyRetrospectiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let weekStartDate: Date
    let existingRetrospective: WeeklyRetrospective?
    
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly Retrospective")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Week of \(weekStartDate.formatted(.dateTime.weekday(.wide).month().day()))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("How did this week go? What did you learn? What would you do differently?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4))
                    )
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRetrospective()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            notes = existingRetrospective?.notes ?? ""
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

#Preview {
    WeekView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}
