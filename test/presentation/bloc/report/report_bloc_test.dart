import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nookly/presentation/bloc/report/report_bloc.dart';
import 'package:nookly/presentation/bloc/report/report_event.dart';
import 'package:nookly/presentation/bloc/report/report_state.dart';
import 'package:nookly/domain/repositories/report_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'report_bloc_test.mocks.dart';

@GenerateMocks([ReportRepository])
void main() {
  late ReportBloc bloc;
  late MockReportRepository mockRepository;

  setUp(() {
    mockRepository = MockReportRepository();
    bloc = ReportBloc(reportRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ReportBloc', () {
    test('initial state should be ReportInitial', () {
      expect(bloc.state, isA<ReportInitial>());
    });

    blocTest<ReportBloc, ReportState>(
      'emits [ReportLoading, ReportReasonsLoaded] when LoadReportReasons is successful',
      build: () {
        when(mockRepository.getReportReasons()).thenAnswer(
          (_) async => ['Spam', 'Harassment', 'Fake Profile'],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadReportReasons()),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportReasonsLoaded>(),
      ],
      verify: (bloc) {
        verify(mockRepository.getReportReasons()).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportLoading, ReportError] when LoadReportReasons fails',
      build: () {
        when(mockRepository.getReportReasons()).thenThrow(
          Exception('Failed to load reasons'),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadReportReasons()),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportError>(),
      ],
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportSubmitting, ReportSubmitted] when ReportUser is successful',
      build: () {
        when(mockRepository.reportUser(
          reportedUserId: 'user123',
          reason: 'Spam',
          details: 'Test details',
        )).thenAnswer(
          (_) async => {
            'message': 'User reported successfully',
            'uniqueReporters': 1,
            'isBanned': false,
          },
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        ReportUser(
          reportedUserId: 'user123',
          reason: 'Spam',
          details: 'Test details',
        ),
      ),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportSubmitted>(),
      ],
      verify: (bloc) {
        verify(mockRepository.reportUser(
          reportedUserId: 'user123',
          reason: 'Spam',
          details: 'Test details',
        )).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [ReportLoading, ReportError] when ReportUser fails',
      build: () {
        when(mockRepository.reportUser(
          reportedUserId: 'user123',
          reason: 'Spam',
          details: null,
        )).thenThrow(
          Exception('Failed to submit report'),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        ReportUser(
          reportedUserId: 'user123',
          reason: 'Spam',
        ),
      ),
      expect: () => [
        isA<ReportLoading>(),
        isA<ReportError>(),
      ],
    );
  });
} 