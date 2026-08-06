import SwiftUI

struct WelcomeManifestoView<Actions: View>: View {
  @ViewBuilder var actions: () -> Actions

  init(@ViewBuilder actions: @escaping () -> Actions) {
    self.actions = actions
  }

  var body: some View {
    ZStack {
      DeepSpaceBackground()
      VStack(spacing: SwarmHalo.s6) {
        Spacer(minLength: SwarmHalo.s12)
        manifesto
        ledger
        Spacer(minLength: SwarmHalo.s6)
        actions()
        Spacer().frame(height: SwarmHalo.s6)
      }
      .padding(.horizontal, SwarmHalo.s6)
    }
    .preferredColorScheme(.dark)
  }

  private var manifesto: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      Text("Halo")
        .font(HaloType.serifUpright(64, weight: .medium))
        .foregroundStyle(SwarmHalo.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      // La tesi di `docs/PRODOTTO.md` §1, testuale e in italiano. Era «Your
      // people, not your audience.»: inglese in un'app italiana, e soprattutto
      // una frase che dice cosa Halo *non* è. §1 chiede l'opposto — una riga
      // sola, zero termini proprietari, che dica cosa Halo è.
      Text("Le persone che hai incontrato davvero.")
        .font(HaloType.serif(36, weight: .regular))
        .foregroundStyle(SwarmHalo.ink)
        .fixedSize(horizontal: false, vertical: true)

      Text("non chi ti segue. non chi conosci online.")
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Tre righe, nessun numero.
  ///
  /// Prima era una riga di metriche — `likes 00 · inner 05 · feed NO` — cioè
  /// dei contatori finti usati per dire che non ci sono contatori. Ma è la
  /// prima schermata dell'app, quella del guscio (`docs/DESIGN.md` §3): mettere
  /// dei numeri lì insegna che qui si contano le cose, che è esattamente la
  /// promessa che il prodotto sta cercando di non fare.
  private var ledger: some View {
    VStack(alignment: .leading, spacing: SwarmHalo.s3) {
      ledgerLine("solo persone che hai incontrato di persona.")
      ledgerLine("niente like, niente follower, niente estranei.")
      ledgerLine("vedi come stanno senza doverci parlare.")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(SwarmHalo.s4)
    .swarmSurface(.rail, in: RoundedRectangle(cornerRadius: SwarmHalo.radiusCard, style: .continuous), activation: .connected)
  }

  private func ledgerLine(_ text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: SwarmHalo.s3) {
      Circle()
        .fill(SwarmHalo.inkMuted)
        .frame(width: 4, height: 4)
      Text(text)
        .font(HaloType.ui(14, weight: .regular))
        .foregroundStyle(SwarmHalo.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
  }
}

extension WelcomeManifestoView where Actions == EmptyView {
  init() {
    self.init { EmptyView() }
  }
}
