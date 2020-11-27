//
//  ContentView.swift
//  Collaborative Building
//
//  Created by Elias Lankinen on 11/22/20.
//

import SwiftUI
import RealityKit
import ARKit
import MultipeerConnectivity

let boxSize: Float = 0.05
let colors: [Color] = [.black,.green,.orange,.pink,.red,.yellow]

var selectedColor: Color = Color.white

struct ContentView : View {
    @State var selected: Int = 0
    
    var body: some View {
        ZStack {
            ARViewContainer(entityColor: colors[selected]).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<colors.count) { index in
                            Button(action: {
                                selected = index
                                selectedColor = colors[selected]
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(colors[index])
                                        .frame(width: 50, height: 50)
                                    if selected == index {
                                        Image(systemName: "checkmark").foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }
                .background(Color.blue)
                .padding(.bottom)
            }
        }
    }
}

// Align cubes
let minecraftMode: Bool = true

var multipeerSession: MultipeerSession?
// A dictionary to map MultiPeer IDs to ARSession ID's.
// This is useful for keeping track of which peer created which ARAnchors.
var peerSessionIDs = [MCPeerID: String]()

struct ARViewContainer: UIViewRepresentable {
    var entityColor: Color
    let origin = AnchorEntity(world: [0,0,0])
    let arView = ARView(frame: .zero)
    
    class Coordinator: NSObject, ARSessionDelegate {
        /// - Tag: DidOutputCollaborationData
        func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
            print("ELIAS ELIAS")
            guard let multipeerSession = multipeerSession else { return }
            if !multipeerSession.connectedPeers.isEmpty {
                guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
                else { fatalError("Unexpectedly failed to encode collaboration data.") }
                // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
                let dataIsCritical = data.priority == .critical
                multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
            } else {
                print("Deferred sending collaboration to later because there are no peers.")
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("LANKINEN LANKINEN")
            guard error is ARError else { return }
            
            let errorWithInfo = error as NSError
            let messages = [
                errorWithInfo.localizedDescription,
                errorWithInfo.localizedFailureReason,
                errorWithInfo.localizedRecoverySuggestion
            ]
            
            // Remove optional error messages.
            let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
            
            DispatchQueue.main.async {
                // Present the error that occurred.
                let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
                let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                    alertController.dismiss(animated: true, completion: nil)
//                    self.resetTracking()
                }
                alertController.addAction(restartAction)
//                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        arView.scene.addAnchor(origin)
        arView.session.delegate = context.coordinator
        
        arView.setupGestures()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        
        // Start looking for other players via MultiPeerConnectivity.
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData, peerJoinedHandler:
                                            peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)
        print("hello")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}

    func receivedData(_ data: Data, from peer: MCPeerID) {
        print("RECIEVE DATA")
//        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
//            arView.session.update(with: collaborationData)
//            return
//        }
//        let sessionIDCommandString = "SessionID:"
//        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString) {
//            let newSessionID = String(commandString[commandString.index(commandString.startIndex,
//                                                                     offsetBy: sessionIDCommandString.count)...])
//            // If this peer was using a different session ID before, remove all its associated anchors.
//            // This will remove the old participant anchor and its geometry from the scene.
//            if let oldSessionID = peerSessionIDs[peer] {
//                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
//            }
//
//            peerSessionIDs[peer] = newSessionID
//        }
    }
    
    func peerDiscovered(_ peer: MCPeerID) -> Bool {
        print("PEER DISCOVERED")
        guard let multipeerSession = multipeerSession else { return false }
        
        if multipeerSession.connectedPeers.count > 3 {
            return false
        } else {
            return true
        }
    }
    
    /// - Tag: PeerJoined
    func peerJoined(_ peer: MCPeerID) {
        print("PEER JOINED")
//        messageLabel.displayMessage("""
//            A peer wants to join the experience.
//            Hold the phones next to each other.
//            """, duration: 6.0)
        // Provide your session ID to the new user so they can keep track of your anchors.
//        sendARSessionIDTo(peers: [peer])
    }
        
    func peerLeft(_ peer: MCPeerID) {
        print("PEER LEFT")
//        messageLabel.displayMessage("A peer has left the shared experience.")

        // Remove all ARAnchors associated with the peer that just left the experience.
//        if let sessionID = peerSessionIDs[peer] {
//            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
//            peerSessionIDs.removeValue(forKey: peer)
//        }
    }
    
    func resetTracking() {
        print("reset tracking")
//        guard let configuration = arView.session.configuration else { print("A configuration is required"); return }
//        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        print("remove all anchors originating from ar session with id")
//        guard let frame = arView.session.currentFrame else { return }
//        for anchor in frame.anchors {
//            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
//            if anchorSessionID.uuidString == identifier {
//                arView.session.remove(anchor: anchor)
//            }
//        }
    }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        print("send ar session id to")
//        guard let multipeerSession = multipeerSession else { return }
//        let idString = arView.session.identifier.uuidString
//        let command = "SessionID:" + idString
//        if let commandData = command.data(using: .utf8) {
//            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
//        }
    }
}

