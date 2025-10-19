import 'package:nookly/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/bloc/profile/profile_event.dart';
import 'package:nookly/presentation/bloc/profile/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;
  late User _currentUser;

  ProfileBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(ProfileInitial()) {
    on<UpdateBirthdate>(_onUpdateBirthdate);
    on<UpdateSex>(_onUpdateSex);
    on<UpdateWishToFind>(_onUpdateWishToFind);
    on<UpdateHometown>(_onUpdateHometown);
    on<UpdateAgePreferences>(_onUpdateAgePreferences);
    on<UpdateBio>(_onUpdateBio);
    on<UpdateName>(_onUpdateName);
    on<RegenerateName>(_onRegenerateName);
    on<UpdateProfilePicture>(_onUpdateProfilePicture);
    on<RegenerateProfilePicture>(_onRegenerateProfilePicture);
    on<UpdateInterests>(_onUpdateInterests);
    on<UpdateObjective>(_onUpdateObjective);
    on<UpdateDistanceRadius>(_onUpdateDistanceRadius);
    on<SaveProfile>(_onSaveProfile);

    // Initialize with current user
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _emitLoadedState();
      } else {
        // Initialize with a default user if no user exists yet
        _currentUser = User(
          id: '',
          email: '',
          name: '',
          age: 0,
          sex: null,
          seekingGender: null,
          location: null,
          preferredAgeRange: null,
          hometown: null,
          bio: null,
          interests: null,
          objectives: null,
          profilePic: null,
          preferredDistanceRadius: null,
        );
        _emitLoadedState();
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  void _emitLoadedState() {
    emit(ProfileLoaded(
      user: _currentUser,
      isProfileComplete: _currentUser.isProfileComplete,
    ));
  }

  void _onUpdateBirthdate(UpdateBirthdate event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: DateTime.now().difference(event.birthdate).inDays ~/ 365,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateSex(UpdateSex event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: event.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateWishToFind(UpdateWishToFind event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: event.wishToFind,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateHometown(UpdateHometown event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: event.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateAgePreferences(UpdateAgePreferences event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: {
        'lower_limit': event.minAge,
        'upper_limit': event.maxAge,
      },
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateBio(UpdateBio event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: event.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateName(UpdateName event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: event.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onRegenerateName(RegenerateName event, Emitter<ProfileState> emit) {
    // TODO: Implement name generation logic
    final generatedName = 'Generated Name ${DateTime.now().millisecondsSinceEpoch}';
    _onUpdateName(UpdateName(generatedName), emit);
  }

  void _onUpdateProfilePicture(UpdateProfilePicture event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: event.profilePictureUrl,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onRegenerateProfilePicture(
    RegenerateProfilePicture event,
    Emitter<ProfileState> emit,
  ) {
    // TODO: Implement profile picture generation logic
    final imageUrl = 'https://api.nookly.com/generate-profile-picture/${DateTime.now().millisecondsSinceEpoch}';
    _onUpdateProfilePicture(UpdateProfilePicture(imageUrl), emit);
  }

  void _onUpdateInterests(UpdateInterests event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: event.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateObjective(UpdateObjective event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: event.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: _currentUser.preferredDistanceRadius,
    );
    _emitLoadedState();
  }

  void _onUpdateDistanceRadius(UpdateDistanceRadius event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      sex: _currentUser.sex,
      seekingGender: _currentUser.seekingGender,
      location: _currentUser.location,
      preferredAgeRange: _currentUser.preferredAgeRange,
      hometown: _currentUser.hometown,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      objectives: _currentUser.objectives,
      profilePic: _currentUser.profilePic,
      preferredDistanceRadius: event.distanceRadius,
    );
    _emitLoadedState();
  }

  Future<void> _onSaveProfile(SaveProfile event, Emitter<ProfileState> emit) async {
    try {
      AppLogger.info('ProfileBloc: Starting to save profile');
      emit(ProfileLoading());
      await _authRepository.updateUserProfile(event.user);
      AppLogger.info('ProfileBloc: Profile saved successfully');
      emit(ProfileSaved(event.user));
    } catch (e) {
      AppLogger.info('ProfileBloc: Error saving profile: $e');
      emit(ProfileError(e.toString()));
    }
  }
} 