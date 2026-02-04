//
//  LCAppAdvancedSettingsView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI

struct LCAppAdvancedSettingsView: View {
    @ObservedObject var model: LCAppModel
    @State private var modSettings: LCAppModSettings
    @State private var newDomain = ""
    @State private var errorShow = false
    @State private var errorInfo = ""
    
    init(model: LCAppModel) {
        self.model = model
        let bundleID = model.appInfo.bundleIdentifier() ?? ""
        _modSettings = State(initialValue: LCAppModSettings.load(for: bundleID))
    }
    
    var body: some View {
        Form {
            // Device Spoofing Section
            Section {
                Toggle("Enable Spoofing", isOn: $modSettings.spoofingEnabled)
                    .onChange(of: modSettings.spoofingEnabled) { _ in
                        saveSettings()
                    }
                
                if modSettings.spoofingEnabled {
                    HStack {
                        Text("UDID")
                        Spacer()
                        Text(String(modSettings.spoofedUDID.prefix(8)) + "...")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Picker("User-Agent", selection: $modSettings.spoofedUserAgent) {
                        Text("Default").tag("")
                        Text("Safari iOS").tag("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")
                        Text("Chrome iOS").tag("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/119.0.0.0 Mobile/15E148 Safari/604.1")
                        Text("Firefox iOS").tag("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/119.0 Mobile/15E148 Safari/605.1.15")
                        Text("Desktop Safari").tag("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15")
                    }
                    .onChange(of: modSettings.spoofedUserAgent) { _ in
                        saveSettings()
                    }
                    
                    Picker("iOS Version", selection: $modSettings.spoofedIOSVersion) {
                        Text("Default").tag("")
                        Text("iOS 15.0").tag("15.0")
                        Text("iOS 15.8").tag("15.8")
                        Text("iOS 16.0").tag("16.0")
                        Text("iOS 16.7").tag("16.7")
                        Text("iOS 17.0").tag("17.0")
                        Text("iOS 17.4").tag("17.4")
                        Text("iOS 18.0").tag("18.0")
                    }
                    .onChange(of: modSettings.spoofedIOSVersion) { _ in
                        saveSettings()
                    }
                    
                    Button("Randomize All") {
                        modSettings.spoofedUDID = UUID().uuidString
                        saveSettings()
                    }
                }
            } header: {
                Text("Device Spoofing")
            }
            
            // Network Section
            Section {
                Toggle("Network Kill Switch", isOn: $modSettings.networkKillSwitch)
                    .onChange(of: modSettings.networkKillSwitch) { _ in
                        saveSettings()
                    }
                
                Toggle("Block Screenshots", isOn: $modSettings.blockScreenshots)
                    .onChange(of: modSettings.blockScreenshots) { _ in
                        saveSettings()
                    }
            } header: {
                Text("Network")
            } footer: {
                Text("Network Kill Switch blocks all network access for this app")
            }
            
            // Domain Blocking Section
            Section {
                ForEach(modSettings.blockedDomains, id: \.self) { domain in
                    HStack {
                        Image(systemName: "xmark.shield.fill")
                            .foregroundColor(.red)
                        Text(domain)
                        Spacer()
                    }
                }
                .onDelete { offsets in
                    modSettings.blockedDomains.remove(atOffsets: offsets)
                    saveSettings()
                }
                
                HStack {
                    TextField("Add domain", text: $newDomain)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Button {
                        guard !newDomain.isEmpty else { return }
                        modSettings.blockedDomains.append(newDomain)
                        newDomain = ""
                        saveSettings()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(newDomain.isEmpty)
                }
            } header: {
                Text("Domain Blocking")
            } footer: {
                Text("Blocked domains will have their network requests denied. Enter domain names like 'example.com' without https://")
            }
            
            // Permissions Section
            Section {
                Toggle("Auto-deny Tracking", isOn: $modSettings.autoDenyTracking)
                    .onChange(of: modSettings.autoDenyTracking) { _ in
                        saveSettings()
                    }
                
                Toggle("Auto-allow Permissions", isOn: $modSettings.autoAllowPermissions)
                    .onChange(of: modSettings.autoAllowPermissions) { _ in
                        saveSettings()
                    }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Auto-deny tracking automatically denies App Tracking Transparency requests. Auto-allow permissions automatically grants permission requests (use with caution).")
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $errorShow) {
            Button("OK") { }
        } message: {
            Text(errorInfo)
        }
    }
    
    private func saveSettings() {
        guard let bundleID = model.appInfo.bundleIdentifier() else { return }
        modSettings.save(for: bundleID)
    }
}
