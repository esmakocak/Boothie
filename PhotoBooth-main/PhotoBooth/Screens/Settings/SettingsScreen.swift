//
//  SettingsScreen.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 9.04.2025.
//

import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("countdownSeconds") private var countdownSeconds: Int = 3
    @AppStorage("showDate") private var showDate: Bool = true

    let countdownOptions = Array(1...10)

    var body: some View {
        ZStack {
            Color("bgColor").opacity(0.65)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: UIDevice.isPad ? 36 : 24) {
                // Geri Butonu
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: UIDevice.isPad ? 24 : 18, weight: .medium))
                        }
                        .foregroundColor(Color("sugarPink"))
                        .padding(.horizontal, UIDevice.isPad ? 20 : 16)
                        .padding(.vertical, UIDevice.isPad ? 12 : 8)
                        .background(Color("lightPink"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("sugarPink"), lineWidth: 1)
                        )
                    }

                    Spacer()
                }
                .padding(.top, 20)

                // Ayarlar
                ScrollView {
                    VStack(alignment: .leading, spacing: UIDevice.isPad ? 40 : 32) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Countdown Timer")
                                .font(.custom("Didot-Bold", size: UIDevice.isPad ? 30 : 20))
                                .foregroundColor(Color("sugarPink"))
                                .padding(.horizontal, 8)
                            
                            Picker("", selection: $countdownSeconds) {
                                ForEach(countdownOptions, id: \.self) { sec in
                                    Text("\(sec) second\(sec > 1 ? "s" : "")")
                                        .tag(sec)
                                        .font(UIDevice.isPad ? .system(size: 30) : .body)
                                }
                            }
                            .labelsHidden()
                            .frame(height: UIDevice.isPad ? 180 : 140)
                            .clipped()
                            .pickerStyle(.wheel)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $showDate) {
                                Text("Display Date")
                                    .font(.custom("Didot-Bold", size: UIDevice.isPad ? 30 : 20))
                                    .foregroundColor(Color("sugarPink"))
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color("sugarPink")))
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettingsScreen()
}