extension ARView {
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(recognizer:)))
        self.addGestureRecognizer(tap)
        self.addGestureRecognizer(longTap)
    }
    
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let pressLocation = recognizer.location(in: self)
        print("longpress")
        let state = recognizer.state.rawValue
        print("state: \(state)")
        if let entity = self.entity(at: pressLocation), state == 1 {
            print("enitty: \(entity)")
            entity.removeFromParent()
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: self)
        guard let rayResult = self.ray(through: tapLocation) else { return }
        
        let results = self.scene.raycast(origin: rayResult.origin, direction: rayResult.direction)
        
        if let firstResult = results.first {
            var touchPosition = firstResult.position
            let touchedEntityPosition = firstResult.entity.transform.translation
            print("touch position: \(touchPosition)")
            print("number of anchors: \(self.scene.anchors.count)")
            print("touched entity position: \(touchedEntityPosition)")
            
            let side: Side? = recognizeSide(touchedEntityPosition: touchedEntityPosition, touchPosition: touchPosition)
            setPositionToMiddle(side: side, touchedEntityPosition: touchedEntityPosition, touchPosition: &touchPosition)
            print()
            
            placeCube(at: touchPosition)
        } else {
            let results = self.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
            if let firstResult = results.first {
                let touchPositionInSurface = simd_make_float3(firstResult.worldTransform.columns.3)
                placeCube(at: touchPositionInSurface)
            } else {
                print("couldn't find a surface")
            }
        }
    }
}

extension ARView {
    func recognizeSide(touchedEntityPosition: SIMD3<Float>, touchPosition: SIMD3<Float>) -> Side? {
        var side: Side? = nil
        let epsilon: Float = 0.01
        let boxUp = touchedEntityPosition.y + (boxSize/2) - epsilon
        if boxUp < touchPosition.y {
            side = .up
        } else {
            let boxFront = touchedEntityPosition.z + (boxSize/2) - epsilon
            let boxBack = touchedEntityPosition.z - (boxSize/2) + epsilon
            let boxLeft = touchedEntityPosition.x + (boxSize/2) - epsilon
            let boxRight = touchedEntityPosition.x - (boxSize/2) + epsilon
            if boxFront < touchPosition.z {
                side = .front
            } else if boxBack > touchPosition.z {
                side = .back
            } else {
                if boxLeft > touchPosition.x {
                    side = .left
                } else if boxRight < touchPosition.x {
                    side = .right
                }
            }
        }
        return side
    }
    
    func setPositionToMiddle (side: Side?, touchedEntityPosition: SIMD3<Float>, touchPosition: inout SIMD3<Float>) {
        switch side {
        case .up:
            print("up")
            touchPosition.y += boxSize/2
            if minecraftMode {
                touchPosition.x = touchedEntityPosition.x
                touchPosition.z = touchedEntityPosition.z
            }
            break
        case .front:
            print("front")
            touchPosition.z += boxSize/2
            if minecraftMode {
                touchPosition.x = touchedEntityPosition.x
                touchPosition.y = touchedEntityPosition.y
            }
            break
        case .back:
            print("back")
            touchPosition.z -= boxSize/2
            if minecraftMode {
                touchPosition.x = touchedEntityPosition.x
                touchPosition.y = touchedEntityPosition.y
            }
            break
        case .left:
            print("left")
            touchPosition.x -= boxSize/2
            if minecraftMode {
                touchPosition.y = touchedEntityPosition.y
                touchPosition.z = touchedEntityPosition.z
            }
            break
        case .right:
            print("right")
            touchPosition.x += boxSize/2
            if minecraftMode {
                touchPosition.y = touchedEntityPosition.y
                touchPosition.z = touchedEntityPosition.z
            }
            break
        default:
            print("nothing")
            touchPosition.y += boxSize/2
            if minecraftMode {
                touchPosition.x = touchedEntityPosition.x
                touchPosition.z = touchedEntityPosition.z
            }
            break
        }
    }
    
    func placeCube(at position: SIMD3<Float>) {
        let origin = self.scene.anchors.first
        let c: UIColor = UIColor(selectedColor)
        let box = ModelEntity(mesh: .generateBox(size: boxSize), materials: [SimpleMaterial(color: c, isMetallic: false)])
        box.generateCollisionShapes(recursive: true)
        if minecraftMode {
            box.position.x = position.x
            box.position.y = position.y
            box.position.z = position.z
            origin?.addChild(box)
        } else {
            let anchor = AnchorEntity(world: position)
            anchor.addChild(box)
            self.scene.addAnchor(anchor)
        }
    }
}
