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
          gender: '',
          bio: '',
          interests: [],
          profilePicture: null,
          location: null,
          preferences: null,
          birthdate: null,
          sex: null,
          wishToFind: null,
          hometown: null,
          minAgePreference: 18,
          maxAgePreference: 80,
          profilePictureUrl: null,
          objective: null,
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
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: event.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateSex(UpdateSex event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: event.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateWishToFind(UpdateWishToFind event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: event.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateHometown(UpdateHometown event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: event.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
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
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: event.minAge,
      maxAgePreference: event.maxAge,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateBio(UpdateBio event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: event.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateName(UpdateName event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: event.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
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
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: event.profilePictureUrl,
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
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: event.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: _currentUser.objective,
    );
    _emitLoadedState();
  }

  void _onUpdateObjective(UpdateObjective event, Emitter<ProfileState> emit) {
    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: _currentUser.name,
      age: _currentUser.age,
      gender: _currentUser.gender,
      bio: _currentUser.bio,
      interests: _currentUser.interests,
      profilePicture: _currentUser.profilePicture,
      location: _currentUser.location,
      preferences: _currentUser.preferences,
      birthdate: _currentUser.birthdate,
      sex: _currentUser.sex,
      wishToFind: _currentUser.wishToFind,
      hometown: _currentUser.hometown,
      minAgePreference: _currentUser.minAgePreference,
      maxAgePreference: _currentUser.maxAgePreference,
      profilePictureUrl: _currentUser.profilePictureUrl,
      objective: event.objective,
    );
    _emitLoadedState();
  }

  Future<void> _onSaveProfile(SaveProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      // Get the current user from auth repository
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        emit(const ProfileError('No authenticated user found'));
        return;
      }

      // Update the current user with the latest changes
      _currentUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: _currentUser.name,
        age: _currentUser.age,
        gender: _currentUser.gender,
        bio: _currentUser.bio,
        interests: _currentUser.interests,
        profilePicture: _currentUser.profilePicture,
        location: _currentUser.location,
        preferences: _currentUser.preferences,
        birthdate: _currentUser.birthdate,
        sex: _currentUser.sex,
        wishToFind: _currentUser.wishToFind,
        hometown: _currentUser.hometown,
        minAgePreference: _currentUser.minAgePreference,
        maxAgePreference: _currentUser.maxAgePreference,
        profilePictureUrl: _currentUser.profilePictureUrl,
        objective: _currentUser.objective,
      );

      // Save the profile
      await _authRepository.updateUserProfile(_currentUser);
      emit(ProfileSaved(_currentUser));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
} 