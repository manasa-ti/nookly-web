import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/purchased_feature.dart';
import 'package:hushmate/domain/repositories/purchased_features_repository.dart';

// Events
abstract class PurchasedFeaturesEvent extends Equatable {
  const PurchasedFeaturesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPurchasedFeatures extends PurchasedFeaturesEvent {
  const LoadPurchasedFeatures();
}

class PurchaseFeature extends PurchasedFeaturesEvent {
  final String featureId;
  const PurchaseFeature(this.featureId);

  @override
  List<Object?> get props => [featureId];
}

class CancelSubscription extends PurchasedFeaturesEvent {
  final String featureId;
  const CancelSubscription(this.featureId);

  @override
  List<Object?> get props => [featureId];
}

// States
abstract class PurchasedFeaturesState extends Equatable {
  const PurchasedFeaturesState();

  @override
  List<Object?> get props => [];
}

class PurchasedFeaturesInitial extends PurchasedFeaturesState {
  const PurchasedFeaturesInitial();
}

class PurchasedFeaturesLoading extends PurchasedFeaturesState {
  const PurchasedFeaturesLoading();
}

class PurchasedFeaturesLoaded extends PurchasedFeaturesState {
  final List<PurchasedFeature> features;
  const PurchasedFeaturesLoaded(this.features);

  @override
  List<Object?> get props => [features];
}

class PurchasedFeaturesError extends PurchasedFeaturesState {
  final String message;
  const PurchasedFeaturesError(this.message);

  @override
  List<Object?> get props => [message];
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