# Specht

Specht is a simple demo app build with [NEKit](https://github.com/zhuhaow/NEKit).

Note you need NetworkExtention entitlement to run it.

It's highlly recommended do not enable `enablePacketProcessing`, `tun2socks` is still not stable as of now.

If you cannot start the connection in Network Preferences panel, you might have to go to `~/Library/Developer/Xcode/DerivedData/Specht-xxxxxxxxxxxxxxxxxxxx/Build/Products/Debug/Specht.app/Contents/PlugIns` and run `pluginkit -a SpechtTunnelPacketProvider.appex` to install the extension manully (which should be a bug of XCode).
