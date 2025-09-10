# 🔥 Firebase Setup Guide for AnotherLife

## Prerequisites
- Xcode 15.0+
- iOS 16.0+
- Firebase account
- Terminal access for Firebase CLI

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Project name: `AnotherLife`
4. Enable Google Analytics: **Yes**
5. Choose Analytics account (create new or use existing)
6. Click **"Create project"**

## Step 2: Add iOS App

1. In Firebase Console, click **"Add app"**
2. Select **iOS** (Apple icon)
3. iOS bundle ID: `com.yourname.AnotherLife` (check your Xcode project)
4. App nickname: `AnotherLife`
5. App Store ID: Leave blank
6. Click **"Register app"**

## Step 3: Download Configuration File

1. Download `GoogleService-Info.plist`
2. **IMPORTANT**: Keep this file safe!

## Step 4: Add to Xcode Project

1. Open `AnotherLife.xcodeproj` in Xcode
2. Drag `GoogleService-Info.plist` into the **AnotherLife** folder
3. Check **"Copy items if needed"**
4. Check **"AnotherLife"** target
5. Click **"Finish"**

## Step 5: Add Firebase SDK

1. In Xcode: **File → Add Package Dependencies**
2. URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Click **"Add Package"**
4. Select these products:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore (includes FirebaseFirestoreSwift)
   - ✅ FirebaseAnalytics
   - ✅ FirebaseCrashlytics
5. Click **"Add Package"**

## Step 6: Enable Authentication

1. In Firebase Console: **Authentication → Sign-in method**
2. Enable **Email/Password**
3. Enable **Apple** (optional)

## Step 7: Create Firestore Database

1. In Firebase Console: **Firestore Database → Create database**
2. Choose **"Start in test mode"**
3. Select your preferred location
4. Click **"Done"**

## Step 8: Deploy Security Rules

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firestore:
   ```bash
   firebase init firestore
   ```
   - Select your project
   - Use existing `firestore.rules`
   - Use existing `firestore.indexes.json`

4. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Step 9: Test Connection

1. Build and run the app
2. Check console for Firebase connection status
3. Try creating an account with email/password

## Troubleshooting

### Common Issues:

**1. "Firebase not configured" error:**
- Make sure `GoogleService-Info.plist` is in the correct location
- Check that it's added to the target

**2. Build errors:**
- Clean build folder: **Product → Clean Build Folder**
- Check that all Firebase packages are properly linked

**3. Authentication not working:**
- Verify Email/Password is enabled in Firebase Console
- Check bundle ID matches Firebase project

**4. Firestore permission denied:**
- Deploy security rules: `firebase deploy --only firestore:rules`
- Check rules are properly formatted

## Next Steps

After successful setup:
1. Test user registration and login
2. Test creating challenges
3. Test real-time updates
4. Implement Apple Sign-In
5. Add push notifications

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify all steps were completed
3. Check Xcode console for detailed error messages
4. Ensure internet connection is stable
