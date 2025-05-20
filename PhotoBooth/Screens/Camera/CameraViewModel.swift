//
//  CameraViewModel.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 8.04.2025.
//

import SwiftUI
import AVFoundation

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @AppStorage("countdownSeconds") private var countdownSetting: Int = 3
    @Published var countdown: Int = 3
    @Published var currentShot: Int = 1
    @Published var isCapturing = false
    @Published var showFlash = false
    @Published var navigateToOutput = false
    @Published var capturedImages: [UIImage] = []
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "captureQueue")
    private var latestPixelBuffer: CVPixelBuffer?
    private var currentInput: AVCaptureDeviceInput?

    let totalShots = 3
    let session = AVCaptureSession()
    @Binding var path: NavigationPath

    init(path: Binding<NavigationPath>) {
        _path = path
        super.init()
        self.countdown = countdownSetting
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            print("❌ Kamera kurulamadı.")
            return
        }

        // Remove existing input if any
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        session.addInput(input)
        currentInput = input

        output.setSampleBufferDelegate(self, queue: captureQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        startSession()
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func startCountdown() {
        isCapturing = true
        countdown = countdownSetting

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                DispatchQueue.main.async {
                    self.countdown -= 1

                    if self.countdown == 0 {
                        timer.invalidate()
                        self.simulatePhotoCapture()
                    }
                }
            }
        }
    }
    
    func simulatePhotoCapture() {
        self.showFlash = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showFlash = false

            // Ekran görüntüsünü al
            if let buffer = self.latestPixelBuffer {
                let ciImage = CIImage(cvPixelBuffer: buffer)
                let context = CIContext()

                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .leftMirrored)

                    self.capturedImages.append(image)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.currentShot < self.totalShots {
                self.currentShot += 1
                self.startCountdown()
            } else {
                self.isCapturing = false
                self.path.append(Route.output(images: self.capturedImages))
            }
        }
    }
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            Task { @MainActor in
                self.latestPixelBuffer = buffer
            }
        }
    }

    func switchCamera() {
        // Stop the session before making changes
        session.stopRunning()
        
        // Begin configuration
        session.beginConfiguration()
        
        // Remove existing input
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // Toggle camera position
        cameraPosition = cameraPosition == .front ? .back : .front
        
        // Get new camera device
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: cameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            print("❌ Failed to get new camera device")
            session.commitConfiguration()
            startSession()
            return
        }
        
        // Add new input
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentInput = newInput
        }
        
        // Commit configuration
        session.commitConfiguration()
        
        // Restart session
        startSession()
    }
}
