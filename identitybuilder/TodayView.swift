//
//  TodayView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var showingNewHabit = false
    @State private var showingMenu = false
    
    private let today = Date()
    
    private var todaysHabits: [Habit] {
        habits.filter { $0.isScheduledForDate(today) }
    }
    
    private var completionPercentage: Int {
        guard !todaysHabits.isEmpty else { return 0 }
        let completedCount = todaysHabits.filter { $0.isCompletedOnDate(today) }.count
        return Int((Double(completedCount) / Double(todaysHabits.count)) * 100)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today (\(today.formatted(.dateTime.weekday(.wide))))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Text("\(completionPercentage)%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(completionPercentage >= 80 ? .green : completionPercentage >= 50 ? .orange : .red)
                    }
                    .padding(.horizontal)
                    
                    // Habits List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(todaysHabits) { habit in
                                HabitRowView(habit: habit, date: today)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingMenu.toggle()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                NewHabitView()
            }
            .actionSheet(isPresented: $showingMenu) {
                ActionSheet(
                    title: Text("Export or import your habit data as CSV."),
                    buttons: [
                        .default(Text("Export Backup")) {
                            // TODO: Implement export
                        },
                        .default(Text("Import Backup")) {
                            // TODO: Implement import
                        },
                        .destructive(Text("Delete All")) {
                            deleteAllHabits()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    private func deleteAllHabits() {
        for habit in habits {
            modelContext.delete(habit)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting habits: \(error)")
        }
    }
}

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit
    let date: Date
    
    @State private var isCompleted: Bool = false
    
    var body: some View {
        HStack {
            // Completion Button
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.identity)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(habit.name)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text("\(habit.streak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                
                Text("streak")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCompleted ? .green : .clear, lineWidth: 2)
                )
        )
        .onAppear {
            isCompleted = habit.isCompletedOnDate(date)
        }
    }
    
    private func toggleCompletion() {
        if let existingCompletion = habit.completionForDate(date) {
            // Remove completion
            modelContext.delete(existingCompletion)
            isCompleted = false
        } else {
            // Add completion
            let completion = HabitCompletion(date: date, habit: habit)
            modelContext.insert(completion)
            habit.completions.append(completion)
            isCompleted = true
        }
        
        // Update streak
        habit.updateStreak()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving completion: \(error)")
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}