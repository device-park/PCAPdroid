/*
 * Headless Capture Control via Broadcast
 * Pure service-based approach without Activity
 */

package com.emanuelef.remote_capture;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;
import androidx.preference.PreferenceManager;
import androidx.core.content.ContextCompat;
import com.emanuelef.remote_capture.model.CaptureSettings;
import com.emanuelef.remote_capture.model.Prefs;

public class CaptureControlReceiver extends BroadcastReceiver {
    public static final String ACTION_START_CAPTURE = "com.emanuelef.remote_capture.START_CAPTURE";
    public static final String ACTION_STOP_CAPTURE = "com.emanuelef.remote_capture.STOP_CAPTURE";
    public static final String ACTION_GET_STATUS = "com.emanuelef.remote_capture.GET_STATUS";
    
    private static final String TAG = "CaptureControlReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (action == null) {
            Log.e(TAG, "No action provided");
            return;
        }

        Log.i(TAG, "Received action: " + action);

        // API Key validation
        String api_key = intent.getStringExtra("api_key");
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        String my_key = Prefs.getApiKey(prefs);

        if (api_key == null || !my_key.equals(api_key)) {
            Log.e(TAG, "Invalid or missing API key");
            setResultCode(-1);
            return;
        }

        switch (action) {
            case ACTION_START_CAPTURE:
                startCapture(context, intent);
                break;
            case ACTION_STOP_CAPTURE:
                stopCapture(context);
                break;
            case ACTION_GET_STATUS:
                getStatus(context);
                break;
            default:
                Log.e(TAG, "Unknown action: " + action);
                setResultCode(-1);
        }
    }

    private void startCapture(Context context, Intent intent) {
        if (CaptureService.isServiceActive()) {
            Log.w(TAG, "Capture already running");
            setResultCode(0);
            return;
        }

        try {
            CaptureSettings settings = new CaptureSettings(context, intent);
            
            // Root capture ise direkt başlat
            if (settings.root_capture || settings.readFromPcap()) {
                Intent serviceIntent = new Intent(context, CaptureService.class);
                serviceIntent.putExtra("settings", settings);
                ContextCompat.startForegroundService(context, serviceIntent);
                Log.i(TAG, "Capture started (root/pcap mode)");
                setResultCode(0);
                return;
            }
            
            // VPN için - önce permission kontrolü
            android.net.VpnService.prepare(context);
            Intent vpnIntent = android.net.VpnService.prepare(context);
            
            if (vpnIntent == null) {
                // Permission zaten var, direkt başlat
                Intent serviceIntent = new Intent(context, CaptureService.class);
                serviceIntent.putExtra("settings", settings);
                ContextCompat.startForegroundService(context, serviceIntent);
                Log.i(TAG, "Capture started (VPN permission already granted)");
                setResultCode(0);
            } else {
                // Permission gerekli - Notification göster
                VpnPermissionActivity.pendingSettings = settings;
                showVpnPermissionNotification(context);
                Log.i(TAG, "VPN permission required - notification shown");
                setResultCode(0);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to start capture: " + e.getMessage(), e);
            setResultCode(-1);
        }
    }
    
    private void showVpnPermissionNotification(Context context) {
        android.app.NotificationManager nm = (android.app.NotificationManager) 
            context.getSystemService(Context.NOTIFICATION_SERVICE);
        
        // Notification channel (Android 8.0+)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            android.app.NotificationChannel channel = new android.app.NotificationChannel(
                "vpn_permission",
                "VPN Permission",
                android.app.NotificationManager.IMPORTANCE_HIGH
            );
            nm.createNotificationChannel(channel);
        }
        
        // PendingIntent for permission activity
        Intent permIntent = new Intent(context, VpnPermissionActivity.class);
        permIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        
        android.app.PendingIntent pendingIntent = android.app.PendingIntent.getActivity(
            context, 0, permIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT | android.app.PendingIntent.FLAG_IMMUTABLE
        );
        
        // Build notification
        android.app.Notification notification = new android.app.Notification.Builder(context, "vpn_permission")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("PCAPdroid VPN Permission")
            .setContentText("Tap to grant VPN permission and start capture")
            .setPriority(android.app.Notification.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build();
        
        nm.notify(1001, notification);
    }

    private void stopCapture(Context context) {
        if (!CaptureService.isServiceActive()) {
            Log.w(TAG, "Capture not running");
            setResultCode(0);
            return;
        }

        CaptureService.stopService();
        Log.i(TAG, "Capture stopped");
        setResultCode(0);
    }

    private void getStatus(Context context) {
        boolean isRunning = CaptureService.isServiceActive();
        Log.i(TAG, "Capture status: " + (isRunning ? "running" : "stopped"));
        setResultCode(isRunning ? 1 : 0);
    }
}
