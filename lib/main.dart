import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/di/injection_container.dart' as di;
import 'package:hushmate/core/services/call_service.dart';
import 'package:hushmate/core/services/auth_handler.dart';
import 'package:hushmate/core/network/network_service.dart';
import 'package:hushmate/presentation/bloc/auth/auth_bloc.dart';
import 'package:hushmate/presentation/bloc/auth/auth_event.dart';
import 'package:hushmate/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:hushmate/presentation/bloc/chat/chat_bloc.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/bloc/purchased_features/purchased_features_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_bloc.dart';
import 'package:hushmate/presentation/bloc/report/report_bloc.dart';
import 'package:hushmate/presentation/pages/splash/splash_screen.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/presentation/pages/home/home_page.dart';
import 'package:hushmate/presentation/pages/auth/login_page.dart';
import 'package:hushmate/presentation/pages/auth/sign_up_page.dart';
import 'package:hushmate/presentation/widgets/auth_wrapper.dart';
import 'package:logger/logger.dart';
import 'package:hushmate/core/utils/logger.dart';

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
  logger.i('Initializing HushMate application...');
  
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
          title: 'HushMate',
          navigatorKey: AuthHandler.navigatorKey, // Add global navigator key
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
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
