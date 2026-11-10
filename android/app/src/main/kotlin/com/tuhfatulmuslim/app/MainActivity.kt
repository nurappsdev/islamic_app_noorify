package com.tuhfatulmuslim.app

import android.content.Context
import android.hardware.GeomagneticField
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * `flutter_compass`'s Android side reports heading relative to *magnetic*
 * north (from the rotation-vector sensor), with no declination correction —
 * unlike iOS, where `CLHeading.trueHeading` is already true-north-corrected.
 * The Qiblah bearing from the dashboard API is a true-north bearing, so the
 * Qiblah compass (see `QiblahHeadingListener`) calls this channel to convert
 * magnetic heading to true heading using the same `GeomagneticField` API
 * native Android compass apps use.
 */
class MainActivity : AudioServiceActivity() {
    private val geomagneticChannel = "islami_app_noorify/geomagnetic"
    private val alarmsChannel = "islami_app_noorify/alarms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // `android_alarm_manager_plus` remembers every alarm it armed with
        // `rescheduleOnReboot` (all of ours) in its own SharedPreferences, but
        // offers no Dart API to list them. The app reads that list so it can
        // cancel alarms it no longer knows about - ones armed under a server
        // id, by an older version, or whose cancel once failed - instead of
        // leaving them to ring daily.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "persistedAlarmIds") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val prefs = getSharedPreferences(
                    "dev.fluttercommunity.plus.android_alarm_manager_plugin",
                    Context.MODE_PRIVATE
                )
                val ids = prefs.getStringSet("persistent_alarm_ids", emptySet())
                    ?.mapNotNull { it.toIntOrNull() }
                    ?: emptyList()
                result.success(ids)
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, geomagneticChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "declination") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val altitude = call.argument<Double>("altitude") ?: 0.0
                if (latitude == null || longitude == null) {
                    result.error("missing_args", "latitude/longitude required", null)
                    return@setMethodCallHandler
                }
                val field = GeomagneticField(
                    latitude.toFloat(),
                    longitude.toFloat(),
                    altitude.toFloat(),
                    System.currentTimeMillis()
                )
                result.success(field.declination.toDouble())
            }
    }
}
