import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_app/models/business.dart';

class VariantOption {
  String name;
  num priceAdjustment;
  bool isAvailable;

  VariantOption({
    required this.name,
    required this.priceAdjustment,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'priceAdjustment': priceAdjustment,
      'isAvailable': isAvailable,
    };
  }

  factory VariantOption.fromMap(Map<String, dynamic> map) {
    return VariantOption(
      name: map['name'] as String,
      priceAdjustment: map['priceAdjustment'] as num? ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }
}

class ProductVariant {
  String name;
  bool isMultiSelect;
  bool isRequired;
  List<VariantOption> options;

  ProductVariant({
    required this.name,
    required this.isMultiSelect,
    required this.isRequired,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isMultiSelect': isMultiSelect,
      'isRequired': isRequired,
      'options': options.map((opt) => opt.toMap()).toList(),
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      name: map['name'] as String,
      isMultiSelect: map['isMultiSelect'] as bool? ?? false,
      isRequired: map['isRequired'] as bool? ?? false,
      options: (map['options'] as List?)
              ?.map((opt) => VariantOption.fromMap(opt as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

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
  List<ProductVariant> variants;
  bool allowMultiple;
  bool isAvailable;
  String? address;
  List<String> amenities;

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
    required this.variants,
    required this.allowMultiple,
    this.isAvailable = true,
    this.address,
    this.amenities = const [],
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
      'variants': variants.map((v) => v.toMap()).toList(),
      'allowMultiple': allowMultiple,
      'isAvailable': isAvailable,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (amenities.isNotEmpty) 'amenities': amenities,
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
      variants: (map['variants'] as List?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      allowMultiple: map['allowMultiple'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      address: map['address'] as String?,
      amenities: (map['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceAds.fromJson(String source) =>
      ServiceAds.fromMap(json.decode(source) as Map<String, dynamic>);
}
