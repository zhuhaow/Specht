import Cocoa
import NetworkExtension
import CocoaLumberjackSwift
import CommonCrypto
import NEKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLevel: DDLogLevel.All)
        DDLog.addLogger(DDASLLogger.sharedInstance(), withLevel: DDLogLevel.All)
        DDTTYLogger.sharedInstance().colorsEnabled = true
        DDLogInfo("App Started.")

        openConfigFolder()
        removeAllManagers()

        // We should wait before all `NETunnelProviderManager`s are removed. But whatever.
        sleep(1)
        reloadAllConfigFiles()
    }

    // not used
    func reloadAllManagers() {
        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler() { managers, error in
            guard let managers = managers else {
                DDLogError("Failed to load VPN settings from preferences. \(error)")
                return
            }

            for manager in managers {
                self.reloadManager(manager)
            }
        }
    }

    // not used
    func reloadManager(manager: NETunnelProviderManager) {
        guard let configuration = manager.protocolConfiguration as? NETunnelProviderProtocol else {
            manager.removeFromPreferencesWithCompletionHandler(nil)
            return
        }

        guard let configFileURL = configuration.providerConfiguration?["configFileURL"] as? String else {
            manager.removeFromPreferencesWithCompletionHandler(nil)
            return
        }

        var isDirectory = ObjCBool(false)
        guard NSFileManager.defaultManager().fileExistsAtPath(configFileURL, isDirectory: &isDirectory) && !isDirectory else {
            manager.removeFromPreferencesWithCompletionHandler(nil)
            return
        }

        do {
            try configuration.providerConfiguration!["config"] = String(contentsOfFile: configFileURL, encoding: NSUTF8StringEncoding)
        } catch {
            manager.removeFromPreferencesWithCompletionHandler(nil)
            return
        }

        manager.saveToPreferencesWithCompletionHandler(nil)
    }

    func removeAllManagers() {
        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler() { managers, error in
            guard let managers = managers else {
                DDLogError("Failed to load VPN settings from preferences. \(error)")
                return
            }

            for manager in managers {
                manager.removeFromPreferencesWithCompletionHandler(nil)
            }
        }
    }

    func loadConfigFile(path: String) {
        let configuration = NETunnelProviderProtocol()
        configuration.providerConfiguration = ["configFileURL": path]

        do {
            try configuration.providerConfiguration!.updateValue(String(contentsOfFile: path, encoding: NSUTF8StringEncoding), forKey: "config")
        } catch {
            return
        }

        let name = ((path as NSString).lastPathComponent as NSString).stringByDeletingPathExtension

        let manager = NETunnelProviderManager()
        manager.localizedDescription = name
        configuration.providerBundleIdentifier = "me.zhuhaow.osx.Specht.SpechtTunnelPacketProvider"
        configuration.serverAddress = "127.0.0.1"
        manager.protocolConfiguration = configuration
        DDLogError("\(manager)")
        manager.saveToPreferencesWithCompletionHandler(nil)
    }

    func reloadAllConfigFiles() {
        let dir = NSHomeDirectory()
        let paths = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(dir).filter {
            ($0 as NSString).pathExtension == "yaml"
        }

        for path in paths {
            loadConfigFile(path)
        }
    }

    func openConfigFolder() {
        NSWorkspace.sharedWorkspace().openFile(NSHomeDirectory())
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}
