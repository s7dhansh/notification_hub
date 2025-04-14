# Notification Hub

A centralized Flutter application for capturing, organizing, and managing notifications from various apps on your device.

## Features

- **Centralized Notification Management**: View all your notifications in one place
- **App Grouping**: Notifications are neatly organized by app for better management
- **Notification Filtering**: Exclude specific apps from notification capture with a simple long press
- **Dashmon Integration**: View notification statistics and patterns with Dashmon integration
- **Privacy Focused**: All data stays on your device with no cloud uploads

## Device Setup

### Android Setup

1. **Grant Notification Listener Permission**:
   - Go to Settings > Apps > Special app access > Notification access
   - Find and enable "Notification Hub"

2. **Additional Steps for Some Devices**:
   - On some Android versions, you may need to enable additional permissions in Settings > Apps > Notification Hub > Permissions
   - Ensure "Display over other apps" is enabled if available

3. **Battery Optimization**:
   - To ensure reliable background operation, disable battery optimization for Notification Hub
   - Go to Settings > Apps > Notification Hub > Battery > Unrestricted

### iOS Setup

Notification access on iOS is more limited compared to Android due to platform restrictions. However, the app will still function with the following setup:

1. **Enable Notifications**:
   - Go to Settings > Notifications > Notification Hub
   - Enable "Allow Notifications"
   - Turn on all notification types (Sounds, Badges, Banners)

2. **Background App Refresh**:
   - Go to Settings > General > Background App Refresh
   - Ensure Notification Hub is enabled

**Note**: On iOS, Notification Hub cannot directly intercept notifications from other apps due to system limitations. It can only receive its own notifications and those that are explicitly shared with it.

## Usage

### Main Features

1. **Permission Setup**: Grant notification access permission when first launching the app
2. **Viewing Notifications**: All notifications are grouped by app in the main screen
3. **Excluding Apps**: Long press on an app name to exclude it from notification capture
4. **Managing Excluded Apps**: Go to settings to view and restore excluded apps
5. **Dashmon Integration**: View notification metrics and patterns through the Dashmon feature

### How to Exclude an App

1. Long press on any app name in the main screen
2. Confirm the exclusion in the dialog that appears
3. Use the UNDO option in the snackbar if needed, or restore later from Settings

## Development

This project is built with Flutter and uses:

- Provider pattern for state management
- SharedPreferences for local storage
- Flutter Local Notifications for notification handling

## Getting Started with Development

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Ensure you have notification permissions enabled on your device
4. Run the app with `flutter run`
