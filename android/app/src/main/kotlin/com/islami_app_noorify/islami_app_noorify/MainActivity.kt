package com.islami_app_noorify.islami_app_noorify

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
