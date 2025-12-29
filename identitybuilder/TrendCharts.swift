//
//  TrendCharts.swift
//  identitybuilder
//
//  Created by Claude on 10/18/25.
//

import SwiftUI

// MARK: - Constants
private let kMondayFirstWeekday = 2 // Calendar.firstWeekday: 1=Sunday, 2=Monday

// MARK: - Trend Chart Components

/// A generic trend chart that can be used for weekly or monthly data
struct HabitTrendChart: View {
    let habit: Habit
    let habitColor: Color
    let trendType: TrendType

    @State private var showingDataTable = false

    enum TrendType {
        case weekly(maxWeeks: Int = 10)
        case monthly(maxMonths: Int = 10)

        var title: String {
            switch self {
            case .weekly(let max): return "\(max)-Week Trend"
            case .monthly(let max): return "\(max)-Month Trend"
            }
        }

        var maxPeriods: Int {
            switch self {
            case .weekly(let max): return max
            case .monthly(let max): return max
            }
        }
    }

    private var periodsSinceCreation: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let today = Date()

        switch trendType {
        case .weekly(let maxWeeks):
            guard let firstPeriod = calendar.dateInterval(of: .weekOfYear, for: habit.createdDate)?.start,
                  let currentPeriodStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
                return 1
            }
            let components = calendar.dateComponents([.weekOfYear], from: firstPeriod, to: currentPeriodStart)
            let weeks = (components.weekOfYear ?? 0) + 1
            return max(1, min(weeks, maxWeeks))

        case .monthly(let maxMonths):
            guard let firstPeriod = calendar.dateInterval(of: .month, for: habit.createdDate)?.start,
                  let currentPeriod = calendar.dateInterval(of: .month, for: today)?.start else {
                return 1
            }
            let components = calendar.dateComponents([.month], from: firstPeriod, to: currentPeriod)
            let months = (components.month ?? 0) + 1
            return max(1, min(months, maxMonths))
        }
    }

    private var trendData: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let periodsToShow = periodsSinceCreation

        let completionDates = Set(habit.completions.map { calendar.startOfDay(for: $0.date) })

        var data: [Double] = []

        for periodOffset in (0..<periodsToShow).reversed() {
            let percentage: Double

            switch trendType {
            case .weekly:
                percentage = calculateWeeklyPercentage(periodOffset: periodOffset, today: today, completionDates: completionDates)
            case .monthly:
                percentage = calculateMonthlyPercentage(periodOffset: periodOffset, today: today, completionDates: completionDates)
            }

            data.append(percentage)
        }

        return data
    }

    // Calculate completion percentage for a specific week (uses same formula as habit.calculateCompletionRate)
    private func calculateWeeklyPercentage(periodOffset: Int, today: Date, completionDates: Set<Date>) -> Double {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday

        // First get the start of the current week, then work backwards
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let weekStart = calendar.date(byAdding: .weekOfYear, value: -periodOffset, to: currentWeekStart) else {
            return 0
        }

        var completedIncludingToday = 0
        var notCompletedExcludingToday = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

            if habit.isScheduledForDate(date) {
                if completionDates.contains(date) {
                    completedIncludingToday += 1
                } else if date < today {
                    notCompletedExcludingToday += 1
                }
            }
        }

        let denominator = completedIncludingToday + notCompletedExcludingToday
        return denominator > 0 ? Double(completedIncludingToday) / Double(denominator) * 100 : 0
    }

    // Calculate completion percentage for a specific month (uses same formula as habit.calculateCompletionRate)
    private func calculateMonthlyPercentage(periodOffset: Int, today: Date, completionDates: Set<Date>) -> Double {
        let calendar = Calendar.current

        // First get the start of the current month, then work backwards
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: today)?.start,
              let targetMonth = calendar.date(byAdding: .month, value: -periodOffset, to: currentMonthStart),
              let monthInterval = calendar.dateInterval(of: .month, for: targetMonth) else {
            return 0
        }

        var completedIncludingToday = 0
        var notCompletedExcludingToday = 0
        var currentDay = monthInterval.start

        while currentDay < monthInterval.end {
            if habit.isScheduledForDate(currentDay) {
                if completionDates.contains(currentDay) {
                    completedIncludingToday += 1
                } else if currentDay < today {
                    notCompletedExcludingToday += 1
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }

        let denominator = completedIncludingToday + notCompletedExcludingToday
        return denominator > 0 ? Double(completedIncludingToday) / Double(denominator) * 100 : 0
    }

    private var movingAverage: [Double] {
        guard trendData.count >= 3 else { return trendData }

        var averages: [Double] = []
        for i in 0..<trendData.count {
            if i < 2 {
                let sum = trendData[0...i].reduce(0, +)
                averages.append(sum / Double(i + 1))
            } else {
                let sum = trendData[i-2...i].reduce(0, +)
                averages.append(sum / 3.0)
            }
        }
        return averages
    }

    private var averageRate: Int {
        guard !trendData.isEmpty else { return 0 }
        let sum = trendData.reduce(0, +)
        return Int(sum / Double(trendData.count))
    }

    private var periodLabels: [String] {
        var calendar = Calendar.current
        calendar.firstWeekday = kMondayFirstWeekday
        let today = Date()
        var labels: [String] = []

        switch trendType {
        case .weekly:
            guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
                return []
            }
            for weekOffset in (0..<periodsSinceCreation).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart) else {
                    labels.append("")
                    continue
                }
                let weekNum = calendar.component(.weekOfYear, from: weekStart)
                labels.append("Week \(weekNum)")
            }

        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"

            for monthOffset in (0..<periodsSinceCreation).reversed() {
                guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today) else {
                    labels.append("")
                    continue
                }
                labels.append(formatter.string(from: monthStart))
            }
        }

        return labels
    }

    private var tableLabels: [String] {
        switch trendType {
        case .weekly:
            return periodLabels
        case .monthly:
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"

            return periodLabels.enumerated().map { index, _ in
                guard let monthStart = calendar.date(byAdding: .month, value: -(periodsSinceCreation - index - 1), to: Date()) else {
                    return ""
                }
                return formatter.string(from: monthStart)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trendType.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        showingDataTable = true
                    }

                Spacer()

                Text("Avg: \(averageRate)%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            DetailedChart(
                data: trendData,
                movingAvg: movingAverage,
                periodLabels: periodLabels,
                color: habitColor,
                height: 120
            )
        }
        .sheet(isPresented: $showingDataTable) {
            ChartDataTable(
                title: "\(habit.identity) - \(trendType.title)",
                labels: tableLabels,
                values: trendData.map { String(format: "%.0f%%", $0) }
            )
        }
    }
}

