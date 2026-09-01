package com.example.agro_aplicaciones

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

/**
 * BootReceiver — reactiva la jornada GPS al encender el teléfono.
 *
 * Si había una jornada activa cuando se apagó el dispositivo, la clave
 * "gps_tracking_registro_id" en SharedPreferences lo indica. Este receiver
 * lanza la MainActivity con un flag especial para que Flutter detecte la
 * condición y llame a GpsTrackingService.resumeIfActive().
 *
 * Flujo:
 *   1. Teléfono enciende → ACTION_BOOT_COMPLETED llega aquí.
 *   2. Si "gps_tracking_registro_id" existe en prefs → lanzar MainActivity.
 *   3. Flutter (_cargarJornada en home_page.dart) llama resumeIfActive()
 *      y el rastreo se reanuda desde MAX(secuencia) en SQLite.
 *
 * Requiere en AndroidManifest.xml:
 *   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
 *   <receiver android:name=".BootReceiver" android:exported="true">
 *       <intent-filter>
 *           <action android:name="android.intent.action.BOOT_COMPLETED" />
 *           <action android:name="android.intent.action.QUICKBOOT_POWERON" />
 *       </intent-filter>
 *   </receiver>
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val PREFS_NAME      = "FlutterSharedPreferences"
        private const val KEY_REGISTRO_ID = "flutter.gps_tracking_registro_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON") return

        // Leer SharedPreferences escritas por Flutter (flutter. prefix)
        val prefs: SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val registroId = prefs.getString(KEY_REGISTRO_ID, null) ?: return

        // Hay una jornada activa — lanzar la app para reanudar el GPS
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("boot_resume_registro_id", registroId)
        }

        try {
            context.startActivity(launchIntent)
        } catch (_: Exception) {
            // En algunos Android 10+ startActivity desde background está
            // restringido; el GPS se reanudará cuando el usuario abra la app.
        }
    }
}
