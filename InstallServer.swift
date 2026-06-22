//
//  InstallServer.swift
//  Elite
//
//  iOS installs ad-hoc / enterprise IPAs through the itms-services URL
//  scheme, which points to a manifest.plist that in turn points to the
//  IPA. Both must be reachable over HTTPS. This lightweight server hosts
//  the signed IPA and its manifest locally so the user can install the
//  freshly signed app directly on the same device — exactly the flow that
//  tools like ESign / Feather use.
//
//  Implementation note: this uses Network.framework to listen on a local
//  port. For a fully self-contained on-device install you normally point
//  iOS to an HTTPS endpoint; pairing this with a loopback TLS proxy (or a
//  short-lived tunnel) completes the chain. The manifest builder below is
//  production-shaped so swapping the transport is trivial.
//

import Foundation
import Network

final class InstallServer {
    static let shared = InstallServer()
    private init() {}

    private var listener: NWListener?
    private var ipaURL: URL?
    private var manifestData: Data?

    /// Starts serving the signed IPA and returns the itms-services URL
    /// that iOS should open to begin installation.
    func start(servingIPA ipa: URL, displayName: String) throws -> URL {
        self.ipaURL = ipa

        // Build the install manifest referencing the served IPA.
        let bundleID = Self.readBundleID(fromIPA: ipa) ?? "com.elite.signed"
        let port: UInt16 = 8443
        let host = "127.0.0.1"
        let ipaServeURL = "https://\(host):\(port)/app.ipa"
        let manifest = Self.makeManifest(ipaURL: ipaServeURL,
                                         bundleID: bundleID,
                                         title: displayName)
        self.manifestData = manifest.data(using: .utf8)

        try startListener(on: port)

        let manifestServeURL = "https://\(host):\(port)/manifest.plist"
        let encoded = manifestServeURL.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? manifestServeURL
        guard let url = URL(string: "itms-services://?action=download-manifest&url=\(encoded)") else {
            throw NSError(domain: "Elite", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Bad install URL"])
        }
        return url
    }

    // MARK: - Listener
    private func startListener(on port: UInt16) throws {
        let params = NWParameters.tcp
        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener?.newConnectionHandler = { [weak self] conn in
            self?.handle(conn)
        }
        listener?.start(queue: .global(qos: .userInitiated))
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self, let data, let request = String(data: data, encoding: .utf8) else {
                conn.cancel(); return
            }
            let path = Self.requestPath(request)
            if path.contains("manifest.plist"), let body = self.manifestData {
                self.send(conn, body: body, contentType: "application/xml")
            } else if path.contains("app.ipa"), let ipa = self.ipaURL,
                      let body = try? Data(contentsOf: ipa) {
                self.send(conn, body: body, contentType: "application/octet-stream")
            } else {
                self.send(conn, body: Data("Not found".utf8), contentType: "text/plain", status: "404 Not Found")
            }
        }
    }

    private func send(_ conn: NWConnection, body: Data, contentType: String, status: String = "200 OK") {
        var header = "HTTP/1.1 \(status)\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n\r\n"
        var payload = Data(header.utf8)
        payload.append(body)
        conn.send(content: payload, completion: .contentProcessed { _ in conn.cancel() })
    }

    // MARK: - Helpers
    private static func requestPath(_ request: String) -> String {
        let firstLine = request.split(separator: "\r\n").first ?? ""
        let parts = firstLine.split(separator: " ")
        return parts.count >= 2 ? String(parts[1]) : "/"
    }

    /// Builds an Apple OTA install manifest.plist.
    static func makeManifest(ipaURL: String, bundleID: String, title: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>items</key>
          <array>
            <dict>
              <key>assets</key>
              <array>
                <dict>
                  <key>kind</key><string>software-package</string>
                  <key>url</key><string>\(ipaURL)</string>
                </dict>
              </array>
              <key>metadata</key>
              <dict>
                <key>bundle-identifier</key><string>\(bundleID)</string>
                <key>bundle-version</key><string>1.0</string>
                <key>kind</key><string>software</string>
                <key>title</key><string>\(title)</string>
              </dict>
            </dict>
          </array>
        </dict>
        </plist>
        """
    }

    /// Best-effort read of CFBundleIdentifier from the IPA's Info.plist.
    static func readBundleID(fromIPA ipa: URL) -> String? {
        // A full implementation would unzip Payload/*.app/Info.plist.
        // Left as a hook; defaults are handled by the caller.
        return nil
    }
}
