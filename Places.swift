import Foundation
import CoreLocation

struct Place: Codable, Equatable {
    var name: String
    var country: String
    var lat: Double
    var lon: Double

    var title: String { country.isEmpty ? name : "\(name)، \(country)" }

    static let khamisMushait = Place(name: "خميس مشيط", country: "السعودية", lat: 18.3000, lon: 42.7333)
}

struct Country: Identifiable {
    let name: String
    let cities: [(String, Double, Double)]
    var id: String { name }
}

let countries: [Country] = [
    Country(name: "السعودية", cities: [
        ("الرياض", 24.7136, 46.6753), ("جدة", 21.4858, 39.1925), ("مكة المكرمة", 21.3891, 39.8579),
        ("المدينة المنورة", 24.5247, 39.5692), ("الدمام", 26.4207, 50.0888), ("الخبر", 26.2172, 50.1971),
        ("الأحساء", 25.3833, 49.5867), ("القطيف", 26.5196, 50.0115), ("الجبيل", 27.0174, 49.6225),
        ("الطائف", 21.2703, 40.4158), ("أبها", 18.2164, 42.5053), ("خميس مشيط", 18.3000, 42.7333),
        ("محايل عسير", 18.5450, 42.0500), ("بيشة", 19.9800, 42.6000), ("الباحة", 20.0129, 41.4677),
        ("جازان", 16.8892, 42.5511), ("نجران", 17.4924, 44.1277), ("تبوك", 28.3838, 36.5550),
        ("حائل", 27.5114, 41.7208), ("بريدة", 26.3260, 43.9750), ("عنيزة", 26.0844, 43.9935),
        ("سكاكا", 29.9697, 40.2064), ("عرعر", 30.9753, 41.0381), ("حفر الباطن", 28.4328, 45.9708),
        ("ينبع", 24.0895, 38.0618)
    ]),
    Country(name: "الإمارات", cities: [
        ("دبي", 25.2048, 55.2708), ("أبوظبي", 24.4539, 54.3773), ("الشارقة", 25.3463, 55.4209),
        ("العين", 24.2075, 55.7447), ("رأس الخيمة", 25.8007, 55.9762)
    ]),
    Country(name: "الكويت", cities: [("الكويت", 29.3759, 47.9774)]),
    Country(name: "قطر", cities: [("الدوحة", 25.2854, 51.5310)]),
    Country(name: "البحرين", cities: [("المنامة", 26.2285, 50.5860)]),
    Country(name: "عُمان", cities: [("مسقط", 23.5880, 58.3829), ("صلالة", 17.0151, 54.0924)]),
    Country(name: "اليمن", cities: [("صنعاء", 15.3694, 44.1910), ("عدن", 12.7855, 45.0187)]),
    Country(name: "مصر", cities: [("القاهرة", 30.0444, 31.2357), ("الإسكندرية", 31.2001, 29.9187)]),
    Country(name: "الأردن", cities: [("عمّان", 31.9454, 35.9284)]),
    Country(name: "العراق", cities: [("بغداد", 33.3152, 44.3661), ("البصرة", 30.5085, 47.7804)]),
    Country(name: "سوريا", cities: [("دمشق", 33.5138, 36.2765)]),
    Country(name: "لبنان", cities: [("بيروت", 33.8938, 35.5018)]),
    Country(name: "فلسطين", cities: [("القدس", 31.7683, 35.2137)]),
    Country(name: "السودان", cities: [("الخرطوم", 15.5007, 32.5599)]),
    Country(name: "ليبيا", cities: [("طرابلس", 32.8872, 13.1913)]),
    Country(name: "تونس", cities: [("تونس", 36.8065, 10.1815)]),
    Country(name: "الجزائر", cities: [("الجزائر", 36.7538, 3.0588)]),
    Country(name: "المغرب", cities: [("الرباط", 34.0209, -6.8416), ("الدار البيضاء", 33.5731, -7.5898)]),
    Country(name: "تركيا", cities: [("إسطنبول", 41.0082, 28.9784), ("أنقرة", 39.9334, 32.8597)]),
    Country(name: "ماليزيا", cities: [("كوالالمبور", 3.1390, 101.6869)]),
    Country(name: "إندونيسيا", cities: [("جاكرتا", -6.2088, 106.8456)]),
    Country(name: "باكستان", cities: [("كراتشي", 24.8607, 67.0011), ("إسلام آباد", 33.6844, 73.0479)]),
    Country(name: "الهند", cities: [("نيودلهي", 28.6139, 77.2090)]),
    Country(name: "بريطانيا", cities: [("لندن", 51.5074, -0.1278)]),
    Country(name: "الولايات المتحدة", cities: [("نيويورك", 40.7128, -74.0060)])
]

/// Finds any city in the world by name (needs internet only while searching).
final class PlaceSearch: ObservableObject {
    @Published var results: [Place] = []
    @Published var searching = false
    private let geocoder = CLGeocoder()

    func search(_ text: String) {
        let q = text.trimmingCharacters(in: .whitespaces)
        geocoder.cancelGeocode()
        guard q.count >= 2 else { results = []; return }
        searching = true
        geocoder.geocodeAddressString(q, in: nil, preferredLocale: Locale(identifier: "ar")) { [weak self] marks, _ in
            DispatchQueue.main.async {
                self?.searching = false
                self?.results = (marks ?? []).compactMap { m in
                    guard let loc = m.location else { return nil }
                    return Place(name: m.locality ?? m.name ?? q, country: m.country ?? "",
                                 lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
                }
            }
        }
    }
}

/// One-shot current location, named in Arabic.
final class LocationFetcher: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var busy = false
    @Published var error: String?
    private let manager = CLLocationManager()
    private var completion: ((Place) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetch(_ done: @escaping (Place) -> Void) {
        completion = done
        error = nil
        busy = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            busy = false
            error = "الوصول للموقع مرفوض. فعّله من الإعدادات ← تمريني ← الموقع، أو اختر مدينتك من القائمة."
        default: manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard busy else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted:
            busy = false
            error = "الوصول للموقع مرفوض. فعّله من الإعدادات ← تمريني ← الموقع، أو اختر مدينتك من القائمة."
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: "ar")) { [weak self] marks, _ in
            DispatchQueue.main.async {
                let m = marks?.first
                let place = Place(name: m?.locality ?? m?.administrativeArea ?? "موقعي الحالي",
                                  country: m?.country ?? "",
                                  lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
                self?.busy = false
                self?.completion?(place)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.busy = false
            self.error = "تعذّر تحديد موقعك الآن. حاول مرة أخرى في مكان مفتوح، أو اختر مدينتك من القائمة."
        }
    }
}
