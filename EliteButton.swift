//
//  EliteButton.swift
//  Elite
//
//  The big primary "Elite it now" action button. It reflects the current
//  signing status (idle / working / ready) and is disabled until all
//  required inputs are present.
//

import SwiftUI

struct EliteButton: View {
    let status: SigningStatus
    let enabled: Bool
    let action: () -> Void

    private var label: String {
        switch status {
        case .idle, .failed:        return "Elite it now"
        case .preparing:            return "Preparing…"
        case .signing:              return "Signing…"
        case .packaging:            return "Packaging…"
        case .readyToInstall:       return "Install Now"
        }
    }

    private var icon: String {
        switch status {
        case .readyToInstall:       return "arrow.down.app.fill"
        case .idle, .failed:        return "bolt.fill"
        default:                    return "hourglass"
        }
    }

    private var isWorking: Bool {
        switch status {
        case .preparing, .signing, .packaging: return true
        default: return false
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isWorking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.accent)
                    .opacity(enabled ? 1 : 0.35)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.45, green: 0.4, blue: 1).opacity(enabled ? 0.45 : 0),
                    radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isWorking)
    }
}
