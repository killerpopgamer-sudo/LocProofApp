import Foundation
import NetworkExtension

class VPNManager {
    static let shared = VPNManager()
    private var providerManager: NETunnelProviderManager?
    
    init() {
        loadProviderManager { _ in }
    }
    
    private func loadProviderManager(completion: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let managers = managers, !managers.isEmpty {
                self.providerManager = managers.first
                completion(managers.first)
            } else {
                let newManager = NETunnelProviderManager()
                newManager.protocolConfiguration = NETunnelProviderProtocol()
                newManager.localizedDescription = "LocProof Core Tunnel"
                newManager.saveToPreferences { error in
                    self.providerManager = newManager
                    completion(newManager)
                }
            }
        }
    }
    
    func startTunnel(lat: Double, lon: Double) {
        loadProviderManager { manager in
            guard let manager = manager else { return }
            
            let options: [String: NSObject] = [
                "latitude": lround(lat * 1000000) as NSObject,
                "longitude": lround(lon * 1000000) as NSObject
            ]
            
            manager.isEnabled = true
            manager.saveToPreferences { _ in
                do {
                    try manager.connection.startVPNTunnel(options: options)
                } catch {
                    print("Tunnel Failed to initialize: \(error)")
                }
            }
        }
    }
    
    func updateCoordinates(lat: Double, lon: Double) {
        guard let connection = providerManager?.connection, connection.status == .connected else { return }
        let message = ["update_lat": lat, "update_lon": lon]
        if let session = connection as? NETunnelProviderSession {
            // Sends the packet information straight to the underlying PacketTunnel extension target
            try? session.sendProviderMessage(Data(JSONEncoder().encode(message))) { _ in }
        }
    }
    
    func stopTunnel() {
        providerManager?.connection.stopVPNTunnel()
    }
}
