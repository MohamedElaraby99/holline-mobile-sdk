# Holline Mobile SDK

> Beta: the API may still change before 1.0. Questions and problems: info@holline.cloud

Adds a support call to your mobile app. Your customer taps a button in your app, the Holline call screen opens inside it, and they talk to your team with no phone credit and without leaving the app.

| Your app | Package | Requires |
| --- | --- | --- |
| Android (Kotlin or Java) | JitPack | Android 7.0 (API 24) |
| iOS (Swift) | `HollineSDK` | iOS 15 |
| React Native | `@holline/react-native` | React Native 0.73, iOS 15, API 24 |
| Flutter | `holline_sdk` | Flutter 3.19, iOS 15, API 24 |

You need your company's **slug**: the last part of your call link, `https://holline.cloud/c/<slug>`.

## Install and open

### React Native

The npm package isn't published yet. Email info@holline.cloud to get it, and don't install a package with this name from anywhere else until this line is gone.

Once you have it, usage looks like this:

```ts
import { Holline } from '@holline/react-native'

Holline.open({ company: 'your-slug', name: user.name, phone: user.phone })
```

### Flutter

```yaml
dependencies:
  holline_sdk:
    git:
      url: https://github.com/MohamedElaraby99/holline-mobile-sdk.git
      path: flutter
      ref: 0.1.0
```

```dart
import 'package:holline_sdk/holline_sdk.dart';

Holline.open(company: 'your-slug', name: user.name, phone: user.phone);
```

### Android

In `settings.gradle.kts`, add JitPack to `dependencyResolutionManagement.repositories`, then add the library to your app:

```kotlin
maven("https://jitpack.io")
```

```kotlin
implementation("com.github.MohamedElaraby99:holline-mobile-sdk:0.1.0")
```

```kotlin
import cloud.holline.sdk.Holline

Holline.open(context, company = "your-slug", name = user.name, phone = user.phone)
```

### iOS

In Xcode, choose **File → Add Package Dependencies**, enter `https://github.com/MohamedElaraby99/holline-mobile-sdk`, then:

```swift
import HollineSDK

Holline.open(company: "your-slug", name: user.name, phone: user.phone)
```

## Required setup

**iOS:** add these to `Info.plist`. Without the microphone entry, calls can't start.

```xml
<key>NSMicrophoneUsageDescription</key>
<string>To talk to customer support.</string>
<key>NSCameraUsageDescription</key>
<string>To turn on your camera in a support video call.</string>
```

**Android:** nothing to add. The SDK's manifest declares what it needs. Before you publish to Google Play:

- Complete the foreground service declaration in Play Console, choosing microphone. The SDK uses it to keep a call running while your app is in the background.
- If your company doesn't use video calls and you don't want the camera permission, remove it from your app's manifest. Calls still work, and the camera button reports that the camera isn't available.

```xml
<uses-permission android:name="android.permission.CAMERA" tools:node="remove" />
```

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `company` | required | Your slug |
| `name`, `phone` | empty | Fill in the form so the customer only taps call. They can still edit them. |
| `source` | `mobile_app` | The source shown for the call in your analytics |

## Showing a live call in your app

Closing the call screen during a call only hides it, and the call keeps running. Calling `open` again brings it back. Use the phase to show a "return to call" banner:

```ts
// React Native
const stop = Holline.onPhaseChanged((phase) => setLive(phase === 'ringing' || phase === 'connected'))
```

```dart
// Flutter
Holline.phases.listen((phase) => setLive(phase == 'ringing' || phase == 'connected'));
```

```kotlin
// Android
Holline.onPhaseChanged = { phase -> setLive(Holline.isInCall) }
```

```swift
// iOS
Holline.onPhaseChanged = { _ in setLive(Holline.isInCall) }
```

| Phase | Meaning |
| --- | --- |
| `flow` | The customer is going through your call menu |
| `form` | The customer is on the name and phone form |
| `ringing` | Waiting for an agent, including in the queue |
| `connected` | Talking to an agent |
| `ended` | The call finished |
| `missed` | Nobody answered. Your team has the customer's number to call back. |
| `callback` | The customer asked to be called back instead of waiting |
| `moved` | The call moved to another screen or device |
| `mic-error` | The microphone is unavailable or permission was refused |

## In the background

- **Android:** the call continues in the background, with a notification that brings the customer back to it.
- **iOS:** the call continues while the customer moves around your app, but iOS stops the web view's microphone when your app leaves the screen. Holline holds a caller's place for 2 minutes, and reopening the screen within that time returns them to the call.

## What runs in your app

The SDK shows `holline.cloud` in a web view, so call features and fixes reach your app without a new release. Links that leave the site, such as WhatsApp, open in the customer's own apps. The customer's name and phone are passed in the URL fragment, so they don't appear in web server logs. They are sent to Holline only when the customer places the call.

## Contributing

`android/` and `ios/` hold the SDK. `flutter/` and `react-native/` are thin wrappers that ship their own copies of it, so after changing the SDK run:

```bash
sh scripts/sync-wrappers.sh
```

Inside the web view, the call page on holline.cloud runs with `?sdk=1`. It reports phases through `window.HollineNative` on Android and `window.webkit.messageHandlers.holline` on iOS. That message format has to stay stable, because apps already in customers' hands depend on it.

```bash
cd android && ./gradlew :holline-sdk:testDebugUnitTest :holline-sdk:assembleRelease
cd flutter && flutter test
```

iOS only compiles on a Mac. The `CI` GitHub Actions workflow builds every platform.

## Support

info@holline.cloud
