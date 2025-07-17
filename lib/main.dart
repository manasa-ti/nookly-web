import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/core/services/call_service.dart';
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:nookly/presentation/bloc/chat/chat_bloc.dart';
import 'package:nookly/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:nookly/presentation/bloc/purchased_features/purchased_features_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_bloc.dart';
import 'package:nookly/presentation/bloc/report/report_bloc.dart';
import 'package:nookly/presentation/pages/splash/splash_screen.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/presentation/pages/auth/sign_up_page.dart';
import 'package:nookly/presentation/widgets/auth_wrapper.dart';
import 'package:logger/logger.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/config/environment_manager.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add some initial logging
  logger.i('Initializing Nookly application...');
  
  // Debug: Print current environment and API URL
  logger.i('Current Environment: ${EnvironmentManager.currentEnvironment}');
  logger.i('API Base URL: ${EnvironmentManager.baseUrl}');
  
  await di.init();
  logger.i('Dependency injection initialized');
  
  // Initialize Agora
  await CallService().initialize();
  
  runApp(const MyApp());
  logger.i('Application started');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        RepositoryProvider(
          create: (context) => di.sl<AuthRepository>(),
        ),
      ],
      child: AuthWrapper(
        child: MaterialApp(
          title: 'nookly',
          navigatorKey: AuthHandler.navigatorKey, // Add global navigator key
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4C5C8A),
              onPrimary: Colors.white,
              surface: Color(0xFF35548b),
              onSurface: Colors.white,
              background: Color(0xFF234481),
              onBackground: Colors.white,
            ),
            useMaterial3: true,
            fontFamily: 'Nunito',
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.white,
              selectionColor: Color(0xFF4C5C8A),
              selectionHandleColor: Color(0xFF4C5C8A),
            ),
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginPage(),
          },
        ),
      ),
    );
  }
} 
