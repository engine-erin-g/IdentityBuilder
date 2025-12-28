//
//  AIComponents.swift
//  identitybuilder
//
//  Created by Claude on 10/18/25.
//

import SwiftUI
import SwiftData

// MARK: - Stat Item Component

struct StatItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Completion Calculation View

struct CompletionCalculationView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let completionRate: Int

    // Extract completion stats for display (mirrors habit.calculateCompletionRate() logic)
    private var stats: (completed: Int, total: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let habitStart = calendar.startOfDay(for: habit.createdDate)

        var completedIncludingToday = 0
        var notCompletedExcludingToday = 0
        var checkDate = habitStart

        let completionDates = Set(habit.completions.map { calendar.startOfDay(for: $0.date) })

        while checkDate <= today {
            if habit.isScheduledForDate(checkDate) {
                if completionDates.contains(checkDate) {
                    completedIncludingToday += 1
                } else if checkDate < today {
                    notCompletedExcludingToday += 1
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }

        return (completedIncludingToday, completedIncludingToday + notCompletedExcludingToday)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Large percentage display
                VStack(spacing: 8) {
                    Text("\(completionRate)%")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(completionRate >= 80 ? .green : completionRate >= 50 ? .orange : .red)

                    Text("Overall Completion Rate")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Divider()
                    .padding(.horizontal, 40)

                // Calculation breakdown
                VStack(spacing: 20) {
                    Text("How it's calculated")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    VStack(spacing: 16) {
                        CalculationRow(
                            label: "Completed",
                            value: "\(stats.completed)",
                            description: "Times you completed this habit (including today)"
                        )

                        CalculationRow(
                            label: "Not Completed",
                            value: "\(stats.total - stats.completed)",
                            description: "Times you missed this habit (past days, excluding today)"
                        )

                        Divider()

                        Text("Formula")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text("\(stats.completed) ÷ (\(stats.completed) + \(stats.total - stats.completed)) × 100 = \(completionRate)%")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(habit.identity)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CalculationRow: View {
    let label: String
    let value: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
            }
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Add Experiment View

struct AddExperimentView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    @Binding var newExperiment: String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a new experiment")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("What will you try to make this habit stick?")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    TextField("e.g., Set out gym clothes the night before", text: $newExperiment)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(habit.identity)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        newExperiment = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newExperiment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - AI Prompt Generator

struct AIPromptGenerator {
    static func fetchExperimentExamples() async -> String {
        // Google Sheet published as CSV - Experiments tab
        let sheetURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vS2YRJx2Dz2rx66UTq0qEY9w_sxD1ndiR-8FU-xo0m2oTQAEdM4ZhjHC4x2ta9uV4iTcKTEYjus5vKL/pub?gid=591473449&single=true&output=csv"

        guard let url = URL(string: sheetURL) else {
            return "Unable to load experiment examples."
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let csvString = String(data: data, encoding: .utf8) {
                return formatExperimentExamples(csvString)
            }
        } catch {
            print("Error fetching experiment examples: \(error)")
        }

        return "Unable to load experiment examples."
    }

    private static func formatExperimentExamples(_ csvString: String) -> String {
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else { return csvString }

        var formattedOutput = ""
        var exampleCount = 0

        // Skip header row and process data rows
        for (index, line) in lines.dropFirst().enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            let columns = parseCSVLine(line)

            // Need at least 1 column with data
            guard columns.count >= 1 else {
                continue
            }

            // Get columns with safe indexing
            let experiment = columns.count > 0 ? columns[0].trimmingCharacters(in: .whitespaces) : ""
            let identity = columns.count > 1 ? columns[1].trimmingCharacters(in: .whitespaces) : ""
            let worked = columns.count > 2 ? columns[2].trimmingCharacters(in: .whitespaces) : ""
            let explanation = columns.count > 3 ? columns[3].trimmingCharacters(in: .whitespaces) : ""
            let framework = columns.count > 4 ? columns[4].trimmingCharacters(in: .whitespaces) : ""

            // Skip rows where all important fields are empty
            guard !experiment.isEmpty || !identity.isEmpty || !worked.isEmpty || !explanation.isEmpty else {
                continue
            }

            exampleCount += 1

            formattedOutput += """

            Example \(exampleCount):
            • Experiment: \(experiment.isEmpty ? "(not specified)" : experiment)
            • Identity: \(identity.isEmpty ? "(not specified)" : identity)
            • Result: \(worked.isEmpty ? "(not specified)" : worked)
            • Why: \(explanation.isEmpty ? "(not specified)" : explanation)
            • Framework: \(framework.isEmpty ? "(not specified)" : framework)

            """
        }

        // If no examples were formatted, return the raw CSV for debugging
        if formattedOutput.isEmpty {
            return csvString
        }

        return formattedOutput
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }

    static func generate(for habit: Habit, completionRate: Int, retrospectives: [WeeklyRetrospective], experimentExamples: String? = nil) -> String {
        let calendar = Calendar.current
        let today = Date()

        let bestStreak = habit.calculateBestStreak()
        let currentExperiments = habit.experiments.isEmpty ? "None" : habit.experiments.map { "- \($0)" }.joined(separator: "\n")

        let pastExperiments = habit.experimentHistory.filter { !habit.experiments.contains($0) }
        let pastExperimentsText = pastExperiments.isEmpty ? "None" : pastExperiments.map { "- \($0)" }.joined(separator: "\n")

        let recentRetrospectives = retrospectives
            .sorted { $0.weekStartDate > $1.weekStartDate }
            .prefix(4)
        let retrospectivesText: String
        if recentRetrospectives.isEmpty {
            retrospectivesText = "None"
        } else {
            retrospectivesText = recentRetrospectives.map { retro in
                let dateStr = retro.weekStartDate.formatted(.dateTime.month().day().year())
                return "- Week of \(dateStr): \(retro.notes.isEmpty ? "No notes" : retro.notes)"
            }.joined(separator: "\n")
        }

        let daysSinceCreation = calendar.dateComponents([.day], from: habit.createdDate, to: today).day ?? 0

        let experimentExamplesSection: String
        if let examples = experimentExamples, !examples.isEmpty {
            experimentExamplesSection = """

            EXPERIMENT EXAMPLES DATABASE:
            Here are proven experiment examples from other habit builders:

            \(examples)

            """
        } else {
            experimentExamplesSection = ""
        }

        return """
        I'm building the identity of "\(habit.identity)" by doing: "\(habit.name)". I am already using an app to track progress!

        PERFORMANCE DATA:
        • \(daysSinceCreation) days tracking | \(habit.selectedDays.count)x/week schedule
        • Current streak: \(habit.streak) days | Best: \(bestStreak) days
        • Completion rate: \(completionRate)% (\(habit.completions.count) total)

        ACTIVE EXPERIMENTS:
        \(currentExperiments)

        PAST EXPERIMENTS (what didn't stick):
        \(pastExperimentsText)

        RECENT REFLECTIONS:
        \(retrospectivesText)\(experimentExamplesSection)
        TASK: Suggest 3-5 experiments to improve my \(completionRate)% completion rate using the 4 Laws of Behavior Change:
        1. OBVIOUS (cues & environment)
        2. ATTRACTIVE (temptation bundling & social proof)
        3. EASY (2-min rule & friction reduction)
        4. SATISFYING (immediate rewards & tracking)

        Format each as: "[LAW] - Specific action" with brief why. Avoid repeating past experiments. Focus on my biggest gaps based on performance and reflections.
        """
    }
}
