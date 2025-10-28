import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nookly/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:nookly/domain/repositories/conversation_repository.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/domain/entities/message.dart';

import 'disappearing_image_bloc_test.mocks.dart';

@GenerateMocks([ConversationRepository, SocketService])
void main() {
  group('Disappearing Image Bloc Tests', () {
    late MockConversationRepository mockConversationRepository;
    late MockSocketService mockSocketService;
    late ConversationBloc conversationBloc;
    const currentUserId = 'test_user_id';

    setUp(() {
      mockConversationRepository = MockConversationRepository();
      mockSocketService = MockSocketService();
      conversationBloc = ConversationBloc(
        conversationRepository: mockConversationRepository,
        socketService: mockSocketService,
        currentUserId: currentUserId,
      );
    });

    tearDown(() {
      conversationBloc.close();
    });

    test('initial state should be ConversationInitial', () {
      expect(conversationBloc.state, equals(ConversationInitial()));
    });

    group('LoadConversation', () {
      blocTest<ConversationBloc, ConversationState>(
        'emits [ConversationLoading, ConversationLoaded] when conversation loads successfully',
        build: () {
          when(mockConversationRepository.getMessages(
            participantId: anyNamed('participantId'),
            page: anyNamed('page'),
            pageSize: anyNamed('pageSize'),
          )).thenAnswer((_) async => {
            'messages': <Message>[],
            'pagination': {'hasMore': false}
          });
          return conversationBloc;
        },
        act: (bloc) => bloc.add(LoadConversation(
          participantId: 'participant_id',
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
          lastSeen: DateTime.now().toIso8601String(),
          connectionStatus: 'connected',
        )),
        expect: () => [
          ConversationLoading(),
          isA<ConversationLoaded>(),
        ],
        verify: (_) {
          verify(mockConversationRepository.getMessages(
            participantId: anyNamed('participantId'),
            page: anyNamed('page'),
            pageSize: anyNamed('pageSize'),
          )).called(1);
        },
      );

      blocTest<ConversationBloc, ConversationState>(
        'emits [ConversationLoading, ConversationError] when conversation load fails',
        build: () {
          when(mockConversationRepository.getMessages(
            participantId: anyNamed('participantId'),
            page: anyNamed('page'),
            pageSize: anyNamed('pageSize'),
          )).thenThrow(Exception('Failed to load conversation'));
          return conversationBloc;
        },
        act: (bloc) => bloc.add(LoadConversation(
          participantId: 'participant_id',
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
          lastSeen: DateTime.now().toIso8601String(),
          connectionStatus: 'connected',
        )),
        expect: () => [
          ConversationLoading(),
          ConversationError('Failed to load conversation: Exception: Failed to load conversation'),
        ],
        verify: (_) {
          verify(mockConversationRepository.getMessages(
            participantId: anyNamed('participantId'),
            page: anyNamed('page'),
            pageSize: anyNamed('pageSize'),
          )).called(1);
        },
      );
    });

    group('SendTextMessage', () {
      blocTest<ConversationBloc, ConversationState>(
        'calls sendTextMessage when message is sent',
        build: () {
          when(mockConversationRepository.getMessages(
            participantId: anyNamed('participantId'),
            page: anyNamed('page'),
            pageSize: anyNamed('pageSize'),
          )).thenAnswer((_) async => {
            'messages': <Message>[],
            'pagination': {'hasMore': false}
          });
          when(mockConversationRepository.sendTextMessage(any, any))
              .thenAnswer((_) async => {});
          return conversationBloc;
        },
        act: (bloc) {
          // First load a conversation
          bloc.add(LoadConversation(
            participantId: 'participant_id',
            participantName: 'Test User',
            participantAvatar: null,
            isOnline: true,
            lastSeen: DateTime.now().toIso8601String(),
            connectionStatus: 'connected',
          ));
          // Then send a message
          bloc.add(SendTextMessage(
            conversationId: 'participant_id',
            content: 'Hello, world!',
          ));
        },
        expect: () => [
          ConversationLoading(),
          isA<ConversationLoaded>(),
        ],
        verify: (_) {
          verify(mockConversationRepository.sendTextMessage(any, any)).called(1);
        },
      );
    });
  });
}
