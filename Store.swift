import Foundation
import Security
import SwiftUI

/// Everything the app remembers, in one codable snapshot.
struct Snapshot: Codable {
    var phase = 0
    var done = Array(repeating: false, count: Store.slots)
    var remindersOn = true
    var morningOffset = -20
    var eveningMinutes = 22 * 60 + 30
    var place = Place.khamisMushait
    var savedAt = Date()
}

/// Copy kept in the iPhone keychain: it stays on the phone even if the app is deleted,
/// so reinstalling restores everything.
enum Vault {
    private static let service = "tamreeni.snapshot"
    private static let account = "main"

    static func write(_ data: Data) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        let attrs: [String: Any] = [kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        if SecItemUpdate(query as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
            var add = query
            attrs.forEach { add[$0.key] = $0.value }
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    static func read() -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }
}

final class Store: ObservableObject {
    static let slots = 144 // 12 weeks × 2 sessions × 6 days
    private static let key = "snapshot.v2"

    @Published var phase: Int { didSet { persist() } }
    @Published var done: [Bool] { didSet { persist() } }
    @Published var remindersOn: Bool { didSet { persist(); reschedule() } }
    /// Minutes relative to sunrise. Negative = before sunrise.
    @Published var morningOffset: Int { didSet { persist(); reschedule() } }
    /// Minutes since midnight.
    @Published var eveningMinutes: Int { didSet { persist(); reschedule() } }
    @Published var place: Place { didSet { persist(); reschedule() } }

    private var loading = false

    init() {
        let snap = Store.loadSnapshot()
        phase = snap.phase
        done = snap.done.count == Store.slots ? snap.done : Array(repeating: false, count: Store.slots)
        remindersOn = snap.remindersOn
        morningOffset = snap.morningOffset
        eveningMinutes = snap.eveningMinutes
        place = snap.place
        persist()
    }

    private static func loadSnapshot() -> Snapshot {
        let dec = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: key), let s = try? dec.decode(Snapshot.self, from: data) {
            return s
        }
        if let data = Vault.read(), let s = try? dec.decode(Snapshot.self, from: data) {
            return s
        }
        return Snapshot()
    }

    var snapshot: Snapshot {
        Snapshot(phase: phase, done: done, remindersOn: remindersOn, morningOffset: morningOffset,
                 eveningMinutes: eveningMinutes, place: place, savedAt: Date())
    }

    private func persist() {
        guard !loading, let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Store.key)
        Vault.write(data)
    }

    private func reschedule() { if !loading { Reminders.schedule(self) } }

    // MARK: Backup file

    func exportBackup() -> URL? {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(snapshot) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tamreeni-backup.json")
        try? data.write(to: url)
        return url
    }

    @discardableResult
    func importBackup(from url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url), let s = try? dec.decode(Snapshot.self, from: data) else {
            return false
        }
        loading = true
        phase = s.phase
        done = s.done.count == Store.slots ? s.done : done
        remindersOn = s.remindersOn
        morningOffset = s.morningOffset
        eveningMinutes = s.eveningMinutes
        place = s.place
        loading = false
        persist()
        Reminders.schedule(self)
        return true
    }

    // MARK: Helpers

    var doneCount: Int { done.filter { $0 }.count }

    static func index(week: Int, session: Session, day: Int) -> Int {
        week * 12 + (session == .am ? 0 : 6) + day
    }

    func markDone(_ s: Session) {
        for w in 0..<12 {
            for day in 0..<6 {
                let i = Store.index(week: w, session: s, day: day)
                if !done[i] { done[i] = true; return }
            }
        }
    }

    func morningTime(on day: Date) -> Date? {
        Sun.sunrise(on: day, lat: place.lat, lon: place.lon)?
            .addingTimeInterval(Double(morningOffset * 60))
    }

    var eveningDate: Date {
        get {
            Calendar.current.date(bySettingHour: eveningMinutes / 60, minute: eveningMinutes % 60,
                                  second: 0, of: Date()) ?? Date()
        }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            eveningMinutes = (c.hour ?? 22) * 60 + (c.minute ?? 30)
        }
    }
}
