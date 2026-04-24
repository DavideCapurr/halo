import Foundation
import HaloShared

/// Modello "demo" leggero per popolare l'orbital field finché Auth + Realtime
/// non sono pronti. Equivalente del PEOPLE array del prototipo design.
struct DemoPerson: Identifiable, Hashable {
  let id: String
  let handle: String
  let name: String
  var tier: FriendshipTier
  var mood: Mood
  var note: String
  var hasNew: Bool
}

enum SeedPeople {
  static let me = DemoPerson(
    id: "self",
    handle: "you",
    name: "tu",
    tier: .inner,
    mood: .chill,
    note: "studio in biblio · qualcuno per un caffè?",
    hasNew: false
  )

  static let all: [DemoPerson] = [
    // Inner (5)
    .init(id: "p01", handle: "gia",   name: "Giacomo",   tier: .inner, mood: .warm,     note: "in loggia, vieni?",        hasNew: true),
    .init(id: "p02", handle: "fra",   name: "Francesca", tier: .inner, mood: .soft,     note: "pioggia sul tetto",        hasNew: true),
    .init(id: "p03", handle: "teo",   name: "Matteo",    tier: .inner, mood: .focused,  note: "econometria fino a tardi", hasNew: false),
    .init(id: "p04", handle: "chia",  name: "Chiara",    tier: .inner, mood: .wild,     note: "navigli tra un’ora",       hasNew: true),
    .init(id: "p05", handle: "lune",  name: "Lune",      tier: .inner, mood: .lost,     note: "",                         hasNew: false),

    // Close (10)
    .init(id: "p06", handle: "ale",   name: "Alessia",   tier: .close, mood: .electric, note: "playlist nuova",           hasNew: true),
    .init(id: "p07", handle: "nico",  name: "Nicolò",    tier: .close, mood: .chill,    note: "",                         hasNew: false),
    .init(id: "p08", handle: "bene",  name: "Benedetta", tier: .close, mood: .warm,     note: "tè e fettine di mela",     hasNew: false),
    .init(id: "p09", handle: "lor",   name: "Lorenzo",   tier: .close, mood: .focused,  note: "finance exam in 2 giorni", hasNew: true),
    .init(id: "p10", handle: "miri",  name: "Miriam",    tier: .close, mood: .blue,     note: "malinconia domenicale",    hasNew: false),
    .init(id: "p11", handle: "elia",  name: "Elia",      tier: .close, mood: .wild,     note: "",                         hasNew: false),
    .init(id: "p12", handle: "svet",  name: "Svetlana",  tier: .close, mood: .soft,     note: "casa, film, zero parole",  hasNew: false),
    .init(id: "p13", handle: "jun",   name: "Jun",       tier: .close, mood: .electric, note: "triplo espresso",          hasNew: true),
    .init(id: "p14", handle: "vale",  name: "Valentina", tier: .close, mood: .lost,     note: "",                         hasNew: false),
    .init(id: "p15", handle: "tom",   name: "Tommaso",   tier: .close, mood: .chill,    note: "biblio rosa",              hasNew: false),

    // Orbit (14)
    .init(id: "p16", handle: "marz",  name: "Marzia",    tier: .orbit, mood: .warm,     note: "", hasNew: false),
    .init(id: "p17", handle: "ste",   name: "Stefano",   tier: .orbit, mood: .focused,  note: "", hasNew: false),
    .init(id: "p18", handle: "anais", name: "Anaïs",     tier: .orbit, mood: .soft,     note: "", hasNew: false),
    .init(id: "p19", handle: "dav",   name: "Davide",    tier: .orbit, mood: .wild,     note: "", hasNew: false),
    .init(id: "p20", handle: "rob",   name: "Roberta",   tier: .orbit, mood: .chill,    note: "", hasNew: false),
    .init(id: "p21", handle: "seb",   name: "Sebastian", tier: .orbit, mood: .electric, note: "", hasNew: false),
    .init(id: "p22", handle: "ire",   name: "Irene",     tier: .orbit, mood: .blue,     note: "", hasNew: false),
    .init(id: "p23", handle: "fede",  name: "Federico",  tier: .orbit, mood: .focused,  note: "", hasNew: false),
    .init(id: "p24", handle: "mika",  name: "Mika",      tier: .orbit, mood: .lost,     note: "", hasNew: false),
    .init(id: "p25", handle: "carla", name: "Carla",     tier: .orbit, mood: .warm,     note: "", hasNew: false),
    .init(id: "p26", handle: "pet",   name: "Petra",     tier: .orbit, mood: .soft,     note: "", hasNew: false),
    .init(id: "p27", handle: "lucio", name: "Lucio",     tier: .orbit, mood: .wild,     note: "", hasNew: false),
    .init(id: "p28", handle: "rah",   name: "Rahul",     tier: .orbit, mood: .chill,    note: "", hasNew: false),
    .init(id: "p29", handle: "eva",   name: "Eva",       tier: .orbit, mood: .blue,     note: "", hasNew: false),
  ]
}
