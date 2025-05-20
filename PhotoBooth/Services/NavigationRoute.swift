//
//  NavigationRoute.swift
//  PhotoBooth
//
//  Created by Esma Koçak on 24.04.2025.
//

import Foundation
import SwiftUI

enum Route: Hashable {
    case camera
    case settings
    case output(images: [UIImage])
}
