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
    @Query(sort: \Habit.sortOrder, order: .forward) private var habits: [Habit]
    @Query private var retrospectives: [WeeklyRetrospective]
    @State private var showingNewHabit = false
    @State private var showingMenu = false
    @State private var selectedDate = Date()
    @State private var showingExportShare = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @Binding var selectedTab: Int
    
    private var todaysHabits: [Habit] {
        habits.sorted { habit1, habit2 in
            // Primary sort by sortOrder
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            // Fallback to createdDate if sortOrder is the same
            return habit1.createdDate < habit2.createdDate
        }
    }

    private var completionPercentage: Int {
        let scheduledHabits = todaysHabits.filter { $0.isScheduledForDate(selectedDate) }
        guard !scheduledHabits.isEmpty else { return 0 }
        let completedCount = scheduledHabits.filter { $0.isCompletedOnDate(selectedDate) }.count
        return Int((Double(completedCount) / Double(scheduledHabits.count)) * 100)
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
            ScrollView {
                VStack(spacing: 8) {
                    if todaysHabits.isEmpty {
                        EmptyStateView(
                            icon: "figure.walk.circle",
                            title: "Start Building Your Identity",
                            description: "Create your first identity-based habit and begin your transformation journey",
                            primaryButtonTitle: "Create First Identity",
                            primaryAction: {
                                showingNewHabit = true
                            },
                            selectedTab: $selectedTab
                        )
                    } else {
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
                        .padding(.top, 8)

                        // Habits List
                        LazyVStack(spacing: 8) {
                            ForEach(Array(todaysHabits.enumerated()), id: \.element.id) { index, habit in
                                HabitRowView(
                                    habit: habit,
                                    date: selectedDate,
                                    isFirst: index == 0,
                                    isLast: index == todaysHabits.count - 1,
                                    onUpdate: updateWidgetData,
                                    onMoveUp: { moveHabitUp(habit) },
                                    onMoveDown: { moveHabitDown(habit) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                // Always start on today's date when view appears
                selectedDate = Date()

                // Initialize sortOrder for habits that don't have one
                initializeSortOrder()
            }
            .toolbar {
                if !todaysHabits.isEmpty {
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
                                        .fixedSize()
                                }
                            }
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 10) {
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
        }
    }
    
    private func deleteAllHabits() {
        for habit in habits {
            modelContext.delete(habit)
        }
        
        do {
            try modelContext.save()
            // Update widget after deleting habits
            Task.detached(priority: .background) {
                await SharedData.shared.saveWidgetData(.sample) // Clear widget data
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("Error deleting habits: \(error)")
        }
    }
    
    private func initializeSortOrder() {
        // Get the max sortOrder currently in use
        let maxSortOrder = habits.map { $0.sortOrder }.max() ?? 0

        // Find habits with sortOrder of 0 (uninitialized)
        let habitsNeedingSortOrder = habits.filter { $0.sortOrder == 0 }
        guard !habitsNeedingSortOrder.isEmpty else { return }

        // Sort by createdDate and assign sequential sortOrder starting after maxSortOrder
        let sortedByDate = habitsNeedingSortOrder.sorted { $0.createdDate < $1.createdDate }
        for (index, habit) in sortedByDate.enumerated() {
            habit.sortOrder = maxSortOrder + index + 1
        }

        do {
            try modelContext.save()
        } catch {
            print("Error initializing sortOrder: \(error)")
        }
    }

    private func moveHabitUp(_ habit: Habit) {
        let sortedHabits = todaysHabits
        guard let currentIndex = sortedHabits.firstIndex(where: { $0.id == habit.id }),
              currentIndex > 0 else { return }

        let previousHabit = sortedHabits[currentIndex - 1]

        // Swap sort orders
        let tempOrder = habit.sortOrder
        habit.sortOrder = previousHabit.sortOrder
        previousHabit.sortOrder = tempOrder

        do {
            try modelContext.save()
            updateWidgetData()
        } catch {
            print("Error moving habit up: \(error)")
        }
    }

    private func moveHabitDown(_ habit: Habit) {
        let sortedHabits = todaysHabits
        guard let currentIndex = sortedHabits.firstIndex(where: { $0.id == habit.id }),
              currentIndex < sortedHabits.count - 1 else { return }

        let nextHabit = sortedHabits[currentIndex + 1]

        // Swap sort orders
        let tempOrder = habit.sortOrder
        habit.sortOrder = nextHabit.sortOrder
        nextHabit.sortOrder = tempOrder

        do {
            try modelContext.save()
            updateWidgetData()
        } catch {
            print("Error moving habit down: \(error)")
        }
    }

    // Update widget data whenever habits change
    private func updateWidgetData() {
        // Only update if there are actual changes - widget updates are expensive
        let widgetData = habits.toWidgetData()

        Task.detached(priority: .background) {
            await SharedData.shared.saveWidgetData(widgetData)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func exportBackup() {
        // CSV Header with all fields
        var csvContent = "Habit Name,Identity Statement,Created At,Selected Days,Completion Dates,Active Experiments,Experiment History,Sort Order\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Export habits in sorted order
        let sortedHabits = habits.sorted { habit1, habit2 in
            if habit1.sortOrder != habit2.sortOrder {
                return habit1.sortOrder < habit2.sortOrder
            }
            return habit1.createdDate < habit2.createdDate
        }

        for habit in sortedHabits {
            let name = escapeCSV(habit.name)
            let identity = escapeCSV(habit.identity)
            let createdAt = dateFormatter.string(from: habit.createdDate)

            // Selected days as comma-separated numbers (0=Sun, 1=Mon, etc.)
            let selectedDays = habit.selectedDays.sorted().map(String.init).joined(separator: ",")

            // Sort completions by date and format them
            let sortedCompletions = habit.completions.sorted { $0.date < $1.date }
            let completionDates = sortedCompletions.map { dateFormatter.string(from: $0.date) }.joined(separator: "|")

            // Active experiments
            let activeExperiments = habit.experiments.map { escapeCSV($0) }.joined(separator: "|")

            // Experiment history (all experiments ever tried)
            let experimentHistory = habit.experimentHistory.map { escapeCSV($0) }.joined(separator: "|")

            csvContent += "\"\(name)\",\"\(identity)\",\(createdAt),\"\(selectedDays)\",\"\(completionDates)\",\"\(activeExperiments)\",\"\(experimentHistory)\",\(habit.sortOrder)\n"
        }

        // Add separator line
        csvContent += "---RETROSPECTIVES---\n"

        // Export retrospectives
        for retro in retrospectives {
            let weekStart = dateFormatter.string(from: retro.weekStartDate)
            let notes = escapeCSV(retro.notes)
            csvContent += "\(weekStart),\"\(notes)\"\n"
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

    private func escapeCSV(_ string: String) -> String {
        // Escape quotes by doubling them
        return string.replacingOccurrences(of: "\"", with: "\"\"")
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

            // Fallback formatter without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]

            // Clear existing habits and retrospectives
            for habit in habits {
                modelContext.delete(habit)
            }
            let retroDescriptor = FetchDescriptor<WeeklyRetrospective>()
            if let existingRetros = try? modelContext.fetch(retroDescriptor) {
                for retro in existingRetros {
                    modelContext.delete(retro)
                }
            }

            var isParsingRetros = false

            for line in lines.dropFirst() where !line.isEmpty {
                // Check for retrospectives separator
                if line.contains("---RETROSPECTIVES---") {
                    isParsingRetros = true
                    continue
                }

                let columns = parseCSVLine(line)

                if isParsingRetros {
                    // Parse retrospective
                    guard columns.count >= 2 else { continue }
                    let weekStartStr = columns[0]
                    let notes = columns[1]

                    if let weekStart = dateFormatter.date(from: weekStartStr) ?? fallbackFormatter.date(from: weekStartStr) {
                        let retro = WeeklyRetrospective(weekStartDate: weekStart, notes: notes)
                        modelContext.insert(retro)
                    }
                } else {
                    // Parse habit - support old formats (6-7 cols) and new format with sortOrder (8 cols)
                    guard columns.count >= 6 else { continue }

                    let name = columns[0]
                    let identity = columns[1]
                    let createdAtStr = columns[2]

                    // Determine format based on column count
                    let selectedDaysStr: String
                    let completionDatesStr: String
                    let activeExperimentsStr: String
                    let experimentHistoryStr: String
                    let sortOrder: Int

                    if columns.count >= 8 {
                        // New format with sortOrder (8 columns)
                        selectedDaysStr = columns[3]
                        completionDatesStr = columns[4]
                        activeExperimentsStr = columns[5]
                        experimentHistoryStr = columns[6]
                        sortOrder = Int(columns[7]) ?? 0
                    } else if columns.count >= 7 {
                        // Format with experimentHistory but no sortOrder (7 columns)
                        selectedDaysStr = columns[3]
                        completionDatesStr = columns[4]
                        activeExperimentsStr = columns[5]
                        experimentHistoryStr = columns[6]
                        sortOrder = 0
                    } else {
                        // Old format (6 columns): backwards compatibility
                        selectedDaysStr = ""
                        completionDatesStr = columns[4]
                        activeExperimentsStr = columns[5]
                        experimentHistoryStr = activeExperimentsStr // Use same as active
                        sortOrder = 0
                    }

                    // Parse selected days
                    let selectedDays: Set<Int>
                    if !selectedDaysStr.isEmpty {
                        selectedDays = Set(selectedDaysStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
                    } else {
                        selectedDays = [0, 1, 2, 3, 4, 5, 6] // Default to all days
                    }

                    // Parse experiments
                    let activeExperiments = activeExperimentsStr.isEmpty ? [] : activeExperimentsStr.split(separator: "|").map { String($0) }
                    let experimentHistory = experimentHistoryStr.isEmpty ? [] : experimentHistoryStr.split(separator: "|").map { String($0) }

                    // Create habit with sortOrder from CSV (or 0 if not present)
                    let habit = Habit(name: name, identity: identity, experiments: activeExperiments, selectedDays: selectedDays, sortOrder: sortOrder)
                    habit.experimentHistory = experimentHistory

                    // Set created date if available
                    if let createdDate = dateFormatter.date(from: createdAtStr) ?? fallbackFormatter.date(from: createdAtStr) {
                        habit.createdDate = createdDate
                    }

                    modelContext.insert(habit)

                    // Parse and add completions
                    if !completionDatesStr.isEmpty {
                        let completionDateStrings = completionDatesStr.split(separator: "|")
                        for dateStr in completionDateStrings {
                            if let date = dateFormatter.date(from: String(dateStr)) ?? fallbackFormatter.date(from: String(dateStr)) {
                                let completion = HabitCompletion(date: date, habit: habit)
                                modelContext.insert(completion)
                                habit.completions.append(completion)
                            }
                        }
                    }

                    habit.updateStreak()
                }
            }

            try modelContext.save()

            // Note: Don't call initializeSortOrder() here because it would overwrite
            // the sortOrder values we just imported from the CSV

            updateWidgetData()

            // Count habits and retrospectives after save
            let habitCheckDescriptor = FetchDescriptor<Habit>()
            let habitCount = (try? modelContext.fetch(habitCheckDescriptor).count) ?? 0
            let retroCheckDescriptor = FetchDescriptor<WeeklyRetrospective>()
            let retroCount = (try? modelContext.fetch(retroCheckDescriptor).count) ?? 0
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
    let isFirst: Bool
    let isLast: Bool
    let onUpdate: () -> Void // Callback to update widget data
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    @State private var isCompleted: Bool = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var isScheduled: Bool {
        habit.isScheduledForDate(date)
    }

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
                    HStack(spacing: 6) {
                        Text(habit.identity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)

                        if !isScheduled {
                            Text("Not scheduled")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.6))
                                )
                        }
                    }

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
        .opacity(isScheduled ? 1.0 : 0.5)
        .contentShape(Rectangle())
        .onTapGesture {
            if isScheduled {
                toggleCompletion()
            }
        }
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Divider()

            Button {
                onMoveUp()
            } label: {
                Label("Move Up", systemImage: "arrow.up")
            }
            .disabled(isFirst)

            Button {
                onMoveDown()
            } label: {
                Label("Move Down", systemImage: "arrow.down")
            }
            .disabled(isLast)

            Divider()

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
        // Update UI immediately for instant feedback
        let wasCompleted = isCompleted

        withAnimation(.easeInOut(duration: 0.15)) {
            isCompleted.toggle()
        }

        // Perform database operations asynchronously
        Task { @MainActor in
            do {
                if let existingCompletion = habit.completionForDate(date) {
                    // Remove completion
                    habit.completions.removeAll { $0.id == existingCompletion.id }
                    modelContext.delete(existingCompletion)
                } else {
                    // Add completion
                    let completion = HabitCompletion(date: date, habit: habit)
                    modelContext.insert(completion)
                    habit.completions.append(completion)
                }

                try modelContext.save()

                // Update streak synchronously (fast operation)
                habit.updateStreak()

                // Trigger widget update in background (low priority)
                Task(priority: .background) {
                    onUpdate()
                }
            } catch {
                print("Error saving completion: \(error)")
                // Revert UI state on error
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCompleted = wasCompleted
                }
            }
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
                Section("IDENTITY") {
                    TextField("What identity are you building?", text: $identity)
                        .textFieldStyle(.roundedBorder)

                    Text("e.g., \"Athlete\", \"Reader\", \"Present\", \"Leader\", \"Artist\", \"Entrepreneur\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("HABIT") {
                    TextField("What does this identity do daily?", text: $habitName)
                        .textFieldStyle(.roundedBorder)

                    Text("e.g., \"Exercise for 30 minutes\", \"Read for 20 minutes\"")
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

// Success Popup View with Confetti
struct SuccessPopupView: View {
    let habitName: String
    let rate: Int
    let completed: Int
    let notCompleted: Int
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    var body: some View {
        // Just confetti, no popup card
        ConfettiView()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// Emoji rain from top of screen
struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<40, id: \.self) { index in
                        EmojiPiece(index: index)
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: -50
                            )
                            .offset(
                                x: 0,
                                y: animate ? geometry.size.height + 100 : 0
                            )
                            .opacity(animate ? 0.3 : 1)
                            .rotationEffect(.degrees(animate ? Double.random(in: 360...720) : 0))
                            .animation(
                                .linear(duration: Double.random(in: 2.0...3.5))
                                .delay(Double(index) * 0.1),
                                value: animate
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct EmojiPiece: View {
    let index: Int

    private let emojis = [
        "🏆",  // Trophy/Champion
        "🚀",  // Rocket
        "🧘",  // Yoga
        "💪",  // Muscle/Strength
        "⭐",  // Star
        "🔥",  // Fire
        "✨",  // Sparkles
        "💯",  // 100
        "👑",  // Crown
        "🎯",  // Target
        "⚡",  // Lightning
        "🌟",  // Glowing Star
        "🙌"   // Raising Hands
    ]

    var body: some View {
        Text(emojis[index % emojis.count])
            .font(.system(size: 36))
    }
}

// Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    TodayView(selectedTab: $selectedTab)
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}