// MARK: - Detailed Chart View

struct DetailedChart: View {
    let data: [Double]
    let movingAvg: [Double]
    let periodLabels: [String]
    let color: Color
    let height: CGFloat

    private var minValue: Double {
        guard !data.isEmpty else { return 0 }
        let min = data.min() ?? 0
        return floor(min / 10) * 10
    }

    private var maxValue: Double {
        guard !data.isEmpty else { return 100 }
        let max = data.max() ?? 100
        return ceil(max / 10) * 10
    }

    private var yAxisValues: [Int] {
        let range = maxValue - minValue
        if range <= 20 {
            return stride(from: Int(maxValue), through: Int(minValue), by: -5).map { $0 }
        } else {
            let step = ceil(range / 4 / 10) * 10
            return stride(from: Int(maxValue), through: Int(minValue), by: -Int(step)).map { $0 }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, value in
                        HStack {
                            Spacer()
                        }
                        .frame(height: 1)
                        .background(Color.gray.opacity(0.2))
                        if index < yAxisValues.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(height: height)

                // Line chart
                GeometryReader { geometry in
                    let chartWidth = geometry.size.width
                    let chartHeight = height
                    let xSpacing = chartWidth / CGFloat(max(data.count - 1, 1))

                    ZStack {
                        // Actual data line (lighter/dashed)
                        if data.count > 1 {
                            DynamicLinePath(data: data, chartHeight: chartHeight, xSpacing: xSpacing, minValue: minValue, maxValue: maxValue)
                                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        }

                        // Moving average line (solid, prominent)
                        if movingAvg.count > 1 {
                            DynamicLinePath(data: movingAvg, chartHeight: chartHeight, xSpacing: xSpacing, minValue: minValue, maxValue: maxValue)
                                .stroke(color, lineWidth: 2.5)
                        }

                        // Data points
                        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                            let x = CGFloat(index) * xSpacing
                            let range = maxValue - minValue
                            let y = range > 0 ? chartHeight * (1 - (value - minValue) / range) : chartHeight / 2

                            Circle()
                                .fill(color.opacity(0.5))
                                .frame(width: 4, height: 4)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: height)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(8)

            // Period labels at the bottom
            HStack(spacing: 0) {
                ForEach(Array(periodLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct DynamicLinePath: Shape {
    let data: [Double]
    let chartHeight: CGFloat
    let xSpacing: CGFloat
    let minValue: Double
    let maxValue: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard data.count > 1 else { return path }

        let range = maxValue - minValue
        guard range > 0 else { return path }

        let firstY = chartHeight * (1 - (data[0] - minValue) / range)
        path.move(to: CGPoint(x: 0, y: firstY))

        for index in 1..<data.count {
            let x = CGFloat(index) * xSpacing
            let y = chartHeight * (1 - (data[index] - minValue) / range)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}
