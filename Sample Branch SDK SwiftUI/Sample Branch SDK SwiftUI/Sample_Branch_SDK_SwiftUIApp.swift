//
//  Sample_Branch_SDK_SwiftUIApp.swift
//  Sample Branch SDK SwiftUI
//
//  Created by Ravnish Singh on 09/09/26.
//

import SwiftUI
import BranchSDK

@main
struct Sample_Branch_SDK_SwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Branch.getInstance().handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    Branch.getInstance().continue(userActivity)
                }
        }
    }
}
