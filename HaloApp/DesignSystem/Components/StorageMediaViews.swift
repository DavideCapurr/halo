import AVFoundation
import HaloShared
import SwiftUI

struct StorageImageView<Placeholder: View>: View {
  let path: String?
  var bucket: String = StorageService.mediaBucket
  var contentMode: ContentMode = .fill
  private let placeholder: () -> Placeholder

  @State private var signedURL: URL?

  init(
    path: String?,
    bucket: String = StorageService.mediaBucket,
    contentMode: ContentMode = .fill,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.path = path
    self.bucket = bucket
    self.contentMode = contentMode
    self.placeholder = placeholder
  }

  var body: some View {
    Group {
      if let signedURL {
        AsyncImage(
          url: signedURL,
          transaction: Transaction(animation: .easeInOut(duration: 0.2))
        ) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: contentMode)
          case .failure:
            placeholder()
          case .empty:
            placeholder()
              .overlay {
                ProgressView()
                  .tint(HaloInk.creamLow)
              }
          @unknown default:
            placeholder()
          }
        }
      } else {
        placeholder()
      }
    }
    .task(id: storageKey) {
      await resolveSignedURL()
    }
  }

  private var storageKey: String {
    "\(bucket):\(path ?? "")"
  }

  @MainActor
  private func resolveSignedURL() async {
    signedURL = nil
    guard let path, !path.isEmpty else { return }

    do {
      signedURL = try await StorageService.shared.signedURL(
        forPath: path,
        bucket: bucket,
        ttlSeconds: 3600
      )
    } catch {
      signedURL = nil
    }
  }
}

struct StorageAudioPlaybackButton: View {
  let path: String?
  let accentMood: Mood
  var size: CGFloat = 36
  var iconSize: CGFloat = 12
  var foregroundColor: Color = SwarmHalo.background
  var fillOpacity: Double = 1
  var showsBorder: Bool = false

  @State private var signedURL: URL?
  @State private var player: AVPlayer?
  @State private var playerURL: URL?
  @State private var isPlaying: Bool = false
  @State private var playbackTask: Task<Void, Never>?

  var body: some View {
    Button {
      togglePlayback()
    } label: {
      ZStack {
        Circle()
          .fill(MoodPalette.auraColor(accentMood, l: 0.70).opacity(fillOpacity))
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(HaloType.system(iconSize, weight: .bold))
          .foregroundStyle(foregroundColor.opacity(signedURL == nil ? 0.42 : 1))
          .offset(x: isPlaying ? 0 : size * 0.025)
      }
      .frame(width: size, height: size)
      .overlay {
        if showsBorder {
          Circle()
            .strokeBorder(MoodPalette.auraColor(accentMood, l: 0.74).opacity(0.58), lineWidth: 0.8)
        }
      }
      .shadow(color: isPlaying ? MoodPalette.auraRing(accentMood, alpha: 0.42) : .clear, radius: 14)
    }
    .buttonStyle(.plain)
    .disabled(signedURL == nil)
    .accessibilityLabel(isPlaying ? "Pausa audio" : "Riproduci audio")
    .task(id: storageKey) {
      await resolveSignedURL()
    }
    .onDisappear {
      stopPlayback(reset: false)
    }
  }

  private var storageKey: String {
    "\(StorageService.mediaBucket):\(path ?? "")"
  }

  @MainActor
  private func resolveSignedURL() async {
    stopPlayback(reset: false)
    signedURL = nil
    player = nil
    playerURL = nil

    guard let path, !path.isEmpty else { return }
    do {
      signedURL = try await StorageService.shared.signedURL(
        forPath: path,
        bucket: StorageService.mediaBucket,
        ttlSeconds: 3600
      )
    } catch {
      signedURL = nil
    }
  }

  @MainActor
  private func togglePlayback() {
    guard let signedURL else { return }

    if isPlaying {
      stopPlayback(reset: false)
      return
    }

    if player == nil || playerURL != signedURL {
      player = AVPlayer(url: signedURL)
      playerURL = signedURL
    }

    if let duration = player?.currentItem?.duration.seconds,
       duration.isFinite,
       duration > 0,
       (player?.currentTime().seconds ?? 0) >= duration - 0.05 {
      player?.seek(to: .zero)
    }

    player?.play()
    isPlaying = true
    monitorPlayback()
  }

  @MainActor
  private func monitorPlayback() {
    playbackTask?.cancel()
    playbackTask = Task { @MainActor in
      while !Task.isCancelled, isPlaying {
        try? await Task.sleep(nanoseconds: 200_000_000)
        guard let player else {
          isPlaying = false
          return
        }

        let duration = player.currentItem?.duration.seconds ?? 0
        guard duration.isFinite, duration > 0 else { continue }

        if player.currentTime().seconds >= duration - 0.05 {
          stopPlayback(reset: true)
          return
        }
      }
    }
  }

  @MainActor
  private func stopPlayback(reset: Bool) {
    playbackTask?.cancel()
    playbackTask = nil
    player?.pause()
    if reset {
      player?.seek(to: .zero)
    }
    isPlaying = false
  }
}
