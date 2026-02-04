//
//  LCAdvancedModsManager.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import Foundation
import SwiftUI

class LCAdvancedModsManager: ObservableObject {
    static let shared = LCAdvancedModsManager()
    
    // Global toggles using AppStorage
    @AppStorage("LCMetalHUDEnabled", store: LCUtils.appGroupUserDefault) 
    var metalHUDEnabled: Bool = false
    
    @AppStorage("LCBlockScreenshotsGlobal", store: LCUtils.appGroupUserDefault) 
    var blockScreenshotsGlobal: Bool = false
    
    @AppStorage("LCDisableTelemetryGlobal", store: LCUtils.appGroupUserDefault) 
    var disableTelemetryGlobal: Bool = false
    
    @AppStorage("LCAutoDeleteIPAsAfterInstall", store: LCUtils.appGroupUserDefault) 
    var autoDeleteIPAsAfterInstall: Bool = true
    
    // Telemetry domain blocklist
    let telemetryDomains = [
        "firebase.google.com",
        "firebaselogging.googleapis.com",
        "firebaseinstallations.googleapis.com",
        "app-measurement.com",
        "google-analytics.com",
        "mixpanel.com",
        "api.mixpanel.com",
        "amplitude.com",
        "api.amplitude.com",
        "segment.com",
        "api.segment.io",
        "adjust.com",
        "app.adjust.com",
        "appsflyer.com",
        "t.appsflyer.com",
        "flurry.com",
        "data.flurry.com",
        "crashlytics.com",
        "settings.crashlytics.com"
    ]
    
    private init() {}
    
    // Helper methods
    func shouldBlockDomain(_ domain: String) -> Bool {
        guard disableTelemetryGlobal else { return false }
        
        for blockedDomain in telemetryDomains {
            if domain.hasSuffix(blockedDomain) || domain == blockedDomain {
                return true
            }
        }
        return false
    }
    
    func setMetalHUDEnvironmentVariables() {
        guard metalHUDEnabled else { return }
        setenv("MTL_HUD_ENABLED", "1", 1)
        setenv("CA_DEBUG_RENDER_SERVER", "1", 1)
    }
}
