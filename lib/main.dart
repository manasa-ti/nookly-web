import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/di/injection_container.dart' as di;
import 'package:hushmate/presentation/bloc/auth/auth_bloc.dart';
import 'package:hushmate/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:hushmate/presentation/bloc/chat/chat_bloc.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/bloc/purchased_features/purchased_features_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_bloc.dart';
import 'package:hushmate/presentation/pages/splash/splash_screen.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
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
        RepositoryProvider(
          create: (context) => di.sl<AuthRepository>(),
        ),
      ],
      child: MaterialApp(
        title: 'HushMate',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
} 