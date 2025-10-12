//
//  YearView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData

struct YearView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    @State private var currentYear = Date()
    
    private var monthlyData: [(String, Double)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentYear)
        
        var data: [(String, Double)] = []
        
        for month in 1...12 {
            let monthName = DateFormatter().shortMonthSymbols[month - 1]
            
            // Get all days in this month
            guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                data.append((monthName, 0))
                continue
            }
            
            var totalScheduled = 0
            var totalCompleted = 0
            var currentDate = monthStart
            
            while currentDate <= monthEnd {
                for habit in habits {
                    if habit.isScheduledForDate(currentDate) {
                        totalScheduled += 1
                        if habit.isCompletedOnDate(currentDate) {
                            totalCompleted += 1
                        }
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            let percentage = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
            data.append((monthName, percentage))
        }
        
        return data
    }
    
    private var habitTrendData: [(String, String, Double)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentYear)
        
        var data: [(String, String, Double)] = []
        
        for habit in habits {
            for month in 1...12 {
                let monthName = DateFormatter().shortMonthSymbols[month - 1]
                
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                    continue
                }
                
                var totalScheduled = 0
                var totalCompleted = 0
                var currentDate = monthStart
                
                while currentDate <= monthEnd {
                    if habit.isScheduledForDate(currentDate) {
                        totalScheduled += 1
                        if habit.isCompletedOnDate(currentDate) {
                            totalCompleted += 1
                        }
                    }
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
                
                let percentage = totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) * 100 : 0
                data.append((habit.name, monthName, percentage))
            }
        }
        
        return data
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Year Navigation Header
                        HStack {
                            Button {
                                withAnimation {
                                    currentYear = Calendar.current.date(byAdding: .year, value: -1, to: currentYear) ?? currentYear
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            Text("\(Calendar.current.component(.year, from: currentYear))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    currentYear = Calendar.current.date(byAdding: .year, value: 1, to: currentYear) ?? currentYear
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Yearly Progress Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Yearly Trends")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            // Simple line chart representation
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, data in
                                    VStack {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 6, height: 6)
                                            .offset(y: CGFloat(100 - data.1) * -1.5)
                                        
                                        Rectangle()
                                            .fill(.blue.opacity(0.3))
                                            .frame(width: 2, height: max(4, data.1 * 1.5))
                                        
                                        Text(String(data.0.prefix(3)))
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                            .rotationEffect(.degrees(-45))
                                    }
                                    .frame(height: 180)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                        
                        // Individual Habit Trends
                        if !habits.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Individual Habit Trends")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                // Simplified multi-line chart
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(habits) { habit in
                                        HStack {
                                            Text(habit.identity)
                                                .font(.caption)
                                                .foregroundStyle(colorForHabit(habit.name))
                                            
                                            HStack(spacing: 2) {
                                                ForEach(monthlyData.indices, id: \.self) { monthIndex in
                                                    let habitData = habitTrendData.filter { $0.0 == habit.name }
                                                    let percentage = habitData.count > monthIndex ? habitData[monthIndex].2 : 0
                                                    
                                                    Rectangle()
                                                        .fill(colorForHabit(habit.name))
                                                        .frame(width: 15, height: max(2, percentage * 0.8))
                                                        .opacity(0.8)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                
                                // Legend
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(habits) { habit in
                                        HStack {
                                            RoundedRectangle(cornerRadius: 2)
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(colorForHabit(habit.name))
                                            
                                            Text(habit.name)
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            Spacer()
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
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func colorForHabit(_ habitName: String) -> Color {
        let colors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .pink, .mint]
        let hash = abs(habitName.hashValue)
        return colors[hash % colors.count]
    }
}

#Preview {
    YearView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyRetrospective.self], inMemory: true)
}