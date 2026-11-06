# @holline/react-native

Adds a Holline support call to your React Native app. Your customer taps a button, the call screen opens inside your app, and they talk to your team with no phone credit.

Beta: the API may still change before 1.0. Questions and problems: info@holline.cloud

## Install

```bash
npm install @holline/react-native
cd ios && pod install
```

Requires React Native 0.73, iOS 15 and Android 7.0 (API 24).

On iOS, add `NSMicrophoneUsageDescription` and `NSCameraUsageDescription` to `Info.plist`. Without the microphone entry, calls can't start.

## Use

`company` is your slug, the last part of your call link: `https://holline.cloud/c/<slug>`.

```ts
import { Holline } from '@holline/react-native'

Holline.open({ company: 'your-slug', name: user.name, phone: user.phone })
```

Closing the screen during a call only hides it, and the call keeps running. To show a "return to call" banner:

```ts
const stop = Holline.onPhaseChanged((phase) => setLive(phase === 'ringing' || phase === 'connected'))
```

Full guide, including Google Play setup: https://holline.cloud/docs#mobile
