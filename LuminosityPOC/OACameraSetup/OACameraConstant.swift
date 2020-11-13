//
//  OACameraConstant.swift
//  OneAssist-Swift
//
//  Created by Ankur Batham on 12/09/20.
//  Copyright © 2020 OneAssist. All rights reserved.
//

import Foundation

internal enum CameraDevice:Int {
    case back = 1
    case front = 2
}

enum OACameraError: Error {
    case noVideoConnection
    case noImageCapture
    case noMetaRect
    case noDevice
    case noCameraPermission
}

extension OACameraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noVideoConnection:
            return "there is no video connection"
        case .noImageCapture:
            return "could not capture any image"
        case .noMetaRect:
            return "no metadata rect found"
        case .noDevice:
            return "your device doesnt have camera"
        case .noCameraPermission:
            return "you dont have camera permission"
        }
    }
}

