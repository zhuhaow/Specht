import Cocoa
import NetworkExtension
import NEKit

class VPNManager {
    static var pendingAction: Int = 0
    static var appDelegate: AppDelegate {
        return NSApplication.sharedApplication().delegate! as! AppDelegate
    }

    static func removeAllManagers(completionHandler: () -> ()) {
        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler { managers, error in
            guard let managers = managers else {
                appDelegate.alertError("Failed to load VPN settings from preferences due to \(error)")
                return
            }

            pendingAction = managers.count

            if pendingAction == 0 {
                completionHandler()
                return
            }

            for manager in managers {
                manager.removeFromPreferencesWithCompletionHandler { error in
                    if error != nil {
                        appDelegate.alertError("Failed to remove VPN settings from preferences due to \(error)")
                    }

                    pendingAction -= 1
                    if pendingAction == 0 {
                        completionHandler()
                    }
                }
            }
        }
    }

    static func loadConfigFile(path: String, completionHandler: () -> ()) {
        let configuration = NETunnelProviderProtocol()
        configuration.providerConfiguration = ["configFileURL": path]

        do {
            let content = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            let config = Configuration()
            try config.load(fromConfigString: content)
            configuration.providerConfiguration!["config"] = content
            configuration.providerConfiguration!["hash"] = MD5.string(content)
        } catch let error {
            appDelegate.alertError("Error when loading config file: \(path). \(error)")
            completionHandler()
            return
        }

        let name = ((path as NSString).lastPathComponent as NSString).stringByDeletingPathExtension

        let manager = NETunnelProviderManager()
        manager.localizedDescription = name
        configuration.providerBundleIdentifier = "me.zhuhaow.osx.Specht.SpechtTunnelPacketProvider"
        configuration.serverAddress = "127.0.0.1"
        manager.protocolConfiguration = configuration
        manager.saveToPreferencesWithCompletionHandler { _ in
            completionHandler()
        }
    }

    static func loadAllConfigFiles(configFolder: String, completionHandler: () -> ()) {
        let paths = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(configFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }

        pendingAction = paths.count

        if pendingAction == 0 {
            completionHandler()
            return
        }

        for path in paths {
            loadConfigFile((configFolder as NSString).stringByAppendingPathComponent(path)) {
                pendingAction -= 1
                if pendingAction == 0 {
                    completionHandler()
                }
            }
        }
    }

//    static func reloadAllManagers() {
//        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler() { managers, error in
//            guard let managers = managers else {
//                NSLog("Failed to load VPN settings from preferences. \(error)")
//                return
//            }
//
//            for manager in managers {
//                self.reloadManager(manager)
//            }
//        }
//    }
//
//    static func reloadManager(manager: NETunnelProviderManager) {
//        guard let configuration = manager.protocolConfiguration as? NETunnelProviderProtocol else {
//            manager.removeFromPreferencesWithCompletionHandler(nil)
//            return
//        }
//
//        guard let configFileURL = configuration.providerConfiguration?["configFileURL"] as? String else {
//            manager.removeFromPreferencesWithCompletionHandler(nil)
//            return
//        }
//
//        var isDirectory = ObjCBool(false)
//        guard NSFileManager.defaultManager().fileExistsAtPath(configFileURL, isDirectory: &isDirectory) && !isDirectory else {
//            manager.removeFromPreferencesWithCompletionHandler(nil)
//            return
//        }
//
//        do {
//            let content = try String(contentsOfFile: configFileURL, encoding: NSUTF8StringEncoding)
//            let hash = MD5.string(content)
//            if hash != configuration.providerConfiguration!["hash"] as! String {
//                configuration.providerConfiguration!["config"] = content
//                configuration.providerConfiguration!["hash"] = hash
//                manager.saveToPreferencesWithCompletionHandler(nil)
//            }
//        } catch {
//            manager.removeFromPreferencesWithCompletionHandler(nil)
//            return
//        }
//    }
}
