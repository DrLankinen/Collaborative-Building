//
//  ContentView.swift
//  Collaborative Building
//
//  Created by Elias Lankinen on 11/22/20.
//

import SwiftUI
import RealityKit

let boxSize: Float = 0.05

struct ContentView : View {
    @State var text: String = ""
    
    var body: some View {
        ZStack {
            ARViewContainer(text: $text).edgesIgnoringSafeArea(.all)
            Text(text).background(Color.blue)
        }
    }
}

let gold = SimpleMaterial(color: .yellow, isMetallic: true)
// Align cubes
let minecraftMode: Bool = true

struct ARViewContainer: UIViewRepresentable {
    let origin = AnchorEntity(world: [0,0,0])
    @Binding var text: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        origin.addChild(sphere)
        arView.scene.addAnchor(origin)
        
        arView.setupGestures()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
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
        let box = ModelEntity(mesh: .generateBox(size: boxSize), materials: [gold])
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
