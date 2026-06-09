import AVFoundation
import CoreImage.CIFilterBuiltins
import HaloShared
import SwiftUI
import UIKit

struct EventRingView: View {
  private static let orientationJoinToken = "bocconi-orientation-week"
  private static let orientationTitle = "Orientation week / Bocconi"

  @Environment(\.dismiss) private var dismiss

  private let initialRingId: UUID?
  private let initialJoinToken: String?

  @State private var rings: [HaloRing] = []
  @State private var selectedRing: HaloRing?
  @State private var members: [RingMember] = []
  @State private var checkIns: [EventCheckIn] = []
  @State private var tokenInput: String
  @State private var showScanner = false
  @State private var showCreate = false
  @State private var isLoading = false
  @State private var isJoining = false
  @State private var isCheckingIn = false
  @State private var isCreatingOrientation = false
  @State private var didHandleInitialToken = false
  @State private var statusMessage: String?
  @State private var errorMessage: String?

  init(ringId: UUID? = nil, joinToken: String? = nil) {
    self.initialRingId = ringId
    self.initialJoinToken = joinToken
    _tokenInput = State(initialValue: joinToken ?? "")
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          rail
          joinPanel
          selectedPanel
          eventList
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
      await load()
      await handleInitialTokenIfNeeded()
    }
    .sheet(isPresented: $showScanner) {
      QRScanSheet { payload in
        Task { await join(payload) }
      }
    }
    .sheet(isPresented: $showCreate) {
      RingCreateSheet(kind: .event) { ring in
        selectedRing = ring
        Task { await load() }
      }
    }
  }

  private var rail: some View {
    SwarmOperationalRail(
      title: "HALO / EVENT RING",
      context: selectedRing?.title ?? "qr live",
      activation: .attention
    ) {
      HStack(spacing: SwarmHalo.s2) {
        Button(action: { showCreate = true }) {
          Image(systemName: "plus")
            .font(HaloType.system(12, weight: .semibold))
            .foregroundStyle(SwarmActivationRole.attention.color)
            .swarmIconFrame(active: true, activation: .attention)
        }
        .buttonStyle(.plain)

        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(HaloType.system(12, weight: .semibold))
            .foregroundStyle(SwarmHalo.inkSecondary)
            .swarmIconFrame()
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var joinPanel: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      sectionHeader("join")
      HStack(spacing: SwarmHalo.s2) {
        TextField("token", text: $tokenInput)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .font(HaloType.mono(12, weight: .medium))
          .foregroundStyle(SwarmHalo.ink)
          .padding(.horizontal, SwarmHalo.s3)
          .padding(.vertical, 11)
          .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: .attention)

        Button(action: { showScanner = true }) {
          Image(systemName: "qrcode.viewfinder")
            .font(HaloType.system(16, weight: .semibold))
            .foregroundStyle(SwarmActivationRole.attention.color)
            .swarmIconFrame(active: true, activation: .attention)
        }
        .buttonStyle(.plain)

        Button {
          Task { await join(tokenInput) }
        } label: {
          Image(systemName: isJoining ? "clock" : "arrow.down.circle")
            .font(HaloType.system(16, weight: .semibold))
            .foregroundStyle(SwarmHalo.background)
            .frame(width: 36, height: 36)
            .background(SwarmActivationRole.attention.color, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isJoining)
        .opacity(isJoining ? 0.55 : 1)
      }

      orientationQuickStart
      feedbackLine
    }
    .padding(SwarmHalo.s4)
    .swarmPanel()
  }

  private var orientationQuickStart: some View {
    HStack(alignment: .center, spacing: SwarmHalo.s3) {
      SwarmCommandButton(
        label: isCreatingOrientation ? "preparo QR" : "orientation week",
        icon: "qrcode",
        activation: .attention
      ) {
        Task { await createOrientationWeekRing() }
      }
      .disabled(isCreatingOrientation)
      .opacity(isCreatingOrientation ? 0.56 : 1)

      Text("token: \(orientationTokenLabel)")
        .font(HaloType.mono(10, weight: .medium))
        .foregroundStyle(SwarmHalo.inkMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }
  }

  @ViewBuilder
  private var feedbackLine: some View {
    if let errorMessage {
      Text(errorMessage)
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(SwarmActivationRole.attention.color)
        .fixedSize(horizontal: false, vertical: true)
    } else if let statusMessage {
      Text(statusMessage)
        .font(HaloType.ui(12, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private var selectedPanel: some View {
    if isLoading && selectedRing == nil {
      SwarmLoadingState(label: "event rings")
    } else if let ring = selectedRing {
      VStack(alignment: .leading, spacing: SwarmHalo.s4) {
        HStack(alignment: .top, spacing: SwarmHalo.s3) {
          RingKindBadge(kind: ring.kind)
          VStack(alignment: .leading, spacing: SwarmHalo.s2) {
            Text(ring.title.lowercased())
              .font(HaloType.serif(36, weight: .regular))
              .foregroundStyle(SwarmHalo.ink)
              .fixedSize(horizontal: false, vertical: true)
            if let subtitle = ring.subtitle {
              Text(subtitle)
                .font(HaloType.ui(13, weight: .regular))
                .foregroundStyle(SwarmHalo.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          Spacer()
        }

        RingScheduleRow(ring: ring)

        HStack(spacing: 0) {
          SwarmMetricTile(label: "members", value: twoDigits(members.count), activation: .connected, active: !members.isEmpty)
          Rectangle().fill(SwarmHalo.inkLine).frame(width: SwarmStroke.hairline, height: 28)
          SwarmMetricTile(label: "check-in", value: twoDigits(checkIns.count), activation: .attention, active: !checkIns.isEmpty)
          Rectangle().fill(SwarmHalo.inkLine).frame(width: SwarmStroke.hairline, height: 28)
          SwarmMetricTile(label: "public", value: ring.isPublic ? "ON" : "OFF", activation: .rest, active: ring.isPublic)
        }
        .padding(.vertical, SwarmHalo.s3)
        .swarmSurface(.rail, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous))

        HStack(spacing: SwarmHalo.s3) {
          SwarmCommandButton(
            label: isCheckingIn ? "check-in" : "check-in",
            icon: "checkmark.seal",
            activation: .attention,
            isProminent: true
          ) {
            Task { await checkIn() }
          }
          .disabled(isCheckingIn)
          .opacity(isCheckingIn ? 0.56 : 1)

          if let url = ring.joinURL {
            ShareLink(item: url) {
              Label("share", systemImage: "square.and.arrow.up")
                .font(HaloType.ui(13, weight: .semibold))
                .foregroundStyle(SwarmHalo.ink)
                .padding(.horizontal, SwarmHalo.s4)
                .padding(.vertical, 10)
                .background(SwarmActivationRole.rest.fill, in: Capsule())
                .overlay(Capsule().strokeBorder(SwarmActivationRole.rest.stroke, lineWidth: SwarmStroke.standard))
            }
          }

          Button {
            UIPasteboard.general.string = ring.joinToken
            statusMessage = "token copiato."
          } label: {
            Image(systemName: "doc.on.doc")
              .font(HaloType.system(14, weight: .semibold))
              .foregroundStyle(SwarmHalo.ink)
              .swarmIconFrame()
          }
          .buttonStyle(.plain)
        }

        if let payload = ring.joinURL?.absoluteString {
          HStack(alignment: .center, spacing: SwarmHalo.s4) {
            RingQRCode(payload: payload)
              .frame(width: 126, height: 126)
            VStack(alignment: .leading, spacing: SwarmHalo.s2) {
              Text("QR")
                .haloEyebrow(SwarmActivationRole.attention.color, size: 8.5, tracking: 2.0)
              Text(ring.joinToken)
                .font(HaloType.mono(11, weight: .medium))
                .foregroundStyle(SwarmHalo.inkSecondary)
                .lineLimit(3)
                .textSelection(.enabled)
            }
            Spacer()
          }
          .padding(SwarmHalo.s3)
          .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
        }
      }
      .padding(SwarmHalo.s4)
      .swarmSurface(.sheet, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .attention)
    } else {
      SwarmEmptyState(
        title: "nessun evento.",
        message: "crea il primo Event Ring.",
        activation: .attention
      )
    }
  }

  private var eventList: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      sectionHeader("live")
      if rings.isEmpty && !isLoading {
        EmptyView()
      } else {
        ForEach(rings) { ring in
          Button {
            selectedRing = ring
            Task { await loadSelectedMetadata() }
          } label: {
            RingListRow(
              ring: ring,
              isSelected: selectedRing?.id == ring.id,
              accessory: ring.isPublic ? "public" : "token"
            )
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func sectionHeader(_ text: String) -> some View {
    HStack(spacing: SwarmHalo.s2) {
      Text(text)
        .haloEyebrow(SwarmHalo.inkMuted, size: 8.5, tracking: 2.0)
      Rectangle()
        .fill(SwarmHalo.inkLine)
        .frame(height: SwarmStroke.hairline)
    }
  }

  @MainActor
  private func load() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let loaded = try await RingsService.shared.rings(kind: .event)
      let sorted = loaded.sorted(by: sortEvents)
      rings = sorted

      if let selectedRing,
         let fresh = sorted.first(where: { $0.id == selectedRing.id }) {
        self.selectedRing = fresh
      } else if let initialRingId,
                let match = sorted.first(where: { $0.id == initialRingId }) {
        selectedRing = match
      } else {
        selectedRing = sorted.first
      }

      await loadSelectedMetadata()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Non riesco a caricare gli Event Ring.")
    }
  }

  @MainActor
  private func loadSelectedMetadata() async {
    guard let selectedRing else {
      members = []
      checkIns = []
      return
    }

    async let membersTask = RingsService.shared.members(for: selectedRing.id)
    async let checkInsTask = RingsService.shared.checkIns(for: selectedRing.id)
    do {
      members = try await membersTask
      checkIns = try await checkInsTask
    } catch {
      members = []
      checkIns = []
    }
  }

  @MainActor
  private func handleInitialTokenIfNeeded() async {
    guard !didHandleInitialToken, let initialJoinToken else { return }
    didHandleInitialToken = true
    await join(initialJoinToken)
  }

  @MainActor
  private func join(_ raw: String) async {
    isJoining = true
    defer { isJoining = false }
    errorMessage = nil
    statusMessage = nil

    do {
      let ring = try await RingsService.shared.join(token: raw)
      if ring.kind == .event {
        selectedRing = ring
        _ = try? await RingsService.shared.checkIn(eventRingId: ring.id)
      }
      tokenInput = ""
      statusMessage = ring.kind == .event ? "sei dentro \(ring.title)." : "ring agganciato."
      await load()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Token non valido.")
    }
  }

  @MainActor
  private func createOrientationWeekRing() async {
    isCreatingOrientation = true
    defer { isCreatingOrientation = false }
    errorMessage = nil
    statusMessage = nil

    do {
      if let existing = rings.first(where: { $0.joinToken == Self.orientationJoinToken }) {
        selectedRing = existing
        statusMessage = "QR orientation selezionato."
        await loadSelectedMetadata()
        return
      }

      let startsAt = Self.orientationWeekStartDate()
      let endsAt = Calendar.current.date(byAdding: .hour, value: 4, to: startsAt)
      let ring = try await RingsService.shared.create(
        kind: .event,
        title: Self.orientationTitle,
        subtitle: "Scan. Join the ring. Be there.",
        locationName: "Bocconi campus",
        startsAt: startsAt,
        endsAt: endsAt,
        isPublic: true,
        requiresApproval: false,
        memberLimit: 250
      )
      selectedRing = ring
      statusMessage = "QR orientation pronto."
      await load()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "QR orientation non creato.")
    }
  }

  @MainActor
  private func checkIn() async {
    guard let selectedRing else { return }
    isCheckingIn = true
    defer { isCheckingIn = false }
    errorMessage = nil

    do {
      _ = try await RingsService.shared.checkIn(eventRingId: selectedRing.id)
      statusMessage = "check-in confermato."
      await loadSelectedMetadata()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Check-in non riuscito.")
    }
  }

  private func sortEvents(_ lhs: HaloRing, _ rhs: HaloRing) -> Bool {
    let left = lhs.startsAt ?? lhs.createdAt
    let right = rhs.startsAt ?? rhs.createdAt
    return left > right
  }

  private func twoDigits(_ value: Int) -> String {
    String(format: "%02d", value)
  }

  private var orientationTokenLabel: String {
    guard selectedRing?.title == Self.orientationTitle,
          let token = selectedRing?.joinToken else {
      return Self.orientationJoinToken
    }
    return token
  }

  private static func orientationWeekStartDate() -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 9
    components.day = 1
    components.hour = 10
    components.minute = 0
    return Calendar(identifier: .gregorian).date(from: components) ?? .now.addingTimeInterval(90 * 24 * 60 * 60)
  }
}

struct RingKindBadge: View {
  let kind: RingKind

  private var role: SwarmActivationRole {
    switch kind {
    case .event: return .attention
    case .club: return .operational
    case .course: return .connected
    case .founder: return .rest
    }
  }

  var body: some View {
    Text(kind.label)
      .haloEyebrow(role.color, size: 8.5, tracking: 1.9)
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(role.fill, in: Capsule())
      .overlay(Capsule().strokeBorder(role.stroke, lineWidth: SwarmStroke.hairline))
  }
}

struct RingScheduleRow: View {
  let ring: HaloRing

  var body: some View {
    HStack(spacing: SwarmHalo.s3) {
      Image(systemName: iconName)
        .font(HaloType.system(14, weight: .semibold))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .swarmIconFrame(active: ring.startsAt != nil, activation: .rest)
      VStack(alignment: .leading, spacing: 4) {
        Text(primary)
          .font(HaloType.ui(13, weight: .semibold))
          .foregroundStyle(SwarmHalo.ink)
          .lineLimit(1)
        Text(secondary)
          .font(HaloType.ui(12, weight: .regular))
          .foregroundStyle(SwarmHalo.inkMuted)
          .lineLimit(1)
      }
      Spacer()
    }
  }

  private var iconName: String {
    ring.locationName == nil ? "calendar" : "mappin.and.ellipse"
  }

  private var primary: String {
    if let startsAt = ring.startsAt {
      return startsAt.formatted(date: .abbreviated, time: .shortened)
    }
    return ring.kind == .founder ? "founder circle" : "sempre aperto"
  }

  private var secondary: String {
    if let location = ring.locationName, !location.isEmpty {
      return location
    }
    if let endsAt = ring.endsAt {
      return "chiude \(endsAt.formatted(date: .abbreviated, time: .shortened))"
    }
    return ring.isPublic ? "pubblico" : "token only"
  }
}

struct RingListRow: View {
  let ring: HaloRing
  var isSelected: Bool
  var accessory: String

  var body: some View {
    HStack(spacing: SwarmHalo.s3) {
      RingKindBadge(kind: ring.kind)
      VStack(alignment: .leading, spacing: 4) {
        Text(ring.title)
          .font(HaloType.ui(14, weight: .semibold))
          .foregroundStyle(SwarmHalo.ink)
          .lineLimit(1)
        Text(ring.subtitle ?? fallback)
          .font(HaloType.ui(12, weight: .regular))
          .foregroundStyle(SwarmHalo.inkMuted)
          .lineLimit(1)
      }
      Spacer()
      Text(accessory)
        .font(HaloType.mono(9, weight: .medium))
        .kerning(1.2)
        .textCase(.uppercase)
        .foregroundStyle(isSelected ? SwarmActivationRole.attention.color : SwarmHalo.inkMuted)
    }
    .padding(SwarmHalo.s3)
    .swarmSurface(.card, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: isSelected ? .attention : .rest)
  }

  private var fallback: String {
    if let startsAt = ring.startsAt {
      return startsAt.formatted(date: .abbreviated, time: .shortened)
    }
    return ring.locationName ?? ring.kind.label
  }
}

struct RingCreateSheet: View {
  @Environment(\.dismiss) private var dismiss

  let kind: RingKind
  var onCreated: (HaloRing) -> Void

  @State private var title = ""
  @State private var subtitle = ""
  @State private var locationName = ""
  @State private var startsAt = Date()
  @State private var endsAt = Date().addingTimeInterval(2 * 60 * 60)
  @State private var isPublic = false
  @State private var requiresApproval = false
  @State private var memberLimit = ""
  @State private var price = ""
  @State private var isWorking = false
  @State private var errorMessage: String?

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: SwarmHalo.s4) {
          SwarmOperationalRail(title: "HALO / NEW RING", context: kind.label, activation: role) {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
                .font(HaloType.system(12, weight: .semibold))
                .foregroundStyle(SwarmHalo.inkSecondary)
                .swarmIconFrame()
            }
            .buttonStyle(.plain)
          }

          field("nome", text: $title)
          field("nota", text: $subtitle)

          if kind == .event || kind == .course {
            field("luogo", text: $locationName)
            DatePicker("inizio", selection: $startsAt, displayedComponents: [.date, .hourAndMinute])
              .font(HaloType.ui(13, weight: .semibold))
              .foregroundStyle(SwarmHalo.ink)
            DatePicker("fine", selection: $endsAt, displayedComponents: [.date, .hourAndMinute])
              .font(HaloType.ui(13, weight: .semibold))
              .foregroundStyle(SwarmHalo.ink)
          }

          if kind == .club || kind == .course {
            field("prezzo EUR", text: $price, keyboard: .numberPad)
          }

          field("limite membri", text: $memberLimit, keyboard: .numberPad)

          Toggle("pubblico", isOn: $isPublic)
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .tint(role.color)

          Toggle("approval", isOn: $requiresApproval)
            .font(HaloType.ui(13, weight: .semibold))
            .foregroundStyle(SwarmHalo.ink)
            .tint(role.color)

          if let errorMessage {
            Text(errorMessage)
              .font(HaloType.ui(12, weight: .regular))
              .foregroundStyle(SwarmActivationRole.attention.color)
          }

          SwarmCommandButton(
            label: isWorking ? "creo" : "crea ring",
            icon: "plus",
            activation: role,
            isProminent: true
          ) {
            Task { await create() }
          }
          .disabled(isWorking)
          .opacity(isWorking ? 0.6 : 1)
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, SwarmHalo.s4)
        .padding(.top, SwarmHalo.s3)
        .padding(.bottom, SwarmHalo.s8)
      }
    }
    .presentationDetents([.large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.clear)
  }

  private var role: SwarmActivationRole {
    switch kind {
    case .event: return .attention
    case .club: return .operational
    case .course: return .connected
    case .founder: return .rest
    }
  }

  private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
    TextField(placeholder, text: text)
      .keyboardType(keyboard)
      .font(HaloType.ui(14, weight: .regular))
      .foregroundStyle(SwarmHalo.ink)
      .padding(.horizontal, SwarmHalo.s3)
      .padding(.vertical, 12)
      .swarmSurface(.control, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusInput, style: .continuous), activation: role)
  }

  @MainActor
  private func create() async {
    isWorking = true
    defer { isWorking = false }
    errorMessage = nil

    do {
      let limit = Int(memberLimit.trimmingCharacters(in: .whitespacesAndNewlines))
      let priceCents = Int(price.trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 * 100 }
      let ring = try await RingsService.shared.create(
        kind: kind,
        title: title,
        subtitle: subtitle,
        locationName: locationName,
        startsAt: kind == .event || kind == .course ? startsAt : nil,
        endsAt: kind == .event || kind == .course ? endsAt : nil,
        isPublic: isPublic,
        requiresApproval: requiresApproval,
        memberLimit: limit,
        priceCents: priceCents
      )
      onCreated(ring)
      dismiss()
    } catch {
      errorMessage = SupabaseErrorMessage.describe(error, fallback: "Ring non creato.")
    }
  }
}

