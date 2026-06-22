//
//  SigningService.swift
//  Elite
//
//  Coordinates the end-to-end signing pipeline:
//   1. Validates the three input files + password.
//   2. Calls the bundled zsign engine (ZSignWrapper) to re-sign the IPA
//      with the user's .p12 certificate and .mobileprovision profile.
//   3. Starts a small embedded local HTTPS-friendly install flow that
//      serves a manifest.plist so iOS can install the freshly signed IPA
//      via the itms-services scheme (the same mechanism ESign uses).
//
//  Note: real on-device signing requires the zsign C++ sources to be
//  compiled into the app target (see Signing/zsign/README). This Swift
//  layer is the orchestration around that engine.
//

import Foundation
import SwiftUI

@MainActor
final class SigningService {
    static let shared = SigningService()
    private init() {}

    func sign(session: SigningSession) async {
        guard let ipa = session.ipaFile?.url,
              let p12 = session.p12File?.url,
              let prov = session.provisioningFile?.url else {
            session.status = .failed(message: "Please select the IPA, certificate and profile first.")
            return
        }

        session.reset()
        session.status = .preparing
        session.appendLog("Preparing workspace…")
        session.progress = 0.1

        // Output path for the signed IPA inside the app sandbox.
        let outDir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("signed", isDirectory: true)
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let signedIPA = outDir.appendingPathComponent("Elite-signed.ipa")
        try? FileManager.default.removeItem(at: signedIPA)

        session.status = .signing
        session.appendLog("Signing with zsign engine…")
        session.progress = 0.45

        let result = await Task.detached(priority: .userInitiated) {
            ZSignWrapper.sign(
                ipaPath: ipa.path,
                p12Path: p12.path,
                provisionPath: prov.path,
                password: session.p12Password,
                outputPath: signedIPA.path
            )
        }.value

        switch result {
        case .failure(let message):
            session.status = .failed(message: message)
            session.appendLog("Failed: \(message)")
            return
        case .success:
            session.appendLog("Signed IPA created at \(signedIPA.lastPathComponent)")
        }

        session.status = .packaging
        session.appendLog("Building install manifest…")
        session.progress = 0.8

        do {
            let installURL = try InstallServer.shared.start(servingIPA: signedIPA,
                                                            displayName: "Elite")
            session.progress = 1.0
            session.status = .readyToInstall(installURL: installURL)
            session.appendLog("Ready to install.")
        } catch {
            session.status = .failed(message: "Could not start install service: \(error.localizedDescription)")
        }
    }
}
