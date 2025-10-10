# Force Update Setup Guide

This guide explains how to set up the forced update feature for your Algebraskolan app.

## Overview

The app now checks the current version against a minimum required version stored in Firebase Remote Config. If the user's version is too old, they'll see a popup forcing them to update via the App Store (iOS) or Play Store (Android).

## Setup Steps

### 1. Install New Dependencies

Run the following command to install the new packages:

```bash
flutter pub get
```

This will install:
- `url_launcher` - Opens the App Store/Play Store
- `package_info_plus` - Gets the current app version

### 2. Configure Store URLs

You need to update the store URLs in `lib/utils/version_checker.dart`:

**For iOS (App Store):**
1. Find your App Store ID from App Store Connect
2. Update line 108: `return 'https://apps.apple.com/app/idYOUR_APP_ID';`
   - Example: `return 'https://apps.apple.com/app/id1234567890';`

**For Android (Play Store):**
1. Your package name is likely in `android/app/build.gradle`
2. Update line 111: `return 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';`
   - Example: `return 'https://play.google.com/store/apps/details?id=se.algebraskolan.app';`

### 3. Set Up Firebase Remote Config

1. **Go to Firebase Console**
   - Navigate to: https://console.firebase.google.com/
   - Select your project: `algebra-82c5d`

2. **Open Remote Config**
   - In the left sidebar, find "Engage" section
   - Click on "Remote Config"

3. **Add Configuration Parameters**

   Click "Add parameter" and create these two parameters:

   **Parameter 1: `min_version_ios`**
   - Parameter key: `min_version_ios`
   - Default value: `1.1.9` (current version, no force update)
   - Description: "Minimum required version for iOS"
   
   **Parameter 2: `min_version_android`**
   - Parameter key: `min_version_android`
   - Default value: `1.1.9` (current version, no force update)
   - Description: "Minimum required version for Android"

4. **Publish Changes**
   - Click "Publish changes" in the top right
   - The configuration is now live!

### 4. How to Force an Update

When you release a new version and want to force users to update:

1. **Release your new app version** (e.g., 1.2.0)
2. **Go to Firebase Remote Config**
3. **Update the minimum version**:
   - For iOS: Set `min_version_ios` to `1.2.0`
   - For Android: Set `min_version_android` to `1.2.0`
4. **Publish the changes**

Users on older versions will now see the force update dialog!

### 5. Version Format

Versions should be in the format: `MAJOR.MINOR.PATCH`
- Example: `1.2.3`
- `1` = Major version
- `2` = Minor version
- `3` = Patch version

The system compares versions numerically, so:
- `1.2.3` > `1.2.2` ✅
- `1.3.0` > `1.2.9` ✅
- `2.0.0` > `1.9.9` ✅

## How It Works

1. **App Startup**: When the app starts, it checks the current version
2. **Fetch Remote Config**: Gets the minimum required version from Firebase
3. **Compare Versions**: Compares current vs. required
4. **Show Dialog**: If update needed, shows a non-dismissible popup
5. **Open Store**: User taps "Update" button → Opens App/Play Store

## Testing

### Test the Force Update Dialog:

1. **Set a higher minimum version** in Firebase Remote Config:
   - Current version: `1.1.9`
   - Set `min_version_ios` to: `2.0.0`

2. **Run your app** (you may need to hot restart)
3. **You should see the force update dialog**
4. **Test the "Update" button** - it should open the correct store

### Reset After Testing:

- Set `min_version_ios` and `min_version_android` back to `1.1.9`

## Important Notes

⚠️ **Be Careful!** Once you set a minimum version in Remote Config, ALL users below that version will be forced to update.

✅ **Best Practices:**
- Only force updates for critical bugs or security issues
- Give users a few days/weeks before forcing an update
- Test thoroughly before setting the minimum version
- Keep the minimum version slightly behind the latest release

## Conditional Updates (Optional)

You can create different rules in Remote Config for:
- Different countries
- Different user segments
- Staged rollouts

To do this, use Remote Config conditions when setting parameter values.

## Troubleshooting

**Dialog doesn't appear?**
- Check Firebase console logs
- Check app logs for "VersionChecker" messages
- Ensure Remote Config has been published
- Try a hot restart (R) not just hot reload (r)

**Store doesn't open?**
- Verify the store URLs in `version_checker.dart`
- Check that `url_launcher` is properly installed
- Test on a physical device (may not work in simulator)

**Wrong store opens?**
- Verify `Platform.isIOS` logic in `version_checker.dart`
- Check that conditional logic uses correct URLs

## Current Version

Your current app version is defined in `pubspec.yaml`:
```yaml
version: 1.1.9+18
```

The first part (`1.1.9`) is what's used for version comparison.

