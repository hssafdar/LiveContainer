//
//  LCReinstallWithContainerView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI

struct LCReinstallWithContainerView: View {
    @ObservedObject var model: LCAppModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedContainerIndex: Int = 0
    @State private var isReinstalling = false
    @State private var errorShow = false
    @State private var errorInfo = ""
    
    var containers: [NSDictionary] {
        model.appInfo.containerInfo as? [NSDictionary] ?? []
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Container to Preserve")) {
                    if containers.isEmpty {
                        Text("No containers available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Container", selection: $selectedContainerIndex) {
                            ForEach(0..<containers.count, id: \.self) { index in
                                let container = containers[index]
                                let dataUUID = container["DataUUID"] as? String ?? "Unknown"
                                let keyGroupId = container["KeyGroupId"] as? Int ?? 0
                                Text("Container \(index + 1) - Group \(keyGroupId)")
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
                
                Section {
                    Button {
                        performReinstall()
                    } label: {
                        if isReinstalling {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Reinstalling...")
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Reinstall with Selected Container")
                                Spacer()
                            }
                        }
                    }
                    .disabled(isReinstalling || containers.isEmpty)
                } footer: {
                    Text("The app will be reinstalled while preserving the selected container's data. This allows you to update the app without losing data.")
                }
            }
            .navigationTitle("Reinstall App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isReinstalling)
                }
            }
            .alert("Error", isPresented: $errorShow) {
                Button("OK") { }
            } message: {
                Text(errorInfo)
            }
        }
    }
    
    private func performReinstall() {
        guard selectedContainerIndex < containers.count else {
            errorInfo = "Invalid container selection"
            errorShow = true
            return
        }
        
        isReinstalling = true
        
        let selectedContainer = containers[selectedContainerIndex]
        let dataUUID = selectedContainer["DataUUID"] as? String ?? ""
        
        // Post notification for main app to handle the reinstallation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("LCReinstallAppWithContainer"),
                object: nil,
                userInfo: [
                    "bundleIdentifier": model.appInfo.bundleIdentifier() ?? "",
                    "dataUUID": dataUUID
                ]
            )
            
            isReinstalling = false
            dismiss()
        }
    }
}
