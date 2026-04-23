import Foundation
import Supabase

/// Singleton wrapper sul client Supabase. Legge URL e anon key da Info.plist,
/// che a loro volta arrivano da Secrets.xcconfig via XcodeGen.
enum SupabaseEnv {
  static let url: URL = {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let url = URL(string: raw) else {
      fatalError("SUPABASE_URL mancante in Info.plist (controlla Secrets.xcconfig).")
    }
    return url
  }()

  static let anonKey: String = {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
          !key.isEmpty else {
      fatalError("SUPABASE_ANON_KEY mancante in Info.plist (controlla Secrets.xcconfig).")
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