struct RingQRCode: View {
  let payload: String

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous)
        .fill(SwarmHalo.ink)
      if let image = QRCodeRenderer.image(for: payload) {
        Image(uiImage: image)
          .resizable()
          .interpolation(.none)
          .scaledToFit()
          .padding(10)
      }
    }
  }
}

private enum QRCodeRenderer {
  private static let context = CIContext()

  static func image(for payload: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(payload.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage else { return nil }
    let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}

private struct QRScanSheet: View {
  @Environment(\.dismiss) private var dismiss
  var onScan: (String) -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      QRScannerView { payload in
        onScan(payload)
        dismiss()
      }
      .ignoresSafeArea()

      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(HaloType.system(12, weight: .semibold))
          .foregroundStyle(SwarmHalo.ink)
          .swarmIconFrame(active: true, activation: .attention)
      }
      .buttonStyle(.plain)
      .padding(SwarmHalo.s4)
    }
    .presentationDetents([.large])
    .presentationCornerRadius(HaloTheme.sheetCornerRadius)
    .presentationBackground(.black)
  }
}

private struct QRScannerView: UIViewControllerRepresentable {
  var onCode: (String) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onCode: onCode)
  }

  func makeUIViewController(context: Context) -> QRScannerViewController {
    let controller = QRScannerViewController()
    controller.onCode = { context.coordinator.handle($0) }
    return controller
  }

  func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

  final class Coordinator {
    private var didScan = false
    private let onCode: (String) -> Void

    init(onCode: @escaping (String) -> Void) {
      self.onCode = onCode
    }

    func handle(_ code: String) {
      guard !didScan else { return }
      didScan = true
      onCode(code)
    }
  }
}

private final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  var onCode: ((String) -> Void)?

  private let session = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var isConfigured = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    configureForPermission()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if session.isRunning {
      session.stopRunning()
    }
  }

  private func configureForPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      configureSession()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          granted ? self?.configureSession() : self?.showDenied()
        }
      }
    default:
      showDenied()
    }
  }

  private func configureSession() {
    guard !isConfigured else { return }
    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device),
          session.canAddInput(input) else {
      showDenied()
      return
    }

    session.beginConfiguration()
    session.addInput(input)

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else {
      session.commitConfiguration()
      showDenied()
      return
    }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    output.metadataObjectTypes = [.qr]
    session.commitConfiguration()

    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    preview.frame = view.bounds
    view.layer.insertSublayer(preview, at: 0)
    previewLayer = preview
    isConfigured = true

    DispatchQueue.global(qos: .userInitiated).async { [weak session] in
      session?.startRunning()
    }
  }

  private func showDenied() {
    let label = UILabel()
    label.text = "camera non disponibile"
    label.textColor = .white
    label.font = .systemFont(ofSize: 15, weight: .medium)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
          let code = object.stringValue else { return }
    onCode?(code)
  }
}
