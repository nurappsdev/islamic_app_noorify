package com.tuhfatulmuslim.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native Home Screen widget for the app's prayer times - visually built to
 * match the same design `PrayerTimeCard` renders: the time-of-day background
 * art (`theme1..4.png`), a Hijri/Bengali date row, a centre block with the
 * day-period-labelled clock and verified location, the current/next-prayer
 * badge with the sejda icon, and (space permitting) the sunrise/sunset row.
 *
 * All text comes from `widgetData` - the `SharedPreferences` that
 * `PrayerWidgetService` (Dart) fills via `HomeWidget.saveWidgetData` - which
 * mirrors the same [AladhanPrayerTimeService] cache the in-app card reads,
 * so this never shows a fabricated schedule. Which prayer is "current" is
 * recomputed here from the stored minutes-of-day every time the widget
 * renders (mirroring `currentPrayerPeriod`), so a widget that hasn't synced
 * in a while never shows a prayer that has already passed as active.
 */
class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    private enum class WidgetSize { SMALL, MEDIUM, LARGE }

    private enum class Period { FAJR, DHUHR, ASR, MAGHRIB, ISHA }

    private data class PrayerMeta(val key: String, val fallbackLabel: String, val period: Period)

    private val prayers = listOf(
        PrayerMeta("fajr", "Fajr", Period.FAJR),
        PrayerMeta("dhuhr", "Dhuhr", Period.DHUHR),
        PrayerMeta("asr", "Asr", Period.ASR),
        PrayerMeta("maghrib", "Maghrib", Period.MAGHRIB),
        PrayerMeta("isha", "Isha", Period.ISHA),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            render(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val size = sizeOf(appWidgetManager, widgetId)
        val views = when (size) {
            WidgetSize.SMALL -> buildSmall(context, widgetData)
            WidgetSize.MEDIUM -> buildMedium(context, widgetData)
            WidgetSize.LARGE -> buildLarge(context, widgetData)
        }

        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("tuhfatulmuslim://prayer-times"),
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /** Buckets the widget's current cell size into one of the three designs. */
    private fun sizeOf(appWidgetManager: AppWidgetManager, widgetId: Int): WidgetSize {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            minWidth < 200 -> WidgetSize.SMALL
            minHeight < 180 -> WidgetSize.MEDIUM
            else -> WidgetSize.LARGE
        }
    }

    // --- Data ---------------------------------------------------------------

    private data class PrayerEntry(val meta: PrayerMeta, val label: String, val time: String, val minutes: Int)

    private class Schedule(
        val entries: Map<Period, PrayerEntry>,
        val sunriseMinutes: Int,
        val sunriseTime: String,
        val dhuhrTime: String,
    )

    private fun readSchedule(widgetData: SharedPreferences): Schedule? {
        val entries = HashMap<Period, PrayerEntry>()
        for (meta in prayers) {
            val minutes = widgetData.getString("${meta.key}_minutes", null)?.toIntOrNull()
                ?: return null
            entries[meta.period] = PrayerEntry(
                meta = meta,
                label = widgetData.getString("${meta.key}_label", null) ?: meta.fallbackLabel,
                time = widgetData.getString("${meta.key}_time", null) ?: "--:--",
                minutes = minutes,
            )
        }
        val sunriseMinutes = widgetData.getString("widget_sunrise_minutes", null)?.toIntOrNull()
            ?: return null
        return Schedule(
            entries = entries,
            sunriseMinutes = sunriseMinutes,
            sunriseTime = widgetData.getString("widget_sunrise_time", null) ?: "--:--",
            dhuhrTime = entries[Period.DHUHR]?.time ?: "--:--",
        )
    }

    /** Mirrors `currentPrayerPeriod` (Dart): the active obligatory prayer, or
     * `null` during the Ishraq gap between Fajr's end (sunrise) and Dhuhr. */
    private fun currentPeriod(schedule: Schedule, nowMinutes: Int): Period? {
        val fajr = schedule.entries.getValue(Period.FAJR).minutes
        val dhuhr = schedule.entries.getValue(Period.DHUHR).minutes
        val asr = schedule.entries.getValue(Period.ASR).minutes
        val maghrib = schedule.entries.getValue(Period.MAGHRIB).minutes
        val isha = schedule.entries.getValue(Period.ISHA).minutes
        return when {
            nowMinutes < fajr -> Period.ISHA
            nowMinutes < schedule.sunriseMinutes -> Period.FAJR
            nowMinutes < dhuhr -> null
            nowMinutes < asr -> Period.DHUHR
            nowMinutes < maghrib -> Period.ASR
            nowMinutes < isha -> Period.MAGHRIB
            else -> Period.ISHA
        }
    }

    /** Mirrors `prayerEnd` (Dart). */
    private fun periodEndTime(schedule: Schedule, period: Period): String = when (period) {
        Period.FAJR -> schedule.sunriseTime
        Period.DHUHR -> schedule.entries.getValue(Period.ASR).time
        Period.ASR -> schedule.entries.getValue(Period.MAGHRIB).time
        Period.MAGHRIB -> schedule.entries.getValue(Period.ISHA).time
        Period.ISHA -> schedule.entries.getValue(Period.FAJR).time
    }

    private data class Badge(val label: String, val range: String)

    private fun buildBadge(
        widgetData: SharedPreferences,
        schedule: Schedule?,
        nowMinutes: Int,
    ): Badge {
        val namazWord = widgetData.getString("widget_namaz_word", null) ?: ""
        if (schedule == null) {
            return Badge("--", "--:--")
        }
        val period = currentPeriod(schedule, nowMinutes)
        val periodName = if (period == null) {
            widgetData.getString("widget_ishraq_label", null) ?: "--"
        } else {
            schedule.entries.getValue(period).label
        }
        val range = if (period == null) {
            "${schedule.sunriseTime} – ${schedule.dhuhrTime}"
        } else {
            "${schedule.entries.getValue(period).time} – ${periodEndTime(schedule, period)}"
        }
        return Badge("$periodName $namazWord".trim(), range)
    }

    private fun nowMinutes(): Int {
        val now = java.util.Calendar.getInstance()
        return now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE)
    }

    private fun themeDrawable(widgetData: SharedPreferences): Int = when (
        widgetData.getString("widget_theme", null)
    ) {
        "1" -> R.drawable.prayer_theme_1
        "2" -> R.drawable.prayer_theme_2
        "3" -> R.drawable.prayer_theme_3
        "4" -> R.drawable.prayer_theme_4
        else -> R.drawable.prayer_theme_1
    }

    private fun text(widgetData: SharedPreferences, key: String): String =
        widgetData.getString(key, null) ?: ""

    // --- Layouts --------------------------------------------------------------

    private fun buildSmall(context: Context, widgetData: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)
        views.setImageViewResource(R.id.widget_bg, themeDrawable(widgetData))
        val badge = buildBadge(widgetData, readSchedule(widgetData), nowMinutes())
        views.setTextViewText(R.id.small_badge_label, badge.label)
        views.setTextViewText(R.id.small_badge_range, badge.range)
        return views
    }

    private fun buildMedium(context: Context, widgetData: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_medium)
        views.setImageViewResource(R.id.widget_bg, themeDrawable(widgetData))
        views.setTextViewText(R.id.medium_hijri, text(widgetData, "widget_hijri_date"))
        views.setTextViewText(R.id.medium_calendar, text(widgetData, "widget_calendar_date"))
        views.setTextViewText(R.id.medium_date, text(widgetData, "widget_greg_date"))
        views.setTextViewText(R.id.medium_time, text(widgetData, "widget_period_time"))
        views.setTextViewText(R.id.medium_location, text(widgetData, "widget_location"))
        val badge = buildBadge(widgetData, readSchedule(widgetData), nowMinutes())
        views.setTextViewText(R.id.medium_badge_label, badge.label)
        views.setTextViewText(R.id.medium_badge_range, badge.range)
        return views
    }

    private fun buildLarge(context: Context, widgetData: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_large)
        views.setImageViewResource(R.id.widget_bg, themeDrawable(widgetData))
        views.setTextViewText(R.id.large_hijri, text(widgetData, "widget_hijri_date"))
        views.setTextViewText(R.id.large_calendar, text(widgetData, "widget_calendar_date"))
        views.setTextViewText(R.id.large_date, text(widgetData, "widget_greg_date"))
        views.setTextViewText(R.id.large_time, text(widgetData, "widget_period_time"))
        views.setTextViewText(R.id.large_location, text(widgetData, "widget_location"))
        val badge = buildBadge(widgetData, readSchedule(widgetData), nowMinutes())
        views.setTextViewText(R.id.large_badge_label, badge.label)
        views.setTextViewText(R.id.large_badge_range, badge.range)
        views.setTextViewText(R.id.large_sunrise_label, text(widgetData, "widget_sunrise_label"))
        views.setTextViewText(R.id.large_sunrise_time, text(widgetData, "widget_sunrise_time"))
        views.setTextViewText(R.id.large_sunset_label, text(widgetData, "widget_sunset_label"))
        views.setTextViewText(R.id.large_sunset_time, text(widgetData, "widget_sunset_time"))
        return views
    }
}
