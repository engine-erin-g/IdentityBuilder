//
//  ContentView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var selectedTab = 0
    @State private var hasInitialized = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Day")
                }
                .tag(0)

            // Use Group to defer view creation until tab is selected
            Group {
                if selectedTab == 1 {
                    WeekView(selectedTab: $selectedTab)
                } else {
                    Color.clear
                }
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Week")
            }
            .tag(1)

            Group {
                if selectedTab == 2 {
                    AIView(selectedTab: $selectedTab)
                } else {
                    Color.clear
                }
            }
            .tabItem {
                Label("AI", systemImage: "sparkles")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .onOpenURL { url in
            // When widget is tapped, open the app and switch to Day tab
            if url.scheme == "identitybuilder" {
                selectedTab = 0
            }
        }
        .onAppear {
            initializeDefaultHabit()
        }
    }

    private func initializeDefaultHabit() {
        // Only initialize once per app session
        guard !hasInitialized else { return }
        hasInitialized = true

        // Check if there are no habits
        guard habits.isEmpty else { return }

        // Create the first default habit: "Open this app every day" with identity "Disciplined"
        let disciplinedHabit = Habit(
            name: "Open this app every day",
            identity: "Disciplined",
            experiments: ["first thing when I open my phone in the morning"],
            selectedDays: Set([0, 1, 2, 3, 4, 5, 6]), // All days of the week
            sortOrder: 1  // Start from 1 to avoid being treated as uninitialized
        )

        // Create the second default habit: "Be thankful to be alive!" with identity "Humble"
        let humbleHabit = Habit(
            name: "Be thankful to be alive!",
            identity: "Humble",
            experiments: ["After I open this app"],
            selectedDays: Set([0, 1, 2, 3, 4, 5, 6]), // All days of the week
            sortOrder: 2  // Higher value appears second
        )

        // Create the third default habit: "Note my feelings during the day" with identity "Present"
        let presentHabit = Habit(
            name: "Note my feelings during the day",
            identity: "Present",
            experiments: ["Before I sleep"],
            selectedDays: Set([0, 1, 2, 3, 4, 5, 6]), // All days of the week
            sortOrder: 3  // Third habit
        )

        modelContext.insert(disciplinedHabit)
        modelContext.insert(humbleHabit)
        modelContext.insert(presentHabit)

        do {
            try modelContext.save()
        } catch {
            print("Error saving default habits: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}
