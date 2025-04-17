import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/purchased_feature.dart';
import 'package:hushmate/domain/repositories/purchased_features_repository.dart';

// Events
abstract class PurchasedFeaturesEvent {}

class LoadPurchasedFeatures extends PurchasedFeaturesEvent {}

class PurchaseFeature extends PurchasedFeaturesEvent {
  final String featureId;
  PurchaseFeature(this.featureId);
}

class CancelSubscription extends PurchasedFeaturesEvent {
  final String featureId;
  CancelSubscription(this.featureId);
}

// States
abstract class PurchasedFeaturesState {}

class PurchasedFeaturesInitial extends PurchasedFeaturesState {}

class PurchasedFeaturesLoading extends PurchasedFeaturesState {}

class PurchasedFeaturesLoaded extends PurchasedFeaturesState {
  final List<PurchasedFeature> features;
  PurchasedFeaturesLoaded(this.features);
}

class PurchasedFeaturesError extends PurchasedFeaturesState {
  final String message;
  PurchasedFeaturesError(this.message);
}

// Bloc
class PurchasedFeaturesBloc extends Bloc<PurchasedFeaturesEvent, PurchasedFeaturesState> {
  final PurchasedFeaturesRepository repository;

  PurchasedFeaturesBloc({required this.repository}) : super(PurchasedFeaturesInitial()) {
    on<LoadPurchasedFeatures>(_onLoadPurchasedFeatures);
    on<PurchaseFeature>(_onPurchaseFeature);
    on<CancelSubscription>(_onCancelSubscription);
  }

  Future<void> _onLoadPurchasedFeatures(
    LoadPurchasedFeatures event,
    Emitter<PurchasedFeaturesState> emit,
  ) async {
    emit(PurchasedFeaturesLoading());
    try {
      final features = await repository.getPurchasedFeatures();
      emit(PurchasedFeaturesLoaded(features));
    } catch (e) {
      emit(PurchasedFeaturesError(e.toString()));
    }
  }

  Future<void> _onPurchaseFeature(
    PurchaseFeature event,
    Emitter<PurchasedFeaturesState> emit,
  ) async {
    try {
      await repository.purchaseFeature(event.featureId);
      // Refresh the features list after purchase
      add(LoadPurchasedFeatures());
    } catch (e) {
      emit(PurchasedFeaturesError(e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<PurchasedFeaturesState> emit,
  ) async {
    try {
      await repository.cancelSubscription(event.featureId);
      // Refresh the features list after cancellation
      add(LoadPurchasedFeatures());
    } catch (e) {
      emit(PurchasedFeaturesError(e.toString()));
    }
  }
} 