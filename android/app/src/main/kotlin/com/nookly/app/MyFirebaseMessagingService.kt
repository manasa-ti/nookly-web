package com.nookly.app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "From: ${remoteMessage.from}")
        
        // Check if message contains a data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
            // Handle data payload here
            // You can pass this data to Flutter side using MethodChannel if needed
        }
        
        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Title: ${it.title}")
            Log.d(TAG, "Message Notification Body: ${it.body}")
            // Notification is automatically displayed by FCM
            // Additional custom handling can be added here
        }
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed FCM token: $token")
        
        // If you want to send the token to your app server, do it here
        // You can also pass this to Flutter side using MethodChannel
        sendRegistrationToServer(token)
    }
    
    private fun sendRegistrationToServer(token: String) {
        // TODO: Implement this method to send token to your app server
        Log.d(TAG, "Token sent to server: $token")
    }
    
    companion object {
        private const val TAG = "FCMService"
    }
}


