# MicSelect

Diagnostic Theos tweak base for iPhone 6s / iOS 15.

## Purpose

v0.1 enumerates AVAudioSession built-in microphone data sources when an
audio session becomes active. It does NOT force a microphone yet.

This is intentional: the next step is to inspect the actual data source
names/IDs exposed by the iPhone 6s on the target iOS 15 build.

## Build

Install Theos and an iOS 15 SDK, then from this directory:

    make package

For rootful jailbreak:

    THEOS_PACKAGE_SCHEME=rootful make package

For rootless:

    THEOS_PACKAGE_SCHEME=rootless make package

The resulting .deb is placed in ./packages/

## Important

The preference path is currently rootless:

    /var/jb/var/mobile/Library/Preferences/com.micselect.preferences.plist

The diagnostic tweak currently loads only in SpringBoard. For actual
microphone routing, the filter will need to target the audio-using
processes, and the routing implementation must be adapted after checking
the real AVAudioSession data sources on the device.
