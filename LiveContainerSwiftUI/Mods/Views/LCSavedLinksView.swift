//
//  LCSavedLinksView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI

struct LCSavedLinksView: View {
    @StateObject private var linksManager = SavedLinksManager.shared
    @State private var showingAddSheet = false
    @State private var newLinkURL = ""
    @State private var newLinkName = ""
    @State private var errorShow = false
    @State private var errorInfo = ""
    
    var body: some View {
        List {
            if linksManager.savedLinks.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "link.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Saved Links")
                            .font(.headline)
                        Text("Add IPA download links to install apps quickly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                ForEach(linksManager.savedLinks) { link in
                    SavedLinkRow(link: link)
                        .contextMenu {
                            Button {
                                Task {
                                    await linksManager.checkLinkStatus(link.id)
                                }
                            } label: {
                                Label("Refresh Status", systemImage: "arrow.clockwise")
                            }
                            
                            Button {
                                UIPasteboard.general.string = link.url
                            } label: {
                                Label("Copy URL", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                if let url = URL(string: link.url) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open in Browser", systemImage: "safari")
                            }
                            
                            Button(role: .destructive) {
                                linksManager.deleteLink(link)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: linksManager.deleteLinks)
            }
        }
        .navigationTitle("Saved IPA Links")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await linksManager.refreshAllLinks()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddLinkSheet(
                url: $newLinkURL,
                name: $newLinkName,
                onAdd: {
                    guard !newLinkURL.isEmpty else {
                        errorInfo = "URL cannot be empty"
                        errorShow = true
                        return
                    }
                    
                    linksManager.addLink(url: newLinkURL, name: newLinkName.isEmpty ? "Unnamed Link" : newLinkName)
                    newLinkURL = ""
                    newLinkName = ""
                    showingAddSheet = false
                }
            )
        }
        .alert("Error", isPresented: $errorShow) {
            Button("OK") { }
        } message: {
            Text(errorInfo)
        }
        .task {
            // Auto-refresh on appear
            await linksManager.refreshAllLinks()
        }
    }
}

struct SavedLinkRow: View {
    let link: SavedIPALink
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // App icon if available
                if let iconData = link.installedAppIconData,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.name)
                        .font(.headline)
                    
                    Text(link.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Status badge
                    if let isOnline = link.isOnline {
                        Circle()
                            .fill(isOnline ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                    }
                    
                    // File size
                    if let fileSize = link.fileSize {
                        Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Last checked time
            if let lastChecked = link.lastChecked {
                Text("Checked: \(lastChecked, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Download progress
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .progressViewStyle(.linear)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            downloadAndInstall()
        }
    }
    
    private func downloadAndInstall() {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        
        SavedLinksManager.shared.downloadIPA(from: link) { progress in
            DispatchQueue.main.async {
                downloadProgress = progress
            }
        } completion: { result in
            DispatchQueue.main.async {
                isDownloading = false
                
                switch result {
                case .success(let url):
                    // TODO: Trigger IPA installation
                    print("Downloaded IPA to: \(url.path)")
                case .failure(let error):
                    print("Download failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct AddLinkSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var url: String
    @Binding var name: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Link Details")) {
                    TextField("Name (optional)", text: $name)
                    TextField("IPA URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add IPA Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(url.isEmpty)
                }
            }
        }
    }
}
