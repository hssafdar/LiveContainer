//
//  LCContainerExportManager.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import Foundation

struct LCExportMetadata: Codable {
    let exportDate: Date
    let exportedBy: String
    let bundleIdentifier: String
    let appName: String
    let appVersion: String
    let containerIncluded: Bool
    let documentsIncluded: Bool
    let libraryIncluded: Bool
    let cachesIncluded: Bool
}

class LCContainerExportManager: ObservableObject {
    static let shared = LCContainerExportManager()
    
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String?
    
    private init() {}
    
    func exportAppAsIPA(
        appInfo: LCAppInfo,
        containerPath: String?,
        includeDocuments: Bool = true,
        includeLibrary: Bool = true,
        includeCaches: Bool = false,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        isExporting = true
        exportProgress = 0.0
        exportError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let result = try self.performExport(
                    appInfo: appInfo,
                    containerPath: containerPath,
                    includeDocuments: includeDocuments,
                    includeLibrary: includeLibrary,
                    includeCaches: includeCaches
                )
                
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportProgress = 1.0
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func performExport(
        appInfo: LCAppInfo,
        containerPath: String?,
        includeDocuments: Bool,
        includeLibrary: Bool,
        includeCaches: Bool
    ) throws -> URL {
        let fm = FileManager.default
        
        // Create temporary export directory
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Progress: 0-30% - Copy app bundle
        DispatchQueue.main.async { self.exportProgress = 0.0 }
        
        let payloadDir = tempDir.appendingPathComponent("Payload")
        try fm.createDirectory(at: payloadDir, withIntermediateDirectories: true)
        
        let bundlePath = URL(fileURLWithPath: appInfo.bundlePath())
        let appName = bundlePath.lastPathComponent
        let destBundlePath = payloadDir.appendingPathComponent(appName)
        
        try fm.copyItem(at: bundlePath, to: destBundlePath)
        
        DispatchQueue.main.async { self.exportProgress = 0.3 }
        
        // Progress: 30-80% - Copy container data if selected
        var metadata = LCExportMetadata(
            exportDate: Date(),
            exportedBy: "LiveContainer",
            bundleIdentifier: appInfo.bundleIdentifier() ?? "",
            appName: appInfo.displayName() ?? "",
            appVersion: appInfo.version() ?? "",
            containerIncluded: containerPath != nil,
            documentsIncluded: includeDocuments,
            libraryIncluded: includeLibrary,
            cachesIncluded: includeCaches
        )
        
        if let containerPath = containerPath {
            let containerURL = URL(fileURLWithPath: containerPath)
            let containerDataDir = tempDir.appendingPathComponent("ContainerData")
            try fm.createDirectory(at: containerDataDir, withIntermediateDirectories: true)
            
            if includeDocuments {
                let docsSource = containerURL.appendingPathComponent("Documents")
                let docsDest = containerDataDir.appendingPathComponent("Documents")
                if fm.fileExists(atPath: docsSource.path) {
                    try fm.copyItem(at: docsSource, to: docsDest)
                }
            }
            
            DispatchQueue.main.async { self.exportProgress = 0.5 }
            
            if includeLibrary {
                let libSource = containerURL.appendingPathComponent("Library")
                let libDest = containerDataDir.appendingPathComponent("Library")
                if fm.fileExists(atPath: libSource.path) {
                    try fm.copyItem(at: libSource, to: libDest)
                }
            }
            
            DispatchQueue.main.async { self.exportProgress = 0.65 }
            
            if includeCaches {
                let cachesSource = containerURL.appendingPathComponent("Library/Caches")
                let cachesDest = containerDataDir.appendingPathComponent("Caches")
                if fm.fileExists(atPath: cachesSource.path) {
                    try fm.copyItem(at: cachesSource, to: cachesDest)
                }
            }
        }
        
        DispatchQueue.main.async { self.exportProgress = 0.8 }
        
        // Write metadata
        let metadataURL = tempDir.appendingPathComponent("LCExportMetadata.json")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
        
        // Progress: 80-100% - Create ZIP using PKZipArchiver
        let outputFileName = "\(appInfo.displayName() ?? "App")_\(Date().timeIntervalSince1970).ipa"
        let outputURL = fm.temporaryDirectory.appendingPathComponent(outputFileName)
        
        // Remove existing file if present
        if fm.fileExists(atPath: outputURL.path) {
            try fm.removeItem(at: outputURL)
        }
        
        // Use PKZipArchiver to create zip
        let archiver = PKZipArchiver()
        let zipData = archiver.zippedData(for: tempDir)
        
        guard let zipData = zipData else {
            throw NSError(domain: "LCContainerExportManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP archive"])
        }
        
        try zipData.write(to: outputURL)
        
        DispatchQueue.main.async { self.exportProgress = 1.0 }
        
        return outputURL
    }
}
