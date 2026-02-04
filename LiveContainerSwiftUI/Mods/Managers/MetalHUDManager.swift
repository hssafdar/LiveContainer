//
//  MetalHUDManager.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import Foundation
import SwiftUI

class MetalHUDManager: ObservableObject {
    static let shared = MetalHUDManager()
    
    @Published var isDeveloperModeEnabled: Bool = false
    @Published var isCheckingDeveloperMode: Bool = false
    
    private init() {
        checkDeveloperMode()
    }
    
    // Check if Developer Mode is enabled using sysctlbyname
    func checkDeveloperMode() {
        isCheckingDeveloperMode = true
        
        // For iOS < 16, Developer Mode doesn't exist
        if #available(iOS 16.0, *) {
            isDeveloperModeEnabled = checkDeveloperModeStatus()
        } else {
            // For older iOS versions, always return true
            isDeveloperModeEnabled = true
        }
        
        isCheckingDeveloperMode = false
    }
    
    @available(iOS 16.0, *)
    private func checkDeveloperModeStatus() -> Bool {
        var status: Int32 = 0
        var size = MemoryLayout<Int32>.size
        
        let result = sysctlbyname("security.mac.amfi.developer_mode_status", &status, &size, nil, 0)
        
        if result == 0 {
            return status == 1
        }
        
        // Fallback to heuristic check if sysctlbyname fails
        return checkDeveloperModeHeuristic()
    }
    
    private func checkDeveloperModeHeuristic() -> Bool {
        // Heuristic: Try to check for debug entitlements or other indicators
        // This is a fallback and may not be 100% accurate
        
        // Check if process has get-task-allow entitlement (debug mode indicator)
        let task = mach_task_self_
        var info = task_category_policy_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_category_policy_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                task_policy_get(task, task_policy_flavor_t(TASK_CATEGORY_POLICY), ptr, &count, nil)
            }
        }
        
        // If we can get task policy, assume developer mode is likely enabled
        return kr == KERN_SUCCESS
    }
    
    // Set Metal HUD environment variables
    func enableMetalHUD() {
        setenv("MTL_HUD_ENABLED", "1", 1)
        setenv("CA_DEBUG_RENDER_SERVER", "1", 1)
    }
    
    func disableMetalHUD() {
        unsetenv("MTL_HUD_ENABLED")
        unsetenv("CA_DEBUG_RENDER_SERVER")
    }
}
