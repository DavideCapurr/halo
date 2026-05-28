import Foundation
import HaloShared

/// Presentation node used by Orbit, Pulse, HaloSpace and widgets.
///
/// The production UI should reason in terms of person nodes: identity,
/// proximity, current vibe, activity and graph symmetry. Seed data below is
/// only one source that can hydrate this shape.
struct HaloPersonNode: Identifiable, Hashable {
  let id: String
  let handle: String
  let name: String
  var tier: FriendshipTier
  var mood: Mood
  var note: String
  var hasNew: Bool
  /// Quanto fa è stato pubblicato l'ultimo post; nil se non ne ha pubblicati attivi.
  var lastPostAt: Date?
  /// True se ha una vibe nelle ultime 24h.
  var hasActiveVibe: Bool
  /// True se entrambe le parti si seguono. Falso = asteroide.
  var isMutual: Bool

  init(
    id: String,
    handle: String,
    name: String,
    tier: FriendshipTier,
    mood: Mood,
    note: String,
    hasNew: Bool,
    lastPostAt: Date? = nil,
    hasActiveVibe: Bool = true,
    isMutual: Bool = true
  ) {
    self.id = id
    self.handle = handle
    self.name = name
    self.tier = tier
    self.mood = mood
    self.note = note
    self.hasNew = hasNew
    self.lastPostAt = lastPostAt
    self.hasActiveVibe = hasActiveVibe
    self.isMutual = isMutual
  }

  init(item: MomentItem) {
    self.id = item.profile.id.uuidString
    self.handle = item.profile.handle
    self.name = item.profile.displayName
    self.tier = item.viewerTier ?? .nebula
    self.mood = item.vibe?.mood ?? item.lastPost?.mood ?? .chill
    self.note = item.vibe?.note ?? item.lastPost?.caption ?? ""
    self.hasNew = Date.now.timeIntervalSince(item.lastActivityAt) <= 30 * 60
    self.lastPostAt = item.lastPost?.createdAt
    self.hasActiveVibe = item.vibe != nil
    self.isMutual = item.isMutual
  }
}

struct HaloMomentPresentation: Identifiable, Hashable {
  enum Kind: Hashable {
    case vibe
    case message
    case photo
    case text
    case audio
    case moodChange
  }

  let id: String
  var person: HaloPersonNode
  var kind: Kind
  var title: String
  var body: String
  var createdAt: Date
  var audience: FriendshipTier
  var isMine: Bool

  var isLive: Bool {
    Date.now.timeIntervalSince(createdAt) <= 30 * 60
  }
}

struct HaloScopePresentation: Identifiable, Hashable {
  let id: String
  let title: String
  let subtitle: String
  let visibleTiers: Set<FriendshipTier>
}

private func minutesAgo(_ m: Double) -> Date { Date.now.addingTimeInterval(-m * 60) }
private func hoursAgo(_ h: Double) -> Date   { Date.now.addingTimeInterval(-h * 3600) }

enum SeedPeople {
  static let me = HaloPersonNode(
    id: "self",
    handle: "you",
    name: "tu",
    tier: .inner,
    mood: .chill,
    note: "studio in biblio · qualcuno per un caffè?",
    hasNew: false,
    lastPostAt: hoursAgo(6),
    hasActiveVibe: true,
    isMutual: true
  )

