//
//  LCExportIPAView.swift
//  LiveContainerSwiftUI
//
//  Created by LiveContainer on 2024/11/01.
//

import SwiftUI
import UniformTypeIdentifiers

struct LCExportIPAView: View {
    @ObservedObject var model: LCAppModel
    @StateObject private var exportManager = LCContainerExportManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedContainerIndex: Int? = nil
    @State private var includeDocuments = true
    @State private var includeLibrary = true
    @State private var includeCaches = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var errorShow = false
    @State private var errorInfo = ""
    
    var containers: [NSDictionary] {
        model.appInfo.containerInfo as? [NSDictionary] ?? []
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Container Selection")) {
                    if containers.isEmpty {
                        Toggle("No container data", isOn: .constant(false))
                            .disabled(true)
                    } else {
                        Picker("Container", selection: $selectedContainerIndex) {
                            Text("None").tag(nil as Int?)
                            
                            ForEach(0..<containers.count, id: \.self) { index in
                                let container = containers[index]
                                let keyGroupId = container["KeyGroupId"] as? Int ?? 0
                                Text("Container \(index + 1) - Group \(keyGroupId)")
                                    .tag(index as Int?)
                            }
                        }
                    }
                }
                
                if selectedContainerIndex != nil {
                    Section(header: Text("Include Container Data")) {
                        Toggle("Documents Folder", isOn: $includeDocuments)
                        Toggle("Library Folder", isOn: $includeLibrary)
                        Toggle("Caches", isOn: $includeCaches)
                    } footer: {
                        Text("Select which container folders to include in the exported IPA")
                    }
                }
                
                Section {
                    if exportManager.isExporting {
                        VStack(spacing: 10) {
                            ProgressView(value: exportManager.exportProgress)
                            Text("Exporting: \(Int(exportManager.exportProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Button {
                            performExport()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("Export as IPA")
                                Spacer()
                            }
                        }
                    }
                } footer: {
                    if selectedContainerIndex != nil {
                        Text("The exported IPA will contain the app bundle in Payload/ and container data in ContainerData/")
                    } else {
                        Text("The exported IPA will contain only the app bundle")
                    }
                }
            }
            .navigationTitle("Export IPA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(exportManager.isExporting)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Error", isPresented: $errorShow) {
                Button("OK") { }
            } message: {
                Text(errorInfo)
            }
        }
    }
    
    private func performExport() {
        var containerPath: String? = nil
        
        if let index = selectedContainerIndex, index < containers.count {
            let container = containers[index]
            let dataUUID = container["DataUUID"] as? String ?? ""
            
            // Construct container path
            let isShared = model.appInfo.isShared
            let basePath = isShared ? LCPath.lcGroupDataPath : LCPath.dataPath
            containerPath = basePath.appendingPathComponent(dataUUID).path
        }
        
        exportManager.exportAppAsIPA(
            appInfo: model.appInfo,
            containerPath: containerPath,
            includeDocuments: includeDocuments,
            includeLibrary: includeLibrary,
            includeCaches: includeCaches
        ) { result in
            switch result {
            case .success(let url):
                exportedFileURL = url
                showShareSheet = true
            case .failure(let error):
                errorInfo = "Export failed: \(error.localizedDescription)"
                errorShow = true
            }
        }
    }
}

// Share Sheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
