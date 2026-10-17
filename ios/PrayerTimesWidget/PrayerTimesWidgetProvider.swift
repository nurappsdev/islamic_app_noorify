import WidgetKit

enum PrayerPeriod: String {
    case fajr, dhuhr, asr, maghrib, isha
}

struct PrayerInfo {
    let period: PrayerPeriod
    let label: String
    let time: String
    let minutes: Int
}

/// What the badge (the current/next obligatory prayer, matching
/// `_CurrentPrayerBadge` on the home card) shows for one timeline entry.
struct PrayerBadge {
    let label: String
    let range: String
}

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let themeImageName: String
    let hijriDate: String
    let calendarDate: String
    let gregorianDate: String
    let periodTime: String
    let location: String
    let badge: PrayerBadge
    let sunriseLabel: String
    let sunriseTime: String
    let sunsetLabel: String
    let sunsetTime: String

    static func placeholder() -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            hasData: false,
            themeImageName: "prayer_theme_1",
            hijriDate: "",
            calendarDate: "",
            gregorianDate: "",
            periodTime: "--:--",
            location: "",
            badge: PrayerBadge(label: "--", range: "--:--"),
            sunriseLabel: "",
            sunriseTime: "--:--",
            sunsetLabel: "",
            sunsetTime: "--:--"
        )
    }
}

/// Reads the schedule `PrayerWidgetService` (Dart) wrote via
/// `HomeWidget.saveWidgetData` into the shared App Group `UserDefaults`, and
/// turns it into a short run of future [PrayerTimesEntry]s - one for every
/// remaining prayer boundary *and* every background-art boundary
/// (`prayerThemeAsset`'s 10:00/16:00/19:30) today, plus tomorrow's Fajr - so
/// WidgetKit swaps the current-prayer badge and the time-of-day picture by
/// itself at each boundary, with no polling and no background wake-up.
struct PrayerTimesProvider: TimelineProvider {
    static let appGroupId = "group.com.tuhfatulmuslim.app.widget"

