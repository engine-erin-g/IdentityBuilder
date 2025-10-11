//
//  YearView.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import SwiftUI
import SwiftData
import Charts

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
                Color.black.ignoresSafeArea()
                
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
                                    .foregroundStyle(.white)
                            }
                            
                            Spacer()
                            
                            Text("\(Calendar.current.component(.year, from: currentYear))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    currentYear = Calendar.current.date(byAdding: .year, value: 1, to: currentYear) ?? currentYear
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Yearly Progress Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Yearly Trends")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            // Overall trend chart
                            Chart {
                                ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, data in
                                    LinePlot(
                                        x: .value("Month", data.0),
                                        y: .value("Percentage", data.1)
                                    )
                                    .foregroundStyle(.blue)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                            }
                            .frame(height: 200)
                            .chartYScale(domain: 0...100)
                            .chartXAxis {
                                AxisMarks(values: monthlyData.map { $0.0 }) { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
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
                                    .foregroundStyle(.white)
                                
                                Chart {
                                    ForEach(habitTrendData, id: \.0) { habitName, month, percentage in
                                        LinePlot(
                                            x: .value("Month", month),
                                            y: .value("Percentage", percentage),
                                            series: .value("Habit", habitName)
                                        )
                                    }
                                }
                                .frame(height: 250)
                                .chartYScale(domain: 0...100)
                                .chartXAxis {
                                    AxisMarks(values: monthlyData.map { $0.0 }) { value in
                                        AxisGridLine()
                                        AxisValueLabel()
                                            .foregroundStyle(.white)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisValueLabel()
                                            .foregroundStyle(.white)
                                    }
                                }
                                .chartForegroundStyleScale([
                                    "Stay curious": .red,
                                    "1500 Active calories": .blue,
                                    "Control mouth": .yellow,
                                    "Control feelings": .green,
                                    "Build build build": .orange
                                ])
                                
                                // Legend
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(habits) { habit in
                                        HStack {
                                            RoundedRectangle(cornerRadius: 2)
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(colorForHabit(habit.name))
                                            
                                            Text(habit.name)
                                                .font(.caption)
                                                .foregroundStyle(.white)
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