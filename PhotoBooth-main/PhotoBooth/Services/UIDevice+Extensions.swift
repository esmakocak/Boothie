//
//  UIDevice+Extensions.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 22.04.2025.
//

import Foundation
import UIKit

extension UIDevice {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
