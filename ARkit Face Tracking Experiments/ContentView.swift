//
//  ContentView.swift
//  Image Detection
//
//  Created by Егор Пехота on 10.06.2021.
//

import SwiftUI
import RealityKit
import ARKit

var scarecrow: HeadOrbit.Scarecrow!
var arView: ARView!

struct ContentView : View {
    @State var propId: Int = 1

    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(propId: $propId).edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    self.propId = self.propId <= 0 ? 0 : self.propId - 1
                }) {
                    Image(systemName: "arrow.backward.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding([.horizontal])
                }
                Button(action: {
                    takeSnapshot()
                }) {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding([.horizontal])
                }
                Button(action: {
                    self.propId = self.propId >= 1 ? 1 : self.propId + 1
                }) {
                    Image(systemName: "arrow.forward.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding([.horizontal])
                }
            }
        }
    }
    
    func takeSnapshot() {
        arView.snapshot(saveToHDR: false) { image in
            let compressedImage = UIImage(
                data: (image?.pngData())!
            )
            UIImageWriteToSavedPhotosAlbum(compressedImage!, nil, nil, nil)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var propId: Int
    
    func makeUIView(context: Context) -> ARView {
        arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        scarecrow = nil
        arView.scene.anchors.removeAll()
        
        let arConfiguration = ARFaceTrackingConfiguration()
        uiView.session.run(arConfiguration, options: [.resetTracking,.removeExistingAnchors])
        
        switch(propId) {
        case 0:
            let arAnchor = try! HeadOrbit.loadOrbitingBall()
            uiView.scene.anchors.append(arAnchor)
            break
            
        case 1:
            let arAnchor = try! HeadOrbit.loadScarecrow()
            uiView.scene.anchors.append(arAnchor)
            scarecrow = arAnchor
            break
          
        default:
            break
        }
    }
    
    func makeCoordinator() -> ARDelegateHandler {
        ARDelegateHandler(self)
    }
    
    class ARDelegateHandler: NSObject, ARSessionDelegate {
        
        var arViewContainer: ARViewContainer

        init(_ control: ARViewContainer) {
            arViewContainer = control
            super.init()
        }
        
        func Deg2Rad(_ value: Float) -> Float {
            return value * .pi / 180
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard scarecrow != nil else {
                return
            }
            
            var faceAnchor: ARFaceAnchor?
            for anchor in anchors {
                if let a = anchor as? ARFaceAnchor {
                    faceAnchor = a
                }
            }
            
            let blendShapes = faceAnchor?.blendShapes
            let eyeBlinkLeft = blendShapes?[.eyeBlinkLeft]?.floatValue
            let eyeBlinkRight = blendShapes?[.eyeBlinkRight]?.floatValue
            
            let browInnerUp = blendShapes?[.browInnerUp]?.floatValue
            let browLeft = blendShapes?[.browDownLeft]?.floatValue
            let browRight = blendShapes?[.browDownRight]?.floatValue
            
            let jawOpen = blendShapes?[.jawOpen]?.floatValue

            scarecrow.leftEye?.orientation = simd_quatf(
                angle: Deg2Rad(-120 + (90 * eyeBlinkLeft!)),
                axis: [0, 0, 1]
            )

            scarecrow.rightEye?.orientation = simd_quatf(
                angle: Deg2Rad(-120 + (90 * eyeBlinkRight!)),
                axis: [0, 0, 1]
            )

            scarecrow.leftEyebrow?.orientation = simd_quatf(
                angle: Deg2Rad((90 * browLeft!) - (30 * browInnerUp!)),
                axis: [0, 1, 0]
            )

            scarecrow.rightEyebrow?.orientation = simd_quatf(
                angle: Deg2Rad((90 * browRight!) - (30 * browInnerUp!)),
                axis: [0, 1, 0]
            )

            scarecrow.mouth?.orientation = simd_quatf(
              angle: Deg2Rad(-100 + (60 * jawOpen!)),
              axis: [0, 1, 0]
            )
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
