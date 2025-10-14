import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/services/deep_link_service.dart';
import 'package:nookly/core/services/heartbeat_service.dart';
import 'package:nookly/core/services/location_service.dart';
import 'package:nookly/core/services/firebase_messaging_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add some initial logging
  logger.i('Initializing Nookly application...');
  
  // Debug: Print current environment and API URL
  logger.i('Current Environment: ${EnvironmentManager.currentEnvironment}');
  logger.i('API Base URL: ${EnvironmentManager.baseUrl}');
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    logger.i('✅ Firebase initialized');
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    logger.i('✅ Firebase background message handler set');
    
    await di.init();
    logger.i('Dependency injection initialized');
    
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
  
  // Update location on app launch (silent failure)
  final locationService = di.sl<LocationService>();
  locationService.updateLocationOnAppLaunch();
  logger.i('Location update initiated on app launch');
  
  runApp(const MyApp());
  logger.i('Application started');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global ScaffoldMessenger key for consistent SnackBar display
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

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
          navigatorKey: FirebaseMessagingService.navigatorKey ?? AuthHandler.navigatorKey, // Firebase notifications and auth navigation
          scaffoldMessengerKey: scaffoldMessengerKey, // Add global scaffold messenger key
          theme: AppTheme.theme,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginPage(),
          },
        ),
      ),
    );
  }
} 
