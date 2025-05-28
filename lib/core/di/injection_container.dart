import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:hushmate/data/repositories/auth_repository_impl.dart';
import 'package:hushmate/data/repositories/chat_repository_impl.dart';
import 'package:hushmate/data/repositories/conversation_repository_impl.dart';
import 'package:hushmate/data/repositories/matches_repository_impl.dart';
import 'package:hushmate/data/repositories/purchased_features_repository_impl.dart';
import 'package:hushmate/data/repositories/received_likes_repository_impl.dart';
import 'package:hushmate/data/repositories/recommended_profiles_repository_impl.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/domain/repositories/chat_repository.dart';
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/domain/repositories/matches_repository.dart';
import 'package:hushmate/domain/repositories/purchased_features_repository.dart';
import 'package:hushmate/domain/repositories/received_likes_repository.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';
import 'package:hushmate/presentation/bloc/auth/auth_bloc.dart';
import 'package:hushmate/presentation/bloc/chat/chat_bloc.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:hushmate/presentation/bloc/purchased_features/purchased_features_bloc.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:hushmate/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_bloc.dart';
import 'package:hushmate/core/network/socket_service.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  
  sl.registerLazySingleton<RecommendedProfilesRepository>(
    () => RecommendedProfilesRepositoryImpl(),
  );
  
  sl.registerLazySingleton<ReceivedLikesRepository>(
    () => ReceivedLikesRepositoryImpl(recommendedProfilesRepository: sl()),
  );
  
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(),
  );
  
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<MatchesRepository>(
    () => MatchesRepositoryImpl(),
  );
  
  sl.registerLazySingleton<PurchasedFeaturesRepository>(
    () => PurchasedFeaturesRepositoryImpl(),
  );
  
  sl.registerLazySingleton<SocketService>(() => SocketService());
  
  // Blocs
  sl.registerFactory(
    () => AuthBloc(authRepository: sl()),
  );
  
  sl.registerFactory(
    () => RecommendedProfilesBloc(repository: sl()),
  );
  
  sl.registerFactory(
    () => ReceivedLikesBloc(repository: sl()),
  );
  
  sl.registerFactory(
    () => ChatBloc(chatRepository: sl()),
  );
  
  sl.registerFactory(
    () => ConversationBloc(
      conversationRepository: sl(),
      socketService: sl(),
      currentUserId: '', // Will be updated after initialization
    ),
  );

  sl.registerFactoryParam<InboxBloc, String, void>(
    (currentUserId, _) => InboxBloc(
      conversationRepository: sl(),
      matchesRepository: sl(),
      currentUserId: currentUserId,
    ),
  );
  
  sl.registerFactory(
    () => PurchasedFeaturesBloc(repository: sl()),
  );

  sl.registerFactory(
    () => ProfileBloc(authRepository: sl()),
  );
} 