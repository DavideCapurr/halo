import Foundation

public enum ReactionKind: String, Codable, CaseIterable, Sendable {
  case pulse, glow, echo, spark, drift, hush
}

public enum PostKind: String, Codable, CaseIterable, Sendable {
  case photo, text, audio
}
