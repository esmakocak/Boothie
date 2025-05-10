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
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "captureQueue")
    private var latestPixelBuffer: CVPixelBuffer?
    private var currentPosition: AVCaptureDevice.Position = .front

    let totalShots = 3
    let session = AVCaptureSession()

    override init() {
        super.init()
        self.countdown = countdownSetting
    }

    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        // Setup new input
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                              for: .video,
                                              position: currentPosition),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        output.setSampleBufferDelegate(self, queue: captureQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
        startSession()
    }

    func switchCamera() {
        currentPosition = currentPosition == .front ? .back : .front
        setupCamera()
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

            if let buffer = self.latestPixelBuffer {
                let ciImage = CIImage(cvPixelBuffer: buffer)
                let context = CIContext()

                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let orientation: UIImage.Orientation = self.currentPosition == .front ? .leftMirrored : .right
                    let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: orientation)
                    self.capturedImages.append(image)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.currentShot < self.totalShots {
                self.currentShot += 1
                self.startCountdown()
            } else {
                self.navigateToOutput = true
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
}