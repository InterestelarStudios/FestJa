// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_business/models/user.dart';

class Business {
  String id;
  String name;
  String logo;
  String region;
  String type;
  String? description;
  String? address;
  String? phone;
  String? email;
  String? website;
  List images;
  UserDetails creator;
  List categories;
  GeoPoint geoPoint;
  Timestamp created;

  Business({
    required this.id,
    required this.name,
    required this.logo,
    required this.region,
    required this.type,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.website,
    required this.images,
    required this.creator,
    required this.categories,
    required this.geoPoint,
    required this.created,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'logo': logo,
      'region': region,
      'type': type,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'creator': creator.toMap(),
      'categories': categories,
      'images': images,
      'geoPoint': geoPoint,
      'created': created,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      name: map['name'] as String,
      logo: map['logo'] as String,
      region: map['region'] as String,
      type: map['type'] as String,
      description: map['description'] != null
          ? map['description'] as String
          : null,
      address: map['address'] != null ? map['address'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      website: map['website'] != null ? map['website'] as String : null,
      creator: UserDetails.fromMap(map['creator'] as Map<String, dynamic>),
      categories: List.from((map['categories'] as List)),
      images: map['images'] != null ? List.from((map['images'] as List)) : [],
      geoPoint: map['geoPoint'] as GeoPoint,
      created: map['created'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Business.fromJson(String source) =>
      Business.fromMap(json.decode(source) as Map<String, dynamic>);

  BusinessDetails toDetails() {
    return BusinessDetails(
      id: id,
      name: name,
      logo: logo,
      region: region,
      categories: categories,
    );
  }
}

class BusinessDetails {
  String id;
  String name;
  String logo;
  String region;
  List categories;

  BusinessDetails({
    required this.id,
    required this.name,
    required this.logo,
    required this.region,
    required this.categories,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'logo': logo,
      'region': region,
      'categories': categories,
    };
  }

  factory BusinessDetails.fromMap(Map<String, dynamic> map) {
    return BusinessDetails(
      id: map['id'] as String,
      name: map['name'] as String,
      logo: map['logo'] as String,
      region: map['region'] as String,
      categories: List.from((map['categories'] as List)),
    );
  }

  String toJson() => json.encode(toMap());

  factory BusinessDetails.fromJson(String source) =>
      BusinessDetails.fromMap(json.decode(source) as Map<String, dynamic>);
}
