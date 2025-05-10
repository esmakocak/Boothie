//
//  CameraScreen.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 8.04.2025.
//

import SwiftUI
import AVFoundation

struct CameraScreen: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showCameraAlert = false
    @State private var showStartButton = true
    
    private var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
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
                }
                .padding(.bottom, 50)

                // Kamera çerçevesi
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: UIDevice.isPad ? 480 : 340, height: UIDevice.isPad ? 480 : 340)
                        .shadow(radius: 8)
                        .overlay(
                            Group {
                                if isPreview {
                                    CameraPreviewPlaceholder()
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
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

                    // Camera Controls
                    VStack {
                        // Camera Switch Button
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                        
                        // Start Button
                        if showStartButton {
                            Button(action: {
                                showStartButton = false
                                viewModel.startCountdown()
                            }) {
                                Text("START")
                                    .font(.custom("Didot-Bold", size: 20))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    .frame(width: UIDevice.isPad ? 480 : 340, height: UIDevice.isPad ? 480 : 340)
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
                            .frame(width: UIDevice.isPad ? 480 : 340, height: UIDevice.isPad ? 480 : 340)
                            .offset(y: -60)
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

                Spacer()
            }

            // Çekimler bitince OutputScreen'e geçiş
            .navigationDestination(isPresented: $viewModel.navigateToOutput) {
                OutputScreen(images: viewModel.capturedImages)
            }
        }
        .onAppear {
            if isPreview {
                viewModel.startCountdown()
            } else {
                requestCameraAccess { granted in
                    if granted {
                        viewModel.setupCamera()
                    } else {
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