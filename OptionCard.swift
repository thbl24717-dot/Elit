//
//  OptionCard.swift
//  Elite
//
//  A single tappable row in the iOS 26 style: leading SF Symbol in a
//  gradient capsule, title + subtitle, and a trailing state indicator
//  (chevron when empty, green check + filename when a file is picked).
//

import SwiftUI

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    /// When a file has been selected this carries its name + size.
    let filledText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.accent)
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(filledText ?? subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(filledText == nil ? Theme.textSecondary : Theme.success)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                if filledText == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.success)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}
