import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/user.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateBirthdate extends ProfileEvent {
  final DateTime birthdate;

  const UpdateBirthdate(this.birthdate);

  @override
  List<Object?> get props => [birthdate];
}

class UpdateSex extends ProfileEvent {
  final String sex;

  const UpdateSex(this.sex);

  @override
  List<Object?> get props => [sex];
}

class UpdateWishToFind extends ProfileEvent {
  final String wishToFind;

  const UpdateWishToFind(this.wishToFind);

  @override
  List<Object?> get props => [wishToFind];
}

class UpdateHometown extends ProfileEvent {
  final String hometown;

  const UpdateHometown(this.hometown);

  @override
  List<Object?> get props => [hometown];
}

class UpdateAgePreferences extends ProfileEvent {
  final int minAge;
  final int maxAge;

  const UpdateAgePreferences({
    required this.minAge,
    required this.maxAge,
  });

  @override
  List<Object?> get props => [minAge, maxAge];
}

class UpdateBio extends ProfileEvent {
  final String bio;

  const UpdateBio(this.bio);

  @override
  List<Object?> get props => [bio];
}

class UpdateName extends ProfileEvent {
  final String name;

  const UpdateName(this.name);

  @override
  List<Object?> get props => [name];
}

class RegenerateName extends ProfileEvent {}

class UpdateProfilePicture extends ProfileEvent {
  final String profilePictureUrl;

  const UpdateProfilePicture(this.profilePictureUrl);

  @override
  List<Object?> get props => [profilePictureUrl];
}

class RegenerateProfilePicture extends ProfileEvent {}

class UpdateInterests extends ProfileEvent {
  final List<String> interests;

  const UpdateInterests(this.interests);

  @override
  List<Object?> get props => [interests];
}

class UpdateObjective extends ProfileEvent {
  final List<String> objectives;

  const UpdateObjective(this.objectives);

  @override
  List<Object?> get props => [objectives];
}

class UpdateDistanceRadius extends ProfileEvent {
  final int distanceRadius;

  const UpdateDistanceRadius(this.distanceRadius);

  @override
  List<Object?> get props => [distanceRadius];
}

class SaveProfile extends ProfileEvent {
  final User user;

  const SaveProfile(this.user);

  @override
  List<Object?> get props => [user];
} 