import SwiftUI
import AuthenticationServices

/// Step 4: Sign in with Apple + email OTP.
struct SignInView: View {
  var onSignedIn: () -> Void = {}

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Text("Halo").font(.system(size: 44, weight: .semibold, design: .rounded)).foregroundStyle(.white)
      Text("presenza, non performance").font(.callout).foregroundStyle(HaloTheme.textMuted)
      Spacer()

      SignInWithAppleButton(
        onRequest: { request in
          request.requestedScopes = [.fullName, .email]
        },
        onCompletion: { _ in
          // TODO step 4: bridge a AuthService.shared.signInWithApple()
        }
      )
      .signInWithAppleButtonStyle(.white)
      .frame(height: 52)
      .padding(.horizontal, 24)

      Button("Entra con email") {
        // TODO step 4: OTP flow
      }
      .foregroundStyle(HaloTheme.textMuted)
      .padding(.bottom, 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(HaloTheme.background)
  }
}
