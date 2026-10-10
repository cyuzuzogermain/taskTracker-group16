/// A person on the project team who can be assigned tasks.
class TeamMember {
  final String id;
  final String name;
  final String role;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
  });

  /// Up to two letters for the avatar, taken from the first two words of
  /// the name. 'Mitchell Barure' gives 'MB' and 'Naomi' gives 'N'.
  String get initials {
    final words = name.trim().split(' ').where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  /// Returns a copy with the given fields changed. The id never changes.
  TeamMember copyWith({String? name, String? role}) {
    return TeamMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  /// Converts the member to a map that can be saved as JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }

  /// Rebuilds a member from a map read out of storage.
  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
    );
  }
}
