//
//  LogStore.swift
//  Sample Branch SDK SwiftUI
//

import Foundation
import Observation

@MainActor
@Observable
final class LogStore {
    static let shared = LogStore()

    struct NetworkEvent: Identifiable {
        let id: UUID
        let endpoint: String
        var requestBody: String?
        var responseBody: String?
    }

    var networkEvents: [NetworkEvent] = []
    var linkParameters: [AnyHashable: Any]?

    private init() {}

    func setLinkParameters(_ params: [AnyHashable: Any]) {
        linkParameters = params
    }

    func beginNetworkEvent(id: UUID, endpoint: String, requestBody: String?) {
        networkEvents.append(NetworkEvent(id: id, endpoint: endpoint, requestBody: requestBody, responseBody: nil))
    }

    func completeNetworkEvent(id: UUID, responseBody: String?) {
        guard let index = networkEvents.firstIndex(where: { $0.id == id }) else { return }
        networkEvents[index].responseBody = responseBody
    }

    func appendLog(_ text: String) {
        print(text)
    }

    func clear() {
        networkEvents.removeAll()
    }
}
