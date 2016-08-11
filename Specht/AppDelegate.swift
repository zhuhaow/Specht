import Cocoa
import NetworkExtension
import NEKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var barItem: NSStatusItem!
    var managerMap: [String: NETunnelProviderManager]!
    var pendingAction = 0

    var configFolder: String {
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(".Specht")
        var isDir: ObjCBool = false
        let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
        if exist && !isDir {
            try! NSFileManager.defaultManager().removeItemAtPath(path)
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        if !exist {
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        reloadAllConfigurationFiles() {
            self.registerObserver()
            self.initMenuBar()
        }
    }


    func initManagerMap(completionHandler: () -> ()) {
        managerMap = [:]

        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler { managers, error in
            guard managers != nil else {
                self.alertError("Failed to load VPN settings from preferences. \(error)")
                return
            }

            for manager in managers! {
                self.managerMap[manager.localizedDescription!] = manager
            }

            completionHandler()
        }
    }

    func initMenuBar() {
        barItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        barItem.title = "Sp"
        barItem.menu = NSMenu()
        barItem.menu!.delegate = self
    }

    func registerObserver() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.statusDidChange(_:)), name: NEVPNStatusDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.configurationDidChange(_:)), name: NEVPNConfigurationChangeNotification, object: nil)
    }

    func statusDidChange(notification: NSNotification) {
    }

    func configurationDidChange(notification: NSNotification) {
    }

    func startConfiguration(sender: NSMenuItem) {
        let manager = managerMap[sender.title]!
        do {
            switch manager.connection.status {
            case .Disconnected:
//                disconnect()
                try (manager.connection as! NETunnelProviderSession).startTunnelWithOptions([:])
            case .Connected, .Connecting, .Reasserting:
                (manager.connection as! NETunnelProviderSession).stopTunnel()
            default:
                break
            }
        } catch let error {
            alertError("Failed to start VPN \(sender.title) due to: \(error)")
        }
    }

    func menuNeedsUpdate(menu: NSMenu) {
        menu.removeAllItems()

        let disableNonConnected = findConnectedManager() != nil
        for manager in managerMap.values {
            let item = buildMenuItemForManager(manager, disableNonConnected: disableNonConnected)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Disconnect", action: #selector(AppDelegate.disconnect(_:)), keyEquivalent: "d")
        menu.addItemWithTitle("Open config folder", action: #selector(AppDelegate.openConfigFolder(_:)), keyEquivalent: "c")
        menu.addItemWithTitle("Reload config", action: #selector(AppDelegate.reloadClicked(_:)), keyEquivalent: "r")
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Exit", action: #selector(AppDelegate.terminate(_:)), keyEquivalent: "q")
    }

    func openConfigFolder(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openFile(configFolder)
    }

    func reloadClicked(sender: AnyObject) {
        reloadAllConfigurationFiles()
    }

    func reloadAllConfigurationFiles(completionHandler: (() -> ())? = nil) {
        VPNManager.removeAllManagers {
            VPNManager.loadAllConfigFiles(self.configFolder) {
                self.initManagerMap() {
                    completionHandler?()
                }
            }
        }
    }

    func disconnect(sender: AnyObject? = nil) {
        for manager in managerMap.values {
            switch manager.connection.status {
            case .Connected, .Connecting:
                (manager.connection as! NETunnelProviderSession).stopTunnel()
            default:
                break
            }
        }
    }

    func findConnectedManager() -> NETunnelProviderManager? {
        for manager in managerMap.values {
            switch manager.connection.status {
            case .Connected, .Connecting, .Reasserting, .Disconnecting:
                return manager
            default:
                break
            }
        }
        return nil
    }

    func buildMenuItemForManager(manager: NETunnelProviderManager, disableNonConnected: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: manager.localizedDescription!, action: #selector(AppDelegate.startConfiguration(_:)), keyEquivalent: "")

        switch manager.connection.status {
        case .Connected:
            item.state = NSOnState
        case .Connecting:
            item.title = item.title.stringByAppendingString("(Connecting)")
        case .Disconnecting:
            item.title = item.title.stringByAppendingString("(Disconnecting)")
        case .Reasserting:
            item.title = item.title.stringByAppendingString("(Reconnecting)")
        case .Disconnected:
            break
        case .Invalid:
            item.title = item.title.stringByAppendingString("(----)")
        }

        if disableNonConnected {
            switch manager.connection.status {
            case .Disconnected, .Invalid:
                item.action = nil
            default:
                break
            }
        }
        return item
    }

    func alertError(errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func terminate(sender: AnyObject) {
        NSApp.terminate(self)
    }

}
