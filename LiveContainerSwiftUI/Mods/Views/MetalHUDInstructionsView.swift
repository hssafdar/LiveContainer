//
//  MetalHUDInstructionsView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI

struct MetalHUDInstructionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Enable Developer Mode")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)
                    
                    Group {
                        instructionStep(
                            number: 1,
                            title: "Open Settings",
                            description: "Open the Settings app on your device."
                        )
                        
                        instructionStep(
                            number: 2,
                            title: "Go to Privacy & Security",
                            description: "Scroll down and tap on 'Privacy & Security'."
                        )
                        
                        instructionStep(
                            number: 3,
                            title: "Find Developer Mode",
                            description: "Scroll to the bottom and tap on 'Developer Mode'."
                        )
                        
                        instructionStep(
                            number: 4,
                            title: "Enable Developer Mode",
                            description: "Toggle the 'Developer Mode' switch to ON. You'll be asked to restart your device."
                        )
                        
                        instructionStep(
                            number: 5,
                            title: "Restart Device",
                            description: "Restart your device when prompted. After restart, you may see a popup asking to confirm enabling Developer Mode."
                        )
                        
                        instructionStep(
                            number: 6,
                            title: "Confirm",
                            description: "Tap 'Turn On' in the popup to finalize enabling Developer Mode."
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Note:")
                            .font(.headline)
                        Text("• Developer Mode is available on iOS 16.0 and later")
                        Text("• This feature requires your device to be in Developer Mode to display the Metal HUD overlay")
                        Text("• The Metal HUD shows real-time GPU performance metrics")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Developer Mode Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func instructionStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
