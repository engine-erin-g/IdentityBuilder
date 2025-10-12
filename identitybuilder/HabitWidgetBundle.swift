//
//  HabitWidgetBundle.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//
//  NOTE: This file is prepared for a Widget Extension target.
//  The @main attribute is commented out to avoid conflicts with the main app.
//  When you create a Widget Extension target, move this file there and uncomment @main.

import WidgetKit
import SwiftUI

// @main  // Uncomment when moved to Widget Extension target
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
    }
}