  static let all: [HaloPersonNode] = [
    // Inner (5)
    .init(id: "p01", handle: "gia",   name: "Giacomo",   tier: .inner, mood: .warm,     note: "in loggia, vieni?",        hasNew: true,  lastPostAt: minutesAgo(12), hasActiveVibe: true),
    .init(id: "p02", handle: "fra",   name: "Francesca", tier: .inner, mood: .soft,     note: "pioggia sul tetto",        hasNew: true,  lastPostAt: minutesAgo(48), hasActiveVibe: true),
    .init(id: "p03", handle: "teo",   name: "Matteo",    tier: .inner, mood: .focused,  note: "econometria fino a tardi", hasNew: false, lastPostAt: hoursAgo(8),    hasActiveVibe: true),
    .init(id: "p04", handle: "chia",  name: "Chiara",    tier: .inner, mood: .wild,     note: "navigli tra un'ora",       hasNew: true,  lastPostAt: minutesAgo(20), hasActiveVibe: true),
    .init(id: "p05", handle: "lune",  name: "Lune",      tier: .inner, mood: .lost,     note: "",                         hasNew: false, lastPostAt: hoursAgo(40),   hasActiveVibe: false),

    // Close (10)
    .init(id: "p06", handle: "ale",   name: "Alessia",   tier: .close, mood: .electric, note: "playlist nuova",           hasNew: true,  lastPostAt: minutesAgo(28), hasActiveVibe: true),
    .init(id: "p07", handle: "nico",  name: "Nicolò",    tier: .close, mood: .chill,    note: "",                         hasNew: false, lastPostAt: hoursAgo(14),   hasActiveVibe: false),
    .init(id: "p08", handle: "bene",  name: "Benedetta", tier: .close, mood: .warm,     note: "tè e fettine di mela",     hasNew: false, lastPostAt: hoursAgo(2),    hasActiveVibe: true),
    .init(id: "p09", handle: "lor",   name: "Lorenzo",   tier: .close, mood: .focused,  note: "finance exam in 2 giorni", hasNew: true,  lastPostAt: minutesAgo(8),  hasActiveVibe: true),
    .init(id: "p10", handle: "miri",  name: "Miriam",    tier: .close, mood: .blue,     note: "malinconia domenicale",    hasNew: false, lastPostAt: hoursAgo(20),   hasActiveVibe: true),
    .init(id: "p11", handle: "elia",  name: "Elia",      tier: .close, mood: .wild,     note: "",                         hasNew: false, lastPostAt: nil,            hasActiveVibe: false),
    .init(id: "p12", handle: "svet",  name: "Svetlana",  tier: .close, mood: .soft,     note: "casa, film, zero parole",  hasNew: false, lastPostAt: hoursAgo(4),    hasActiveVibe: true),
    .init(id: "p13", handle: "jun",   name: "Jun",       tier: .close, mood: .electric, note: "triplo espresso",          hasNew: true,  lastPostAt: minutesAgo(15), hasActiveVibe: true),
    .init(id: "p14", handle: "vale",  name: "Valentina", tier: .close, mood: .lost,     note: "",                         hasNew: false, lastPostAt: hoursAgo(60),   hasActiveVibe: false),
    .init(id: "p15", handle: "tom",   name: "Tommaso",   tier: .close, mood: .chill,    note: "biblio rosa",              hasNew: false, lastPostAt: hoursAgo(10),   hasActiveVibe: true),

    // Orbit (14)
    .init(id: "p16", handle: "marz",  name: "Marzia",    tier: .orbit, mood: .warm,     note: "", hasNew: false, lastPostAt: hoursAgo(36), hasActiveVibe: false),
    .init(id: "p17", handle: "ste",   name: "Stefano",   tier: .orbit, mood: .focused,  note: "", hasNew: false, lastPostAt: hoursAgo(18), hasActiveVibe: true),
    .init(id: "p18", handle: "anais", name: "Anaïs",     tier: .orbit, mood: .soft,     note: "", hasNew: false, lastPostAt: hoursAgo(50), hasActiveVibe: false),
    .init(id: "p19", handle: "dav",   name: "Davide",    tier: .orbit, mood: .wild,     note: "", hasNew: false, lastPostAt: hoursAgo(7),  hasActiveVibe: true),
    .init(id: "p20", handle: "rob",   name: "Roberta",   tier: .orbit, mood: .chill,    note: "", hasNew: false, lastPostAt: nil,          hasActiveVibe: false),
    .init(id: "p21", handle: "seb",   name: "Sebastian", tier: .orbit, mood: .electric, note: "", hasNew: false, lastPostAt: hoursAgo(32), hasActiveVibe: false),
    .init(id: "p22", handle: "ire",   name: "Irene",     tier: .orbit, mood: .blue,     note: "", hasNew: false, lastPostAt: hoursAgo(2),  hasActiveVibe: true),
    .init(id: "p23", handle: "fede",  name: "Federico",  tier: .orbit, mood: .focused,  note: "", hasNew: false, lastPostAt: hoursAgo(22), hasActiveVibe: false),
    .init(id: "p24", handle: "mika",  name: "Mika",      tier: .orbit, mood: .lost,     note: "", hasNew: false, lastPostAt: hoursAgo(64), hasActiveVibe: false),
    .init(id: "p25", handle: "carla", name: "Carla",     tier: .orbit, mood: .warm,     note: "", hasNew: false, lastPostAt: hoursAgo(12), hasActiveVibe: true),
    .init(id: "p26", handle: "pet",   name: "Petra",     tier: .orbit, mood: .soft,     note: "", hasNew: false, lastPostAt: nil,          hasActiveVibe: false),
    .init(id: "p27", handle: "lucio", name: "Lucio",     tier: .orbit, mood: .wild,     note: "", hasNew: false, lastPostAt: hoursAgo(28), hasActiveVibe: false),
    .init(id: "p28", handle: "rah",   name: "Rahul",     tier: .orbit, mood: .chill,    note: "", hasNew: false, lastPostAt: hoursAgo(6),  hasActiveVibe: true),
    .init(id: "p29", handle: "eva",   name: "Eva",       tier: .orbit, mood: .blue,     note: "", hasNew: false, lastPostAt: hoursAgo(45), hasActiveVibe: false),
  ]

