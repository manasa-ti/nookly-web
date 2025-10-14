package com.nookly.app

import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    
    // Nookly App Theme Colors
    companion object {
        const val PRIMARY_COLOR = "#667eea"        // Nookly primary blue
        const val SECONDARY_COLOR = "#234481"      // Nookly dark blue
        const val ACCENT_COLOR = "#FF1493"         // Hot pink for matches/likes
        const val SUCCESS_COLOR = "#4CAF50"        // Green for social activity
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Create channel groups
            createChannelGroups(notificationManager)
            
            // Create all notification channels
            createMessagesChannel(notificationManager)
            createMatchesAndLikesChannel(notificationManager)
            createSocialActivityChannel(notificationManager)
            createAppUpdatesChannel(notificationManager)
            createPromotionsChannel(notificationManager)
            createCallsChannel(notificationManager)
            createDefaultChannel(notificationManager)
        }
    }
    
    private fun createChannelGroups(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val coreGroup = NotificationChannelGroup(
                "core_features",
                "Dating Features"
            )
            
            val engagementGroup = NotificationChannelGroup(
                "engagement",
                "Engagement & Updates"
            )
            
            notificationManager.createNotificationChannelGroups(listOf(coreGroup, engagementGroup))
        }
    }
    
    /**
     * Messages Channel - Chat messages
     */
    private fun createMessagesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "messages",
                "Chat Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "New messages from your matches"
                group = "core_features"
                
                enableLights(true)
                lightColor = Color.parseColor(PRIMARY_COLOR)
                
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
                
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
                
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Matches & Likes Channel - New matches, likes, super likes
     */
    private fun createMatchesAndLikesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "matches_likes",
                "Matches & Likes",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "New matches, likes, and super likes"
                group = "core_features"
                
                enableLights(true)
                lightColor = Color.parseColor(ACCENT_COLOR)
                
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 100, 100, 100, 100, 100)
                
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Social Activity Channel - Profile views, interests
     */
    private fun createSocialActivityChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "social_activity",
                "Social Activity",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Profile views, interests, and social updates"
                group = "engagement"
                
                enableLights(true)
                lightColor = Color.parseColor(SUCCESS_COLOR)
                
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 200)
                
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * App Updates Channel - Daily recommendations, tips
     */
    private fun createAppUpdatesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "app_updates",
                "App Updates & Tips",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Daily recommendations, reminders, and helpful tips"
                group = "engagement"
                
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
                
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Promotions Channel - Special offers, premium features
     */
    private fun createPromotionsChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "promotions",
                "Promotions & Offers",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Special offers, premium features, and events"
                group = "engagement"
                
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
                
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Calls Channel - Video/Voice calls
     */
    private fun createCallsChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "calls",
                "Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming video and voice calls"
                group = "core_features"
                
                enableLights(true)
                lightColor = Color.parseColor(PRIMARY_COLOR)
                
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Default Channel - Fallback for miscellaneous notifications
     */
    private fun createDefaultChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "default_channel",
                "General",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General app notifications"
                
                enableLights(true)
                lightColor = Color.parseColor(PRIMARY_COLOR)
                
                enableVibration(true)
                setShowBadge(true)
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
} 