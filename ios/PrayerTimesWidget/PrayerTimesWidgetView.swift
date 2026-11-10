import SwiftUI
import WidgetKit

/// The palette `PrayerTimeCard` uses for its text and the badge pill, kept
/// identical here so the widget reads as an extension of the card.
private enum PrayerPalette {
    static let border = Color(red: 0xD9 / 255, green: 0xDE / 255, blue: 0xA8 / 255)
    static let strongText = Color(red: 0x3F / 255, green: 0x5A / 255, blue: 0x4A / 255)
    static let mutedText = Color(red: 0x5B / 255, green: 0x85 / 255, blue: 0x6F / 255)
    static let badgeFill = Color(red: 0xE4 / 255, green: 0xED / 255, blue: 0xB6 / 255)
    static let badgeBorder = Color(red: 0xA2 / 255, green: 0xB2 / 255, blue: 0x53 / 255)
    static let centerPill = Color.white.opacity(0.8)
}

/// Full-bleed time-of-day art behind everything, cropped and clipped the
/// same way the Android layouts crop `prayer_theme_<n>`.
private struct ThemeBackground: View {
    let imageName: String

    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
}

private struct CardFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(PrayerPalette.border, lineWidth: 1)
            )
    }
}

/// White text with a soft shadow, for labels that sit directly on the photo
/// (the date row and, on Large, the sunrise/sunset row).
private struct OnPhotoText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

private extension View {
    func cardFrame() -> some View { modifier(CardFrame()) }
    func onPhotoText() -> some View { modifier(OnPhotoText()) }

    /// `containerBackground` is the iOS 17+ way to set a widget's
    /// background (and avoids the legacy default padding/material iOS adds
    /// around widgets that don't use it); `.background()` is the fallback
    /// this extension's iOS 16 minimum needs.
    @ViewBuilder
    func widgetBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) { background() }
        } else {
            self.background(background())
        }
    }
}

private struct DateRow: View {
    let entry: PrayerTimesEntry

    var body: some View {
        HStack {
            Text(entry.hijriDate).lineLimit(1)
            Spacer()
            Text(entry.calendarDate).lineLimit(1)
        }
        .font(.system(size: 10).italic())
        .onPhotoText()
    }
}

private struct CenterBlock: View {
    let entry: PrayerTimesEntry
    let timeFont: Font

    var body: some View {
        VStack(spacing: 1) {
            Text(entry.gregorianDate)
                .font(.system(size: 9))
                .foregroundStyle(PrayerPalette.mutedText)
            Text(entry.periodTime)
                .font(timeFont)
                .foregroundStyle(PrayerPalette.strongText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(entry.location)
                .font(.system(size: 9))
                .foregroundStyle(PrayerPalette.mutedText)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(PrayerPalette.centerPill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PrayerBadgeView: View {
    let entry: PrayerTimesEntry
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            Image("prayer_sejda_icon")
                .resizable()
                .scaledToFit()
                .padding(compact ? 4 : 6)
                .frame(width: compact ? 26 : 34, height: compact ? 26 : 34)
                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.badge.label)
                    .font(.system(size: compact ? 11 : 13))
                    .lineLimit(1)
                Text(entry.badge.range)
                    .font(.system(size: compact ? 10 : 12))
                    .lineLimit(1)
            }
            .foregroundStyle(.black)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 11)
        .padding(.vertical, compact ? 6 : 8)
        .background(PrayerPalette.badgeFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PrayerPalette.badgeBorder, lineWidth: 1)
        )
    }
}

private struct SunEdgeRow: View {
    let entry: PrayerTimesEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.sunriseLabel).font(.system(size: 10))
                Text(entry.sunriseTime).font(.system(size: 12, weight: .bold))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(entry.sunsetLabel).font(.system(size: 10))
                Text(entry.sunsetTime).font(.system(size: 12, weight: .bold))
            }
        }
        .lineLimit(1)
        .onPhotoText()
    }
}

struct PrayerTimesSmallView: View {
    let entry: PrayerTimesEntry

    var body: some View {
        VStack(spacing: 2) {
            Text(entry.badge.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PrayerPalette.strongText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(entry.badge.range)
                .font(.system(size: 11))
                .foregroundStyle(PrayerPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PrayerPalette.centerPill)
        .widgetBackground { ThemeBackground(imageName: entry.themeImageName) }
        .cardFrame()
    }
}

struct PrayerTimesMediumView: View {
    let entry: PrayerTimesEntry

    var body: some View {
        VStack(spacing: 6) {
            DateRow(entry: entry)
            Spacer(minLength: 0)
            CenterBlock(entry: entry, timeFont: .system(size: 15, weight: .bold))
            PrayerBadgeView(entry: entry, compact: true)
        }
        .padding(12)
        .widgetBackground { ThemeBackground(imageName: entry.themeImageName) }
        .cardFrame()
    }
}

struct PrayerTimesLargeView: View {
    let entry: PrayerTimesEntry

    var body: some View {
        VStack(spacing: 8) {
            DateRow(entry: entry)
            Spacer(minLength: 0)
            CenterBlock(entry: entry, timeFont: .system(size: 20, weight: .bold))
            PrayerBadgeView(entry: entry, compact: false)
            SunEdgeRow(entry: entry)
        }
        .padding(16)
        .widgetBackground { ThemeBackground(imageName: entry.themeImageName) }
        .cardFrame()
    }
}
