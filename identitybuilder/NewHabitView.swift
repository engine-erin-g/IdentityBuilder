//
//  NewHabitView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct NewHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var habitName = ""
    @State private var identity = ""
    @State private var experiments: [String] = []
    @State private var experimentHistory: [String] = []
    @State private var newExperiment = ""
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 0] // All days selected by default

    private let weekdays = [
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri"),
        (6, "Sat"),
        (0, "Sun")
    ]
    
    var isValidForm: Bool {
        !habitName.isEmpty && !identity.isEmpty && !selectedDays.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("HABIT") {
                    TextField("What do you want to do?", text: $habitName)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("e.g., \"Exercise for 30 minutes\", \"Read for 20 minutes\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("IDENTITY") {
                    TextField("What identity are you building?", text: $identity)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("e.g., \"Athlete\", \"Reader\", \"Leader\", \"Artist\", \"Entrepreneur\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("SCHEDULE") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(weekdays, id: \.0) { dayIndex, dayName in
                            Button {
                                if selectedDays.contains(dayIndex) {
                                    selectedDays.remove(dayIndex)
                                } else {
                                    selectedDays.insert(dayIndex)
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(dayName)
                                        .font(.caption)
                                        .foregroundStyle(.primary)

                                    Circle()
                                        .fill(selectedDays.contains(dayIndex) ? .blue : Color(UIColor.systemGray5))
                                        .overlay(
                                            Circle()
                                                .stroke(Color(UIColor.systemGray3), lineWidth: selectedDays.contains(dayIndex) ? 0 : 1)
                                        )
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("EXPERIMENTS (OPTIONAL)") {
                    HStack {
                        TextField("Add experiment...", text: $newExperiment)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            if !newExperiment.isEmpty {
                                experiments.append(newExperiment)
                                // Add to history if not already there
                                if !experimentHistory.contains(newExperiment) {
                                    experimentHistory.append(newExperiment)
                                }
                                newExperiment = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .disabled(newExperiment.isEmpty)
                    }

                    ForEach(experiments.indices, id: \.self) { index in
                        HStack {
                            Text(experiments[index])
                            Spacer()
                            Button {
                                // Keep in history even when removed
                                experiments.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good habits - Make them:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Obvious: put gym shoes by door, prep tomorrow's clothes")
                            Text("• Attractive: only watch shows while exercising, use nice journal")
                            Text("• Easy: start with 2 min, reduce steps, pre-prep")
                            Text("• Satisfying: track with X's, share progress, reward yourself")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Text("Bad habits - Make them:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Invisible: hide phone in drawer, keep junk food out of house")
                            Text("• Unattractive: visualize consequences, make it ugly")
                            Text("• Difficult: uninstall apps, add friction, lock it away")
                            Text("• Unsatisfying: accountability partner, public commitment")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addHabit()
                        dismiss()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
    }
    
    private func addHabit() {
        // Add any pending experiment in the text field
        if !newExperiment.isEmpty {
            experiments.append(newExperiment)
            if !experimentHistory.contains(newExperiment) {
                experimentHistory.append(newExperiment)
            }
        }

        let newHabit = Habit(
            name: habitName,
            identity: identity,
            experiments: experiments,
            selectedDays: selectedDays
        )

        // Set experiment history
        newHabit.experimentHistory = experimentHistory

        modelContext.insert(newHabit)

        do {
            try modelContext.save()

            // Fetch all habits and update widget data
            let fetchDescriptor = FetchDescriptor<Habit>()
            if let allHabits = try? modelContext.fetch(fetchDescriptor) {
                let widgetData = allHabits.toWidgetData()
                SharedData.shared.saveWidgetData(widgetData)
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("Error saving habit: \(error)")
        }
    }
}

#Preview {
    NewHabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}