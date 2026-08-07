//
//  ContentView.swift
//  StashBar
//
//  Created by Matty on 22/07/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var onShowSettings: () -> Void = {}
    
    // notepad state
    @AppStorage("scratchpadText") private var scratchpadText: String = ""
    
    // file shelf state
    @State private var files: [FileItem] = []
    @State private var isTargeted = false
    @StateObject private var exporter = ExportManager()
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // header
            HStack {
                Label("StashBar", systemImage: "tray.and.arrow.down")
                    .font(.headline)
                Spacer()
                if !scratchpadText.isEmpty || !files.isEmpty {
                    Button("Clear All") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
            }
            
            // text note section
            VStack(alignment: .leading, spacing: 4) {
                Text("QUICK NOTE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $scratchpadText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                    .frame(height: 120)
            }
            
            Divider()
            
            // file shelf drop section
            VStack(alignment: .leading, spacing: 6) {
                Text("FILE SHELF (\(files.count))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5])
                                )
                        )
                    
                    if files.isEmpty {
                        Text("Drop files here to stash temporarily")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(files) { item in
                                    FileTileView(item: item) {
                                        files.removeAll { $0.id == item.id}
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .frame(height: 90)
                // drop destination for files
                .dropDestination(for: URL.self) { droppedURLs, _ in
                    let newItems = droppedURLs.map { FileItem(url: $0)}
                    for newItem in newItems {
                        if !files.contains(where: { $0.url == newItem.url }) {
                            files.append(newItem)
                        }
                    }
                    return true
                } isTargeted: { targeted in
                    isTargeted = targeted
                }
            }
            
            Divider()
            
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
                Text(exporter.folderName ?? "No folder chosen")
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button("Change…") { exporter.chooseFolder() }
                    .buttonStyle(.borderless)
            }
            .font(.caption2)
            
            
            HStack(spacing: 4) {
                if let status = exporter.status {
                    Image(systemName: status.isSuccess
                          ? "checkmark.circle.fill"
                          : "exclamationmark.triangle.fill")
                    Text(status.message)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                
            }
            .font(.caption2)
            .foregroundColor(exporter.status?.isSuccess == false ? .red : . secondary)
            .frame(height: 24)
            .animation(.easeInOut(duration: 0.2), value: exporter.status)
    
            
            // action row
            HStack(spacing: 8) {
                Button("Save Markdown") {
                    if exporter.folderName == nil, !exporter.chooseFolder() { return }
                    exporter.exportMarkdown(scratchpadText)
                }
                .disabled(scratchpadText.isEmpty)
                
                Button("Send to Notes") {
                    exporter.exportToAppleNotes(scratchpadText)
                }
                .disabled(scratchpadText.isEmpty)
                
                Spacer()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit StashBar")
                
                
                Button {
                    onShowSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
    
                
            }
            .font(.caption)
            
        }
        .padding()
        .frame(width: 320)
        .confirmationDialog("Clear the notepad and file shelf?", isPresented: $showingConfirmation, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                scratchpadText = ""
                files.removeAll()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// model representing a stashed file
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    
    var name: String {
        url.lastPathComponent
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

// individual tile view for a file
struct FileTileView: View {
    let item: FileItem
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 60)
        }
        .padding(6)
        .background(Color.primary.opacity(0.06))
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
        // Enables dragging the file OUT of StashBar
        .overlay(
            FileDragSource(url: item.url, onDragCompleted: onDelete)
        )
        .contextMenu {
            Button("Remove", role: .destructive, action: onDelete)
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
    }
}
