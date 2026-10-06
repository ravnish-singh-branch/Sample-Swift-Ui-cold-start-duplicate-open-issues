//
//  NetworkLogger.swift
//  Sample Branch SDK SwiftUI
//

import Foundation

final class NetworkLogger: URLProtocol {
    private static let handledKey = "NetworkLoggerHandled"

    private var dataTask: URLSessionTask?
    private var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url,
              let host = url.host else { return false }
        guard host.contains("branch.io") else { return false }
        // Requests forwarded by `startLoading` below are marked as handled so this
        // protocol doesn't re-intercept its own proxied request and recurse forever.
        return property(forKey: handledKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        Self.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        let session = URLSession(configuration: .default)
        let eventId = UUID()
        let endpoint = Self.endpointName(for: request.url)
        let requestBody = request.httpBody.flatMap { String(data: $0, encoding: .utf8) }

        Task { @MainActor in
            LogStore.shared.beginNetworkEvent(id: eventId, endpoint: endpoint, requestBody: requestBody)
        }

        dataTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                Task { @MainActor in
                    LogStore.shared.completeNetworkEvent(id: eventId, responseBody: "Error: \(error.localizedDescription)")
                }
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let response = response as? HTTPURLResponse {
                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }
                Task { @MainActor in
                    let responseBody = "HTTP \(response.statusCode)" + (bodyString.map { "\n\($0)" } ?? "")
                    LogStore.shared.completeNetworkEvent(id: eventId, responseBody: responseBody)
                }
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }

            self.client?.urlProtocolDidFinishLoading(self)
        }

        dataTask?.resume()
    }

    private static func endpointName(for url: URL?) -> String {
        guard let path = url?.path, !path.isEmpty else { return url?.absoluteString ?? "unknown" }
        return path.hasPrefix("/") ? String(path.dropFirst()) : path
    }

    override func stopLoading() {
        dataTask?.cancel()
    }
}
