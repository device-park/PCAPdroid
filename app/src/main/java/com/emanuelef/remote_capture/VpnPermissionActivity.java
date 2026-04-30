/*
 * VPN Permission Activity
 * Sadece VPN permission almak için - UI yok
 */

package com.emanuelef.remote_capture;

import android.app.Activity;
import android.content.Intent;
import android.net.VpnService;
import android.os.Bundle;
import android.util.Log;
import androidx.core.content.ContextCompat;
import com.emanuelef.remote_capture.model.CaptureSettings;

public class VpnPermissionActivity extends Activity {
    private static final String TAG = "VpnPermissionActivity";
    private static final int VPN_REQUEST_CODE = 100;
    
    public static CaptureSettings pendingSettings = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        Log.d(TAG, "VPN permission check started");
        
        // VPN permission kontrolü
        Intent vpnIntent = VpnService.prepare(this);
        
        if (vpnIntent != null) {
            // Permission yok, iste
            Log.i(TAG, "Requesting VPN permission");
            startActivityForResult(vpnIntent, VPN_REQUEST_CODE);
        } else {
            // Permission zaten var
            Log.i(TAG, "VPN permission already granted");
            startCaptureService();
            finish();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                Log.i(TAG, "VPN permission granted");
                startCaptureService();
            } else {
                Log.e(TAG, "VPN permission denied");
            }
            finish();
        }
    }

    private void startCaptureService() {
        if (pendingSettings == null) {
            Log.e(TAG, "No pending settings!");
            return;
        }
        
        try {
            Intent serviceIntent = new Intent(this, CaptureService.class);
            serviceIntent.putExtra("settings", pendingSettings);
            
            ContextCompat.startForegroundService(this, serviceIntent);
            Log.i(TAG, "Capture service started");
            
            pendingSettings = null;
        } catch (Exception e) {
            Log.e(TAG, "Failed to start service: " + e.getMessage(), e);
        }
    }
}
