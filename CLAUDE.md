# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**identitybuilder** is an iOS habit tracking app built with SwiftUI and SwiftData. The app is based on the principle of identity-based habits (inspired by James Clear's "Atomic Habits"), where users track habits by the identity they're building (e.g., "Athlete," "Reader") rather than just actions.

## Build & Run Commands

### Standard Build
```bash
xcodebuild -scheme identitybuilder -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Clean Build
```bash
xcodebuild -scheme identitybuilder -destination 'platform=iOS Simulator,name=iPhone 17' clean build
```

## Architecture

### Data Model (SwiftData)
The app uses SwiftData for persistence with four core models:

- **Habit**: Main model with properties:
  - `name`: What the user does (e.g., "Exercise for 30 minutes")
  - `identity`: Who they're becoming (e.g., "Athlete")
  - `experiments`: Current active experiments to make the habit stick
  - `experimentHistory`: Complete history of all experiments tried (including removed ones)
  - `selectedDays`: Set<Int> where 0=Sunday, 1=Monday, etc.
  - `streak`: Current consecutive completion streak
  - `completions`: Relationship to HabitCompletion records

- **HabitCompletion**: Tracks individual completions with date and habit relationship

- **WeeklyRetrospective**: Stores user reflections for each week

- **Item**: Legacy model for compatibility

### View Architecture

**Three-Tab Structure** (ContentView):

1. **TodayView (Day tab)**:
   - Primary habit tracking interface
   - Shows habits scheduled for selected date
   - Date navigation with previous/next/today buttons
   - Completion percentage at top
   - Tap card to complete, long-press to edit
   - Export/import CSV backup functionality

2. **WeekView (Week tab)**:
   - 7-day habit completion visualization
   - Weekly retrospective notes feature
   - Week-by-week navigation

3. **YearView (Year tab)**:
   - Monthly trend charts
   - Individual habit performance over the year

### Key UI Patterns

**Form Consistency**: NewHabitView and EditHabitView (embedded in TodayView) share identical structure:
- No navigation titles (inline display mode only)
- Same sections: HABIT, IDENTITY, SCHEDULE, EXPERIMENTS (OPTIONAL), EXPERIMENT HISTORY (edit only)
- Auto-save pending experiments: If user types in experiment field but doesn't click +, it's automatically added on save
- All days selected by default, week starts Monday

**Compact Design Philosophy**:
- Small fonts and tight spacing throughout
- Date/percentage: 24pt
- Habit cards: 16pt identity, 13pt name, 24pt streak number
- Padding: 12-16px horizontal, 6-10px vertical
- Corner radius: 12px for cards

**Theme Adaptability**:
- All colors use `Color(UIColor.system...)` variants for automatic light/dark mode support
- Unselected schedule days show stroke outline in both themes

### Widget Integration (Prepared but Not Active)

The app has widget infrastructure prepared:
- `WidgetModels.swift`: Data structures for widget (WidgetData, WidgetHabit)
- `SharedData.swift`: UserDefaults App Group sharing (`group.com.yourcompany.identitybuilder`)
- `HabitExtensions.swift`: Converts [Habit] to WidgetData
- `HabitWidgetBundle.swift`: Widget entry point (currently has @main commented out to avoid conflict)

**Note**: Widget is prepared but not in a widget extension yet. When creating the widget extension, uncomment @main in HabitWidgetBundle.swift.

### Streak Calculation Logic

Streaks count backwards from today:
- Only counts scheduled days where habit is completed
- Stops at first incomplete scheduled day
- Skips unscheduled days without breaking streak
- Updates after save to ensure database consistency

### Data Import/Export

**CSV Format**:
```
Habit,Identity,Experiments,Schedule,CompletionDate
Exercise 30min,Athlete,"gym,morning",1234560,2024-10-09T10:00:00Z
```
- Experiments: comma-separated in quotes
- Schedule: concatenated day numbers (e.g., "1234560" = Mon-Sat)
- Dates: ISO8601 format

## Important Implementation Details

### State Management
- SwiftData @Query for reactive data fetching
- @Environment(\.modelContext) for database operations
- Habit completion state tied to selected date via `onChange(of: date)`

### Widget Updates
After any habit modification:
```swift
let fetchDescriptor = FetchDescriptor<Habit>()
if let allHabits = try? modelContext.fetch(fetchDescriptor) {
    let widgetData = allHabits.toWidgetData()
    SharedData.shared.saveWidgetData(widgetData)
    WidgetCenter.shared.reloadAllTimelines()
}
```

### Completion Toggle Pattern
Always remove from both completions array AND modelContext, then save before updating streak:
```swift
habit.completions.removeAll { $0.id == existingCompletion.id }
modelContext.delete(existingCompletion)
try modelContext.save()
habit.updateStreak()
```

## Code Style Notes

- Use theme-adaptive colors: `Color(UIColor.systemBackground)`, `.primary`, `.secondary`
- Abbreviated weekdays: "Mon", "Tue", etc. (not "Monday", "Tuesday")
- Week starts on Monday (selectedDays ordering: [1,2,3,4,5,6,0])
- Date format for display: "EEE, MMM d" (e.g., "Thu, Oct 9")
- All padding/spacing values are small for compact design
- Experiments shown as blue pills with rounded backgrounds

## Schema Changes

When modifying SwiftData models, update the schema registration in `identitybuilderApp.swift`:
```swift
let schema = Schema([
    Habit.self,
    HabitCompletion.self,
    WeeklyRetrospective.self,
    Item.self,
])
```
