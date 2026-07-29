import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class Usuario {
  String id;
  String username;
  String email;
  String image;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.image,
  });

  UserDetails toDetails() {
    return UserDetails(id: id, username: username, image: image);
  }
}

class UserDetails {
  String id;
  String username;
  String image;

  UserDetails({required this.id, required this.username, required this.image});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'username': username, 'image': image};
  }

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      id: map['id'] as String,
      username: map['username'] as String,
      image: map['image'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDetails.fromJson(String source) =>
      UserDetails.fromMap(json.decode(source) as Map<String, dynamic>);
}
