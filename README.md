#Specht
[![Join the chat at https://gitter.im/zhuhaow/NEKit](https://badges.gitter.im/zhuhaow/NEKit.svg)](https://gitter.im/zhuhaow/NEKit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/zhuhaow/Specht.svg?branch=master)](https://travis-ci.org/zhuhaow/SpechtLite) [![GitHub license](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)
### A rule-based proxy app built with Network Extension for macOS.

![Splash image](imgs/splash.png)

## Overview
Specht is a simple proxy app built with [NEKit](https://github.com/zhuhaow/NEKit).

**Unless you have a developer ID with Network Extension entitlement, you cannot use Specht ([Why?](https://github.com/zhuhaow/SpechtLite#full)).** Please use [SpechtLite](https://github.com/zhuhaow/SpechtLite) instead.

Specht can do everything SpechtLite can do.

Plus, Specht sets up proxy automatically through API provided by Network Extension so you do not need to do it in System Preferences yourself. And Specht can redirect all TCP flows (even when apps ignore system proxy settings) to go through proxy servers.

The core of Specht is just a few lines of code calling [NEKit](https://github.com/zhuhaow/NEKit). Specht is mainly provided as a demo for developers who want to work with NEKit. Use SpechtLite if you are not interested in NEKit.

Note there is no fancy GUI configuration panel. You set up Specht with configuration files as [SpechtLite](https://github.com/zhuhaow/SpechtLite).


## Configuration File
Refer to [SpechtLite](https://github.com/zhuhaow/SpechtLite) for how to write configuration files.

## How to sign this app?
You have to sign this app yourself to run it which means you have to:

* Join Apple Developer Program ($99/year)
* [Request](https://developer.apple.com/contact/network-extension/) Network Entension entitlement from Apple (at least Packet Tunnel).

After you get the permission from Apple, go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/mac/certificate/):

1. Issue a Mac Development certificate (skip it if you already have one).
2. Register two App IDs for the app and its embedded extension, what Specht uses can be found in the XCode, you can change them if you want (I suggest not changing it until you get everything up and running.) Don't forget to select "Personal VPN".
3. Go to provision to add two new profiles, select "Mac App Development", and follow the guide, do include Network Extension entitlement. 

Now you can sign the app, in Build Settings, set Provisioning Profile to the correct provision files just created and build.

## Some tips
* Do get to know how Network Entension works from the offcial document before you change anything.
* Use "Console" and filter to see what is wrong with macOS.
* Kill "SpechtTunnelPacketProvider" (and if something is not working correctly, "neagent") before running each rebuild.
* The old "SpechtTunnelPacketProvider" usually will be uninstalled correctly but the new one may not get installed. You can check this in "Console". If anything goes wrong, you have to go to `xcodebuild -project Specht.xcodeproj -configuration Debug -showBuildSettings | grep TARGET_BUILD_DIR` and then into `Specht.app/Contents/PlugIns`, run `pluginkit -a SpechtTunnelPacketProvider.appex` to install the extension manually.

## Known Issues
* When we disconnect, "SpechtTunnelPacketProvider" should terminate immediately. However, it will stil run for several seconds. If we connect to a new tunnel immediately, it will use the old "SpechtTunnelPacketProvider" process which will be killed in a few seconds later. So I have to terminate the extension explicitly as of now. Though there should be no consequences, the system takes that as a crash, so this must be fixed before any apps can be uploaded to the Mac App Store.

## I still need help ...
If you have any questions, please ask at [![Join the chat at https://gitter.im/zhuhaow/NEKit](https://badges.gitter.im/zhuhaow/NEKit.svg)](https://gitter.im/zhuhaow/NEKit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge). And yes, you can ask in Chinese.

Do not open an issue unless it is one.

It's best if you can leave an issue relating to NEKit at [NEKit issues](https://github.com/zhuhaow/NEKit/issues).



## Can I upload this to the Mac App Store?
Specht is published under GPLv3. 

But please do not use the icon and the name if you do want to redistribute it.
