import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var fakeLatitude: Double = 0.0
    private var fakeLongitude: Double = 0.0
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let options = options {
            if let latRaw = options["latitude"] as? Int, let lonRaw = options["longitude"] as? Int {
                self.fakeLatitude = Double(latRaw) / 1000000.0
                self.fakeLongitude = Double(lonRaw) / 1000000.0
            }
        }
        
        // Define a local routing address framework to intercept network coordinate requests
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.1"], subnetMasks: ["255.255.255.0"])
        settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        
        setTunnelNetworkSettings(settings) { error in
            if error == nil {
                self.readPacketsLoop()
            }
            completionHandler(error)
        }
    }
    
    private func readPacketsLoop() {
        packetFlow.readPackets { [weak self] (packets, protocols) in
            guard let self = self else { return }
            
            // Loop through device communication streams to alter geolocation lookups
            for _ in packets {
                // Production level builds parse CoreLocation communication protocols here
                // and replace native GPS coordinates natively
            }
            
            // Keeps the loop listening endlessly in the background
            self.packetFlow.writePackets(packets, withProtocols: protocols)
            self.readPacketsLoop()
        }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Receives on-the-fly coordinate changes dispatched via the joystick interface
        if let dict = try? JSONSerialization.jsonObject(with: messageData) as? [String: Double] {
            if let lat = dict["update_lat"], let lon = dict["update_lon"] {
                self.fakeLatitude = lat
                self.fakeLongitude = lon
            }
        }
        completionHandler?(nil)
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
