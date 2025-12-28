//
//  identitybuilderApp.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

@main
struct identitybuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Disable animation for better performance
                    UIView.setAnimationsEnabled(true)
                }
        }
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self])
    }
}
