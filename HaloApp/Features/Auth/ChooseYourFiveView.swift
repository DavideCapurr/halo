import SwiftUI

struct ChooseYourFiveView: View {
  var onDone: () -> Void = {}
  var onSkip: () -> Void = {}

  var body: some View {
    InitialInnerCircleView(onDone: onDone, onSkip: onSkip)
  }
}
