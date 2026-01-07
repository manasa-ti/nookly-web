import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'firebase_options.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/services/deep_link_service.dart';
import 'package:nookly/core/services/heartbeat_service.dart';
import 'package:nookly/core/services/location_service.dart';
import 'package:nookly/core/services/firebase_messaging_service.dart';
import 'package:nookly/core/services/crash_reporting_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/services/analytics_route_observer.dart';
import 'package:nookly/data/repositories/notification_repository.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:nookly/presentation/bloc/chat/chat_bloc.dart';
import 'package:nookly/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:nookly/presentation/bloc/purchased_features/purchased_features_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_bloc.dart';
import 'package:nookly/presentation/bloc/report/report_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_bloc.dart';
import 'package:nookly/presentation/pages/splash/splash_screen.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/presentation/widgets/auth_wrapper.dart';
import 'package:logger/logger.dart';
import 'package:nookly/core/config/environment_manager.dart';
import 'package:nookly/core/theme/app_theme.dart';
import 'package:nookly/core/services/screen_protection_service.dart';
import 'package:nookly/core/services/remote_config_service.dart';
import 'package:nookly/core/utils/logger.dart';

// Create a global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  
  logger.i('📬 Background message received: ${message.messageId}');
  logger.i('Message data: ${message.data}');
  
  if (message.notification != null) {
    logger.i('Notification Title: ${message.notification?.title}');
    logger.i('Notification Body: ${message.notification?.body}');
  }
  
  // Handle the background message here
  // You can update local database, show notification, etc.
}

void main() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add some initial logging
  logger.i('Initializing Nookly application...');
  
  // Debug: Print current environment and API URL
  logger.i('Current Environment: ${EnvironmentManager.currentEnvironment}');
  logger.i('API Base URL: ${EnvironmentManager.baseUrl}');
  
  // Initialize Firebase
  try {
    // Check if Firebase is already initialized (prevents re-initialization errors)
    if (Firebase.apps.isEmpty) {
      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('✅ Firebase initialized');
    } else {
      logger.i('✅ Firebase already initialized (${Firebase.apps.length} app(s))');
    }
    
    // Set background message handler (not available on web)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      logger.i('✅ Firebase background message handler set');
    } else {
      logger.i('⚠️ Background message handler skipped on web');
    }
    
    await di.init();
    logger.i('Dependency injection initialized');
    
    // Initialize Remote Config (needed for screen protection)
    try {
      final remoteConfigService = di.sl<RemoteConfigService>();
      // Use initializeDefaultsOnly() to avoid blocking app startup with network fetch
      // The fetch will happen in background, but defaults are available immediately
      await remoteConfigService.initializeDefaultsOnly();
      logger.i('✅ Remote Config initialized with defaults');
      
      // Fetch remote values in background (non-blocking)
      remoteConfigService.fetchAndActivate().then((_) {
        logger.i('✅ Remote Config fetch completed');
      }).catchError((e) {
        logger.e('❌ Remote Config fetch failed (using defaults): $e');
        logger.e('❌ Error type: ${e.runtimeType}');
        if (e is Error) {
          logger.e('❌ Stack trace: ${e.stackTrace}');
        }
      });
    } catch (e) {
      logger.w('⚠️ Remote Config initialization failed (using defaults): $e');
      // Continue - defaults will be used
    }
    
    // Initialize Crash Reporting and Analytics (must be after di.init())
    try {
      final crashReportingService = di.sl<CrashReportingService>();
      await crashReportingService.initialize();
      logger.i('✅ Crash reporting initialized');
      
      final analyticsService = di.sl<AnalyticsService>();
      await analyticsService.initialize();
      logger.i('✅ Analytics initialized');
      
      // Initialize Performance Monitoring (only if Firebase is initialized)
      if (Firebase.apps.isNotEmpty) {
        try {
          final performance = FirebasePerformance.instance;
          await performance.setPerformanceCollectionEnabled(true); // Enabled for all environments
          logger.i('✅ Performance monitoring initialized');
          
          // Track app startup time
          final startupTrace = performance.newTrace('app_startup');
          startupTrace.start();
          startupStopwatch.stop();
          startupTrace.putAttribute('startup_time_ms', startupStopwatch.elapsedMilliseconds.toString());
          startupTrace.putAttribute('environment', EnvironmentManager.currentEnvironment.toString());
          startupTrace.stop();
          logger.i('📊 App startup tracked: ${startupStopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          logger.w('⚠️ Performance monitoring failed: $e');
        }
      } else {
        logger.w('⚠️ Performance monitoring skipped - Firebase not initialized');
      }
    } catch (e, stackTrace) {
      logger.e('❌ Error initializing analytics/crash reporting: $e');
      logger.e('Stack trace: $stackTrace');
      // Continue - analytics failures shouldn't block app startup
    }
    
  // Initialize Firebase Messaging
  final firebaseMessagingService = FirebaseMessagingService();
  
  // Set navigator key for notification navigation
  FirebaseMessagingService.navigatorKey = GlobalKey<NavigatorState>();
  
  await firebaseMessagingService.initialize();
  logger.i('✅ Firebase Messaging initialized');
  
  // Handle FCM token refresh
  final notificationRepository = di.sl<NotificationRepository>();
  firebaseMessagingService.onTokenRefresh = (newToken) async {
    await notificationRepository.onTokenRefresh(newToken);
  };
  } catch (e, stackTrace) {
    logger.e('❌ Firebase initialization failed: $e');
    logger.e('Stack trace: $stackTrace');
    logger.w('⚠️ App will continue without Firebase features');
    logger.w('⚠️ iOS: Make sure GoogleService-Info.plist is added to Xcode project');
    logger.w('⚠️ Android: Make sure google-services.json is in android/app/');
    
    // Continue with app initialization
    await di.init();
    logger.i('Dependency injection initialized');
  }
  
  // Initialize Deep Link Service
  DeepLinkService().initialize();
  
  // Initialize Heartbeat Service
  final heartbeatService = di.sl<HeartbeatService>();
  heartbeatService.initialize();
  logger.i('Heartbeat service initialized');
  
  startupStopwatch.stop();
  logger.i('🚀 App initialization completed in ${startupStopwatch.elapsedMilliseconds}ms');
  
  // Start the app immediately - don't block UI on location
  runApp(const MyApp());
  logger.i('Application started');
  
  // Update location in background after app starts (non-blocking)
  _updateLocationInBackground();
}

