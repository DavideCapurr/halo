import HaloShared
import SwiftUI

struct MemoryArchiveView: View {
  @Environment(\.dismiss) private var dismiss

  var hasPlus: Bool = false
  var onUpgrade: () -> Void = {}

  @State private var posts: [HaloPost] = []
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          if hasPlus {
            archiveBody
          } else {
            lockedBody
          }
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, SwarmHalo.s8)
      }
      .scrollIndicators(.hidden)
    }
    .presentationDetents([.large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
    .task {
      guard hasPlus else { return }
      await load()
    }
  }

  private var rail: some View {
    SwarmOperationalRail(title: "HALO / MEMORY", context: hasPlus ? "\(posts.count) fragments" : "plus", activation: .attention) {
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .swarmIconFrame()
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var archiveBody: some View {
    if isLoading {
      SwarmLoadingState(label: "memory")
    } else if let errorMessage {
      SwarmEmptyState(
        title: "memory chiusa.",
        message: errorMessage,
        activation: .attention
      )
    } else if posts.isEmpty {
      SwarmEmptyState(
        title: "nessun frammento.",
        message: "i Moment scaduti appariranno qui.",
        activation: .rest
      )
    } else {
      LazyVStack(spacing: SwarmHalo.s3) {
        ForEach(posts) { post in
          MemoryPostRow(post: post)
        }
      }
    }
  }

  private var lockedBody: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s4) {
      Text("i tuoi frammenti. non il feed.")
        .font(HaloType.serif(40, weight: .regular))
        .foregroundStyle(SwarmHalo.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("Memory riapre i post scaduti senza renderli pubblici.")
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 0) {
        SwarmMetricTile(label: "pubblico", value: "00", activation: .rest, active: false)
        Rectangle().fill(SwarmHalo.inkLine).frame(width: SwarmStroke.hairline, height: 28)
        SwarmMetricTile(label: "owner", value: "01", activation: .attention, active: true)
        Rectangle().fill(SwarmHalo.inkLine).frame(width: SwarmStroke.hairline, height: 28)
        SwarmMetricTile(label: "plus", value: "ON", activation: .attention, active: true)
      }
      .padding(.vertical, SwarmHalo.s3)
      .swarmSurface(.rail, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous))

      SwarmCommandButton(label: "attiva Halo Plus", icon: "sparkles", activation: .attention, isProminent: true) {
        onUpgrade()
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(.sheet, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
  }

  @MainActor
  private func load() async {
    isLoading = true
    defer { isLoading = false }

    do {
      posts = try await PostsService.shared.memoryArchive()
      errorMessage = nil
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco ad aprire Memory.")
    }
  }
}

private struct MemoryPostRow: View {
  let post: HaloPost

  var body: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      HStack(spacing: SwarmHalo.s3) {
        kindIcon
        VStack(alignment: .leading, spacing: 4) {
          Text(post.kind.rawValue)
            .haloEyebrow(SwarmActivationRole.attention.color, size: 8.5, tracking: 1.9)
          Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
            .font(HaloType.ui(12, weight: .regular))
            .foregroundStyle(SwarmHalo.inkMuted)
        }
        Spacer()
        Text(post.minTier.label.lowercased())
          .font(HaloType.mono(9, weight: .medium))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundStyle(SwarmHalo.inkMuted)
      }

      content

      if let caption = post.caption, !caption.isEmpty {
        Text(caption)
          .font(HaloType.ui(13, weight: .regular))
          .foregroundStyle(SwarmHalo.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(SwarmHalo.s4)
    .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
  }

  @ViewBuilder
  private var content: some View {
    switch post.kind {
    case .photo:
      StorageImageView(path: post.mediaPath, contentMode: .fill) {
        placeholder("photo")
      }
      .frame(maxWidth: .infinity)
      .aspectRatio(1.2, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous))
    case .audio:
      HStack(spacing: SwarmHalo.s3) {
        StorageAudioPlaybackButton(path: post.mediaPath, accentMood: post.mood ?? .chill, size: 44)
        Text("audio fragment")
          .font(HaloType.ui(13, weight: .semibold))
          .foregroundStyle(SwarmHalo.ink)
        Spacer()
      }
      .padding(SwarmHalo.s3)
      .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: .attention)
    case .text:
      if post.caption == nil || post.caption?.isEmpty == true {
        placeholder("text")
      }
    }
  }

  private var kindIcon: some View {
    Image(systemName: iconName)
      .font(HaloType.system(14, weight: .semibold))
      .foregroundStyle(SwarmActivationRole.attention.color)
      .swarmIconFrame(active: true, activation: .attention)
  }

  private var iconName: String {
    switch post.kind {
    case .photo: return "photo"
    case .text: return "text.alignleft"
    case .audio: return "waveform"
    }
  }

  private func placeholder(_ label: String) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .fill(SwarmHalo.inkWhisper)
      Text(label)
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 1.8)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 120)
  }
}
