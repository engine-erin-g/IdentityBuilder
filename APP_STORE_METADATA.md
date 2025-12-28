# Identity Builder - App Store Submission Checklist

## App Information

### Basic Details
- **App Name**: Identity Builder
- **Subtitle**: Build Better Habits Through Identity
- **Bundle ID**: erin-ndrio.identitybuilder
- **Version**: 1.0 (Build 1)
- **Category**: Lifestyle
- **Age Rating**: 4+

### Description

**Short Description (30 chars max):**
Build habits, build yourself

**Full Description:**

Transform your habits by focusing on who you want to become, not just what you want to do. Identity Builder is based on James Clear's "Atomic Habits" philosophy: lasting change happens when you shift your identity.

KEY FEATURES:

📊 Identity-Based Tracking
• Link habits to your desired identity (e.g., "Athlete," "Reader")
• See how each action builds the person you're becoming
• Track what matters: who you are, not just what you do

🧪 Experiment Framework
• Test habit-building strategies using the 4 Laws of Behavior Change
• Track what works and what doesn't
• Build your personal playbook for success

📈 Powerful Analytics
• Daily completion tracking with streak counters
• Weekly trends and retrospectives
• 10-week and 10-month progress charts
• See your transformation over time

✨ AI-Powered Insights (Optional)
• Copy personalized prompts for your favorite AI tool
• Get experiment suggestions based on your performance
• Learn from proven strategies in our experiment database

