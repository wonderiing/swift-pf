//
//  ARVIEW.swift
//  proyecto-final
//
//  Created by Alumno on 11/09/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedModel: String?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: CGRect.zero)
        
        // Configurar la sesión AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
        // Para simulador: configurar fondo y crear objeto por defecto
        #if targetEnvironment(simulator)
        // Configurar fondo negro para simulador
        arView.environment.background = .color(.black)
        context.coordinator.createDefaultObject()
        #endif
        
        // Configurar el contexto
        context.coordinator.arView = arView
        
        // Agregar gestos táctiles para mover objetos
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Actualizar cuando cambie el modelo seleccionado
        if let modelName = selectedModel {
            context.coordinator.loadModel(named: modelName)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var arView: ARView?
        var currentAnchor: AnchorEntity?
        var selectedEntity: ModelEntity?
        var lastPanLocation: CGPoint = .zero
        
        func createDefaultObject() {
            guard let arView = arView else { return }
            
            // Crear un anchor en el suelo (sin depender de detección de planos)
            let anchor = AnchorEntity()
            
            // Crear un cubo de ejemplo más pequeño y proporcionado
            let box = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
            let modelEntity = ModelEntity(mesh: box, materials: [material])
            
            // Escalar el objeto para que sea más pequeño
            modelEntity.scale = [1.0, 1.0, 1.0]
            
            // Posicionar el objeto en el suelo
            modelEntity.position = [0, -0.5, -1.0]
            
            // Agregar rotación automática para que sea más interesante
            let rotationAnimation = FromToByAnimation<Transform>(
                name: "rotation",
                from: Transform(scale: [1, 1, 1], rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), translation: [0, -0.5, -1.0]),
                to: Transform(scale: [1, 1, 1], rotation: simd_quatf(angle: .pi * 2, axis: [0, 1, 0]), translation: [0, -0.5, -1.0]),
                duration: 4.0,
                timing: .linear,
                isAdditive: false,
                bindTarget: .transform
            )
            
            let animationResource = try! AnimationResource.generate(with: rotationAnimation)
            modelEntity.playAnimation(animationResource.repeat())
            
            anchor.addChild(modelEntity)
            currentAnchor = anchor
            arView.scene.addAnchor(anchor)
        }
        
        func loadModel(named modelName: String) {
            guard let arView = arView else { return }
            
            // Remover el anchor anterior si existe
            if let currentAnchor = currentAnchor {
                arView.scene.removeAnchor(currentAnchor)
            }
            
            // Crear un anchor en el centro de la pantalla
            let anchor = AnchorEntity()
            
            // Cargar el modelo USDZ
            if let modelEntity = try? ModelEntity.loadModel(named: modelName) {
                // Configurar escala específica para cada modelo
                let scale: SIMD3<Float>
                let position: SIMD3<Float>
                
                #if targetEnvironment(simulator)
                // Escalas y posiciones para simulador (en el suelo)
                switch modelName {
                case "robot":
                    scale = [0.08, 0.08, 0.08]
                    position = [0, -0.5, -1.0]
                case "toy_car":
                    scale = [0.12, 0.12, 0.12]
                    position = [0, -0.5, -1.0]
                case "pancakes_photogrammetry":
                    scale = [0.15, 0.15, 0.15]
                    position = [0, -0.5, -1.0]
                default:
                    scale = [0.1, 0.1, 0.1]
                    position = [0, -0.5, -1.0]
                }
                #else
                // Escalas y posiciones para dispositivo real
                switch modelName {
                case "robot":
                    scale = [0.05, 0.05, 0.05]
                    position = [0, -0.3, -0.5]
                case "toy_car":
                    scale = [0.08, 0.08, 0.08]
                    position = [0, -0.3, -0.5]
                case "pancakes_photogrammetry":
                    scale = [0.1, 0.1, 0.1]
                    position = [0, -0.3, -0.5]
                default:
                    scale = [0.05, 0.05, 0.05]
                    position = [0, -0.3, -0.5]
                }
                #endif
                
                modelEntity.scale = scale
                modelEntity.position = position
                
                // Agregar el modelo al anchor
                anchor.addChild(modelEntity)
                currentAnchor = anchor
                
                // Agregar el anchor a la escena
                arView.scene.addAnchor(anchor)
                
                print("✅ Modelo cargado: \(modelName) con escala \(scale)")
            } else {
                print("❌ No se pudo cargar el modelo: \(modelName)")
                // Si no se puede cargar el modelo, crear un cubo de ejemplo más grande
                let box = MeshResource.generateBox(size: 0.3)
                let material = SimpleMaterial(color: .systemGreen, isMetallic: false)
                let modelEntity = ModelEntity(mesh: box, materials: [material])
                
                #if targetEnvironment(simulator)
                modelEntity.scale = [1.0, 1.0, 1.0]
                modelEntity.position = [0, 0, -0.8]
                #else
                modelEntity.position = [0, 0, -0.5]
                #endif
                
                anchor.addChild(modelEntity)
                currentAnchor = anchor
                
                arView.scene.addAnchor(anchor)
            }
        }
        
        // MARK: - Gestos táctiles
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            // Buscar entidad tocada
            if let entity = arView.entity(at: location) as? ModelEntity {
                selectedEntity = entity
                print("✅ Objeto seleccionado: \(entity.name)")
            } else {
                // Si no se toca un objeto, deseleccionar
                selectedEntity = nil
                print("❌ Objeto deseleccionado")
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView, let selectedEntity = selectedEntity else { return }
            
            let location = gesture.location(in: arView)
            
            switch gesture.state {
            case .began:
                lastPanLocation = location
            case .changed:
                let deltaX = Float(location.x - lastPanLocation.x) * 0.002
                let deltaZ = Float(location.y - lastPanLocation.y) * 0.002 // Usar Y para Z
                
                // Mover el objeto en el plano horizontal (X y Z)
                let currentPosition = selectedEntity.position
                selectedEntity.position = [
                    currentPosition.x + deltaX,
                    currentPosition.y, // Mantener Y fijo (altura del suelo)
                    currentPosition.z + deltaZ
                ]
                
                lastPanLocation = location
            case .ended:
                break
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let selectedEntity = selectedEntity else { return }
            
            if gesture.state == .changed {
                let scale = Float(gesture.scale)
                let currentScale = selectedEntity.scale
                selectedEntity.scale = [
                    currentScale.x * scale,
                    currentScale.y * scale,
                    currentScale.z * scale
                ]
                gesture.scale = 1.0
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let selectedEntity = selectedEntity else { return }
            
            if gesture.state == .changed {
                let rotation = Float(gesture.rotation)
                let currentRotation = selectedEntity.orientation
                let newRotation = simd_quatf(angle: rotation, axis: [0, 1, 0])
                selectedEntity.orientation = currentRotation * newRotation
                gesture.rotation = 0
            }
        }
    }
}

