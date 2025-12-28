//
//  HabitColors.swift
//  identitybuilder
//
//  Created by Claude on 10/18/25.
//

import SwiftUI

/// Manages consistent color assignment for habits with caching for performance
struct HabitColors {
    static let colors: [Color] = [.red, .green, .blue, .orange, .purple, .yellow, .pink, .mint, .cyan, .indigo, .teal, .brown, .gray]

    // Cache for color mappings to avoid recomputation
    private static var cache: [String: [String: Color]] = [:]

    /// Generates a unique cache key based on habit IDs and creation dates
    private static func cacheKey(for habits: [Habit]) -> String {
        habits
            .sorted { $0.createdDate < $1.createdDate }
            .map { $0.id.uuidString }
            .joined(separator: ",")
    }

    static func colorMapping(for habits: [Habit]) -> [String: Color] {
        let key = cacheKey(for: habits)

        // Return cached mapping if available
        if let cached = cache[key] {
            return cached
        }

        // Sort habits by creation date to maintain consistent ordering
        let sortedHabits = habits.sorted { $0.createdDate < $1.createdDate }

        var result: [String: Color] = [:]
        for (index, habit) in sortedHabits.enumerated() {
            result[habit.id.uuidString] = colors[index % colors.count]
        }

        // Cache the result
        cache[key] = result
        return result
    }

    static func color(for habit: Habit, in habits: [Habit]) -> Color {
        let mapping = colorMapping(for: habits)
        return mapping[habit.id.uuidString] ?? .gray
    }

    static func colorIndex(for habit: Habit, in habits: [Habit]) -> Int {
        let sortedHabits = habits.sorted { $0.createdDate < $1.createdDate }
        return sortedHabits.firstIndex(where: { $0.id == habit.id }) ?? 0
    }

    /// Clears the color mapping cache (useful if habits are deleted or modified significantly)
    static func clearCache() {
        cache.removeAll()
    }
}
