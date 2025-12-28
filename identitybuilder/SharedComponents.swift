//
//  SharedComponents.swift
//  identitybuilder
//
//  Created by Claude on 10/18/25.
//

import SwiftUI

// MARK: - Chart Data Table
struct ChartDataTable: View {
    let title: String
    let labels: [String]
    let values: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(zip(labels, values).enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(item.1)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Modifiers

/// Card styling used throughout the app
struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 12, padding: CGFloat = 12) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

/// Pill styling for experiments and tags
struct PillModifier: ViewModifier {
    var color: Color = .blue
    var fontSize: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
            )
    }
}

extension View {
    func pillStyle(color: Color = .blue, fontSize: CGFloat = 12) -> some View {
        modifier(PillModifier(color: color, fontSize: fontSize))
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let primaryButtonTitle: String
    let primaryButtonIcon: String
    let primaryAction: () -> Void
    let showInspiration: Bool
    @Binding var selectedTab: Int

    init(
        icon: String,
        title: String,
        description: String,
        primaryButtonTitle: String,
        primaryButtonIcon: String = "plus.circle.fill",
        primaryAction: @escaping () -> Void,
        showInspiration: Bool = true,
        selectedTab: Binding<Int>
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonIcon = primaryButtonIcon
        self.primaryAction = primaryAction
        self.showInspiration = showInspiration
        self._selectedTab = selectedTab
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(.blue.opacity(0.6))

            // Text Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action Buttons
            VStack(spacing: 12) {
                // Primary Action Button
                Button {
                    primaryAction()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: primaryButtonIcon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(primaryButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }

                // Inspiration Button
                if showInspiration {
                    Button {
                        selectedTab = 3 // Inspiration tab
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Get Inspired")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.blue, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
