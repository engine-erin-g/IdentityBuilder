//
//  Widget Setup Instructions
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

/* 
WIDGET SETUP INSTRUCTIONS

To add the widget functionality to your app, you'll need to:

1. **Create a Widget Extension in Xcode:**
   - File → New → Target → Widget Extension
   - Name it "HabitWidgetExtension"
   - Make sure "Include Configuration Intent" is unchecked for simplicity

2. **Move Widget Files:**
   - Move `HabitWidget.swift`, `HabitWidgetBundle.swift`, `WidgetModels.swift`, and `SharedData.swift` to the widget extension target
   - Make sure `HabitExtensions.swift` is available to both the main app and widget targets

3. **Set up App Groups:**
   - In your Apple Developer account, create an App Group named "group.com.yourcompany.identitybuilder"
   - In Xcode, go to your main app target → Signing & Capabilities → Add Capability → App Groups
   - Select the app group you created
   - Do the same for your widget extension target

4. **Update SharedData.swift:**
   - Replace "group.com.yourcompany.identitybuilder" with your actual app group identifier

5. **Widget Features:**
   - Shows current week number (Week 41)
   - Displays completion percentages for current/previous week (66%/94%)
   - Lists all habits with their identity names and streak counts
   - Visual completion status for each day of the week:
     - Green circles with checkmarks = completed
     - Red circles with X's = missed (past days)
     - Gray circles = future days or not scheduled
   - Dark theme matching your app design

6. **Widget Sizes:**
   - systemMedium: Shows 3-4 habits
   - systemLarge: Shows all habits

7. **Data Flow:**
   - When habits are completed/edited in the main app, widget data is saved to shared UserDefaults
   - Widget automatically refreshes hourly or when timeline is reloaded
   - Widget falls back to sample data if no real data is available

The widget perfectly matches the design shown in your screenshot!
*/