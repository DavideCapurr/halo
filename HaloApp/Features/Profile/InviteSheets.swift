import SwiftUI
import UIKit
import HaloShared

struct InnerInviteSheet: View {
  @Environment(\.dismiss) private var dismiss

  let person: HaloPersonNode

  @State private var message: String = ""
  @State private var invite: HaloInvite?
  @State private var isCreating: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 0) {
      topRail
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          hero
          if let invite, let url = invite.deepLinkURL {
            createdState(url)
          } else {
            messageField
            if let errorMessage {
              errorText(errorMessage)
            }
          }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
      }
      .scrollIndicators(.hidden)

      footer
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
    .background(haloSheetBackground())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var topRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("INNER / INVITE")
          .haloEyebrow(SwarmActivationRole.connected.color, size: 8.5, tracking: 2.3)
        Text(person.name.lowercased())
          .font(HaloType.serif(24, weight: .regular))
          .foregroundStyle(HaloInk.cream)
      }
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 30, height: 30)
          .background(Circle().fill(SwarmHalo.inkWhisper))
          .overlay(Circle().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
  }

  private var hero: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 12) {
        PortraitView(personId: person.id, size: 44, grayscale: true)
          .background(HaloTheme.portraitBacking, in: Circle())
          .overlay(Circle().strokeBorder(SwarmActivationRole.connected.stroke, lineWidth: 0.8))
        VStack(alignment: .leading, spacing: 2) {
          Text("stai aprendo l'Inner.")
            .font(HaloType.serif(22, weight: .regular))
            .foregroundStyle(HaloInk.cream)
          Text("@\(person.handle) ricevera un link privato.")
            .font(HaloType.ui(12, weight: .regular))
            .foregroundStyle(HaloInk.creamMute)
        }
      }
      Text("copy: ti ho messo nel mio Inner.")
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
    }
    .padding(14)
    .swarmSurface(
      .panel,
      in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous),
      activation: .connected
    )
  }

  private var messageField: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("messaggio")
      TextField("ti ho messo nel mio Inner.", text: $message, axis: .vertical)
        .textFieldStyle(.plain)
        .font(HaloType.serif(17, weight: .regular))
        .foregroundStyle(HaloInk.cream)
        .lineLimit(3, reservesSpace: true)
        .onChange(of: message) { _, newValue in
          if newValue.count > 160 { message = String(newValue.prefix(160)) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))
      Text("\(message.count)/160")
        .font(HaloType.mono(10, weight: .medium))
        .foregroundStyle(HaloInk.creamMute)
    }
  }

  private func createdState(_ url: URL) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      SwarmEmptyState(
        title: "invite pronto.",
        message: "manda il link a @\(person.handle). scade tra 14 giorni.",
        activation: .connected
      )
      Text(url.absoluteString)
        .font(HaloType.mono(11, weight: .medium))
        .foregroundStyle(HaloInk.creamLow)
        .lineLimit(3)
        .textSelection(.enabled)
        .padding(12)
        .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))
    }
  }

  private var footer: some View {
    HStack {
      if let invite, let url = invite.deepLinkURL {
        Button("copia") {
          UIPasteboard.general.string = url.absoluteString
          HapticEngine.selection()
        }
        .font(HaloType.ui(14, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(HaloInk.creamMute)
        Spacer()
        ShareLink(item: url) {
          Label("condividi", systemImage: "square.and.arrow.up")
            .font(HaloType.ui(15, weight: .semibold))
            .foregroundStyle(HaloInk.cream)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .swarmSurface(.control, in: Capsule(), activation: .connected)
        }
      } else {
        Button("annulla") { dismiss() }
          .font(HaloType.ui(14, weight: .medium))
          .buttonStyle(.plain)
          .foregroundStyle(HaloInk.creamMute)
        Spacer()
        Button {
          Task { await createInvite() }
        } label: {
          Text(isCreating ? "creo..." : "crea invite")
            .font(HaloType.ui(15, weight: .semibold))
            .foregroundStyle(SwarmHalo.background)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(SwarmActivationRole.connected.color, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
      }
    }
  }

  private func sectionHeader(_ text: String) -> some View {
    HStack(spacing: 8) {
      Text(text)
        .haloEyebrow(HaloInk.creamMute, size: 8.5, tracking: 2.0)
      Rectangle()
        .fill(HaloInk.creamLine)
        .frame(height: 0.5)
    }
  }

  private func errorText(_ message: String) -> some View {
    Text(message)
      .font(HaloType.ui(12, weight: .regular))
      .foregroundStyle(SwarmHalo.launchAmber)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .swarmSurface(
        .panel,
        in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous),
        activation: .attention
      )
  }

  @MainActor
  private func createInvite() async {
    guard !isCreating else { return }
    guard let userId = UUID(uuidString: person.id) else {
      errorMessage = "Questo profilo non puo ricevere invite."
      return
    }

    isCreating = true
    errorMessage = nil
    defer { isCreating = false }

    do {
      invite = try await InvitesService.shared.createInnerInvite(
        to: userId,
        message: message.isEmpty ? "ti ho messo nel mio Inner." : message
      )
    } catch {
      errorMessage = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a creare l'invite. Riprova."
      )
    }
  }
}

struct InviteAcceptSheet: View {
  @Environment(\.dismiss) private var dismiss

  let token: String

  @State private var invite: HaloInvite?
  @State private var inviter: Profile?
  @State private var isLoading: Bool = true
  @State private var isAccepting: Bool = false
  @State private var didAccept: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 0) {
      topRail
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)

      VStack(spacing: 14) {
        if isLoading {
          SwarmLoadingState(label: "carico invite")
        } else if didAccept {
          SwarmEmptyState(
            title: "Inner confermato.",
            message: "ora puoi chiudere questa finestra.",
            activation: .connected
          )
        } else if let errorMessage {
          SwarmEmptyState(
            title: "invite non valido.",
            message: errorMessage,
            activation: .attention
          )
        } else if let invite, let inviter {
          inviteBody(invite: invite, inviter: inviter)
        }
      }
      .padding(.horizontal, 18)
      .frame(maxHeight: .infinity, alignment: .top)

      footer
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
    .background(haloSheetBackground())
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
    .task {
      await load()
    }
  }

  private var topRail: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text("HALO / INVITE")
          .haloEyebrow(SwarmActivationRole.connected.color, size: 8.5, tracking: 2.3)
        Text("inner request")
          .font(HaloType.serif(24, weight: .regular))
          .foregroundStyle(HaloInk.cream)
      }
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(HaloInk.creamLow)
          .frame(width: 30, height: 30)
          .background(Circle().fill(SwarmHalo.inkWhisper))
          .overlay(Circle().strokeBorder(HaloInk.creamLine, lineWidth: 0.5))
      }
      .buttonStyle(.plain)
    }
  }

  private func inviteBody(invite: HaloInvite, inviter: Profile) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        PortraitView(personId: inviter.id.uuidString, size: 52, grayscale: true)
          .background(HaloTheme.portraitBacking, in: Circle())
          .overlay(Circle().strokeBorder(SwarmActivationRole.connected.stroke, lineWidth: 0.8))
        VStack(alignment: .leading, spacing: 3) {
          Text("\(inviter.displayName) ti ha messo nel suo Inner.")
            .font(HaloType.serif(24, weight: .regular))
            .foregroundStyle(HaloInk.cream)
            .fixedSize(horizontal: false, vertical: true)
          Text("@\(inviter.handle)")
            .font(HaloType.ui(12, weight: .regular))
            .foregroundStyle(HaloInk.creamMute)
        }
      }

      if let message = invite.message, !message.isEmpty {
        Text(message)
          .font(HaloType.serif(17, weight: .regular))
          .foregroundStyle(HaloInk.creamLow)
          .padding(14)
          .haloContentGlass(in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput))
      }
    }
    .padding(14)
    .swarmSurface(
      .panel,
      in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous),
      activation: .connected
    )
  }

  private var footer: some View {
    HStack {
      Button("chiudi") { dismiss() }
        .font(HaloType.ui(14, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(HaloInk.creamMute)
      Spacer()
      if !didAccept && errorMessage == nil && !isLoading {
        Button {
          Task { await accept() }
        } label: {
          Text(isAccepting ? "confermo..." : "conferma Inner")
            .font(HaloType.ui(15, weight: .semibold))
            .foregroundStyle(SwarmHalo.background)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(SwarmActivationRole.connected.color, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isAccepting)
      }
    }
  }

  @MainActor
  private func load() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let invite = try await InvitesService.shared.invite(token: token)
      self.invite = invite
      self.inviter = try await InvitesService.shared.inviterProfile(for: invite)
      if !invite.isPending {
        errorMessage = "Questo invite e scaduto o gia stato usato."
      }
    } catch {
      errorMessage = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a leggere questo invite."
      )
    }
  }

  @MainActor
  private func accept() async {
    guard !isAccepting else { return }
    isAccepting = true
    errorMessage = nil
    defer { isAccepting = false }

    do {
      invite = try await InvitesService.shared.accept(token: token)
      didAccept = true
    } catch {
      errorMessage = SupabaseErrorMessage.describe(
        error,
        fallback: "Non riesco a confermare questo invite."
      )
    }
  }
}
