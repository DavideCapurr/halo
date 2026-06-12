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

enum SupabaseErrorMessage {
  static let connectivity = "Non riesco a raggiungere Halo. Controlla la connessione e riprova."
  static let schemaUnavailable = "Questa sezione non e disponibile in questo momento. Riprova tra poco."

  static func describe(_ error: Error, fallback: String) -> String {
    if isConnectivityError(error as NSError) {
      return connectivity
    }

    if isSchemaCacheError(error) {
      return schemaUnavailable
    }

    let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    if description.isEmpty || isTechnicalPostgrestMessage(description) {
      return fallback
    }
    return description
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

  private static func isSchemaCacheError(_ error: Error) -> Bool {
    let raw = [
      error.localizedDescription,
      String(describing: error),
    ]
    .joined(separator: " ")
    .lowercased()

    return raw.contains("schema cache")
      || raw.contains("could not find the table")
      || raw.contains("could not find the function")
      || raw.contains("pgrst202")
      || raw.contains("pgrst205")
  }

  private static func isTechnicalPostgrestMessage(_ message: String) -> Bool {
    let raw = message.lowercased()
    return raw.contains("postgrest")
      || raw.contains("pgrst")
      || raw.contains("public.")
      || raw.contains("schema cache")
      || raw.contains("could not find")
  }
}