  // Mutuali esplicitamente depriorizzati: amici reali che l'utente ha "buttato
  // fuori" dai 4 anelli trascinandoli oltre il bordo. Restano nel grafo ma
  // vivono nella cintura asteroidi con stile attenuato.
  static let demoted: [HaloPersonNode] = [
    .init(id: "d01", handle: "kev",  name: "Kevin",  tier: .asteroid, mood: .chill, note: "", hasNew: false, lastPostAt: hoursAgo(30), hasActiveVibe: false, isMutual: true),
    .init(id: "d02", handle: "luna", name: "Luna",   tier: .asteroid, mood: .blue,  note: "", hasNew: false, lastPostAt: hoursAgo(70), hasActiveVibe: false, isMutual: true),
    .init(id: "d03", handle: "rik",  name: "Riccardo", tier: .asteroid, mood: .lost, note: "", hasNew: false, lastPostAt: nil,        hasActiveVibe: false, isMutual: true),
  ]

  // Asteroidi: account pubblici / artisti / brand seguiti in modo asimmetrico.
  static let asteroids: [HaloPersonNode] = [
    .init(id: "a01", handle: "mura",   name: "Mura",       tier: .nebula, mood: .electric, note: "", hasNew: false, lastPostAt: hoursAgo(3),  hasActiveVibe: true,  isMutual: false),
    .init(id: "a02", handle: "noir",   name: "Noir",       tier: .nebula, mood: .wild,     note: "", hasNew: false, lastPostAt: hoursAgo(11), hasActiveVibe: true,  isMutual: false),
    .init(id: "a03", handle: "atlas",  name: "Atlas",      tier: .nebula, mood: .focused,  note: "", hasNew: false, lastPostAt: hoursAgo(22), hasActiveVibe: false, isMutual: false),
    .init(id: "a04", handle: "veil",   name: "Veil",       tier: .nebula, mood: .soft,     note: "", hasNew: false, lastPostAt: hoursAgo(7),  hasActiveVibe: true,  isMutual: false),
    .init(id: "a05", handle: "kyo",    name: "Kyo",        tier: .nebula, mood: .blue,     note: "", hasNew: false, lastPostAt: nil,          hasActiveVibe: false, isMutual: false),
    .init(id: "a06", handle: "aria",   name: "Aria",       tier: .nebula, mood: .warm,     note: "", hasNew: false, lastPostAt: hoursAgo(15), hasActiveVibe: false, isMutual: false),
    .init(id: "a07", handle: "moss",   name: "Moss",       tier: .nebula, mood: .chill,    note: "", hasNew: false, lastPostAt: hoursAgo(1),  hasActiveVibe: true,  isMutual: false),
    .init(id: "a08", handle: "ember",  name: "Ember",      tier: .nebula, mood: .lost,     note: "", hasNew: false, lastPostAt: hoursAgo(40), hasActiveVibe: false, isMutual: false),
  ]
}
