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
//    let origin = AnchorEntity(plane: .horizontal)
    let origin = AnchorEntity(world: [0,0,0])
    @Binding var text: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        origin.addChild(sphere)
        arView.scene.addAnchor(origin)
        
        arView.setupGestures()
//        let entity = ModelEntity(mesh: .generateBox(size: 0.1), materials: [gold])
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(entity)
//        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

enum Side {
    case up
    case left
    case front
    case right
    case back
}

extension ARView {
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: self)
        guard let rayResult = self.ray(through: tapLocation) else { return }
        
        let results = self.scene.raycast(origin: rayResult.origin, direction: rayResult.direction)
        let origin = self.scene.anchors.first
        let originPosition = origin?.position
        
        print("origin position: \(originPosition)")
        
        if let firstResult = results.first {
            var touchPosition = firstResult.position
            let touchedEntityTranslation = firstResult.entity.transform.translation
            print("touch position: \(touchPosition)")
            print("number of anchors: \(self.scene.anchors.count)")
            print("touched entity position: \(touchedEntityTranslation)")
            
            var side: Side? = nil
            let epsilon: Float = 0.01
            let boxUp = touchedEntityTranslation.y + (boxSize/2) - epsilon
            if boxUp < touchPosition.y {
                side = .up
            } else {
                let boxFront = touchedEntityTranslation.z + (boxSize/2) - epsilon
                let boxBack = touchedEntityTranslation.z - (boxSize/2) + epsilon
                let boxLeft = touchedEntityTranslation.x + (boxSize/2) - epsilon
                let boxRight = touchedEntityTranslation.x - (boxSize/2) + epsilon
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
            
            switch side {
            case .up:
                print("up")
                touchPosition.y += boxSize/2
                if minecraftMode {
                    touchPosition.x = touchedEntityTranslation.x
                    touchPosition.z = touchedEntityTranslation.z
                }
                break
            case .front:
                print("front")
                touchPosition.z += boxSize/2
                if minecraftMode {
                    touchPosition.x = touchedEntityTranslation.x
                    touchPosition.y = touchedEntityTranslation.y
                }
                break
            case .back:
                print("back")
                touchPosition.z -= boxSize/2
                if minecraftMode {
                    touchPosition.x = touchedEntityTranslation.x
                    touchPosition.y = touchedEntityTranslation.y
                }
                break
            case .left:
                print("left")
                touchPosition.x -= boxSize/2
                if minecraftMode {
                    touchPosition.y = touchedEntityTranslation.y
                    touchPosition.z = touchedEntityTranslation.z
                }
                break
            case .right:
                print("right")
                touchPosition.x += boxSize/2
                if minecraftMode {
                    touchPosition.y = touchedEntityTranslation.y
                    touchPosition.z = touchedEntityTranslation.z
                }
                break
            default:
                print("nothing")
                touchPosition.y += boxSize/2
                if minecraftMode {
                    touchPosition.x = touchedEntityTranslation.x
                    touchPosition.z = touchedEntityTranslation.z
                }
                break
            }
            print()
            
            placeCube(at: touchPosition)
        } else {
            let results = self.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
            
            if let firstResult = results.first {
                let touchPositionInSurface = simd_make_float3(firstResult.worldTransform.columns.3)
                print("position: \(touchPositionInSurface)")
                print()
                placeCube(at: touchPositionInSurface)
            }
        }
    }
    
    func placeCube(at position: SIMD3<Float>) {
        let origin = self.scene.anchors.first
        let box = ModelEntity(mesh: .generateBox(size: boxSize), materials: [gold])
//        box.components.set(CollisionComponent(
//            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
//            mode: .default,
//            filter: .default
//        ))
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
