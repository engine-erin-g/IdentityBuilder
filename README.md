# Identity Builder

**Transform your habits by focusing on who you want to become.**

An iOS habit tracking app based on James Clear's "Atomic Habits" philosophy - lasting change happens when you shift your identity, not just your actions.

---

## 📱 Features

### Core Functionality
- **Identity-Based Tracking**: Link habits to identities (e.g., "Athlete," "Reader")
- **Flexible Scheduling**: Choose which days to track each habit
- **Streak Tracking**: See your current and best streaks
- **Completion Rates**: Track your success over time

### Analytics & Insights
- **Daily View**: Quick habit completion with percentage tracking
- **Weekly Trends**: 7-day completion visualization with retrospectives
- **Long-Term Charts**: 10-week and 10-month trend analysis
- **AI Insights**: Generate personalized experiment suggestions

### Experiments Framework
- Track what strategies you're trying (4 Laws of Behavior Change)
- Keep history of what worked and what didn't
- Build your personal playbook for success

### Data & Privacy
- **100% Local Storage**: All data stored on-device using SwiftData
- **CSV Export/Import**: Full data portability and backup
- **No Account Required**: No sign-up, no tracking
- **Widget Support**: At-a-glance progress on home screen

---

## 🏗️ Architecture

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent storage with CloudKit-ready models
- **WidgetKit**: Home screen widget integration
- **App Groups**: Data sharing between app and widget

### Project Structure
```
identitybuilder/
├── Models.swift              # Core data models (Habit, HabitCompletion, WeeklyRetrospective)
├── ContentView.swift         # Main tab container
├── TodayView.swift           # Daily habit tracking interface
├── WeekView.swift            # Weekly trends and retrospectives
├── AIView.swift              # AI-powered insights
├── InspirationView.swift     # Benjamin Franklin's 13 virtues
├── NewHabitView.swift        # Create new habits
├── TrendCharts.swift         # Reusable chart components
├── HabitExtensions.swift     # Widget data conversion
├── SharedData.swift          # App Group data sharing
├── HabitColors.swift         # Consistent color assignments
├── SharedComponents.swift    # Reusable UI components
├── AIComponents.swift        # AI-related views
└── WidgetModels.swift        # Codable models for widgets
```

### Key Design Decisions
- **13 Habit Limit**: Inspired by Benjamin Franklin's 13 virtues - focus on mastery
- **Monday as Week Start**: Configurable via `kMondayFirstWeekday` constant
- **Completion Rate Formula**: `completed / (completed + missed)` - excludes today from denominator
- **Streak Calculation**: Counts backwards from today, skips unscheduled days

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 or later
- Xcode 17.0 or later
- iOS 18.0+ deployment target
- Apple Developer account (for App Store submission)

### Setup
```bash
# Clone the repository
git clone [your-repo-url]
cd identitybuilder

# Open in Xcode
open identitybuilder.xcodeproj

# Select iPhone simulator
# Product > Run (Cmd+R)
```

### Configuration
1. **Bundle Identifier**: Update `erin-ndrio.identitybuilder` to your own
2. **App Group**: Update `group.erin-ndrio.identitybuilder` in:
   - Entitlements files
   - SharedData.swift
3. **Development Team**: Set your team in project settings

---

## 📦 App Store Submission

### ✅ Ready for Submission
All technical requirements are complete:
- ✅ Privacy Manifest (`PrivacyInfo.xcprivacy`)
- ✅ Proper Info.plist configuration
- ✅ App Icon (1024x1024)
- ✅ Export compliance declaration
- ✅ Widget Extension configured
- ✅ App Group setup

### What You Need
1. **Privacy Policy** (5 min) - See `SUBMIT_TO_APP_STORE.md`
2. **Screenshots** (30-60 min) - 3-10 images at 1290x2796
3. **App Store Connect Setup** (10 min) - Create app listing
4. **Archive & Upload** (15 min) - Product > Archive in Xcode

**Total time: ~1-2 hours**

See `SUBMIT_TO_APP_STORE.md` for detailed step-by-step instructions.

---

## 📖 Documentation

- **SUBMIT_TO_APP_STORE.md**: Complete submission guide
- **APP_STORE_METADATA.md**: Copy-ready app descriptions, keywords, and review notes
- **CLAUDE.md**: Developer guidelines and architecture notes

---

## 🛠️ Development

### Build Commands
```bash
# Simulator build
xcodebuild -scheme identitybuilder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Device build (archive)
# Use Xcode: Product > Archive
# Or see SUBMIT_TO_APP_STORE.md for CLI commands
```

### Code Quality
- **No Debug Code**: All print statements removed (except error logging)
- **Named Constants**: Magic numbers extracted to documented constants
- **Error Handling**: Proper try-catch with logging
- **Documentation**: Comprehensive comments explaining complex logic

### Testing
- Unit tests: `identitybuilderTests/`
- UI tests: `identitybuilderUITests/`
- Manual testing checklist in `APP_STORE_METADATA.md`

---

## 🎨 Design Philosophy

### Inspired by "Atomic Habits"
1. **Identity-First**: Who do you want to become?
2. **Systems Over Goals**: Focus on daily actions
3. **1% Better**: Small, consistent improvements
4. **Make It Obvious, Attractive, Easy, Satisfying**: The 4 Laws

### UI/UX Principles
- **Compact Design**: Small fonts, tight spacing for information density
- **Theme Adaptive**: Full light/dark mode support
- **Minimal Friction**: Quick habit completion, no unnecessary steps
- **Data Transparency**: CSV export for full control

---

## 📊 Data Models

### Habit
- Identity, name, experiments
- Selected days (0=Sunday, 1=Monday, etc.)
- Streak calculation
- Sort order for custom arrangement

### HabitCompletion
- Date and habit relationship
- Used for completion rate calculation

### WeeklyRetrospective
- Week start date
- Reflection notes

---

## 🤝 Contributing

This is a personal project, but suggestions are welcome:
1. Open an issue for bugs or feature requests
2. PRs welcome for bug fixes
3. Major changes: discuss in issue first

---

## 📄 License

[Add your license here - MIT, GPL, etc.]

---

## 🙏 Acknowledgments

- **James Clear** - "Atomic Habits" methodology
- **Benjamin Franklin** - 13 virtues framework
- Built with SwiftUI and modern Apple frameworks

---

## 📞 Support

- **Issues**: [GitHub Issues](your-repo-url/issues)
- **Email**: [your-email]
- **App Store**: [Link after submission]

---

## 🗓️ Version History

### 1.0 (Current)
- Initial release
- Core habit tracking functionality
- Weekly trends and retrospectives
- AI-powered experiment suggestions
- Widget support
- CSV export/import

---

**Built with ❤️ for anyone striving to become a better version of themselves.**
