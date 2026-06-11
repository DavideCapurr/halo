import Foundation
import Supabase

/// Singleton wrapper sul client Supabase. Legge URL e anon key da Info.plist,
/// alimentato dalle build settings del target in Xcode.
enum SupabaseEnv {
  static let url: URL = {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let url = URL(string: raw) else {
      fatalError("SUPABASE_URL mancante in Info.plist o nelle Build Settings del target.")
    }
    return url
  }()

  static let anonKey: String = {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
          !key.isEmpty else {
      fatalError("SUPABASE_ANON_KEY mancante in Info.plist o nelle Build Settings del target.")
    }
    return key
  }()
}

enum SupabaseClientProvider {
  static let shared: SupabaseClient = SupabaseClient(
    supabaseURL: SupabaseEnv.url,
    supabaseKey: SupabaseEnv.anonKey
  )
}

/// App-level config read from Info.plist / Build Settings.
enum AppConfig {
  /// Base URL of the public campaigns web landing (e.g. https://halo.app).
  /// When set, campaign shares link to the open web page instead of the deep
  /// link, so non-Halo users can open and donate.
  static let webBaseURL: URL? = {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "HALO_WEB_BASE_URL") as? String,
          !raw.isEmpty else {
      return nil
    }
    return URL(string: raw)
  }()
}

enum SupabaseErrorMessage {
  static let connectivity = "Non riesco a raggiungere Halo. Controlla la connessione e riprova."

  static func describe(_ error: Error, fallback: String) -> String {
    if isConnectivityError(error as NSError) {
      return connectivity
    }

    let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    return description.isEmpty ? fallback : description
  }

  private static func isConnectivityError(_ error: NSError) -> Bool {
    if error.domain == NSURLErrorDomain {
      switch error.code {
      case NSURLErrorCannotFindHost,
           NSURLErrorCannotConnectToHost,
           NSURLErrorDNSLookupFailed,
           NSURLErrorNetworkConnectionLost,
           NSURLErrorNotConnectedToInternet,
           NSURLErrorTimedOut:
        return true
      default:
        break
      }
    }

    guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
      return false
    }
    return isConnectivityError(underlying)
  }
}