🎯 Inspired by Benjamin Franklin
• Limited to 13 daily habits (Franklin's proven method)
• Focus on mastery, not overwhelm
• Quality over quantity

💾 Your Data, Your Control
• All data stored locally on your device
• CSV export/import for full data ownership
• Widget support for at-a-glance progress
• No account required, no tracking

Perfect for anyone inspired by "Atomic Habits" who wants to build better systems and become the person they aspire to be.

### Keywords (100 chars max)
habit tracker,atomic habits,identity,routine,self improvement,productivity,goals,streak,discipline

### What's New in This Version
Initial release - Transform your habits through identity-based tracking!

### Support URL
https://github.com/anthropics/identitybuilder (or your own URL)

### Privacy Policy URL
(Required - create a simple privacy policy page)

---

## Screenshots Required

### iPhone (6.7" Display - iPhone 14 Pro Max or newer)
**Required: 3-10 screenshots**

Suggested screenshots:
1. **Today View** - Show habit tracking with completion percentage
2. **Weekly Trends** - Display the week view with charts
3. **Habit Details** - Show a habit card with experiments and stats
4. **AI Insights** - Display the AI view with suggestions
5. **Weekly Retrospective** - Show reflection interface
6. **Inspiration** - Benjamin Franklin's 13 virtues screen

Dimensions: 1290 x 2796 pixels (or 1284 x 2778)

### iPad (Optional but Recommended)
**12.9" iPad Pro (6th Gen)**
Dimensions: 2048 x 2732 pixels

---

## App Store Review Information

### Demo Account
Not required - no login needed

### Notes for Review
"Identity Builder is a habit tracking app based on the 'Atomic Habits' philosophy by James Clear. The app focuses on identity-based habits rather than goal-based habits.

Key features to test:
1. Create a new habit with identity, name, and schedule
2. Complete habits on the Day tab
3. View weekly trends and add retrospective notes
4. Try the AI tab to generate personalized suggestions (requires copying to external AI tool)
5. Export/import data via CSV in the settings menu (tap ••• on Day tab)

The app uses local SwiftData storage only - no network requests except for the optional AI experiment examples (from a public Google Sheet).

Widget functionality is prepared but requires adding to home screen to test."

---

## Privacy Questionnaire

### Data Collection
**Does this app collect data from users?**
No

**Explanation:**
All habit data is stored locally on the device using SwiftData. The app does not transmit any user data to external servers. The only network request is optional: fetching experiment examples from a public Google Sheet when users tap "AI" (does not send any user data).

### Third-Party SDKs
None - uses only Apple's native frameworks (SwiftUI, SwiftData, WidgetKit)

### Data Types (All NO)
- [ ] Contact Info
- [ ] Health & Fitness
- [ ] Financial Info
- [ ] Location
- [ ] Sensitive Info
- [ ] Contacts
- [ ] User Content
- [ ] Browsing History
- [ ] Search History
- [ ] Identifiers
- [ ] Purchases
- [ ] Usage Data
- [ ] Diagnostics
- [ ] Other Data

---

## Export Compliance

### Does your app use encryption?
Yes (but exempt)

**Explanation:**
The app uses Apple's standard HTTPS for fetching experiment examples from Google Sheets. This qualifies for exemption under:
- (a) Uses only standard encryption
- (b) Available to mass market with no special registration
- ITSAppUsesNonExemptEncryption = NO

---

## Content Rights

### Age Rating Questionnaire
- Unrestricted Web Access: No
- Gambling/Contests: No
- Mature/Suggestive Themes: No (None)
- Violence: No (None)
- Realistic Violence: No (None)
- Profanity/Crude Humor: No (None)
- Horror/Fear Themes: No (None)
- Medical/Treatment Info: No
- Alcohol/Tobacco/Drugs: No (None)

**Result: 4+ (All ages)**

---

## Pre-Submission Checklist

### Required Files
- [x] App Icon (1024x1024) ✅ Already present
- [x] PrivacyInfo.xcprivacy ✅ Created
- [x] Info.plist configured ✅ Updated
- [ ] Screenshots (3-10 images per device size)
- [ ] App Preview video (optional)
- [ ] Privacy Policy URL (create simple page)

### Build Settings
- [x] Version: 1.0
- [x] Build: 1
- [x] Bundle ID: erin-ndrio.identitybuilder
- [x] Development Team: 4CXBYS784C
- [x] Signing: Automatic (for App Store)

### Code Quality
- [x] No debug code
- [x] No console logs (minimal error logging only)
- [x] Proper error handling
- [x] Widget Extension properly configured
- [x] App Group configured (group.erin-ndrio.identitybuilder)

### Testing
- [ ] Archive builds successfully
- [ ] App runs on physical device
- [ ] All features work correctly
- [ ] Widget displays properly
- [ ] Data export/import works
- [ ] No crashes or major bugs

---

## Next Steps

1. **Create Screenshots**
   - Use iPhone 14 Pro Max simulator or real device
   - Capture 3-10 compelling screenshots
   - Consider using tools like Fastlane Snapshot or manual captures

2. **Create Privacy Policy**
   - Simple page stating: "All data stored locally, no collection"
   - Host on GitHub Pages, your website, or use a service

3. **Build Archive**
   ```bash
   # In Xcode:
   # 1. Select "Any iOS Device (arm64)" as destination
   # 2. Product > Archive
   # 3. Organizer > Distribute App > App Store Connect
   # 4. Upload with automatic signing
   ```

4. **App Store Connect Setup**
   - Create new app in App Store Connect
   - Fill in metadata, keywords, description
   - Upload screenshots
   - Submit for review

5. **TestFlight (Optional)**
   - Test with external users first
   - Gather feedback before public release

---

## Common Review Issues to Avoid

✅ **Already Addressed:**
- App has clear purpose and functionality
- No private APIs used
- Privacy manifest included
- Encryption compliance documented
- No misleading functionality

⚠️ **Watch Out For:**
- Make sure screenshots accurately represent the app
- Ensure description doesn't over-promise
- Test thoroughly before submitting
- Respond quickly to review questions

---

## Contact Information

**For App Store Review Team:**
- First Name: [Your first name]
- Last Name: [Your last name]
- Email: [Your email]
- Phone: [Your phone number]

---

Generated on: $(date)
Version: 1.0 (Build 1)
