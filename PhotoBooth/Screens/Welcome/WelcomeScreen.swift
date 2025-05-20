//
//  WelcomeScreen.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 8.04.2025.
//

import SwiftUI

struct WelcomeScreen: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                ZStack {
                    Color("bgColor")
                        .ignoresSafeArea()
                    
                    Image("photobooth_background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width)
                        .ignoresSafeArea()
                    
                    Text("PHOTOBOOTH")
                        .font(.custom("Didot-Bold", size: geo.size.width * 0.08))
                        .foregroundColor(Color("sugarPink"))
                        .frame(width: geo.size.width)
                        .offset(y: UIDevice.isPad ? -geo.size.height * 0.44 : -geo.size.height * 0.40)
                    
                    // START
                    Button {
                        path.append(Route.camera)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                            Text("START")
                                .font(.custom("Didot-Bold", size: UIDevice.isPad ? geo.size.width * 0.05 : geo.size.width * 0.06))
                                .foregroundColor(Color("sugarPink"))
                        }
                    }
                    .offset(x: UIDevice.isPad ? -geo.size.width * 0.22 : -geo.size.width * 0.27,
                            y: UIDevice.isPad ? geo.size.height * 0.075 : geo.size.height * 0.07)
                    
                    // SETTINGS
                    Button {
                        path.append(Route.settings)
                    } label: {
                        Text("SETTINGS")
                            .font(.custom("Didot-Bold", size: UIDevice.isPad ? geo.size.width * 0.025 : geo.size.width * 0.033))
                            .foregroundColor(Color("sugarPink"))
                    }
                    .offset(x: UIDevice.isPad ? -geo.size.width * 0.15 : -geo.size.width * 0.19,
                            y: UIDevice.isPad ? geo.size.height * 0.18 : geo.size.height * 0.16)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .camera:
                    CameraScreen(path: $path)
                case .settings:
                    SettingsScreen()
                case .output(let images):
                    OutputScreen(images: images, path: $path)
                }
            }
        }
    }
}

#Preview {
    WelcomeScreen()
}
