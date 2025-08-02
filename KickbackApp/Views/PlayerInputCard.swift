//
//  PlayerInputCard.swift
//  KickbackApp
//
//  Created by Claude Code on 8/2/25.
//

import SwiftUI

/// Field identification for focus management
enum PlayerInputField: Hashable {
    case player1Name
    case player1Gender
    case player2Name
    case player2Gender
}

/// Clean, modern player input card with proper form handling and accessibility
/// Simplified design focused on usability over visual effects
struct PlayerInputCard: View {
    
    // MARK: - Properties
    
    let playerNumber: Int
    @Binding var name: String
    @Binding var gender: String
    @Binding var currentFocusedField: PlayerInputField?
    let glassID: String
    
    /// Focus state management for smooth transitions
    @FocusState private var isNameFieldFocused: Bool
    
    /// Animation state for validation feedback
    @State private var showValidationError = false
    
    /// Force UI refresh when gender changes
    @State private var refreshID = UUID()
    
    /// Gender options for picker
    private let genderOptions = ["He/Him", "She/Her", "They/Them", "Other"]
    
    /// Clean card styling constants
    private let cardCornerRadius: CGFloat = 16
    private let fieldSpacing: CGFloat = 16
    private let cardPadding: CGFloat = 20
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: fieldSpacing) {
            // Player header
            playerHeader
            
            // Name input field
            nameInputField
            
            // Pronoun selection field
            pronounSelectionField
        }
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: playerColor.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(
                    playerColor.opacity(isFocused ? 0.3 : 0.1),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onChange(of: isNameFieldFocused) { _, newValue in
            updateFocusState(nameField: newValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Player \(playerNumber) information card")
        .accessibilityHint("Enter name and select pronouns for player \(playerNumber)")
    }
    
    // MARK: - Subviews
    
    /// Simple player header with number and validation status
    @ViewBuilder
    private var playerHeader: some View {
        HStack(spacing: 12) {
            // Player icon
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(playerColor)
            
            // Player title
            Text("Player \(playerNumber)")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Validation indicator
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Clean name input field
    @ViewBuilder
    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field label
            Text("Name")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(playerColor)
            
            // Text field
            TextField("Enter name", text: $name)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.background.quaternary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isNameFieldFocused ? playerColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .focused($isNameFieldFocused)
                .submitLabel(.next)
                .onSubmit {
                    // Focus next field or dismiss keyboard
                    isNameFieldFocused = false
                }
                .accessibilityLabel("Player \(playerNumber) name")
                .accessibilityHint("Enter the name for player \(playerNumber)")
        }
    }
    
    /// Clean pronoun selection field with proper Menu handling
    @ViewBuilder
    private var pronounSelectionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field label
            Text("Pronouns")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(playerColor)
            
            // Custom Menu for pronouns (more reliable than Picker)
            Menu {
                ForEach(genderOptions, id: \.self) { option in
                    Button(action: {
                        gender = option
                        
                        // Force UI refresh
                        refreshID = UUID()
                        
                        // Provide haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        HStack {
                            Text(option)
                            Spacer()
                            if gender == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(playerColor)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(gender.isEmpty ? "Select pronouns" : gender)
                        .font(.body)
                        .foregroundColor(gender.isEmpty ? .secondary : .primary)
                        .animation(.none, value: gender) // Disable animation to ensure immediate update
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .id(refreshID) // Force recreation when refreshID changes
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background.quaternary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isFocused ? playerColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .accessibilityLabel("Player \(playerNumber) pronouns")
            .accessibilityHint("Select pronouns for player \(playerNumber)")
            .accessibilityValue(gender.isEmpty ? "Not selected" : gender)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Player-specific color theming
    private var playerColor: Color {
        switch playerNumber {
        case 1:
            return Color("BrandPurple")
        case 2:
            return Color("BrandPurpleLight")
        default:
            return .blue
        }
    }
    
    /// Combined focus state for animations
    private var isFocused: Bool {
        return isNameFieldFocused
    }
    
    /// Completion state for validation
    private var isComplete: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !gender.isEmpty
    }
    
    /// Field identification for parent focus management
    private var nameField: PlayerInputField {
        return playerNumber == 1 ? .player1Name : .player2Name
    }
    
    private var genderField: PlayerInputField {
        return playerNumber == 1 ? .player1Gender : .player2Gender
    }
    
    // MARK: - Actions
    
    /// Updates focus state for parent coordination
    private func updateFocusState(nameField: Bool? = nil, genderField: Bool? = nil) {
        if let nameField = nameField {
            currentFocusedField = nameField ? self.nameField : nil
        }
        if let genderField = genderField {
            currentFocusedField = genderField ? self.genderField : nil
        }
    }
    
}

// MARK: - Preview Support

#Preview("Player Input Card - Empty") {
    PlayerInputCard(
        playerNumber: 1,
        name: Binding.constant(""),
        gender: Binding.constant(""),
        currentFocusedField: Binding.constant(nil),
        glassID: "preview-player1"
    )
    .padding()
    .background(.background.secondary)
}

#Preview("Player Input Card - Filled") {
    PlayerInputCard(
        playerNumber: 2,
        name: Binding.constant("Jordan"),
        gender: Binding.constant("She/Her"),
        currentFocusedField: Binding.constant(.player2Name),
        glassID: "preview-player2"
    )
    .padding()
    .background(.background.secondary)
}

#Preview("Both Player Cards") {
    VStack(spacing: 20) {
        PlayerInputCard(
            playerNumber: 1,
            name: Binding.constant("Alex"),
            gender: Binding.constant("They/Them"),
            currentFocusedField: Binding.constant(nil),
            glassID: "preview-player1"
        )
        
        PlayerInputCard(
            playerNumber: 2,
            name: Binding.constant(""),
            gender: Binding.constant(""),
            currentFocusedField: Binding.constant(.player2Name),
            glassID: "preview-player2"
        )
    }
    .padding()
    .background(.background.secondary)
}