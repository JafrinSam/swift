import SwiftUI
import SwiftData

// =====================================================
// MARK: - Router (Centralized Navigation)
// =====================================================

@Observable
class Router {
    var path = NavigationPath()
    var selectedTab: AppTab = .command
    
    // MARK: - Type-Safe Destinations (for deep linking)
    enum Destination: Hashable {
        case questDetail(String)      // Quest ID
        case snippetEditor(String)    // Snippet ID
        case rechargeGame(String)     // "memoryFlip", "codeSnake", "bugSquash"
        case burnoutProtocol
    }
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func switchTab(_ tab: AppTab) {
        selectedTab = tab
        popToRoot()
    }
}

// MARK: - Tab Enum
enum AppTab: Int, CaseIterable, Identifiable {
    case command = 0
    case board = 1
    case vitality = 2
    case toolkit = 3
    case system = 4
    
    var id: Int { rawValue }
    
    var label: String {
        switch self {
        case .command:  return "Command"
        case .board:    return "Board"
        case .vitality: return "Vitality"
        case .toolkit:  return "Toolkit"
        case .system:   return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .command:  return "terminal.fill"
        case .board:    return "square.stack.3d.up.fill"
        case .vitality: return "waveform.path.ecg"
        case .toolkit:  return "wrench.and.screwdriver.fill"
        case .system:   return "gearshape.2.fill"
        }
    }
}
