import 'package:app/data/models/mol_card.model.dart';
import 'package:app/data/models/mol_gastro_category.model.dart';
import 'package:app/data/models/mol_service.model.dart';
import 'package:dart_util_box/dart_util_box.dart';

/// MOL-specific enrichment data for a station.
class MolData {
  const MolData({
    required this.molCode,
    required this.company,
    required this.brand,
    required this.name,
    required this.address,
    required this.city,
    required this.postcode,
    required this.lat,
    required this.lng,
    required this.status,
    required this.shopSize,
    required this.numOfPos,
    required this.services,
    required this.cards,
    required this.gastro,
  });

  final String molCode;
  final String? company;
  final String? brand;
  final String? name;
  final String? address;
  final String? city;
  final String? postcode;
  final double? lat;
  final double? lng;
  final String? status;
  final int? shopSize;
  final int? numOfPos;
  final List<MolService> services;
  final List<MolCard> cards;
  final List<MolGastroCategory> gastro;

  factory MolData.fromJson(Map<String, dynamic> json) => MolData(
    molCode: json['molCode'] as String,
    company: json['company'] as String?,
    brand: json['brand'] as String?,
    name: json['name'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    postcode: json['postcode'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    status: json['status'] as String?,
    shopSize: json['shopSize'] as int?,
    numOfPos: json['numOfPos'] as int?,
    services: (json['services'] as List<dynamic>).mapToList(
      (e) => MolService.fromJson(e as Map<String, dynamic>),
    ),
    cards: (json['cards'] as List<dynamic>).mapToList(
      (e) => MolCard.fromJson(e as Map<String, dynamic>),
    ),
    gastro: (json['gastro'] as List<dynamic>).mapToList(
      (e) => MolGastroCategory.fromJson(e as Map<String, dynamic>),
    ),
  );
}
