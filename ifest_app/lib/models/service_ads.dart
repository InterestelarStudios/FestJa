// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_app/models/business.dart';

class ServiceAds {
  String id;
  String title;
  String description;
  List categories;
  List images;
  num price;
  BusinessDetails business;
  Timestamp creted;
  String region;
  GeoPoint geoPoint;

  ServiceAds({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    required this.images,
    required this.price,
    required this.business,
    required this.creted,
    required this.geoPoint,
    required this.region,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'categories': categories,
      'images': images,
      'price': price,
      'business': business.toMap(),
      'creted': creted,
      'geoPoint': geoPoint,
      'region': region,
    };
  }

  factory ServiceAds.fromMap(Map<String, dynamic> map) {
    return ServiceAds(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      categories: List.from((map['categories'] as List)),
      images: List.from((map['images'] as List)),
      price: map['price'] as num,
      business: BusinessDetails.fromMap(
        map['business'] as Map<String, dynamic>,
      ),
      creted: map['creted'] as Timestamp,
      geoPoint: map['geoPoint'] as GeoPoint,
      region: map['region'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceAds.fromJson(String source) =>
      ServiceAds.fromMap(json.decode(source) as Map<String, dynamic>);
}
