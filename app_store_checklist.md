# App Store Submission Checklist for Nookly

## Pre-Submission Checklist

### ✅ Apple Developer Account
- [ ] Enrolled in Apple Developer Program ($99/year)
- [ ] Accepted latest agreements
- [ ] Completed tax and banking information
- [ ] Verified account is active

### ✅ App Store Connect Setup
- [ ] Created app in App Store Connect
- [ ] Bundle ID: `com.nookly.app`
- [ ] App name: "Nookly"
- [ ] Primary language set to English

### ✅ App Configuration
- [ ] Version number: 1.0.0+1 (in pubspec.yaml)
- [ ] Bundle identifier matches: `com.nookly.app`
- [ ] App icon: 1024x1024 PNG in assets/icons/app_icon.png
- [ ] Generated app icons: `flutter pub run flutter_launcher_icons:main`

### ✅ Code Signing & Certificates
- [ ] Apple Distribution Certificate created
- [ ] App Store Provisioning Profile created
- [ ] Automatic signing enabled in Xcode
- [ ] Team selected in Xcode project settings

### ✅ App Store Connect Information
- [ ] App Information filled out:
  - [ ] Subtitle (30 characters max)
  - [ ] Keywords
  - [ ] Support URL
  - [ ] Marketing URL (optional)
  - [ ] Privacy Policy URL (REQUIRED)

- [ ] App Store tab filled out:
  - [ ] App Name: Nookly
  - [ ] Subtitle
  - [ ] Description (4000 characters max)
  - [ ] Keywords
  - [ ] Support URL
  - [ ] Marketing URL

### ✅ TestFlight Setup
- [ ] Test Information filled out:
  - [ ] Feedback Email
  - [ ] Beta App Description
  - [ ] Beta App Review Information
- [ ] Testers added to TestFlight
- [ ] Internal testing group created

### ✅ App Store Review Information
- [ ] Contact Information provided
- [ ] Demo Account credentials provided
- [ ] Notes for reviewers added
- [ ] Content Rights confirmed
- [ ] Age Rating questionnaire completed

### ✅ Screenshots & Assets
- [ ] Screenshots for all required device sizes:
  - [ ] iPhone 6.7" (1290 x 2796)
  - [ ] iPhone 6.5" (1242 x 2688)
  - [ ] iPhone 5.5" (1242 x 2208)
  - [ ] iPad Pro 12.9" (2048 x 2732)
- [ ] App Store icon: 1024x1024 PNG
- [ ] App preview videos (optional but recommended)

### ✅ Legal Requirements
- [ ] Privacy Policy created and hosted
- [ ] Privacy Policy URL added to App Store Connect
- [ ] Terms of Service created (recommended)
- [ ] Age verification system implemented
- [ ] Content moderation system in place

### ✅ Dating App Specific Requirements
- [ ] User reporting system implemented
- [ ] Blocking functionality available
- [ ] Age verification (18+ requirement)
- [ ] Safety features implemented
- [ ] Emergency contact options
- [ ] Content filtering system

### ✅ Technical Requirements
- [ ] App builds successfully in release mode
- [ ] No crashes on launch
- [ ] All features work as expected
- [ ] Performance is acceptable
- [ ] Memory usage is reasonable
- [ ] Battery usage is optimized

### ✅ Privacy & Permissions
- [ ] Camera permission usage description
- [ ] Microphone permission usage description
- [ ] Photo Library permission usage description
- [ ] Location permission usage description (if used)
- [ ] All permission descriptions are clear and accurate

## Build & Upload Checklist

### ✅ Pre-Build
- [ ] Flutter clean completed
- [ ] Dependencies updated: `flutter pub get`
- [ ] iOS dependencies installed: `cd ios && pod install`
- [ ] App icons generated

### ✅ Build Process
- [ ] Release build successful: `flutter build ios --release`
- [ ] Archive created in Xcode
- [ ] No build errors or warnings
- [ ] App size is reasonable (< 100MB recommended)

### ✅ Upload Process
- [ ] Archive uploaded to App Store Connect
- [ ] Build appears in TestFlight
- [ ] Build processing completed
- [ ] No upload errors

## TestFlight Testing Checklist

### ✅ Internal Testing
- [ ] Build submitted for TestFlight review
- [ ] TestFlight review approved
- [ ] Internal testers invited
- [ ] Testers can install and run the app
- [ ] All features tested by internal team
- [ ] Bug fixes implemented if needed

### ✅ External Testing (Optional)
- [ ] External testers invited
- [ ] Beta app review approved (if needed)
- [ ] External testers can access the app
- [ ] Feedback collected and addressed

## App Store Submission Checklist

### ✅ Final Preparation
- [ ] All screenshots uploaded
- [ ] App description finalized
- [ ] Keywords optimized
- [ ] Privacy policy URL verified
- [ ] Support URL verified
- [ ] Marketing URL verified (if applicable)

### ✅ Submission
- [ ] App submitted for review
- [ ] Review information complete
- [ ] Demo account provided
- [ ] Contact information accurate
- [ ] Notes for reviewers clear

## Post-Submission Checklist

### ✅ Review Process
- [ ] Monitor review status in App Store Connect
- [ ] Respond to any review team questions
- [ ] Address any rejection issues
- [ ] Resubmit if necessary

### ✅ Launch Preparation
- [ ] App approved for App Store
- [ ] Release date set
- [ ] Marketing materials ready
- [ ] Support team prepared
- [ ] Analytics tracking implemented

## Important Notes

### ⚠️ Common Rejection Reasons for Dating Apps
- [ ] Insufficient content moderation
- [ ] Missing age verification
- [ ] Inadequate user reporting system
- [ ] Privacy policy issues
- [ ] Inappropriate content in screenshots
- [ ] Missing safety features

### ⚠️ Performance Requirements
- [ ] App launches within 20 seconds
- [ ] No excessive battery drain
- [ ] Reasonable memory usage
- [ ] Smooth user experience
- [ ] No frequent crashes

### ⚠️ Legal Compliance
- [ ] GDPR compliance (if applicable)
- [ ] CCPA compliance (if applicable)
- [ ] Local data protection laws
- [ ] Age verification requirements
- [ ] Content moderation requirements

## Timeline Tracking

### Week 1: Setup
- [ ] Apple Developer Account
- [ ] App Store Connect setup
- [ ] Initial app configuration

### Week 2: Development
- [ ] Code signing setup
- [ ] App Store Connect app creation
- [ ] TestFlight setup

### Week 3: Testing
- [ ] Build and upload
- [ ] TestFlight testing
- [ ] Bug fixes and improvements

### Week 4: Submission
- [ ] Final app preparation
- [ ] App Store submission
- [ ] Review process

### Week 5: Launch
- [ ] App approval
- [ ] Launch preparation
- [ ] Post-launch monitoring

---

**Total Checklist Items: 80+**
**Estimated Completion Time: 4-6 weeks**

Remember: This is a comprehensive checklist. Not all items may apply to your specific situation, but it's better to be thorough than to miss something important during the submission process. 