import 'json_utils.dart';

/// A delivery address stored in Supabase.
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line,
    required this.city,
    required this.phone,
    this.country = 'France',
    this.isDefault = false,
    this.mapImageUrl,
  });

  final String id;
  final String label;
  final String line;
  final String city;
  final String country;
  final String phone;
  final bool isDefault;
  final String? mapImageUrl;

  String get fullAddress => '$line, $city, $country';

  Address copyWith({
    String? label,
    String? line,
    String? city,
    String? country,
    String? phone,
    bool? isDefault,
    String? mapImageUrl,
  }) {
    return Address(
      id: id,
      label: label ?? this.label,
      line: line ?? this.line,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      mapImageUrl: mapImageUrl ?? this.mapImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'line': line,
      'city': city,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'mapImageUrl': mapImageUrl,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: Json.str(json['id']),
      label: Json.str(json['label']),
      line: Json.str(json['line']),
      city: Json.str(json['city']),
      country: Json.str(json['country'], 'France'),
      phone: Json.str(json['phone']),
      isDefault: Json.boolean(json['isDefault']),
      mapImageUrl: Json.strOrNull(json['mapImageUrl']),
    );
  }
}
