//
//  LCDownloadedIPAsView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI

struct LCDownloadedIPAsView: View {
    @State private var downloadedIPAs: [DownloadedIPA] = []
    @State private var errorShow = false
    @State private var errorInfo = ""
    @State private var showDeleteAllAlert = false
    
    var body: some View {
        List {
            if downloadedIPAs.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Downloaded IPAs")
                            .font(.headline)
                        Text("Downloaded IPA files will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                ForEach(downloadedIPAs) { ipa in
                    IPARow(ipa: ipa, onInstall: {
                        installIPA(ipa)
                    })
                }
                .onDelete(perform: deleteIPAs)
            }
        }
        .navigationTitle("Downloaded IPAs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !downloadedIPAs.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Text("Delete All")
                    }
                }
            }
        }
        .alert("Delete All IPAs?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllIPAs()
            }
        } message: {
            Text("This will permanently delete all downloaded IPA files.")
        }
        .alert("Error", isPresented: $errorShow) {
            Button("OK") { }
        } message: {
            Text(errorInfo)
        }
        .onAppear {
            loadDownloadedIPAs()
        }
    }
    
    private func loadDownloadedIPAs() {
        let fm = FileManager.default
        let docsPath = LCPath.docPath
        let downloadedIPAsPath = docsPath.appendingPathComponent("DownloadedIPAs")
        
        // Ensure directory exists
        if !fm.fileExists(atPath: downloadedIPAsPath.path) {
            try? fm.createDirectory(at: downloadedIPAsPath, withIntermediateDirectories: true)
        }
        
        do {
            let files = try fm.contentsOfDirectory(at: downloadedIPAsPath, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            
            downloadedIPAs = files
                .filter { $0.pathExtension.lowercased() == "ipa" }
                .compactMap { url in
                    guard let attributes = try? fm.attributesOfItem(atPath: url.path) else { return nil }
                    
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    
                    return DownloadedIPA(
                        url: url,
                        fileName: url.lastPathComponent,
                        fileSize: fileSize,
                        downloadDate: creationDate
                    )
                }
                .sorted { $0.downloadDate > $1.downloadDate }
        } catch {
            errorInfo = "Failed to load downloaded IPAs: \(error.localizedDescription)"
            errorShow = true
        }
    }
    
    private func deleteIPAs(at offsets: IndexSet) {
        let fm = FileManager.default
        
        for index in offsets {
            let ipa = downloadedIPAs[index]
            try? fm.removeItem(at: ipa.url)
        }
        
        downloadedIPAs.remove(atOffsets: offsets)
    }
    
    private func deleteAllIPAs() {
        let fm = FileManager.default
        
        for ipa in downloadedIPAs {
            try? fm.removeItem(at: ipa.url)
        }
        
        downloadedIPAs.removeAll()
    }
    
    private func installIPA(_ ipa: DownloadedIPA) {
        // TODO: Trigger IPA installation
        print("Installing IPA: \(ipa.fileName)")
    }
}

struct DownloadedIPA: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let downloadDate: Date
}

struct IPARow: View {
    let ipa: DownloadedIPA
    let onInstall: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "doc.zipper")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ipa.fileName)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: ipa.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(ipa.downloadDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                onInstall()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
    }
}
