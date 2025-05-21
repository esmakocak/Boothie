//
//  OutputScreenViewModel.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 8.04.2025.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

@MainActor
class OutputScreenViewModel: ObservableObject {
    @Published var showSavedAlert = false
    // Keep a strong reference to the document controller
    private var documentInteractionController: UIDocumentInteractionController?

    func saveCombinedStrip(from images: [UIImage], isDarkFrame: Bool) {
        guard let photostrip = createPhotoStrip(from: images, isDarkFrame: isDarkFrame) else {
            print("❌ Görsel oluşturulamadı")
            return
        }

        UIImageWriteToSavedPhotosAlbum(photostrip, nil, nil, nil)
        showSavedAlert = true
    }

    // Updated WhatsApp sharing function
    func shareViaWhatsApp(from images: [UIImage], isDarkFrame: Bool, from viewController: UIViewController) -> Bool {
        guard let photostrip = createPhotoStrip(from: images, isDarkFrame: isDarkFrame) else {
            print("❌ Failed to create image for sharing")
            return false
        }
        
        // Save image temporarily
        if let imageData = photostrip.jpegData(compressionQuality: 0.9) {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent("photostrip_\(UUID().uuidString).jpg")
            
            do {
                try imageData.write(to: tempFile)
                
                // Create document interaction controller and keep a strong reference
                documentInteractionController = UIDocumentInteractionController(url: tempFile)
                documentInteractionController?.uti = "net.whatsapp.image"
                
                // Present the share sheet
                if documentInteractionController?.presentOpenInMenu(from: CGRect.zero, in: viewController.view, animated: true) == true {
                    return true
                } else {
                    // If presentOpenInMenu returns false, WhatsApp might not be available
                    return false
                }
            } catch {
                print("❌ Error saving temporary file: \(error)")
                return false
            }
        }
        
        return false
    }

    func applyEffect(image: UIImage, effect: OutputEffect) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        let outputImage: CIImage?

        switch effect {
        case .sepia:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = ciImage

            let sepia = CIFilter.sepiaTone()
            sepia.inputImage = mono.outputImage
            sepia.intensity = 0.6

//            let exposure = CIFilter.exposureAdjust()
//            exposure.inputImage = sepia.outputImage
//            exposure.ev = 0.2
//
            let bloom = CIFilter.bloom()
            bloom.inputImage = sepia.outputImage
            bloom.intensity = 0.3
            bloom.radius = 2.0

            outputImage = bloom.outputImage

        case .fadedMono:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = ciImage

            let curve = CIFilter.toneCurve()
            curve.inputImage = mono.outputImage
            curve.point0 = CGPoint(x: 0.0, y: 0.1)
            curve.point1 = CGPoint(x: 0.25, y: 0.3)
            curve.point2 = CGPoint(x: 0.5, y: 0.5)
            curve.point3 = CGPoint(x: 0.75, y: 0.75)
            curve.point4 = CGPoint(x: 1.0, y: 1.0)

            let bloom = CIFilter.bloom()
            bloom.inputImage = curve.outputImage
            bloom.intensity = 0.5
            bloom.radius = 5

            let sharp = CIFilter.unsharpMask()
            sharp.inputImage = bloom.outputImage
            sharp.intensity = 0.3
            sharp.radius = 1.2

            let vignette = CIFilter.vignette()
            vignette.inputImage = sharp.outputImage
            vignette.intensity = 0.4
            vignette.radius = 10.0

            outputImage = vignette.outputImage

        case .softGlow:
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.brightness = 0.09
            colorControls.saturation = 1.1
            colorControls.contrast = 1.1

            let tint = CIFilter.colorMonochrome()
            tint.inputImage = colorControls.outputImage
            tint.color = CIColor(red: 1.0, green: 0.7, blue: 0.9)
            tint.intensity = 0.1

            let curve = CIFilter.toneCurve()
            curve.inputImage = tint.outputImage
            curve.point0 = CGPoint(x: 0.0, y: 0.0)
            curve.point1 = CGPoint(x: 0.25, y: 0.2)
            curve.point2 = CGPoint(x: 0.5, y: 0.5)
            curve.point3 = CGPoint(x: 0.75, y: 0.8)
            curve.point4 = CGPoint(x: 1.0, y: 1.0)

            let bloom = CIFilter.bloom()
            bloom.inputImage = curve.outputImage
            bloom.intensity = 0.4
            bloom.radius = 6

            let warmth = CIFilter.temperatureAndTint()
            warmth.inputImage = bloom.outputImage
            warmth.neutral = CIVector(x: 7500, y: 0)
            warmth.targetNeutral = CIVector(x: 7500, y: 0)

            outputImage = warmth.outputImage

        case .motionBlurred:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = ciImage

            let overlay = CIFilter.colorMonochrome()
            overlay.inputImage = mono.outputImage
            overlay.color = CIColor(red: 0.3, green: 0.4, blue: 0.7)
            overlay.intensity = 0.3

            let motion = CIFilter.motionBlur()
            motion.inputImage = overlay.outputImage
            motion.radius = 2
            motion.angle = 0

            let contrast = CIFilter.colorControls()
            contrast.inputImage = motion.outputImage
            contrast.brightness = 0.08
            contrast.saturation = 0.5
            contrast.contrast = 1.2

            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = contrast.outputImage
            exposure.ev = -0.2

            let vignette = CIFilter.vignette()
            vignette.inputImage = exposure.outputImage
            vignette.intensity = 0.5
            vignette.radius = 10

            outputImage = vignette.outputImage
        }

