//
//  WeekView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData
import Charts

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var retrospectives: [WeeklyRetrospective]
    
    @State private var currentWeek = Date()
    @State private var showingRetrospective = false
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
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
        let calendar = Calendar.current
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
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Week Navigation Header
                        HStack {
                            Button {
                                withAnimation {
                                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("This Week")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                
                                Text(weekStartDate.formatted(.dateTime.year().weekOfYear()))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Week Calendar View
                        HStack {
                            ForEach(weekDates, id: \.self) { date in
                                VStack(spacing: 8) {
                                    Text(date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US"))))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                    
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Week Widget Preview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Week Widget Preview")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            ForEach(habits) { habit in
                                HStack {
                                    Text("\(habit.identity)(\(habit.streak))")
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        ForEach(weekDates, id: \.self) { date in
                                            Circle()
                                                .frame(width: 20, height: 20)
                                                .foregroundStyle(
                                                    habit.isScheduledForDate(date) ?
                                                    (habit.isCompletedOnDate(date) ? .green : .red) :
                                                    .clear
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(.gray, lineWidth: habit.isScheduledForDate(date) ? 0 : 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                        
                        // Weekly Progress Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Progress")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Chart {
                                ForEach(Array(weeklyCompletionData.enumerated()), id: \.offset) { index, data in
                                    LinePlot(
                                        x: .value("Day", data.0),
                                        y: .value("Percentage", data.1)
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(height: 200)
                            .chartYScale(domain: 0...100)
                            .chartXAxis {
                                AxisMarks(values: weeklyCompletionData.map { $0.0 }) { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                        
                        // Weekly Retrospective Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Weekly Retrospective")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Button {
                                    showingRetrospective = true
                                } label: {
                                    Image(systemName: currentWeekRetrospective != nil ? "pencil" : "plus")
                                        .foregroundStyle(.blue)
                                }
                            }
                            
                            if let retro = currentWeekRetrospective {
                                Text(retro.notes.isEmpty ? "No notes added yet." : retro.notes)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                    )
                            } else {
                                Text("Tap + to add your weekly reflection")
                                    .foregroundStyle(.gray)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
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
                    .textEditorStyle(.roundedBorder)
                    .frame(minHeight: 200)
                
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