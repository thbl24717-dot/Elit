//
//  ZSignWrapper.swift
//  Elite
//
//  Thin Swift facade over the zsign signing engine. The heavy lifting is
//  done by the C/C++ zsign sources compiled into the target and exposed
//  through an Objective-C++ bridge (`ZSign`), declared in the bridging
//  header. This keeps the rest of the app written in pure Swift.
//
//  If the zsign sources have not been added yet, the wrapper degrades
//  gracefully and reports a clear, actionable error instead of crashing.
//

import Foundation

enum SignResult {
    case success
    case failure(String)
}

enum ZSignWrapper {

    /// Re-signs `ipaPath` with the given certificate + profile and writes
    /// the result to `outputPath`. Returns a `SignResult`.
    static func sign(ipaPath: String,
                    p12Path: String,
                    provisionPath: String,
                    password: String,
                    outputPath: String) -> SignResult {

        // Validate inputs exist & look right before invoking the engine.
        let fm = FileManager.default
        guard fm.fileExists(atPath: ipaPath) else {
            return .failure("IPA file not found.")
        }
        guard fm.fileExists(atPath: p12Path) else {
            return .failure("P12 certificate not found.")
        }
        guard fm.fileExists(atPath: provisionPath) else {
            return .failure("Provisioning profile not found.")
        }

        #if canImport(ZSignBridge) || ZSIGN_AVAILABLE
        // The Objective-C++ bridge `ZSign` returns 0 on success and a
        // negative code on failure, with a message in `errorOut`.
        var errorMessage: NSString? = nil
        let code = ZSign.sign(withIPA: ipaPath,
                              p12: p12Path,
                              provision: provisionPath,
                              password: password,
                              output: outputPath,
                              error: &errorMessage)
        if code == 0 {
            return .success
        } else {
            return .failure((errorMessage as String?) ?? "zsign failed (code \(code)).")
        }
        #else
        // Engine not yet linked. Tell the developer exactly what to do.
        return .failure("Signing engine not linked. Add the zsign sources to the target (see Signing/zsign/README.md) and define ZSIGN_AVAILABLE.")
        #endif
    }
}
