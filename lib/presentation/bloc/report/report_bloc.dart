import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/repositories/report_repository.dart';
import 'package:nookly/presentation/bloc/report/report_event.dart';
import 'package:nookly/presentation/bloc/report/report_state.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/domain/repositories/auth_repository.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;
  final AnalyticsService _analyticsService;
  final AuthRepository _authRepository;

  ReportBloc({
    required ReportRepository reportRepository,
    AnalyticsService? analyticsService,
    AuthRepository? authRepository,
  })  : _reportRepository = reportRepository,
        _analyticsService = analyticsService ?? di.sl<AnalyticsService>(),
        _authRepository = authRepository ?? di.sl<AuthRepository>(),
        super(ReportInitial()) {
    on<LoadReportReasons>(_onLoadReportReasons);
    on<ReportUser>(_onReportUser);
  }

  Future<void> _onLoadReportReasons(
    LoadReportReasons event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final reasons = await _reportRepository.getReportReasons();
      emit(ReportReasonsLoaded(reasons));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onReportUser(
    ReportUser event,
    Emitter<ReportState> emit,
  ) async {
    // If we have reasons loaded, show submitting state with reasons
    if (state is ReportReasonsLoaded) {
      final currentState = state as ReportReasonsLoaded;
      emit(ReportSubmitting(currentState.reasons));
    } else {
      emit(ReportLoading());
    }

    try {
      final result = await _reportRepository.reportUser(
        reportedUserId: event.reportedUserId,
        reason: event.reason,
        details: event.details,
      );

      // Track user reported
      try {
        final currentUser = await _authRepository.getCurrentUser();
        if (currentUser != null) {
          _analyticsService.logUserReported(
            reporteeId: event.reportedUserId,
            reporterId: currentUser.id,
          );
        }
      } catch (e) {
        // Analytics failure shouldn't block the report
      }

      emit(ReportSubmitted(
        message: result['message'] as String,
        uniqueReporters: result['uniqueReporters'] as int,
        isBanned: result['isBanned'] as bool,
      ));
    } catch (e) {
      // If we had reasons loaded before, keep them in error state
      if (state is ReportSubmitting) {
        emit(ReportError(e.toString()));
      } else {
        emit(ReportError(e.toString()));
      }
    }
  }
} 