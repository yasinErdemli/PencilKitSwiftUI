//
//  ContentView.swift
//  PencilKitSwiftUI
//
//  Created by Yasin Erdemli on 20.09.2023.
//

import SwiftUI
import PencilKit


struct PencilView: UIViewRepresentable {
    let size: CGSize
    @Binding var isToolPickerVisible: Bool
    @Binding var image: Image 
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        context.coordinator.canvas = canvas
        canvas.drawingPolicy = .anyInput
        canvas.contentSize = .init(width: size.width, height: size.height)
        
        if let url = context.coordinator.url(), let data = FileManager.default.contents(atPath: url.path()) {
            do {
                let drawing = try PKDrawing(data: data)
                context.coordinator.canvas.drawing = drawing
            } catch {
                print(error.localizedDescription)
            }
        }
        if context.coordinator.toolPicker == nil {
            let picker = PKToolPicker()
            picker.addObserver(canvas)
            context.coordinator.toolPicker = picker
        }
        canvas.becomeFirstResponder()
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if isToolPickerVisible == true {
            context.coordinator.toolPicker?.setVisible(true, forFirstResponder: context.coordinator.canvas)
        } else {
            context.coordinator.toolPicker?.setVisible(false, forFirstResponder: context.coordinator.canvas)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(size: size, image: $image)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var toolPicker: PKToolPicker?
        var canvas: PKCanvasView!
        let size: CGSize
        @Binding var image: Image
        init(size: CGSize, image: Binding<Image>) {
            self.size = size
            self._image = image
        }
        
        func url() -> URL?{
           if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
               url.appendPathComponent("drawing", conformingTo: .data)
                return url
           } else {
               return nil
           }
        }
        
        func url2() -> URL?{
           if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
               url.appendPathComponent("picture", conformingTo: .data)
                return url
           } else {
               return nil
           }
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            if let url = url() {
                do {
                    try data.write(to: url)
                } catch {
                    print(error.localizedDescription)
                }
            }
            let uiimageData = canvas.drawing.image(from: canvasView.bounds, scale: 1).jpegData(compressionQuality: 0.6)
            if let url = url2(), let data = uiimageData {
                do {
                    try data.write(to: url)
                } catch {
                    print(error)
                }
            }
            
            if let data = uiimageData, let uiimage = UIImage(data: data)  {
                self.image = Image(uiImage: uiimage)
            }
            
        }
        
        func getImage() -> Image {
            guard let uiimageData = canvas.drawing.image(from: canvas.bounds, scale: 1).jpegData(compressionQuality: 0.6), let uiimage = UIImage(data: uiimageData) else {
                return .init(systemName: "xmark")
            }
            return .init(uiImage: uiimage)
        }
    }
        
}

struct ContentView: View {
    @State private var isToolPickerVisible: Bool = false
    @State private var image = Image(systemName: "checkmark")
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                PencilView(size: .init(width: geometry.size.width, height: geometry.size.height), isToolPickerVisible: $isToolPickerVisible, image: $image)
                    .position(.init(x: geometry.size.width / 2, y: geometry.size.height / 2))
            })
            .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            HStack(content: {
                Button("Tools") {
                    self.isToolPickerVisible.toggle()
                }
                .padding()
                
                ShareLink(item: image, preview: .init("image", icon: image))
            })
            
        }
    }
    func url() -> URL?{
        if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            url.appendPathComponent("drawing", conformingTo: .data)
            return url
        } else {
            return nil
        }
    }
    
    func url2() -> URL?{
       if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
           url.appendPathComponent("picture", conformingTo: .data)
            return url
       } else {
           return nil
       }
    }
    
    
    func getImage() throws -> Image {
        guard let url = url2(), let data = FileManager.default.contents(atPath: url.path()) else  {
            throw URLError(.badURL)
        }
        print(url)
        print(data)
        let uiimage = UIImage(data: data)!
        let image = Image(uiImage: uiimage)
        return image
    }
}

#Preview {
    ContentView()
}


