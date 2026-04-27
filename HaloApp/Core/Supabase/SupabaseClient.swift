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
