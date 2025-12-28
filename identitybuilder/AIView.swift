//
//  AIView.swift
//  identitybuilder
//
//  Created by Claude on 10/16/25.
//

import SwiftUI
import SwiftData

struct AIView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var retrospectives: [WeeklyRetrospective]

    @State private var selectedHabit: Habit?
    @State private var showingCopiedMessage = false
    @State private var copiedPrompt = ""
    @Binding var selectedTab: Int
    @State private var showingNewHabit = false
    @State private var isLoadingPrompt = false

    // Pre-compute habit data to avoid recalculating on every render
    private var habitData: [(habit: Habit, rate: Int)] {
        habits.map { habit in
            (habit, habit.calculateCompletionRate())
        }.sorted { $0.rate < $1.rate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if habits.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "AI-Powered Insights",
                        description: "Create identities and get personalized AI guidance to help you build better habits",
                        primaryButtonTitle: "Create First Identity",
                        primaryAction: {
                            showingNewHabit = true
                        },
                        selectedTab: $selectedTab
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(habitData, id: \.habit.id) { data in
                                HabitAICard(
                                    habit: data.habit,
                                    completionRate: data.rate,
                                    retrospectives: retrospectives,
                                    allHabits: habits,
                                    onCopyPrompt: {
                                        copyPromptToClipboard(for: data.habit, rate: data.rate)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 20)
                    }
                }

                if isLoadingPrompt {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading experiment examples...")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                }

                if showingCopiedMessage {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingCopiedMessage = false
                            }
                        }

                    VStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Prompt copied!")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    Text("Paste in the AI tool of your choice")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    withAnimation {
                                        showingCopiedMessage = false
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 20))
                                }
                            }

                            Divider()

                            ScrollView {
                                Text(copiedPrompt)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 350)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewHabit) {
                NewHabitView()
            }
        }
    }

    private func copyPromptToClipboard(for habit: Habit, rate: Int) {
        isLoadingPrompt = true

        Task {
            // Fetch experiment examples from Google Sheet
            let experimentExamples = await AIPromptGenerator.fetchExperimentExamples()

            // Generate prompt with experiment examples
            let prompt = AIPromptGenerator.generate(
                for: habit,
                completionRate: rate,
                retrospectives: retrospectives,
                experimentExamples: experimentExamples
            )

            await MainActor.run {
                UIPasteboard.general.string = prompt
                copiedPrompt = prompt
                isLoadingPrompt = false

                withAnimation {
                    showingCopiedMessage = true
                }
            }
        }
    }
}

// MARK: - Habit AI Card

struct HabitAICard: View {
    @Environment(\.modelContext) private var modelContext

    let habit: Habit
    let completionRate: Int
    let retrospectives: [WeeklyRetrospective]
    let allHabits: [Habit]
    let onCopyPrompt: () -> Void

    @State private var showingCalculation = false
    @State private var showingAddExperiment = false
    @State private var showingEditHabit = false
    @State private var newExperiment = ""

    private var habitColor: Color {
        HabitColors.color(for: habit, in: allHabits)
    }

    private var bestStreak: Int {
        habit.calculateBestStreak()
    }

    private var completionsThisYear: Int {
        let calendar = Calendar.current
        let today = Date()

        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) else {
            return 0
        }

        return habit.completions.filter { completion in
            completion.date >= startOfYear
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.identity)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)

                        Button {
                            showingEditHabit = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                        }
                    }

                    Text(habit.name)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingCalculation = true
                } label: {
                    Text("\(completionRate)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(completionRate >= 80 ? .green : completionRate >= 50 ? .orange : .red)
                }
            }

            Divider()

            // Stats - One row
            HStack(spacing: 8) {
                StatItem(title: "Streak", value: "\(habit.streak)", unit: "days")
                StatItem(title: "Best", value: "\(bestStreak)", unit: "days")
                StatItem(title: "Freq", value: "\(habit.selectedDays.count)", unit: "x/wk")
                StatItem(title: "Year", value: "\(completionsThisYear)", unit: "times")
            }

            Divider()

            // Experiments
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Experiments")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        showingAddExperiment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }
                }

                if habit.experiments.isEmpty {
                    Text("No experiments yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(habit.experiments, id: \.self) { experiment in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "flask.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                                .padding(.top, 2)
                            Text(experiment)
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            // 10-Week Trend
            HabitTrendChart(habit: habit, habitColor: habitColor, trendType: .weekly(maxWeeks: 10))

            // 10-Month Trend
            HabitTrendChart(habit: habit, habitColor: habitColor, trendType: .monthly(maxMonths: 10))

            // AI Button
            HStack {
                Spacer()
                Button {
                    onCopyPrompt()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("AI")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                Spacer()
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingCalculation) {
            CompletionCalculationView(
                habit: habit,
                completionRate: completionRate
            )
        }
        .sheet(isPresented: $showingAddExperiment) {
            AddExperimentView(
                habit: habit,
                newExperiment: $newExperiment,
                onSave: {
                    saveExperiment()
                }
            )
        }
        .sheet(isPresented: $showingEditHabit) {
            EditHabitView(
                habit: habit,
                onDelete: {
                    deleteHabit()
                }
            )
        }
    }

    private func deleteHabit() {
        modelContext.delete(habit)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting habit: \(error)")
        }
    }

    private func saveExperiment() {
        let trimmed = newExperiment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !habit.experiments.contains(trimmed) {
            habit.experiments.append(trimmed)
            if !habit.experimentHistory.contains(trimmed) {
                habit.experimentHistory.append(trimmed)
            }
        }

        do {
            try modelContext.save()
            newExperiment = ""
        } catch {
            print("Error saving experiment: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var selectedTab = 2
    AIView(selectedTab: $selectedTab)
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}