    private static let periods: [(period: PrayerPeriod, fallback: String)] = [
        (.fajr, "Fajr"),
        (.dhuhr, "Dhuhr"),
        (.asr, "Asr"),
        (.maghrib, "Maghrib"),
        (.isha, "Isha"),
    ]

    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        completion(buildEntries().first ?? PrayerTimesEntry.placeholder())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let entries = buildEntries()
        let refreshAt = entries.last?.date.addingTimeInterval(60) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(refreshAt)))
    }

    private func buildEntries() -> [PrayerTimesEntry] {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId) else {
            return [PrayerTimesEntry.placeholder()]
        }

        let hijriDate = defaults.string(forKey: "widget_hijri_date") ?? ""
        let calendarDate = defaults.string(forKey: "widget_calendar_date") ?? ""
        let gregorianDate = defaults.string(forKey: "widget_greg_date") ?? ""
        let periodTime = defaults.string(forKey: "widget_period_time") ?? "--:--"
        let location = defaults.string(forKey: "widget_location") ?? ""
        let namazWord = defaults.string(forKey: "widget_namaz_word") ?? ""
        let ishraqLabel = defaults.string(forKey: "widget_ishraq_label") ?? "--"
        let sunriseLabel = defaults.string(forKey: "widget_sunrise_label") ?? ""
        let sunriseTime = defaults.string(forKey: "widget_sunrise_time") ?? "--:--"
        let sunsetLabel = defaults.string(forKey: "widget_sunset_label") ?? ""
        let sunsetTime = defaults.string(forKey: "widget_sunset_time") ?? "--:--"

        guard
            let sunriseMinutesString = defaults.string(forKey: "widget_sunrise_minutes"),
            let sunriseMinutes = Int(sunriseMinutesString)
        else {
            return [PrayerTimesEntry.placeholder()]
        }

        var prayers: [PrayerPeriod: PrayerInfo] = [:]
        for (period, fallback) in Self.periods {
            guard
                let minutesString = defaults.string(forKey: "\(period.rawValue)_minutes"),
                let minutes = Int(minutesString)
            else {
                return [PrayerTimesEntry.placeholder()]
            }
            let label = defaults.string(forKey: "\(period.rawValue)_label") ?? fallback
            let time = defaults.string(forKey: "\(period.rawValue)_time") ?? "--:--"
            prayers[period] = PrayerInfo(period: period, label: label, time: time, minutes: minutes)
        }

        let now = Date()
        let calendar = Calendar.current
        func dateAt(minutes: Int, day: Date = now) -> Date {
            calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
        }

        // Mirrors `currentPrayerPeriod` (Dart): which obligatory prayer is
        // active, or nil during the Ishraq gap between Fajr's end (sunrise)
        // and Dhuhr.
        func currentPeriod(at minuteOfDay: Int) -> PrayerPeriod? {
            let fajr = prayers[.fajr]!.minutes
            let dhuhr = prayers[.dhuhr]!.minutes
            let asr = prayers[.asr]!.minutes
            let maghrib = prayers[.maghrib]!.minutes
            let isha = prayers[.isha]!.minutes
            if minuteOfDay < fajr { return .isha }
            if minuteOfDay < sunriseMinutes { return .fajr }
            if minuteOfDay < dhuhr { return nil }
            if minuteOfDay < asr { return .dhuhr }
            if minuteOfDay < maghrib { return .asr }
            if minuteOfDay < isha { return .maghrib }
            return .isha
        }

        // Mirrors `prayerEnd` (Dart).
        func periodEndTime(_ period: PrayerPeriod) -> String {
            switch period {
            case .fajr: return sunriseTime
            case .dhuhr: return prayers[.asr]!.time
            case .asr: return prayers[.maghrib]!.time
            case .maghrib: return prayers[.isha]!.time
            case .isha: return prayers[.fajr]!.time
            }
        }

        func badge(at minuteOfDay: Int) -> PrayerBadge {
            guard let period = currentPeriod(at: minuteOfDay) else {
                return PrayerBadge(
                    label: "\(ishraqLabel) \(namazWord)".trimmingCharacters(in: .whitespaces),
                    range: "\(sunriseTime) \u{2013} \(prayers[.dhuhr]!.time)"
                )
            }
            let info = prayers[period]!
            return PrayerBadge(
                label: "\(info.label) \(namazWord)".trimmingCharacters(in: .whitespaces),
                range: "\(info.time) \u{2013} \(periodEndTime(period))"
            )
        }

        // Same background art PrayerTimeCard shows for this time of day.
        func themeImage(at minuteOfDay: Int) -> String {
            let fajr = prayers[.fajr]!.minutes
            if minuteOfDay < fajr { return "prayer_theme_4" }
            if minuteOfDay <= 10 * 60 { return "prayer_theme_1" }
            if minuteOfDay <= 16 * 60 { return "prayer_theme_2" }
            if minuteOfDay <= 19 * 60 + 30 { return "prayer_theme_3" }
            return "prayer_theme_4"
        }

        func entry(at date: Date, minuteOfDay: Int) -> PrayerTimesEntry {
            PrayerTimesEntry(
                date: date,
                hasData: true,
                themeImageName: themeImage(at: minuteOfDay),
                hijriDate: hijriDate,
                calendarDate: calendarDate,
                gregorianDate: gregorianDate,
                periodTime: periodTime,
                location: location,
                badge: badge(at: minuteOfDay),
                sunriseLabel: sunriseLabel,
                sunriseTime: sunriseTime,
                sunsetLabel: sunsetLabel,
                sunsetTime: sunsetTime
            )
        }

        // Every boundary today where the badge or the background art
        // changes, plus tomorrow's Fajr - at most a handful of entries.
        let nowMinute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let boundaryMinutes = Set(
            [
                prayers[.fajr]!.minutes, sunriseMinutes, prayers[.dhuhr]!.minutes,
                prayers[.asr]!.minutes, prayers[.maghrib]!.minutes, prayers[.isha]!.minutes,
                10 * 60 + 1, 16 * 60 + 1, 19 * 60 + 31,
            ]
        ).sorted()

        var entries = [entry(at: now, minuteOfDay: nowMinute)]
        for minute in boundaryMinutes where minute > nowMinute {
            entries.append(entry(at: dateAt(minutes: minute), minuteOfDay: minute))
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        entries.append(
            entry(at: dateAt(minutes: prayers[.fajr]!.minutes, day: tomorrow), minuteOfDay: prayers[.fajr]!.minutes)
        )

        return entries
    }
}
