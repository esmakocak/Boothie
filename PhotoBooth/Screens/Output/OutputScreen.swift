import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct OutputScreen: View {
    let images: [UIImage]
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OutputScreenViewModel()
    @State private var goToWelcome = false
    @State private var animateStrip = false
    @State private var isSaving = false
    @State private var showSavedToast = false
    @State private var isDarkFrame = false
    @State private var filteredImages: [UIImage] = []
    @State private var currentEffect: OutputEffect = .sepia
    @AppStorage("showDate") private var showDate: Bool = true
    
    var body: some View {
        ZStack {
            Color("bgColor")
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Şerit kart
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isDarkFrame ? .black : .white)
                        .frame(width: 260)
                        .shadow(radius: 4)
                    
                    VStack(spacing: 16) {
                        ForEach(filteredImages.indices, id: \.self) { index in
                            Image(uiImage: filteredImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 220, height: 220)
                                .clipped()
                                .cornerRadius(6)
                        }
                        
                        ZStack {
                            if showDate {
                                Text(formattedDate())
                                    .font(.custom("SnellRoundhand", size: 20))
                                    .foregroundColor(isDarkFrame ? .white : .black)
                            }
                        }
                        .frame(height: 24)
                        .padding(.bottom, 12)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                }
                .modifier(SlideFadeIn(show: animateStrip))
                .padding(.bottom, 20)
                .offset(y: -60)
                
                Spacer()
                
                // Butonlar
                HStack(spacing: 8) {
                    // 🔁 TAKE AGAIN
                    Button(action: {
                        goToWelcome = true
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: UIDevice.isPad ? 26 : 18, weight: .bold))
                            .foregroundColor(Color("sugarPink"))
                            .padding(UIDevice.isPad ? 13 : 12)
                            .background(Color("lightPink"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("sugarPink"), lineWidth: 1)
                            )
                    }
                    
                    // 📸 COLLECT
                    Button(action: {
                        withAnimation { isSaving = true }
                        
                        viewModel.saveCombinedStrip(from: filteredImages, isDarkFrame: isDarkFrame)
                        
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
                                .stroke(Color("sugarPink"), lineWidth: 1)
                                .background(
                                    Color("lightPink").opacity(isSaving ? 0.7 : 1)
                                        .cornerRadius(12)
                                )
                            
                            Group {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                } else {
                                    Text("COLLECT PHOTO")
                                        .font(.custom("Didot-Bold", size: UIDevice.isPad ? 22 : 18))
                                        .frame(width: UIDevice.isPad ? 240 : 200, height: UIDevice.isPad ? 60 : 50)
                                        .foregroundColor(Color("sugarPink"))
                                }
                            }
                        }
                        .frame(width: UIDevice.isPad ? 270 : 200, height: UIDevice.isPad ? 54 : 50)
                    }
                    .disabled(isSaving)

                    // Share Button
                    Button(action: {
                        if let image = viewModel.createPhotoStrip(from: filteredImages, isDarkFrame: isDarkFrame) {
                            let activityVC = UIActivityViewController(
                                activityItems: [image],
                                applicationActivities: nil
                            )
                            
                            // Present the share sheet
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                activityVC.popoverPresentationController?.sourceView = rootVC.view
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: UIDevice.isPad ? 26 : 18, weight: .bold))
                            .foregroundColor(Color("sugarPink"))
                            .padding(UIDevice.isPad ? 13 : 12)
                            .background(Color("lightPink"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("sugarPink"), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 5)
                .padding(.horizontal, 20)
                .offset(y: -60)
                
                // 🎨 Effect & Frame Butonları
                HStack(spacing: 12) {
                    // 🎨 EFFECT
                    Button(action: {
                        currentEffect = currentEffect.next()
                        applyCurrentEffect()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.filters")
                            Text("Effect")
                        }
                        .frame(width: UIDevice.isPad ? 160 : 120, height: UIDevice.isPad ? 54 : 44)
                        .font(.custom("Didot-Bold", size: UIDevice.isPad ? 20 : 16))
                        .foregroundColor(Color("sugarPink"))
                        .background(Color("lightPink"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("sugarPink"), lineWidth: 1)
                        )
                    }
                    
                    // 🖼 FRAME
                    Button(action: {
                        withAnimation {
                            isDarkFrame.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.dashed")
                            Text("Frame")
                        }
                        .frame(width: UIDevice.isPad ? 160 : 120, height: UIDevice.isPad ? 54 : 44)
                        .font(.custom("Didot-Bold", size: UIDevice.isPad ? 20 : 16))
                        .foregroundColor(Color("sugarPink"))
                        .background(Color("lightPink"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("sugarPink"), lineWidth: 1)
                        )
                    }
                }
                .padding(.bottom, 60)
                .offset(y: -60) 
            }
            .padding(.horizontal, 20)
            
            // ✅ Saved Toast
            .overlay(
                VStack {
                    if showSavedToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("sugarPink"))
                            Text("Saved to Gallery")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(20)
                        .shadow(radius: 4)
                        .opacity(showSavedToast ? 1 : 0)
                        .offset(y: showSavedToast ? 0 : 20)
                        .animation(.easeInOut(duration: 0.4), value: showSavedToast)
                        .padding(.bottom, 120)
                        .allowsHitTesting(false)
                    }
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            )
            .navigationDestination(isPresented: $goToWelcome) {
                WelcomeScreen()
            }
        }
        .onAppear {
            applyCurrentEffect()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateStrip = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    func applyCurrentEffect() {
        filteredImages = images.map {
            viewModel.applyEffect(image: $0, effect: currentEffect)
        }
    }
}