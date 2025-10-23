import 'dart:convert';

class User {
  final int? id;
  final String email;
  final String firstName;
  final String lastName;
  final String? faceEmbedding; // JSON string olarak saklanır
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.faceEmbedding,
    required this.createdAt,
  });

  // Database'den gelen Map'i User objesine çevir
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      faceEmbedding: map['face_embedding'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // User objesini Map'e çevir (database'e yazmak için)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'face_embedding': faceEmbedding,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Embedding'i List<double> olarak al
  List<double> get embeddingList {
    if (faceEmbedding == null) return [];
    try {
      final List<dynamic> list = json.decode(faceEmbedding!);
      return list.map((e) => double.parse(e.toString())).toList();
    } catch (e) {
      return [];
    }
  }

  // Embedding'i set et
  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? faceEmbedding,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, firstName: $firstName, lastName: $lastName}';
  }
}
