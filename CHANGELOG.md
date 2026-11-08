# Changelog

## 0.2.0

- **Meetings:** `Holline.joinMeeting(link, name)` opens a Holline meeting from its link or code inside your app. `Holline.isMeetingLink(link)` tells you whether a link is one. This is on Android, iOS, Flutter and React Native.
- **Opening meeting links in your app:** a company sets its app in the dashboard, and its meeting links then open through iOS Universal Links and Android App Links. See "Opening meeting links in your app" in the README.
- **Meeting phases** come through `onPhaseChanged`: `meeting-ready`, `meeting-lobby`, `meeting-joined`, `meeting-left`, `meeting-ended`, `meeting-removed`, `meeting-denied`, `meeting-full` and `meeting-missing`.
- **Leaving:** the page's "back to the app" button closes the screen.
- **In the background:** `isInCall` is true while a meeting is joined, so on Android a meeting keeps running in the background as a call does.

Nothing changes for calls: `open` works as before.

## 0.1.0

First release: support calls inside your app.
