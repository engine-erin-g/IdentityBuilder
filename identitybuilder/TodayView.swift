//
//  TodayView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var showingNewHabit = false
    @State private var showingMenu = false
    @State private var selectedDate = Date()
    @State private var showingExportShare = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    
    private var todaysHabits: [Habit] {
        habits.filter { $0.isScheduledForDate(selectedDate) }
    }

    private var completionPercentage: Int {
        guard !todaysHabits.isEmpty else { return 0 }
        let completedCount = todaysHabits.filter { $0.isCompletedOnDate(selectedDate) }.count
        return Int((Double(completedCount) / Double(todaysHabits.count)) * 100)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var dateTitle: String {
        if isToday {
            return "Today (\(selectedDate.formatted(.dateTime.weekday(.abbreviated))))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 8) {
                    // Empty spacer for toolbar alignment
                    Spacer()
                        .frame(height: 0)

                    // Date and completion
                    HStack(alignment: .firstTextBaseline) {
                        Text(selectedDate.formatted(.dateTime.weekday(.abbreviated).month().day()))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(completionPercentage)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(completionPercentage >= 80 ? .green : completionPercentage >= 50 ? .orange : .red)
                    }
                    .padding(.horizontal, 16)

                    // Habits List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(todaysHabits) { habit in
                                HabitRowView(habit: habit, date: selectedDate, onUpdate: updateWidgetData)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Button {
                            withAnimation {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                        }

                        Button {
                            withAnimation {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isToday ? .gray.opacity(0.3) : .primary)
                        }
                        .disabled(isToday)

                        if !isToday {
                            Button {
                                withAnimation {
                                    selectedDate = Date()
                                }
                            } label: {
                                Text("Today")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        #if DEBUG
                        Button {
                            Task { @MainActor in
                                SampleData.createSampleHabits(modelContext: modelContext)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                        #endif

                        Button {
                            showingMenu.toggle()
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }

                        Button {
                            showingNewHabit = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                NewHabitView()
            }
            .alert("Export or import your habit data as CSV.", isPresented: $showingMenu) {
                Button("Export Backup") {
                    exportBackup()
                }
                Button("Import Backup") {
                    showingImportPicker = true
                }
                Button("Delete All", role: .destructive) {
                    deleteAllHabits()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .onAppear {
                updateWidgetData()
            }
        }
    }
    
    private func deleteAllHabits() {
        for habit in habits {
            modelContext.delete(habit)
        }
        
        do {
            try modelContext.save()
            // Update widget after deleting habits
            SharedData.shared.saveWidgetData(.sample) // Clear widget data
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error deleting habits: \(error)")
        }
    }
    
    // Update widget data whenever habits change
    private func updateWidgetData() {
        let widgetData = habits.toWidgetData()
        SharedData.shared.saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func exportBackup() {
        var csvContent = "Habit Name,Identity Statement,Created At,Is Active,Completion Dates,Experiments\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for habit in habits {
            let name = habit.name
            let identity = habit.identity
            let createdAt = dateFormatter.string(from: habit.createdDate)
            let isActive = "true"

            // Sort completions by date and format them
            let sortedCompletions = habit.completions.sorted { $0.date < $1.date }
            let completionDates = sortedCompletions.map { dateFormatter.string(from: $0.date) }.joined(separator: "|")

            let experiments = habit.experiments.joined(separator: "|")

            csvContent += "\(name),\(identity),\(createdAt),\(isActive),\(completionDates),\(experiments)\n"
        }

        let fileName = "habits_backup_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showingExportShare = true
        } catch {
            print("Error exporting: \(error)")
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBackup(from: url)
        case .failure(let error):
            print("Error selecting file: \(error)")
        }
    }

    private func importBackup(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)

            // Skip header
            guard lines.count > 1 else { return }

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            // Clear existing habits
            for habit in habits {
                modelContext.delete(habit)
            }

            for line in lines.dropFirst() where !line.isEmpty {
                let columns = parseCSVLine(line)
                guard columns.count >= 6 else { continue }

                let name = columns[0]
                let identity = columns[1]
                let createdAtStr = columns[2]
                // columns[3] is "Is Active" - we ignore it for now
                let completionDatesStr = columns[4]
                let experimentsStr = columns[5]

                // Parse experiments
                let experiments = experimentsStr.isEmpty ? [] : experimentsStr.split(separator: "|").map { String($0) }

                // Default to all days selected (since original format doesn't specify)
                let selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6]

                // Create habit
                let habit = Habit(name: name, identity: identity, experiments: experiments, selectedDays: selectedDays)

                // Set created date if available
                if let createdDate = dateFormatter.date(from: createdAtStr) {
                    habit.createdDate = createdDate
                }

                modelContext.insert(habit)

                // Parse and add completions
                if !completionDatesStr.isEmpty {
                    let completionDateStrings = completionDatesStr.split(separator: "|")
                    for dateStr in completionDateStrings {
                        if let date = dateFormatter.date(from: String(dateStr)) {
                            let completion = HabitCompletion(date: date, habit: habit)
                            modelContext.insert(completion)
                            habit.completions.append(completion)
                        }
                    }
                }

                habit.updateStreak()
            }

            try modelContext.save()
            updateWidgetData()
        } catch {
            print("Error importing: \(error)")
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)

        return result
    }
}

// Share sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit
    let date: Date
    let onUpdate: () -> Void // Callback to update widget data

    @State private var isCompleted: Bool = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Completion Button
                Button {
                    toggleCompletion()
                } label: {
                    Circle()
                        .strokeBorder(isCompleted ? Color.green : Color.gray.opacity(0.5), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(isCompleted ? Color.green : Color.clear)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(isCompleted ? 1 : 0)
                        )
                        .frame(width: 28, height: 28)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.identity)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(habit.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(habit.streak)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.orange)

                    Text("streak")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, habit.experiments.isEmpty ? 10 : 6)

            // Experiments
            if !habit.experiments.isEmpty {
                HStack(spacing: 5) {
                    ForEach(habit.experiments, id: \.self) { experiment in
                        Text(experiment)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.blue.opacity(0.2))
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ?
                    Color.green.opacity(0.15) :
                    Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            toggleCompletion()
        }
        .onLongPressGesture {
            showingEditSheet = true
        }
        .onAppear {
            isCompleted = habit.isCompletedOnDate(date)
        }
        .onChange(of: date) { oldValue, newValue in
            isCompleted = habit.isCompletedOnDate(newValue)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit, onDelete: {
                showingDeleteAlert = true
            })
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete \"\(habit.identity)\"? This action cannot be undone.")
        }
    }
    
    private func toggleCompletion() {
        if let existingCompletion = habit.completionForDate(date) {
            // Remove completion
            habit.completions.removeAll { $0.id == existingCompletion.id }
            modelContext.delete(existingCompletion)
            isCompleted = false
        } else {
            // Add completion
            let completion = HabitCompletion(date: date, habit: habit)
            modelContext.insert(completion)
            habit.completions.append(completion)
            isCompleted = true
        }

        do {
            try modelContext.save()

            // Update streak after saving
            habit.updateStreak()

            // Update widget data after saving
            onUpdate()
        } catch {
            print("Error saving completion: \(error)")
        }
    }

    private func deleteHabit() {
        modelContext.delete(habit)
        do {
            try modelContext.save()
            onUpdate()
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
}

struct EditHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let onDelete: () -> Void

    @State private var habitName: String
    @State private var identity: String
    @State private var experiments: [String]
    @State private var experimentHistory: [String]
    @State private var newExperiment = ""
    @State private var selectedDays: Set<Int>

    private let weekdays = [
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri"),
        (6, "Sat"),
        (0, "Sun")
    ]

    init(habit: Habit, onDelete: @escaping () -> Void) {
        self.habit = habit
        self.onDelete = onDelete
        _habitName = State(initialValue: habit.name)
        _identity = State(initialValue: habit.identity)
        _experiments = State(initialValue: habit.experiments)
        _experimentHistory = State(initialValue: habit.experimentHistory)
        _selectedDays = State(initialValue: habit.selectedDays)
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

                // Show experiment history if there are any past experiments
                if !experimentHistory.isEmpty {
                    Section("EXPERIMENT HISTORY") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(experimentHistory, id: \.self) { experiment in
                                HStack {
                                    Text(experiment)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if experiments.contains(experiment) {
                                        Text("Active")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.green.opacity(0.2))
                                            )
                                    } else {
                                        Text("Past")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(UIColor.systemGray5))
                                            )
                                    }
                                }
                            }
                        }

                        Text("This is a record of all experiments you've tried with this habit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }

                Section {
                    Button("Delete Habit", role: .destructive) {
                        dismiss()
                        onDelete()
                    }
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
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(habitName.isEmpty || identity.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        // Add any pending experiment in the text field
        if !newExperiment.isEmpty {
            experiments.append(newExperiment)
            if !experimentHistory.contains(newExperiment) {
                experimentHistory.append(newExperiment)
            }
        }

        habit.name = habitName
        habit.identity = identity
        habit.experiments = experiments
        habit.experimentHistory = experimentHistory
        habit.selectedDays = selectedDays

        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}