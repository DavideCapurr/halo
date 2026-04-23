import Foundation

public enum AppGroup {
  /// Deve combaciare con project.yml → APP_GROUP_ID.
  public static let identifier = "group.app.halo.shared"

  public static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
  }

  public static var widgetSnapshotURL: URL? {
    containerURL?.appendingPathComponent(WidgetSnapshot.filename)
  }
}
