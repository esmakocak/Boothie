import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct OutputScreen: View {
    let images: [UIImage]
    @StateObject private var viewModel = OutputScreenViewModel()
    @Binding var path: NavigationPath
    @State private var animateStrip = false
    @State private var isSaving = false
    @State private var showSavedToast = false
    @State private var isDarkFrame = false
    @State private var filteredImages: [UIImage] = []
    @State private var currentEffect: OutputEffect = .original
    @AppStorage("showDate") private var showDate: Bool = true
    @State private var isExiting = false
    @State private var offsetX: CGFloat = 0
    @State private var isWhatsAppSharing = false
    @State private var whatsAppNotInstalledAlert = false
    @State private var showEditOptions = false
    @State private var showFrameOptions = false
    @State private var photostrip: UIImage? = nil
    
    // Frame colors
    private let frameColors: [Color] = [.white, .black,  Color.lightPink, Color.sugarPink, Color.purple.opacity(0.7) ,Color.teal.opacity(0.7)]
    @State private var selectedFrameColor: Color = .white
    
    // Device detection
    private var isPad: Bool {
        UIDevice.isPad
    }
    
    // Match the exact dimensions from createPhotoStrip function
    private let photoSize: CGFloat = 220
    private let cardWidth: CGFloat = 260
    private let spacing: CGFloat = 16
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 40
    private let dateHeight: CGFloat = 24
    
    private func calculateCardHeight() -> CGFloat {
        let totalHeight = topPadding + (photoSize * CGFloat(filteredImages.count)) + (spacing * CGFloat(max(0, filteredImages.count - 1))) + dateHeight + bottomPadding
        return totalHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color("bgColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top navigation bar with proper safe area
                    HStack {
                        // Retake button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                isExiting = true
                                offsetX = geometry.size.width
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                path = NavigationPath()
                            }
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color("sugarPink"))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("lightPink"))
                                )
                        }
                        
                        Spacer()
                        
                        // Save and Share buttons
                        HStack(spacing: 12) {
                            // Save button
                            Button(action: {
                                withAnimation { isSaving = true }
                                
                                viewModel.saveCombinedStrip(from: filteredImages, frameColor: selectedFrameColor)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    withAnimation {
                                        isSaving = false
                                        showSavedToast = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation {
                                            showSavedToast = false
                                        }
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("lightPink"))
                                        .frame(width: 44, height: 44)
                                    
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("sugarPink")))
                                    } else {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(Color("sugarPink"))
                                    }
                                }
                            }
                            .disabled(isSaving)
                            
                            // Share button
                            Button(action: {
                                withAnimation { isWhatsAppSharing = true }
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootViewController = windowScene.windows.first?.rootViewController {
                                    let success = viewModel.shareViaWhatsApp(
                                        from: filteredImages,
                                        frameColor: selectedFrameColor,
                                        from: rootViewController
                                    )
                                    
                                    if !success {
                                        whatsAppNotInstalledAlert = true
                                    }
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        isWhatsAppSharing = false
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("lightPink"))
                                        .frame(width: 44, height: 44)
                                    
                                    if isWhatsAppSharing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("sugarPink")))
                                    } else {
                                        Image(systemName: "paperplane")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(Color("sugarPink"))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20) // Increased top padding for better visibility
                    .padding(.bottom, 10)
                    
                    // Photostrip in the middle
                    Spacer(minLength: 0)
                    if let photostrip {
                        let aspectRatio = cardWidth / calculateCardHeight()
                        Image(uiImage: photostrip)
                            .resizable()
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .frame(maxWidth: min(cardWidth, geometry.size.width * 0.7))
                            .shadow(radius: 10)
                            .padding(.vertical, 10)
                            .transition(.scale)
                    } else {
                        // Placeholder if needed
                        let aspectRatio = cardWidth / calculateCardHeight()
                        Rectangle()
                            .fill(Color.clear)
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .frame(maxWidth: min(cardWidth, geometry.size.width * 0.7))
                    }
                    Spacer(minLength: 0)
                    
                    // Edit and Frame buttons
                    HStack(spacing: 20) {
                        // Edit button
                        Button(action: {
                            withAnimation {
                                showEditOptions.toggle()
                                if showEditOptions {
                                    showFrameOptions = false
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 20))
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(width: 80, height: 60)
                            .foregroundColor(Color("sugarPink"))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("lightPink"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("sugarPink"), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Frame button
                        Button(action: {
                            withAnimation {
                                showFrameOptions.toggle()
                                if showFrameOptions {
                                    showEditOptions = false
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.dashed")
                                    .font(.system(size: 20))
                                Text("Frame")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(width: 80, height: 60)
                            .foregroundColor(Color("sugarPink"))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("lightPink"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("sugarPink"), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Bottom options area
                    ZStack {
                        // Edit options
                        if showEditOptions {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(OutputEffect.allCases, id: \.self) { effect in
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 60, height: 60)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                
                                                // Sample image with effect
                                                if let sampleImage = images.first {
                                                    Image(uiImage: viewModel.applyEffect(image: sampleImage, effect: effect))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 56, height: 56)
                                                        .clipShape(Circle())
                                                }
                                                
                                                // Selection indicator
                                                if currentEffect == effect {
                                                    Circle()
                                                        .stroke(Color("sugarPink"), lineWidth: 2)
                                                        .frame(width: 64, height: 64)
                                                    
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Color("sugarPink"))
                                                        .font(.system(size: 18))
                                                        .background(Circle().fill(Color.white))
                                                        .offset(x: 22, y: -22)
                                                }
                                            }
                                            
                                            Text(effect.displayName)
                                                .font(.system(size: 12))
                                                .foregroundColor(.black)
                                        }
                                        .onTapGesture {
                                            currentEffect = effect
                                            applyCurrentEffect()
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                            }
                            .frame(height: 110)
                            .background(Color.white.opacity(0.8))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Frame options
                        if showFrameOptions {
                            HStack(spacing: 20) {
                                ForEach(frameColors, id: \.self) { color in
                                    ZStack {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 40, height: 40)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        
                                        if selectedFrameColor == color {
                                            Circle()
                                                .stroke(Color("sugarPink"), lineWidth: 2)
                                                .frame(width: 46, height: 46)
                                            
                                            Image(systemName: "checkmark")
                                                .foregroundColor(color == .white ? Color("sugarPink") : .white)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            selectedFrameColor = color
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                            .background(Color.white.opacity(0.8))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(height: 110)
                }
                .offset(x: offsetX)
                .opacity(isExiting ? 0.4 : 1)
                .animation(.easeInOut(duration: 0.45), value: offsetX)
                
                // Toast notification
                if showSavedToast {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("sugarPink"))
                                .font(.system(size: 20))
                            Text("Saved to Gallery")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 120) // Adjusted to be below the top buttons
                }
            }
        }
        .onAppear {
            applyCurrentEffect()
            updatePhotostrip()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateStrip = true
                }
            }
        }
        .onChange(of: filteredImages) { _ in
            updatePhotostrip()
        }
        .onChange(of: isDarkFrame) { _ in
            updatePhotostrip()
        }
        .onChange(of: selectedFrameColor) { _ in
            updatePhotostrip()
        }
        .navigationBarBackButtonHidden(true)
        .alert("WhatsApp Not Installed", isPresented: $whatsAppNotInstalledAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please install WhatsApp to use this feature.")
        }
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    func applyCurrentEffect() {
        filteredImages = images.map {
            viewModel.applyEffect(image: $0, effect: currentEffect)
        }
    }
    
    private func updatePhotostrip() {
        photostrip = viewModel.createPhotoStrip(from: filteredImages, frameColor: selectedFrameColor)
    }
}

enum OutputEffect: String, CaseIterable {
    case original, sepia, fadedMono, softGlow, motionBlurred, vintage, noir
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .sepia: return "Sepia"
        case .fadedMono: return "Faded"
        case .softGlow: return "Soft Glow"
        case .motionBlurred: return "Motion"
        case .vintage: return "Vintage"
        case .noir: return "Noir"
        }
    }
}

#Preview {
    let fakeImage = UIImage(color: .gray, size: CGSize(width: 220, height: 220))
    OutputScreen(images: [fakeImage, fakeImage, fakeImage], path: .constant(NavigationPath()))
}

extension UIImage {
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.init(cgImage: image.cgImage!)
    }
}
