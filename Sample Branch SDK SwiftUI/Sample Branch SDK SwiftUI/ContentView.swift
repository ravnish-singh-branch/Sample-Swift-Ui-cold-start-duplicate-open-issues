//
//  ContentView.swift
//  Sample Branch SDK SwiftUI
//
//  Created by Ravnish Singh on 09/09/26.
//

import SwiftUI
import UIKit
import BranchSDK

@MainActor
struct ContentView: View {
    @State private var logStore = LogStore.shared
    @State private var generatedLink: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Link Data") {
                    if let linkParameters = logStore.linkParameters {
                        NavigationLink("View Parameters") {
                            LinkParametersView(parameters: linkParameters)
                        }
                    } else {
                        Text("No link data yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Network Events") {
                    ForEach(Array(logStore.networkEvents.enumerated()), id: \.element.id) { index, event in
                        NavigationLink {
                            NetworkEventDetailView(event: event)
                        } label: {
                            Text("\(index + 1). \(event.endpoint)")
                                .font(.body.monospaced())
                        }
                    }
                }
            }
            .navigationTitle("Branch Logs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        logStore.clear()
                        generatedLink = nil
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        generateDeepLink()
                    } label: {
                        Label("Generate Link", systemImage: "link.badge.plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let generatedLink {
                    VStack(spacing: 4) {
                        Text(generatedLink)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                        Text("Tap to copy")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIPasteboard.general.string = generatedLink
                    }
                }
            }
        }
    }

    private func generateDeepLink() {
        guard generatedLink == nil else { return }

        let buo = BranchUniversalObject(canonicalIdentifier: "content/sample")
        buo.title = "Sample Branch Link"

        let linkProperties = BranchLinkProperties()
        linkProperties.feature = "sharing"
        linkProperties.addControlParam("$desktop_url", withValue: "https://example.com")

        buo.getShortUrl(with: linkProperties) { url, error in
            Task { @MainActor in
                if let url {
                    generatedLink = url
                } else if let error {
                    generatedLink = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

private struct LinkParametersView: View {
    let parameters: [AnyHashable: Any]

    private var sortedEntries: [(key: String, value: String)] {
        parameters.map { (key: "\($0.key)", value: "\($0.value)") }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sortedEntries, id: \.key) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.value)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Link Data")
    }
}

private struct NetworkEventDetailView: View {
    let event: LogStore.NetworkEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Request Body")
                        .font(.headline)
                    Text(event.requestBody ?? "—")
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Response Body")
                        .font(.headline)
                    Text(event.responseBody ?? "—")
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(event.endpoint)
    }
}

#Preview {
    ContentView()
}
