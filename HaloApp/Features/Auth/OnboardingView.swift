import SwiftUI
import PhotosUI
import HaloShared

/// Onboarding: scegli handle (univoco) + display name + avatar.
/// Salva il profilo via `ProfilesService.update`. Se l'utente sceglie un avatar,
/// fa upload via `StorageService.uploadAvatar` e salva il path.
struct OnboardingView: View {
  let initialProfile: Profile
  var onDone: (Profile) -> Void = { _ in }

  @State private var handle: String
  @State private var displayName: String
  @State private var photo: PhotosPickerItem?
  @State private var avatarData: Data?
  @State private var isWorking: Bool = false
  @State private var errorMessage: String?

  init(initialProfile: Profile, onDone: @escaping (Profile) -> Void = { _ in }) {
    self.initialProfile = initialProfile
    self.onDone = onDone
    self._handle = State(initialValue: initialProfile.handle.hasPrefix("halo_") ? "" : initialProfile.handle)
    self._displayName = State(initialValue: initialProfile.displayName == "Halo" ? "" : initialProfile.displayName)
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(spacing: 22) {
          eyebrow
          avatarPicker
          handleField
          nameField
          if let err = errorMessage {
            Text(err)
              .font(.system(size: 12))
              .foregroundStyle(MoodPalette.auraColor(.warm, l: 0.65))
          }
          Spacer().frame(height: 12)
          ctaButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 40)
      }
      if isWorking {
        ProgressView().tint(.white)
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - subviews

  private var eyebrow: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("BENVENUTO IN HALO")
        .font(.system(size: 11, weight: .semibold))
        .kerning(1.4)
        .foregroundStyle(HaloTheme.textCaption)
      Text("come ti chiami qui dentro?")
        .font(.system(size: 26, weight: .semibold))
        .kerning(-0.6)
        .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var avatarPicker: some View {
    PhotosPicker(selection: $photo, matching: .images, photoLibrary: .shared()) {
      ZStack {
        Circle()
          .fill(MoodPalette.auraColor(.chill, l: 0.55))
          .frame(width: 110, height: 110)
        if let data = avatarData, let img = UIImage(data: data) {
          Image(uiImage: img).resizable().scaledToFill()
            .frame(width: 110, height: 110)
            .clipShape(Circle())
        } else {
          PortraitView(personId: handle.isEmpty ? "halo|self" : handle, size: 100)
            .background(HaloTheme.portraitBacking, in: Circle())
        }
        Image(systemName: "camera.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.black)
          .frame(width: 32, height: 32)
          .background(Color.white, in: Circle())
          .overlay(Circle().strokeBorder(Color.black.opacity(0.4), lineWidth: 2))
          .offset(x: 38, y: 38)
      }
    }
    .frame(maxWidth: .infinity)
    .onChange(of: photo) { _, newItem in
      Task {
        if let data = try? await newItem?.loadTransferable(type: Data.self) {
          avatarData = data
        }
      }
    }
  }

  private var handleField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("HANDLE")
        .font(.system(size: 10, weight: .semibold))
        .kerning(1)
        .foregroundStyle(HaloTheme.textCaption)
      HStack(spacing: 4) {
        Text("@").foregroundStyle(.white.opacity(0.55))
        TextField("handle", text: $handle)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .foregroundStyle(.white)
          .onChange(of: handle) { _, v in
            let cleaned = v.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
            handle = String(cleaned.prefix(24))
          }
      }
      .padding(.horizontal, 14).padding(.vertical, 12)
      .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
      .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
    }
  }

  private var nameField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("DISPLAY NAME")
        .font(.system(size: 10, weight: .semibold))
        .kerning(1)
        .foregroundStyle(HaloTheme.textCaption)
      TextField("come vuoi essere chiamato", text: $displayName)
        .foregroundStyle(.white)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HaloTheme.hairline, lineWidth: 0.5))
    }
  }

  private var ctaButton: some View {
    let disabled = handle.isEmpty || displayName.isEmpty
    return Button {
      Task { await save() }
    } label: {
      Text("Inizia")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
          LinearGradient(
            colors: [MoodPalette.auraColor(.warm, l: 0.78), MoodPalette.auraColor(.warm, l: 0.55)],
            startPoint: .top, endPoint: .bottom
          ),
          in: RoundedRectangle(cornerRadius: 14)
        )
        .shadow(color: MoodPalette.auraRing(.warm, alpha: 0.4), radius: 12, y: 4)
    }
    .buttonStyle(.plain)
    .disabled(disabled)
    .opacity(disabled ? 0.4 : 1)
  }

  // MARK: - save

  @MainActor
  private func save() async {
    isWorking = true; defer { isWorking = false }
    do {
      var avatarPath: String? = initialProfile.avatarPath
      if let data = avatarData {
        avatarPath = try await StorageService.shared.uploadAvatar(data: data, contentType: "image/jpeg")
      }
      var profile = initialProfile
      profile.handle = handle
      profile.displayName = displayName
      profile.avatarPath = avatarPath
      try await ProfilesService.shared.update(profile)
      onDone(profile)
    } catch {
      errorMessage = "Non riesco a salvare il profilo. Riprova."
    }
  }
}
