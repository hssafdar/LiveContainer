//
//  SavedLinksManager.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import Foundation
import SwiftUI

struct SavedIPALink: Codable, Identifiable {
    let id: UUID
    var url: String
    var name: String
    let dateAdded: Date
    var isOnline: Bool?
    var fileSize: Int64?
    var lastChecked: Date?
    var installedAppBundleID: String?
    var installedAppIconData: Data?
    
    init(url: String, name: String) {
        self.id = UUID()
        self.url = url
        self.name = name
        self.dateAdded = Date()
    }
}

class SavedLinksManager: ObservableObject {
    static let shared = SavedLinksManager()
    
    @Published var savedLinks: [SavedIPALink] = []
    @Published var isRefreshing: Bool = false
    
    private let storageKey = "LCSavedIPALinks"
    private let defaults = LCUtils.appGroupUserDefault
    
    private init() {
        loadLinks()
    }
    
    // MARK: - Persistence
    
    func loadLinks() {
        guard let data = defaults?.data(forKey: storageKey),
              let links = try? JSONDecoder().decode([SavedIPALink].self, from: data) else {
            savedLinks = []
            return
        }
        savedLinks = links
    }
    
    func saveLinks() {
        guard let data = try? JSONEncoder().encode(savedLinks) else { return }
        defaults?.set(data, forKey: storageKey)
    }
    
    // MARK: - CRUD Operations
    
    func addLink(url: String, name: String) {
        let link = SavedIPALink(url: url, name: name)
        savedLinks.append(link)
        saveLinks()
        
        // Check status immediately
        Task {
            await checkLinkStatus(link.id)
        }
    }
    
    func updateLink(_ link: SavedIPALink) {
        if let index = savedLinks.firstIndex(where: { $0.id == link.id }) {
            savedLinks[index] = link
            saveLinks()
        }
    }
    
    func deleteLink(_ link: SavedIPALink) {
        savedLinks.removeAll { $0.id == link.id }
        saveLinks()
    }
    
    func deleteLinks(at offsets: IndexSet) {
        savedLinks.remove(atOffsets: offsets)
        saveLinks()
    }
    
    // MARK: - Status Checking
    
    @MainActor
    func refreshAllLinks() async {
        isRefreshing = true
        
        await withTaskGroup(of: Void.self) { group in
            for link in savedLinks {
                group.addTask {
                    await self.checkLinkStatus(link.id)
                }
            }
        }
        
        isRefreshing = false
    }
    
    @MainActor
    func checkLinkStatus(_ linkId: UUID) async {
        guard let index = savedLinks.firstIndex(where: { $0.id == linkId }) else { return }
        
        var link = savedLinks[index]
        link.lastChecked = Date()
        
        guard let url = URL(string: link.url) else {
            link.isOnline = false
            link.fileSize = nil
            savedLinks[index] = link
            saveLinks()
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                link.isOnline = (200...299).contains(httpResponse.statusCode)
                
                if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
                   let size = Int64(contentLength) {
                    link.fileSize = size
                }
            }
        } catch {
            link.isOnline = false
            link.fileSize = nil
        }
        
        savedLinks[index] = link
        saveLinks()
    }
    
    // MARK: - Download
    
    func downloadIPA(from link: SavedIPALink, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: link.url) else {
            completion(.failure(NSError(domain: "SavedLinksManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "SavedLinksManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
                return
            }
            
            // Move to DownloadedIPAs directory
            let fm = FileManager.default
            let docsPath = LCPath.docPath
            let downloadedIPAsPath = docsPath.appendingPathComponent("DownloadedIPAs")
            
            do {
                try fm.createDirectory(at: downloadedIPAsPath, withIntermediateDirectories: true)
                
                let fileName = link.name.isEmpty ? "downloaded.ipa" : "\(link.name).ipa"
                let destURL = downloadedIPAsPath.appendingPathComponent(fileName)
                
                // Remove existing file if present
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                
                try fm.moveItem(at: tempURL, to: destURL)
                completion(.success(destURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        // Track progress - observation will be automatically cleaned up when task completes
        var observation: NSKeyValueObservation? = nil
        observation = downloadTask.progress.observe(\.fractionCompleted) { [weak downloadTask] progress, _ in
            progressHandler(progress.fractionCompleted)
            
            // Clean up observation when complete
            if progress.fractionCompleted >= 1.0 {
                observation?.invalidate()
                observation = nil
            }
        }
        
        downloadTask.resume()
    }
}
