//
//  ConversationMode.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Conversation mode enumeration with liquid glass design properties
public enum ConversationMode: String, CaseIterable {
    case blindDate = "Blind Date"
    case couples = "Couples"
    case unhinged = "Unhinged"
    case freePlay = "Free Play"
    
    public var title: String {
        return self.rawValue
    }
    
    public var description: String {
        switch self {
        case .blindDate:
            return "First encounters and getting to know each other"
        case .couples:
            return "Deep connection questions for intimate relationships"
        case .unhinged:
            return "Wild and spontaneous conversation starters"
        case .freePlay:
            return "Open-ended questions for any conversation style"
        }
    }
    
    public var iconName: String {
        switch self {
        case .blindDate:
            return "eye.circle"
        case .couples:
            return "heart.circle.fill"
        case .unhinged:
            return "flame.circle"
        case .freePlay:
            return "play.circle"
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .blindDate:
            return .blue
        case .couples:
            return .purple
        case .unhinged:
            return .orange
        case .freePlay:
            return .green
        }
    }
    
    public var glassID: String {
        return "mode-\(rawValue)"
    }
    
    public var preferredCategories: [QuestionCategory] {
        switch self {
        case .blindDate:
            return [.firstDate, .blindDate]
        case .couples:
            return [.deepCouple, .intimacyBuilding, .vulnerabilitySharing]
        case .unhinged:
            return [.funAndPlayful, .futureVisions]
        case .freePlay:
            return [.personalGrowth, .emotionalIntelligence, .valuesAlignment, .firstDate, .funAndPlayful]
        }
    }
}