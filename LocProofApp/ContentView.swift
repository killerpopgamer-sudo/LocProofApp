import SwiftUI
import MapKit
import NetworkExtension

struct ContentView: View {
    // Default map position centered on a fallback location
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @State private var targetCoordinate = CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673)
    @State private var isSpoofing = false
    @State private var movementSpeed: Double = 5.0 // km/h
    @State private var joystickOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Full-Screen Interactive Map
            Map(position: $position) {
                Marker("Target Location", coordinate: targetCoordinate)
                    .tint(.blue)
            }
            .onMapCameraChange { context in
                // Updates target pin as the user drags the map
                targetCoordinate = context.region.center
            }
            .ignoresSafeArea()
            
            // Top Control Overlay: Speed and Mode
            VStack {
                VStack(spacing: 10) {
                    Text("LocProof Controller")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Speed: \(Int(movementSpeed)) km/h")
                            .font(.subheadline)
                        Slider(value: $movementSpeed, in: 1...120)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding()
                
                Spacer()
                
                // Bottom Control Overlay: Teleport & Joystick
                HStack {
                    // Virtual Joystick Configuration
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(.blue)
                            .frame(width: 40, height: 40)
                            .offset(joystickOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let limit: CGFloat = 30
                                        let x = max(min(value.translation.width, limit), -limit)
                                        let y = max(min(value.translation.height, limit), -limit)
                                        self.joystickOffset = CGSize(width: x, height: y)
                                        self.updateLocationByJoystick(x: x, y: y)
                                    }
                                    .onEnded { _ in
                                        self.joystickOffset = .zero
                                    }
                            )
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Main Teleport Action Button
                    Button(action: {
                        self.toggleSpoofing()
                    }) {
                        HStack {
                            Image(systemName: isSpoofing ? "stop.fill" : "paperplane.fill")
                            Text(isSpoofing ? "Stop" : "Teleport")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(isSpoofing ? Color.red : Color.blue)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    func toggleSpoofing() {
        isSpoofing.toggle()
        if isSpoofing {
            VPNManager.shared.startTunnel(lat: targetCoordinate.latitude, lon: targetCoordinate.longitude)
        } else {
            VPNManager.shared.stopTunnel()
        }
    }
    
    func updateLocationByJoystick(x: CGFloat, y: CGFloat) {
        guard isSpoofing else { return }
        // Scale down joystick translations to shift lat/long coordinates slightly
        let latChange = Double(-y) * 0.00001 * (movementSpeed / 5.0)
        let lonChange = Double(x) * 0.00001 * (movementSpeed / 5.0)
        
        targetCoordinate.latitude += latChange
        targetCoordinate.longitude += lonChange
        
        // Update the active tunnel server configuration variables dynamically
        VPNManager.shared.updateCoordinates(lat: targetCoordinate.latitude, lon: targetCoordinate.longitude)
    }
}
