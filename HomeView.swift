//
//  HomeView.swift
//  Elite
//
//  The single main screen. From top to bottom it shows:
//   - A header with the Elite logo and a progress badge.
//   - Four option cards: IPA File, P12 Certificate File,
//     Provisioning Profile, and the P12 Certificate Password field.
//   - The "Elite it now" primary button.
//   - A medium-sized Telegram channel link pinned to the bottom-left.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SigningSession

    // Which picker (if any) is currently presented.
    @State private var activePicker: PickerKind?
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            // Soft accent bloom in the top corner for the iOS 26 look.
            Circle()
                .fill(Theme.accent)
                .frame(width: 320, height: 320)
                .blur(radius: 140)
                .opacity(0.45)
                .offset(x: 120, y: -260)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        optionsSection
                        passwordSection
                        EliteButton(status: session.status,
                                    enabled: session.isReadyToSign,
                                    action: handlePrimaryAction)
                            .padding(.top, 6)
                        statusSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 90)
                }

                telegramBar
            }
        }
        .sheet(item: Binding(
            get: { activePicker.map { PickerItem(kind: $0) } },
            set: { activePicker = $0?.kind }
        )) { item in
            DocumentPicker(kind: item.kind) { url in
                handlePicked(kind: item.kind, url: url)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: 54, height: 54)
                Image(systemName: "seal.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Elite")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("IPA Signer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(session.completedCount)/4")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .glassCard(cornerRadius: 14)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Options
    private var optionsSection: some View {
        VStack(spacing: 12) {
            OptionCard(
                icon: "app.badge",
                title: "IPA File",
                subtitle: "Select an .ipa application file",
                filledText: session.ipaFile.map { "\($0.name)  •  \($0.displaySize)" }
            ) { activePicker = .ipa }

            OptionCard(
                icon: "lock.shield.fill",
                title: "P12 Certificate File",
                subtitle: "Select your .p12 certificate",
                filledText: session.p12File.map { "\($0.name)  •  \($0.displaySize)" }
            ) { activePicker = .p12 }

            OptionCard(
                icon: "doc.badge.gearshape.fill",
                title: "Provisioning Profile",
                subtitle: "Select your .mobileprovision",
                filledText: session.provisioningFile.map { "\($0.name)  •  \($0.displaySize)" }
            ) { activePicker = .provisioning }
        }
    }

    // MARK: - Password
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.accent)
                        .frame(width: 46, height: 46)
                    Image(systemName: "key.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("P12 Certificate Password")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Enter the password for your certificate")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }

            HStack {
                Group {
                    if showPassword {
                        TextField("", text: $session.p12Password, prompt:
                            Text("Password").foregroundColor(Theme.textSecondary))
                    } else {
                        SecureField("", text: $session.p12Password, prompt:
                            Text("Password").foregroundColor(Theme.textSecondary))
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Theme.textPrimary)
                .font(.system(size: 16))

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 18)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - Status / log
    @ViewBuilder
    private var statusSection: some View {
        switch session.status {
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard(cornerRadius: 18)
        case .readyToInstall:
            Label("Signed successfully. Tap Install Now to add it to your device.",
                  systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.success)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard(cornerRadius: 18)
        default:
            EmptyView()
        }
    }

    // MARK: - Telegram bar (bottom-left, medium size)
    private var telegramBar: some View {
        HStack {
            Link(destination: URL(string: "https://t.me/EliteIPA")!) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("t.me/EliteIPA")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(Theme.telegram)
                )
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Actions
    private func handlePicked(kind: PickerKind, url: URL) {
        let file = PickedFile(url: url)
        switch kind {
        case .ipa:          session.ipaFile = file
        case .p12:          session.p12File = file
        case .provisioning: session.provisioningFile = file
        }
    }

    private func handlePrimaryAction() {
        if case .readyToInstall(let installURL) = session.status {
            UIApplication.shared.open(installURL)
            return
        }
        Task { await SigningService.shared.sign(session: session) }
    }
}

/// Small Identifiable wrapper so `.sheet(item:)` works with PickerKind.
private struct PickerItem: Identifiable {
    let kind: PickerKind
    var id: Int {
        switch kind {
        case .ipa: return 0
        case .p12: return 1
        case .provisioning: return 2
        }
    }
}
