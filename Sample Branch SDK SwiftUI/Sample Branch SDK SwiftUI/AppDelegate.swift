//
//  AppDelegate.swift
//  Sample Branch SDK SwiftUI
//

import UIKit
import BranchSDK

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        URLProtocol.registerClass(NetworkLogger.self)
        
        Branch.enableLogging(at: .verbose, withCallback: { message, logLevel, error in
            Task { @MainActor in
                LogStore.shared.appendLog(message)
            }
        })
        
        Branch.enableLogging()

        // Branch reads its `branch_key` from the app's Info.plist.
        Branch.getInstance().initSession(launchOptions: launchOptions) { params, error in
            Task { @MainActor in
                if let error {
                    LogStore.shared.appendLog("Branch session initialization failed: \(error.localizedDescription)")
                    return
                }
                LogStore.shared.appendLog("Branch session initialized with parameters: \(params ?? [:])")
                if let params {
                    LogStore.shared.setLinkParameters(params)
                }
            }
        }
        return true
    }
}