struct ARViewSwiftUI: View {
    @State private var selectedModel: String? = nil
    @State private var showingModelPicker = false
    
    let availableModels = [
        "robot",
        "toy_car", 
        "pancakes_photogrammetry"
    ]
    
    var body: some View {
        ZStack {
            // Vista AR
            ARViewContainer(selectedModel: $selectedModel)
                .ignoresSafeArea()
            
            // Controles superiores
            VStack {
                HStack {
                    Button("Modelos") {
                        showingModelPicker = true
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button("Limpiar") {
                        selectedModel = nil
                    }
                    .padding()
                    .background(Color.red.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                // Instrucciones
                VStack(spacing: 8) {
                    #if targetEnvironment(simulator)
                    Text("Modo Simulador - Objeto 3D visible")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    #else
                    Text("Apunta la cámara a una superficie plana")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    #endif
                    
                    Text("Toca 'Modelos' para seleccionar un objeto 3D")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    Text("Toca para seleccionar • Arrastra para mover • Pellizca para escalar • Rota con dos dedos")
                        .foregroundColor(.white)
                        .font(.caption2)
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView(selectedModel: $selectedModel, availableModels: availableModels)
        }
    }
}

struct ModelPickerView: View {
    @Binding var selectedModel: String?
    let availableModels: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(availableModels, id: \.self) { model in
                Button(action: {
                    selectedModel = model
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "cube.box")
                            .foregroundColor(.blue)
                        Text(model)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Seleccionar Modelo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ARViewSwiftUI()
}
