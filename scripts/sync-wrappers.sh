#!/bin/sh
# Copies the native SDK into the Flutter and React Native packages, which must ship
# their own sources to work when installed on their own. Edit android/ and ios/,
# then run this. CI fails if the copies are out of date.
set -e
cd "$(dirname "$0")/.."

android_src=android/holline-sdk/src/main
ios_src=ios/Sources/HollineSDK/Holline.swift

copy_android() {
  dest=$1
  mkdir -p "$dest/src/main/java/cloud/holline/sdk"
  find "$dest/src/main/java/cloud/holline/sdk" -maxdepth 1 -name 'Holline*.kt' -delete
  cp "$android_src"/java/cloud/holline/sdk/*.kt "$dest/src/main/java/cloud/holline/sdk/"
  rm -rf "$dest/src/main/res"
  cp -R "$android_src/res" "$dest/src/main/res"
  cp "$android_src/AndroidManifest.xml" "$dest/src/main/AndroidManifest.xml"
}

copy_android flutter/android
copy_android react-native/android
cp "$ios_src" flutter/ios/holline_sdk/Sources/holline_sdk/Holline.swift
cp "$ios_src" react-native/ios/Holline.swift
cp LICENSE react-native/LICENSE
