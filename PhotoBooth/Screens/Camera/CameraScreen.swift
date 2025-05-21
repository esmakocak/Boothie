//
//  CameraScreen.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 8.04.2025.
//

import SwiftUI
import AVFoundation

struct CameraScreen: View {
    
    @Binding var path: NavigationPath
    @StateObject private var viewModel: CameraViewModel
    @State private var showCameraAlert = false
    
    // DAHA SONRA SİL !
    private var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
    
    init(path: Binding<NavigationPath>) {
        self._path = path
        _viewModel = StateObject(wrappedValue: CameraViewModel(path: path))
    }

    var body: some View {
        ZStack {
            Color("bgColor")
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Üstteki "smile ..." yazısı
                HStack {
                    Text(" smile ...")
                        .font(.custom("SnellRoundhand", size: UIDevice.isPad ? 48 : 34))
                        .foregroundColor(.black)
                        .padding(.leading, 32)
                        .padding(.top, 32)
                    Spacer()
                    
                    // Flash Toggle Button
                    Button(action: {
                        viewModel.toggleTorch()
                    }) {
                        Image(systemName: viewModel.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: UIDevice.isPad ? 32 : 24))
                            .foregroundColor(viewModel.isFlashEnabled ? .yellow : Color("sugarPink"))
                            .padding(UIDevice.isPad ? 16 : 12)
                            .background(Color("lightPink"))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color("sugarPink"), lineWidth: 1)
                            )
                    }
                    .padding(.top, 32)
                    
                    // Camera Toggle Button
                    Button(action: {
                        viewModel.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: UIDevice.isPad ? 32 : 24))
                            .foregroundColor(Color("sugarPink"))
                            .padding(UIDevice.isPad ? 16 : 12)
                            .background(Color("lightPink"))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color("sugarPink"), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 32)
                    .padding(.top, 32)
                }
                .padding(.bottom, 50)

                // Kamera çerçevesi
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: UIDevice.isPad ? 480 : 340, height: UIDevice.isPad ? 480 : 340)                        .shadow(radius: 8)
                        .overlay(
                            
                            // DAHA SONRA SİL !
                            Group {
                                if isPreview {
                                    // PREVIEW'da sahte kamera
                                    CameraPreviewPlaceholder()
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    // GERÇEK kamera
                                    CameraPreviewView(session: viewModel.session)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }

                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.25), lineWidth: 6)
                                .blur(radius: 4)
                                .offset(x: 2, y: 2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        )
                        .offset(y: -60)

                    // Geri sayım rakamı (vintage style)
                    Text(viewModel.countdown > 0 ? "\(viewModel.countdown)" : " ")
                        .font(.system(size: UIDevice.isPad ? 128 : 96, weight: .semibold, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                        .kerning(2)
                        .scaleEffect(viewModel.countdown > 0 ? 1.0 : 0.85)
                        .opacity(viewModel.countdown > 0 && viewModel.isCapturing ? 1 : 0)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.countdown)
                        .offset(y: -60)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    

                    // Flash efekti
                    if viewModel.showFlash {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: UIDevice.isPad ? 480 : 340, height: UIDevice.isPad ? 480 : 340)                            .offset(y: -60)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.showFlash)
                    }
                }

                // Alt dot'lar (kaç foto çekildi)
                HStack(spacing: UIDevice.isPad ? 18 : 12) {
                    ForEach(1...viewModel.totalShots, id: \.self) { index in
                        Circle()
                            .fill(index <= viewModel.currentShot ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: UIDevice.isPad ? 16 : 12, height: UIDevice.isPad ? 16 : 12)
                            .scaleEffect(index == viewModel.currentShot ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentShot)
                    }
                }
                .offset(y: -80)

                // Start Button
                Button(action: {
                    viewModel.startCountdown()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("sugarPink"))
                            .frame(width: UIDevice.isPad ? 100 : 70, height: UIDevice.isPad ? 100 : 70)

                        Circle()
                            .stroke(Color("lightPink"), lineWidth: 5)
                            .frame(width: UIDevice.isPad ? 100 : 70, height: UIDevice.isPad ? 100 : 70)

                        Circle()
                            .stroke(Color("sugarPink"), lineWidth: 5)
                            .frame(width: UIDevice.isPad ? 106 : 76, height: UIDevice.isPad ? 106 : 76)
                    }
                }
                .disabled(viewModel.isCapturing)
                .opacity(viewModel.isCapturing ? 0.5 : 1)
                .offset(y: UIDevice.isPad ? -60 : -40)

                Spacer()
            }

            if viewModel.showFrontFlashOverlay {
                Color.white
                    .opacity(1.0)
                    .ignoresSafeArea()
                    .zIndex(100)
            }
        }
        
        
        // DAHA SONRA SİL !
        .onAppear {
            if isPreview {
                // Do nothing in preview
            } else {
                requestCameraAccess { granted in
                    if !granted {
                        showCameraAlert = true
                    }
                }
            }
        }
        .alert("Camera Access Needed", isPresented: $showCameraAlert) {
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow camera access from Settings to use the photo booth.")
        }
        .navigationBarBackButtonHidden(true)
    }

    // Kamera izni
    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
}

#Preview {
    CameraScreen(path: .constant(NavigationPath()))
}


struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "camera.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
                .foregroundColor(.gray)
        }
    }
}
