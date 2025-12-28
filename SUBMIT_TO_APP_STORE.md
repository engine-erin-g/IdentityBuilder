# Quick Guide: Submit to App Store

## ✅ Pre-Flight Checklist (ALL DONE!)

- ✅ **Privacy Manifest**: `PrivacyInfo.xcprivacy` created
- ✅ **Info.plist**: Updated with proper metadata
- ✅ **App Icon**: 1024x1024 PNG verified
- ✅ **Bundle ID**: erin-ndrio.identitybuilder
- ✅ **Version**: 1.0 (Build 1)
- ✅ **Build Tested**: Generic iOS build succeeds
- ✅ **Code Quality**: Debug code removed, error handling improved
- ✅ **Constants**: Magic numbers extracted to named constants

## 📋 What You Still Need

### 1. Create Privacy Policy (5 minutes)
Create a simple webpage or GitHub page with:

```markdown
# Privacy Policy for Identity Builder

Last updated: [Date]

## Data Collection
Identity Builder does NOT collect, store, or transmit any personal data. All habit tracking data is stored locally on your device using Apple's SwiftData framework.

## Third-Party Services
The app optionally fetches experiment examples from a public Google Sheet when you use the AI feature. This request does not include any of your personal data.

## Contact
For questions, contact: [your email]
```

Host it at: GitHub Pages, your website, or use a free service.

### 2. Take Screenshots (30-60 minutes)

**Required**: 3-10 screenshots for iPhone 6.7" display (1290x2796 or 1284x2778)

#### Suggested Screenshots:
1. **Today View** - Habit cards with completion percentage
2. **Weekly View** - Trends and retrospective
3. **Habit Detail** - Experiments and stats
4. **AI Insights** - Personalized suggestions
5. **Weekly Retrospective** - Reflection interface
6. **Inspiration** - Benjamin Franklin's virtues

#### How to Take Screenshots:
**Option A: Simulator**
```bash
# 1. Open Xcode
# 2. Product > Run on iPhone 15 Pro Max simulator
# 3. Use Cmd+S to capture screenshots
# 4. Find in: ~/Desktop
```

**Option B: Real Device**
- Use iPhone 14 Pro Max or newer
- Take screenshots with volume+power button
- Transfer to Mac

**Option C: Professional (Recommended)**
- Use tools like Fastlane Snapshot
- Or design mockups in Figma/Sketch with screenshots

### 3. App Store Connect Setup

#### Step 1: Create App
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: Identity Builder
   - **Primary Language**: English
   - **Bundle ID**: erin-ndrio.identitybuilder
   - **SKU**: identitybuilder-2025 (or any unique identifier)

#### Step 2: Fill Metadata
Copy from `APP_STORE_METADATA.md`:
- App Description
- Keywords
- Support URL
- Privacy Policy URL (from step 1)
- Screenshots (from step 2)

#### Step 3: Pricing & Availability
- **Price**: Free (or set price)
- **Availability**: All territories (or select)

#### Step 4: App Privacy
Answer questionnaire (see APP_STORE_METADATA.md):
- **Data Collection**: NO
- All checkboxes: NO

### 4. Build & Upload

#### Option A: Xcode (Easiest)
```bash
# 1. Open identitybuilder.xcodeproj in Xcode
# 2. Select "Any iOS Device (arm64)" as destination
# 3. Product → Archive
# 4. When archive completes:
#    - Click "Distribute App"
#    - Select "App Store Connect"
#    - Select "Upload"
#    - Use automatic signing
#    - Click "Upload"
```

#### Option B: Command Line
```bash
# Build archive
xcodebuild archive \
  -scheme identitybuilder \
  -archivePath ./build/identitybuilder.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ./build/identitybuilder.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### 5. Submit for Review

1. **Go to App Store Connect** → Your App → Version 1.0
2. **Build**: Select the uploaded build (may take 5-10 min to process)
3. **App Review Information**:
   - Contact: Your name, email, phone
   - Notes: Copy from `APP_STORE_METADATA.md`
4. **Version Release**: Choose automatic or manual
5. **Click "Save"** then **"Submit for Review"**

## ⏱️ Review Timeline

- **Processing**: 10-30 minutes after upload
- **In Review**: 24-48 hours (typically)
- **Resolution**: Same day (if issues found)
- **Total**: 1-3 days average

## 🚨 Common Rejection Reasons & Fixes

### 1. "App is not sufficiently different from a web browsing experience"
**Fix**: Already avoided - native SwiftUI app

### 2. "Privacy policy missing or inadequate"
**Fix**: Create simple privacy policy (see step 1)

### 3. "Screenshots don't accurately represent app"
**Fix**: Use actual app screenshots, not mockups

### 4. "Missing export compliance"
**Fix**: Already set ITSAppUsesNonExemptEncryption = NO

### 5. "App crashes on launch"
**Fix**: Test on real device before submitting

## 📊 Post-Submission Checklist

- [ ] Set up TestFlight for beta testing (optional)
- [ ] Prepare App Store marketing materials
- [ ] Plan launch announcement (social media, etc.)
- [ ] Monitor reviews and respond quickly
- [ ] Prepare for first update (collect user feedback)

## 🔄 Future Updates

When ready to update:
1. Increment version in Xcode (1.0 → 1.1, etc.)
2. Update build number (1 → 2, 3, etc.)
3. Build & upload same as initial submission
4. Add "What's New" text describing changes

## 📞 Need Help?

- **Apple Developer Support**: developer.apple.com/contact
- **App Store Review**: Contact via App Store Connect
- **Technical Issues**: Apple Developer Forums

## 🎉 You're Ready!

Everything is configured. Just need to:
1. Create privacy policy (5 min)
2. Take screenshots (30-60 min)
3. Create app in App Store Connect (10 min)
4. Archive & upload (15 min)
5. Submit for review (5 min)

**Total time: ~1-2 hours**

Good luck with your launch! 🚀
