import SwiftUI

enum CustomBlendMode {
    case normal
    case colorDodge
    case hardMix
    case darken
    case linearDodge
    case difference
    case multiply
    case lighterColor
    case exclusion
    case colorBurn
    case overlay
    case subtract
    case linearBurn
    case softLight
    case divide
    case darker
    case hardLight
    case hue
    case color
    case vividLight
    case saturation
    case lighten
    case linearLight
    case screen
    case pinLight
    case luminosity

    var swiftUIBlendMode: BlendMode {
        switch self {
        case .normal:
            return .normal
        case .multiply:
            return .multiply
        case .screen:
            return .screen
        case .overlay:
            return .overlay
        case .darken:
            return .darken
        case .lighten:
            return .lighten
        case .colorDodge:
            return .colorDodge
        case .colorBurn:
            return .colorBurn
        case .softLight:
            return .softLight
        case .hardLight:
            return .hardLight
        case .difference:
            return .difference
        case .exclusion:
            return .exclusion
        case .hue:
            return .hue
        case .saturation:
            return .saturation
        case .color:
            return .color
        case .luminosity:
            return .luminosity
        // For custom blend modes not directly supported by SwiftUI
        default:
            return .normal
        }
    }
}
