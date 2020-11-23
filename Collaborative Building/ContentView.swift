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
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

let gold = SimpleMaterial(color: .yellow, isMetallic: true)

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.debugOptions = [.showStatistics, .showFeaturePoints]
        
        arView.setupGestures()
//        let entity = ModelEntity(mesh: .generateBox(size: 0.1), materials: [gold])
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(entity)
//        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
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
        if let firstResult = results.first {
            var position = firstResult.position
            print("position: \(position)")
            position.y += boxSize/2
            placeCube(at: position)
        } else {
            let results = self.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
            if let firstResult = results.first {
                let position = simd_make_float3(firstResult.worldTransform.columns.3)
                placeCube(at: position)
            }
        }
    }
    
    func placeCube(at position: SIMD3<Float>) {
        let box = ModelEntity(mesh: .generateBox(size: boxSize), materials: [gold])
//        box.components.set(CollisionComponent(
//            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
//            mode: .default,
//            filter: .default
//        ))
        box.generateCollisionShapes(recursive: true)
        let anchor = AnchorEntity(world: position)
        anchor.addChild(box)
        self.scene.addAnchor(anchor)
    }
}
