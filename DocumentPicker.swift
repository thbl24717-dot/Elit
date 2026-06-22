//
//  DocumentPicker.swift
//  Elite
//
//  UIViewControllerRepresentable wrapper around UIDocumentPickerViewController.
//  It lets us restrict the picker to specific Uniform Type Identifiers so that
//  the "IPA File" option only shows .ipa files, while the certificate and
//  provisioning options accept their own types.
//

import SwiftUI
import UniformTypeIdentifiers

/// Picker kinds map to the four import buttons.
enum PickerKind {
    case ipa
    case p12
    case provisioning

    /// Allowed content types per kind.
    var contentTypes: [UTType] {
        switch self {
        case .ipa:
            // .ipa is not a system-declared UTType, so we build it from the
            // filename extension. We also fall back to a generic archive so
            // the file remains selectable on every iOS version.
            let ipa = UTType(filenameExtension: "ipa") ?? .data
            return [ipa]
        case .p12:
            let p12 = UTType(filenameExtension: "p12") ?? .data
            let pfx = UTType(filenameExtension: "pfx") ?? .data
            return [p12, pfx, .pkcs12].compactMap { $0 }
        case .provisioning:
            let mp = UTType(filenameExtension: "mobileprovision") ?? .data
            let prov = UTType(filenameExtension: "provisionprofile") ?? .data
            return [mp, prov]
        }
    }
}

private extension UTType {
    /// PKCS#12 system type when available.
    static var pkcs12: UTType? { UTType("com.rsa.pkcs-12") }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let kind: PickerKind
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: kind.contentTypes,
            asCopy: true // copy into the app sandbox so we can read it freely
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // Move the copied file into a stable Documents location.
            let dest = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: url, to: dest)
                onPick(dest)
            } catch {
                onPick(url)
            }
        }
    }
}
