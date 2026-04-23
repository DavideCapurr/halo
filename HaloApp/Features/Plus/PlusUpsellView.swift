import SwiftUI

/// Step 13: upsell Halo Plus €3,99/mese.
struct PlusUpsellView: View {
  var body: some View {
    VStack(spacing: 12) {
      Text("Halo Plus").font(.largeTitle).foregroundStyle(.white)
      Text("€3,99 / mese").foregroundStyle(HaloTheme.textMuted)
      // TODO step 13: features list + StoreKit buy button
    }
    .padding()
    .background(HaloTheme.background)
  }
}
