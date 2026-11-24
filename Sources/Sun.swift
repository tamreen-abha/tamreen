import Foundation

/// Sunrise using the same astronomy as the Umm al-Qura timetable
/// (sun's upper limb at 0.833° below the horizon), rounded to the nearest minute.
enum Sun {
    private static let d2r = Double.pi / 180

    static func sunrise(on day: Date, lat: Double, lon: Double) -> Date? {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let c = local.dateComponents([.year, .month, .day], from: day)
        guard let y0 = c.year, let m0 = c.month, let d = c.day else { return nil }

        var y = y0, m = m0
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = 2 - a + a / 4
        let jd0 = Double(Int(365.25 * Double(y + 4716))) + Double(Int(30.6001 * Double(m + 1)))
            + Double(d) + Double(b) - 1524.5
        let jd = jd0 - lon / (15 * 24)

        var t = 6.0 / 24
        var rise = 6.0
        for _ in 0..<2 {
            let p = position(jd + t)
            let noon = 12 - p.eqt
            let cosH = (-sin(0.833 * d2r) - sin(p.dec * d2r) * sin(lat * d2r)) / (cos(p.dec * d2r) * cos(lat * d2r))
            guard cosH >= -1, cosH <= 1 else { return nil }
            rise = noon - acos(cosH) / d2r / 15
            t = rise / 24
        }
        let utHours = rise - lon / 15

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utc.date(from: DateComponents(year: y0, month: m0, day: d)) else { return nil }
        let seconds = (utHours * 3600 / 60).rounded() * 60
        return midnightUTC.addingTimeInterval(seconds)
    }

    private static func position(_ jd: Double) -> (dec: Double, eqt: Double) {
        let dd = jd - 2451545.0
        let g = fixAngle(357.529 + 0.98560028 * dd)
        let q = fixAngle(280.459 + 0.98564736 * dd)
        let l = fixAngle(q + 1.915 * sin(g * d2r) + 0.020 * sin(2 * g * d2r))
        let e = 23.439 - 0.00000036 * dd
        var ra = atan2(cos(e * d2r) * sin(l * d2r), cos(l * d2r)) / d2r / 15
        ra = fix(ra, 24)
        let dec = asin(sin(e * d2r) * sin(l * d2r)) / d2r
        var eqt = q / 15 - ra
        eqt = fix(eqt + 12, 24) - 12
        return (dec, eqt)
    }

    private static func fixAngle(_ a: Double) -> Double { fix(a, 360) }
    private static func fix(_ a: Double, _ m: Double) -> Double {
        let r = a.truncatingRemainder(dividingBy: m)
        return r < 0 ? r + m : r
    }
}
