//
//  ContentView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Day")
                }
            
            WeekView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Week")
                }
            
            YearView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Year")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self, Item.self], inMemory: true)
}
