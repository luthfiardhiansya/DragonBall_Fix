import 'package:flutter/foundation.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.className,
    this.photoPath,
    this.photoBytes,
  });

  final String name;
  final String className;
  final String? photoPath;
  final Uint8List? photoBytes;

  UserProfile copyWith({
    String? name,
    String? className,
    String? photoPath,
    Uint8List? photoBytes,
  }) {
    return UserProfile(
      name: name ?? this.name,
      className: className ?? this.className,
      photoPath: photoPath ?? this.photoPath,
      photoBytes: photoBytes ?? this.photoBytes,
    );
  }
}

final ValueNotifier<UserProfile> appProfile = ValueNotifier<UserProfile>(
  const UserProfile(
    name: 'Muhammad Luthfi Ardhiansyah',
    className: 'XII RPL 3',
  ),
);
