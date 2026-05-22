import SwiftUI
import AuthenticationServices
import CryptoKit
import HaloShared
import Security

/// Sign in con Apple + fallback email/password. Bridge ad `AuthService`.
struct SignInView: View {
  var onSignedIn: (Profile) -> Void = { _ in }

  @State private var showEmail: Bool = false
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var errorMessage: String?
  @State private var isWorking: Bool = false
  @State private var appleNonce: String = ""

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: 24) {
        Spacer()
        Text("Halo")
          .font(.system(size: 44, weight: .semibold, design: .rounded))
          .foregroundStyle(.white)
        Text("le tue persone. non un pubblico.")
          .font(.callout)
          .foregroundStyle(HaloTheme.textMuted)
        Spacer()

        SignInWithAppleButton(
          onRequest: { request in
            prepareAppleRequest(request)
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
        .haloContentGlass(in: RoundedRectangle(cornerRadius: 12))

      SecureField("password", text: $password)
        .textFieldStyle(.plain)
        .font(.system(size: 15))
        .foregroundStyle(.white)
        .textContentType(.password)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .haloContentGlass(in: RoundedRectangle(cornerRadius: 12))

      Button {
        Task { await signInWithEmail() }
      } label: {
        Text("Entra")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .haloGlass(in: RoundedRectangle(cornerRadius: 12), interactive: true)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - actions

  private func handleApple(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .failure(let e):
      errorMessage = e.localizedDescription
    case .success(let auth):
      isWorking = true
      let nonce = appleNonce
      Task {
        defer { isWorking = false }
        do {
          let profile = try await AuthService.shared.signInWithApple(authorization: auth, nonce: nonce)
          onSignedIn(profile)
        } catch {
          errorMessage = "Sign in fallito. Riprova."
        }
      }
    }
  }

  private func signInWithEmail() async {
    isWorking = true; defer { isWorking = false }
    do {
      let profile = try await AuthService.shared.signInWithEmail(email: email, password: password)
      onSignedIn(profile)
      errorMessage = nil
    } catch {
      errorMessage = message(for: error)
    }
  }

  private func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
    let nonce = randomNonce()
    appleNonce = nonce
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)
  }

  private func randomNonce(length: Int = 32) -> String {
    precondition(length > 0)
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    result.reserveCapacity(length)

    while result.count < length {
      var bytes = [UInt8](repeating: 0, count: 16)
      let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
      guard status == errSecSuccess else {
        fatalError("Impossibile generare un nonce sicuro.")
      }

      for byte in bytes {
        if result.count == length { break }
        if byte < charset.count {
          result.append(charset[Int(byte)])
        }
      }
    }

    return result
  }

  private func sha256(_ input: String) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func message(for error: Error) -> String {
    if let error = error as? AuthService.EmailSignInError,
       let description = error.errorDescription {
      return description
    }
    let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    return description.isEmpty ? "Non riesco ad accedere. Riprova." : description
  }
}
