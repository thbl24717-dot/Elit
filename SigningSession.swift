//
//  SigningSession.swift
//  Elite
//
//  Observable object that stores the four user inputs required to
//  sign an IPA: the IPA file, the .p12 certificate, the provisioning
//  profile, and the certificate password. Also tracks signing state.
//

import Foundation
import SwiftUI

/// Represents the high level status of the signing pipeline.
enum SigningStatus: Equatable {
    case idle
    case preparing
    case signing
    case packaging
    case readyToInstall(installURL: URL)
    case failed(message: String)
}

/// A single picked input shown in the UI (filename + on-disk URL).
struct PickedFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    /// Human readable size, e.g. "12.4 MB".
    var displaySize: String {
        let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        let mb = Double(bytes ?? 0) / 1_048_576.0
        if mb >= 1 { return String(format: "%.1f MB", mb) }
        let kb = Double(bytes ?? 0) / 1024.0
        return String(format: "%.0f KB", kb)
    }
}

@MainActor
final class SigningSession: ObservableObject {
    // MARK: - User inputs
    @Published var ipaFile: PickedFile?
    @Published var p12File: PickedFile?
    @Published var provisioningFile: PickedFile?
    @Published var p12Password: String = ""

    // MARK: - Pipeline state
    @Published var status: SigningStatus = .idle
    @Published var progress: Double = 0          // 0...1 for progress ring
    @Published var logLines: [String] = []

    /// All four required inputs are present (password may be empty for
    /// some certificates, so we only require the three files).
    var isReadyToSign: Bool {
        ipaFile != nil && p12File != nil && provisioningFile != nil
    }

    /// How many of the required items are satisfied (for the header badge).
    var completedCount: Int {
        var c = 0
        if ipaFile != nil { c += 1 }
        if p12File != nil { c += 1 }
        if provisioningFile != nil { c += 1 }
        if !p12Password.isEmpty { c += 1 }
        return c
    }

    func appendLog(_ line: String) {
        logLines.append(line)
    }

    func reset() {
        status = .idle
        progress = 0
        logLines.removeAll()
    }
}
