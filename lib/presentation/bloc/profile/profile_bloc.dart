import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/presentation/bloc/profile/profile_event.dart';
import 'package:hushmate/presentation/bloc/profile/profile_state.dart';

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
    on<SaveProfile>(_onSaveProfile);

    // Initialize with current user
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _emitLoadedState();
    }
  }

  void _emitLoadedState() {
    final isProfileComplete = _currentUser.birthdate != null &&
        _currentUser.sex != null &&
        _currentUser.wishToFind != null &&
        _currentUser.hometown != null &&
        _currentUser.minAgePreference != null &&
        _currentUser.maxAgePreference != null &&
        _currentUser.bio != null &&
        _currentUser.name != null &&
        _currentUser.profilePictureUrl != null &&
        _currentUser.interests != null &&
        _currentUser.interests!.isNotEmpty &&
        _currentUser.objective != null;

    emit(ProfileLoaded(
      user: _currentUser,
      isProfileComplete: isProfileComplete,
    ));
  }

  void _onUpdateBirthdate(UpdateBirthdate event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: event.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateSex(UpdateSex event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: event.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateWishToFind(UpdateWishToFind event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: event.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateHometown(UpdateHometown event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: event.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateAgePreferences(
    UpdateAgePreferences event,
    Emitter<ProfileState> emit,
  ) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: event.minAge,
      maxAgePreference: event.maxAge,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateBio(UpdateBio event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: event.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateName(UpdateName event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: event.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onRegenerateName(RegenerateName event, Emitter<ProfileState> emit) {
    // TODO: Implement name generation logic
    final generatedName = 'Generated Name ${DateTime.now().millisecondsSinceEpoch}';
    _onUpdateName(UpdateName(generatedName), emit);
  }

  void _onUpdateProfilePicture(
    UpdateProfilePicture event,
    Emitter<ProfileState> emit,
  ) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: event.profilePictureUrl,
      interests: _currentUser.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onRegenerateProfilePicture(
    RegenerateProfilePicture event,
    Emitter<ProfileState> emit,
  ) {
    // TODO: Implement profile picture generation logic
    final generatedPictureUrl =
        'https://api.hushmate.com/generate-profile-picture/${DateTime.now().millisecondsSinceEpoch}';
    _onUpdateProfilePicture(UpdateProfilePicture(generatedPictureUrl), emit);
  }

  void _onUpdateInterests(UpdateInterests event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: event.interests,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateObjective(UpdateObjective event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      bio: _currentUser.bio,
      name: _currentUser.name,
      profilePictureUrl: _currentUser.profilePictureUrl,
      interests: _currentUser.interests,
      objective: event.objective,
    );
    _emitLoadedState();
  }

  Future<void> _onSaveProfile(SaveProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      // TODO: Implement profile saving logic
      await Future.delayed(const Duration(seconds: 1)); // Simulated API call
      emit(ProfileSaved(_currentUser));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
} 