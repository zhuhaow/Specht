import NetworkExtension
import CocoaLumberjackSwift
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    var interface: TUNInterface!
    var enablePacketProcessing = true

    var proxyPort: Int!

    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        DDLog.removeAllLoggers()
        DDLog.addLogger(DDASLLogger.sharedInstance(), withLevel: DDLogLevel.All)
        DDLogInfo("Extension Started.")

        let configuration = Configuration()
        configuration.load(fromConfigString: (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!["config"] as! String)
        RuleManager.currentManager = configuration.ruleManager
        proxyPort = configuration.proxyPort ?? 9090

        RawSocketFactory.TunnelProvider = self

        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")

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
        let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
        DNSSettings.matchDomains = [""]
        DNSSettings.matchDomainsNoSearch = false
        networkSettings.DNSSettings = DNSSettings

        if enablePacketProcessing {
            interface = TUNInterface(packetFlow: packetFlow)

            let fakeIPPool = IPv4Pool(start: IPv4Address(fromString: "198.18.1.1"), end: IPv4Address(fromString: "198.18.255.255"))
            let dnsServer = DNSServer(address: IPv4Address(fromString: "198.18.0.1"), port: Port(port: 53), fakeIPPool: fakeIPPool)
            let resolver = UDPDNSResolver(address: IPv4Address(fromString: "114.114.114.114"), port: Port(port: 53))
            dnsServer.registerResolver(resolver)
            interface.registerStack(dnsServer)
            DNSServer.currentServer = dnsServer

            let udpStack = UDPDirectStack()
            interface.registerStack(udpStack)

            let tcpStack = TCPStack.stack
            interface.registerStack(tcpStack)
        }

        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                DDLogError("Encountered an error setting up the network: \(error)")
                return
            }

            ProxyServer.mainProxy = GCDHTTPProxyServer(address: IPv4Address(fromString: "127.0.0.1"), port: Port(port: UInt16(self.proxyPort)))
            try! ProxyServer.mainProxy.start()

            completionHandler(nil)

            if self.enablePacketProcessing {
                self.interface.start()
            }
        }
    }

    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        completionHandler()
    }
}
