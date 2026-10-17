import SwiftUI
import WidgetKit

struct PrayerTimesWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerTimesEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PrayerTimesSmallView(entry: entry)
        case .systemLarge:
            PrayerTimesLargeView(entry: entry)
        default:
            PrayerTimesMediumView(entry: entry)
        }
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Today's prayer times and a countdown to the next prayer.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct PrayerTimesWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
    }
}
