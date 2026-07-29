// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_app/models/user.dart';

class Event {
  String id;
  String title;
  List categories;
  Timestamp date;
  UserDetails owner;
  Timestamp created;
  dynamic people;
  String? description;
  String? image;
  GeoPoint? geoPoint;
  String? address;
  String? region;

  Event({
    required this.id,
    required this.title,
    required this.categories,
    required this.date,
    required this.owner,
    required this.created,
    required this.people,
    this.description,
    this.image,
    this.geoPoint,
    this.address,
    this.region,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'categories': categories,
      'date': date,
      'owner': owner.toMap(),
      'created': created,
      'people': people,
      'description': description,
      'image': image,
      'geoPoint': geoPoint,
      'address': address,
      'region': region,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String? ?? '',
      title: map['title'] as String,
      categories: List.from((map['categories'] as List)),
      date: map['date'] as Timestamp,
      owner: UserDetails.fromMap(map['owner'] as Map<String, dynamic>),
      created: map['created'] as Timestamp,
      people: map['people'] ?? 0,
      description: map['description'] != null
          ? map['description'] as String
          : null,
      image: map['image'] != null ? map['image'] as String : null,
      geoPoint: map['geoPoint'] != null ? map['geoPoint'] as GeoPoint : null,
      address: map['address'] != null ? map['address'] as String : null,
      region: map['region'] != null ? map['region'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Event.fromJson(String source) =>
      Event.fromMap(json.decode(source) as Map<String, dynamic>);
}
