import SwiftUI
import AuthenticationServices
import HaloShared

/// Sign in con Apple + fallback email OTP. Bridge ad `AuthService`.
struct SignInView: View {
  var onSignedIn: (Profile) -> Void = { _ in }

  @State private var showEmail: Bool = false
  @State private var email: String = ""
  @State private var otp: String = ""
  @State private var awaitingOTP: Bool = false
  @State private var errorMessage: String?
  @State private var isWorking: Bool = false

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 24) {
        Spacer()
        Text("Halo")
          .font(.system(size: 44, weight: .semibold, design: .rounded))
          .foregroundStyle(.white)
        Text("presenza, non performance")
          .font(.callout)
          .foregroundStyle(HaloTheme.textMuted)
        Spacer()

        SignInWithAppleButton(
          onRequest: { request in
            request.requestedScopes = [.fullName, .email]
          },
          onCompletion: { result in
            handleApple(result)
          }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 52)
        .padding(.horizontal, 24)

        Button {
          showEmail.toggle()
        } label: {
          Text(showEmail ? "Nascondi email" : "Entra con email")
            .foregroundStyle(HaloTheme.textMuted)
            .font(.system(size: 14, weight: .medium))
        }

        if showEmail {
          emailBlock
            .padding(.horizontal, 24)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }

        if let err = errorMessage {
          Text(err)
            .font(.system(size: 12))
            .foregroundStyle(MoodPalette.auraColor(.warm, l: 0.65))
            .padding(.horizontal, 24)
        }

        Spacer().frame(height: 24)
      }
      .animation(.easeInOut(duration: 0.25), value: showEmail)
      if isWorking {
        ProgressView().tint(.white)
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - email block

  @ViewBuilder
  private var emailBlock: some View {
    if !awaitingOTP {
      VStack(spacing: 10) {
        TextField("la tua email", text: $email)
          .textFieldStyle(.plain)
          .font(.system(size: 15))
          .foregroundStyle(.white)
          .keyboardType(.emailAddress)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .padding(.horizontal, 14).padding(.vertical, 12)
          .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
          .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))

        Button {
          Task { await requestOTP() }
        } label: {
          Text("Mandami il codice")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
      }
    } else {
      VStack(spacing: 10) {
        Text("ti abbiamo mandato un codice a \(email)")
          .font(.system(size: 12))
          .foregroundStyle(HaloTheme.textMuted)

        TextField("000000", text: $otp)
          .textFieldStyle(.plain)
          .font(.system(.title3, design: .monospaced))
          .kerning(8)
          .multilineTextAlignment(.center)
          .foregroundStyle(.white)
          .keyboardType(.numberPad)
          .textContentType(.oneTimeCode)
          .padding(.vertical, 12)
          .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
          .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
          .onChange(of: otp) { _, v in
            if v.count > 6 { otp = String(v.prefix(6)) }
          }

        Button {
          Task { await verifyOTP() }
        } label: {
          Text("Entra")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - actions

  private func handleApple(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .failure(let e):
      errorMessage = e.localizedDescription
    case .success(let auth):
      isWorking = true
      Task {
        defer { isWorking = false }
        do {
          let profile = try await AuthService.shared.signInWithApple(authorization: auth)
          onSignedIn(profile)
        } catch {
          errorMessage = "Sign in fallito. Riprova."
        }
      }
    }
  }

  private func requestOTP() async {
    isWorking = true; defer { isWorking = false }
    do {
      try await AuthService.shared.requestEmailOTP(email: email)
      awaitingOTP = true
      errorMessage = nil
    } catch {
      errorMessage = "Non riesco a mandare il codice. Controlla l'email."
    }
  }

  private func verifyOTP() async {
    isWorking = true; defer { isWorking = false }
    do {
      let profile = try await AuthService.shared.verifyEmailOTP(email: email, code: otp)
      onSignedIn(profile)
    } catch {
      errorMessage = "Codice non valido."
    }
  }
}