        if let outputImage,
           let cgImage = context.createCGImage(outputImage.cropped(to: ciImage.extent), from: ciImage.extent) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }

        return image
    }

    private func createPhotoStrip(from images: [UIImage], isDarkFrame: Bool) -> UIImage? {
        let photoSize = CGSize(width: 220, height: 220)
        let spacing: CGFloat = 16
        let topPadding: CGFloat = 20
        let bottomPadding: CGFloat = 40
        let cardWidth: CGFloat = 260
        let cardCornerRadius: CGFloat = 0
        let imageCornerRadius: CGFloat = 3
        let dateHeight: CGFloat = 24

        let totalHeight = topPadding + (photoSize.height * CGFloat(images.count)) + (spacing * CGFloat(images.count - 1)) + dateHeight + bottomPadding
        let size = CGSize(width: cardWidth, height: totalHeight)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Arka plan
        let backgroundRect = CGRect(origin: .zero, size: size)
        let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: cardCornerRadius)
        (isDarkFrame ? UIColor.black : UIColor.white).setFill()
        backgroundPath.fill()

        var yOffset = topPadding
        for image in images {
            let frame = CGRect(x: (cardWidth - photoSize.width) / 2, y: yOffset, width: photoSize.width, height: photoSize.height)

            let path = UIBezierPath(roundedRect: frame, cornerRadius: imageCornerRadius)
            context.saveGState()
            path.addClip()
            drawImageAspectFill(image, in: frame)
            context.restoreGState()

            yOffset += photoSize.height + spacing
        }

        // Always reserve space for date, only draw text if showDate is true
        let textY = yOffset - spacing + 10
        let textRect = CGRect(x: 0, y: textY, width: cardWidth, height: 40)
        
        if UserDefaults.standard.object(forKey: "showDate") == nil || UserDefaults.standard.bool(forKey: "showDate"){
            let dateText = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "SnellRoundhand", size: 20) ?? UIFont.systemFont(ofSize: 20),
                .foregroundColor: isDarkFrame ? UIColor.white : UIColor.black,
                .paragraphStyle: paragraph
            ]

            dateText.draw(in: textRect, withAttributes: attributes)
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }

    private func drawImageAspectFill(_ image: UIImage, in frame: CGRect) {
        let scale = max(frame.width / image.size.width, frame.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        let x = frame.origin.x + (frame.width - width) / 2
        let y = frame.origin.y + (frame.height - height) / 2
        image.draw(in: CGRect(x: x, y: y, width: width, height: height))
    }
}