/// Update location in background without blocking app startup
Future<void> _updateLocationInBackground() async {
  try {
    logger.i('📍 Starting background location update...');
    final locationService = di.sl<LocationService>();
    await locationService.updateLocationOnAppLaunch();
    logger.i('✅ Background location update completed');
  } catch (e) {
    logger.e('❌ Background location update failed: $e');
    // Silent failure - don't affect app startup
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Global ScaffoldMessenger key for consistent SnackBar display
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();
      
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLocationUpdateInProgress = false;
  ScreenProtectionService? _screenProtectionService;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize screen protection at app launch for iOS
    _initializeScreenProtection();
  }

  Future<void> _initializeScreenProtection() async {
    try {
      _screenProtectionService = di.sl<ScreenProtectionService>();
      // Enable protection globally at app launch (iOS needs early activation)
      // This ensures protection is active before any screens are shown
      await _screenProtectionService!.enableProtection(
        screenType: 'chat', // Default screen type, will be overridden by individual screens
        context: null, // Context not available yet, but protection can still be enabled
      );
      AppLogger.info('🔒 Screen protection enabled at app launch');
    } catch (e) {
      AppLogger.error('Failed to enable screen protection at app launch', e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-enable protection when app resumes (iOS may need this)
      _screenProtectionService?.enableProtection(
        screenType: 'chat',
        context: null,
      );
      
      // App resumed from background (e.g., from settings)
      // Add small delay to let chat observer handle socket reconnection first
      Future.delayed(const Duration(milliseconds: 100), () {
        _updateLocationOnResume();
      });
    }
  }

  Future<void> _updateLocationOnResume() async {
    // Prevent concurrent location updates
    if (_isLocationUpdateInProgress) {
      logger.i('📍 Location update already in progress, skipping...');
      return;
    }
    
    try {
      _isLocationUpdateInProgress = true;
      logger.i('📍 App resumed, checking location permission...');
      final locationService = di.sl<LocationService>();
      await locationService.updateLocationOnAppLaunch();
      logger.i('✅ Resume location update completed');
    } catch (e) {
      logger.e('❌ Error updating location on resume: $e');
    } finally {
      _isLocationUpdateInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<RecommendedProfilesBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ReceivedLikesBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ChatBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ConversationBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<PurchasedFeaturesBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ProfileBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ReportBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<GamesBloc>(),
        ),
        RepositoryProvider(
          create: (context) => di.sl<AuthRepository>(),
        ),
      ],
      child: AuthWrapper(
        child: MaterialApp(
          title: 'nookly',
          debugShowCheckedModeBanner: false, // Hide debug banner in all modes
          navigatorKey: FirebaseMessagingService.navigatorKey ?? AuthHandler.navigatorKey, // Firebase notifications and auth navigation
          scaffoldMessengerKey: MyApp.scaffoldMessengerKey, // Add global scaffold messenger key
          theme: AppTheme.theme,
          navigatorObservers: [
            AnalyticsRouteObserver(), // Track screen views automatically
          ],
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginPage(),
          },
        ),
      ),
    );
  }
} 
