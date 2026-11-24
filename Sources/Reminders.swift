import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

enum Reminders {
    /// Calendar weekday numbers (Sunday = 1): Saturday to Thursday.
    static let trainingWeekdays = [7, 1, 2, 3, 4, 5]

    static func requestAndSchedule(_ store: Store) {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { DispatchQueue.main.async { schedule(store) } }
        }
    }

    static func schedule(_ store: Store) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard store.remindersOn else { return }

        // Evening: repeats every Saturday–Thursday at the chosen time.
        for wd in trainingWeekdays {
            var dc = DateComponents()
            dc.weekday = wd
            dc.hour = store.eveningMinutes / 60
            dc.minute = store.eveningMinutes % 60
            add(center, id: "pm-\(wd)", title: "🌙 جلسة المساء",
                body: "ربع ساعة من تمارين الأرض والتثبيت، ثم الإطالة والشاور والنوم.",
                trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true))
        }

        // Morning: follows the sunrise, so each day is scheduled on its own (iOS allows 64 pending).
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        var count = 0
        for i in 0..<60 where count < 50 {
            guard let day = cal.date(byAdding: .day, value: i, to: today) else { continue }
            if cal.component(.weekday, from: day) == 6 { continue } // Friday rest
            guard let t = store.morningTime(on: day), t > now else { continue }
            let dc = cal.dateComponents([.year, .month, .day, .hour, .minute], from: t)
            add(center, id: "am-\(i)", title: "🌅 جلسة الفجر",
                body: "تمارين وقوف خفيفة قبل الدوام، نحو ربع ساعة.",
                trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: false))
            count += 1
        }

        // Free Apple ID installs stop working after 7 days: remind a day before.
        if let installed = installDate(),
           let warn = cal.date(byAdding: .day, value: 6, to: installed),
           let at = cal.date(bySettingHour: 20, minute: 0, second: 0, of: warn), at > now {
            let dc = cal.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            add(center, id: "reinstall", title: "⚠️ أعد تثبيت تطبيق تمريني",
                body: "سيتوقف التطبيق غدًا. وصّل الجوال باللابتوب وأعد تثبيته من Sideloadly، وبياناتك محفوظة.",
                trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: false))
        }
    }

    static func test() {
        add(UNUserNotificationCenter.current(), id: "test-\(Date().timeIntervalSince1970)",
            title: "تجربة التنبيه ✅", body: "التنبيهات تعمل. أراك في الجلسة القادمة!",
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
    }

    static func installDate() -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: Bundle.main.bundlePath)
        return (attrs?[.creationDate] as? Date) ?? (attrs?[.modificationDate] as? Date)
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, title: String, body: String,
                            trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
