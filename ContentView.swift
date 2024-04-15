//
//  ContentView.swift
//  MLPractice
//
//  Created by CEDAM21 on 09/04/24.
//

import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: PhotosPickerItem?
    @State private var image: Image?
    @State private var detectedText: String = ""
    @State private var detectedFace: String = ""
    
    var body: some View {
            VStack {
                image?
                    .resizable()
                    .scaledToFit()

                if !detectedText.isEmpty {
                    Text(detectedText)
                }
                if !detectedFace.isEmpty {
                    Text(detectedFace)
                }
                
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Image(systemName: "photo.stack")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .onChange(of: selectedImage) {
                Task{
                    if let imageData = try? await selectedImage?.loadTransferable(type: Data.self){
                        if let uiImage = UIImage(data: imageData){
                            self.image = Image(uiImage: uiImage)
                            processSecondImage(imageData: imageData)
                        } else {
                            print("Couldn't load image data")
                        }
                    } else {
                        print("Failed to load image")
                    }
                }
            }
        }
    
//    Text Recognition
    func processImage(imageData: Data){
        
        guard let cgImage = UIImage(data: imageData)?.cgImage else {return}
        
//        1. Request
        let request = VNRecognizeTextRequest { (request, error) in
//            3. Result / Observation
            guard let observation = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Failed text recognition")
                return
            }
            
            self.detectedText = observation.compactMap { $0.topCandidates(1).first?.string }.joined(separator: ", ")
        }
        
//        2. Handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        2.1 Perform
        do {
            try handler.perform([request])
        } catch
        {
            print("Failed to perform text detection: \(error)")
        }
    }
    
    func proccesFaceinImage(imageData: Data){
        
        guard let cgImage = UIImage(data: imageData)?.cgImage else {return}
        
//        1. Request
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            //            3. Result / Observation
            guard let observations = request.results as? [VNFaceObservation], error == nil else {
                print("Failed face recognition")
                return
            }
            
            // Iterar sobre cada observación para acceder a los valores
             for observation in observations {
                 // Acceder al rectángulo que delimita la cara detectada
                 let boundingBox = observation.boundingBox
                 
                 // Acceder a los puntos característicos (landmarks) de la cara detectada si es necesario
                 if let landmarks = observation.landmarks {
                     // Por ejemplo, puedes acceder a los puntos característicos de la cara, ojos, boca, etc.
                     if let leftEye = landmarks.leftEye {
                         // Hacer algo con el punto característico del ojo izquierdo
                     }
                     if let rightEye = landmarks.rightEye {
                         // Hacer algo con el punto característico del ojo derecho
                     }
                     // Puedes acceder a otros landmarks de manera similar
                 }
                 self.detectedFace = boundingBoxAsText(boundingBox: boundingBox, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
             }
        }
        
//        2. Handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        2.1 Perform
        do {
            try handler.perform([request])
        } catch
        {
            print("Failed to perform face detection: \(error)")
        }
    }
    
    func processSecondImage(imageData: Data) {
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            self.detectedFace = "Error al convertir la imagen"
            return
        }
        
        // 1. Request
        let request = VNDetectHumanHandPoseRequest { (request, error) in
            // 3. Resultado / Observación
            guard let observations = request.results as? [VNHumanHandPoseObservation], error == nil else {
                // Error en el procesamiento de la imagen
                self.detectedFace = "Error en el procesamiento"
                return
            }
            
            var thumbTipString = ""
            
            // 5. Procesa las observaciones para extraer información de la pose de la mano
            for observation in observations {
                // Aquí puedes acceder a diferentes partes de la mano y sus poses
                // Por ejemplo, puedes obtener la posición de la punta del dedo índice
                if let thumbTip = try? observation.recognizedPoint(.thumbTip) {
                    thumbTipString = "Posición de la punta del dedo pulgar: (\(thumbTip.x), \(thumbTip.y))"
                    break // Sal del bucle una vez que encuentres la posición de la punta del dedo pulgar
                }
            }
            
            // Asigna la cadena a detectedFace fuera del bucle
            if thumbTipString.isEmpty {
                self.detectedFace = "No se detectó la mano"
            } else {
                self.detectedFace = thumbTipString
            }
        }
        
        // 2. Handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 2.1 - Perform
        do {
            try handler.perform([request])
        } catch {
            self.detectedFace = "Error al detectar la mano"
        }
    }

    
    // Convertir el boundingBox en texto
    func boundingBoxAsText(boundingBox: CGRect, imageSize: CGSize) -> String {
        // Normalizar las coordenadas del boundingBox respecto al tamaño de la imagen
        let normalizedRect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
        
        // Crear una cadena formateada con las coordenadas del boundingBox
        let text = String(format: "X: %.2f, Y: %.2f, Width: %.2f, Height: %.2f",
                          normalizedRect.origin.x,
                          normalizedRect.origin.y,
                          normalizedRect.size.width,
                          normalizedRect.size.height)
        
        return text
    }

}

#Preview {
    ContentView()
}
