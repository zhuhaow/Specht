import NetworkExtension
import CocoaLumberjackSwift
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    var interface: TUNInterface!
    // Since tun2socks is not stable, this is recommended to set to false
    var enablePacketProcessing = true

    var proxyPort: Int!

    var proxyServer: ProxyServer!

    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        DDLog.removeAllLoggers()
        // warning: setting to .Debug level might be way too verbose.
        DDLog.addLogger(DDASLLogger.sharedInstance(), withLevel: DDLogLevel.Info)

        // Use the build-in debug observer.
        ObserverFactory.currentFactory = DebugObserverFactory()

        let configuration = Configuration()
        try! configuration.load(fromConfigString: (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!["config"] as! String)
        RuleManager.currentManager = configuration.ruleManager
        proxyPort = configuration.proxyPort ?? 9090

        RawSocketFactory.TunnelProvider = self

        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.MTU = 1500

        let ipv4Settings = NEIPv4Settings(addresses: ["192.169.89.1"], subnetMasks: ["255.255.255.0"])
        if enablePacketProcessing {
            ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]
            ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            ]
        }
        networkSettings.IPv4Settings = ipv4Settings

        let proxySettings = NEProxySettings()
        //        proxySettings.autoProxyConfigurationEnabled = true
        //        proxySettings.proxyAutoConfigurationJavaScript = "function FindProxyForURL(url, host) {return \"SOCKS 127.0.0.1:\(proxyPort)\";}"
        proxySettings.HTTPEnabled = true
        proxySettings.HTTPServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.HTTPSEnabled = true
        proxySettings.HTTPSServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        proxySettings.matchDomains = [""]
        networkSettings.proxySettings = proxySettings

        // the 198.18.0.0/15 is reserved for benchmark.
        if enablePacketProcessing {
            let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
            DNSSettings.matchDomains = [""]
            DNSSettings.matchDomainsNoSearch = false
            networkSettings.DNSSettings = DNSSettings
        }

        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                DDLogError("Encountered an error setting up the network: \(error)")
                completionHandler(error)
                return
            }

            self.proxyServer = GCDHTTPProxyServer(address: IPv4Address(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            try! self.proxyServer.start()

            completionHandler(nil)

            if self.enablePacketProcessing {
                self.interface = TUNInterface(packetFlow: self.packetFlow)

                let fakeIPPool = IPv4Pool(start: IPv4Address(fromString: "198.18.1.1")!, end: IPv4Address(fromString: "198.18.255.255")!)
                let dnsServer = DNSServer(address: IPv4Address(fromString: "198.18.0.1")!, port: Port(port: 53), fakeIPPool: fakeIPPool)
                let resolver = UDPDNSResolver(address: IPv4Address(fromString: "114.114.114.114")!, port: Port(port: 53))
                dnsServer.registerResolver(resolver)
                self.interface.registerStack(dnsServer)
                DNSServer.currentServer = dnsServer

                let udpStack = UDPDirectStack()
                self.interface.registerStack(udpStack)

                let tcpStack = TCPStack.stack
                tcpStack.proxyServer = self.proxyServer
                self.interface.registerStack(tcpStack)
                self.interface.start()
            }
        }
    }

    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        if enablePacketProcessing {
            interface.stop()
            interface = nil
            DNSServer.currentServer = nil
        }

        proxyServer.stop()
        proxyServer = nil
        RawSocketFactory.TunnelProvider = nil

        completionHandler()

        // For unknown reason, the extension will be running for several extra seconds, which prevents us from starting another configuration immediately. So we crash the extension now.
        // I do not find any consequences.
        exit(EXIT_SUCCESS)
    }
}
