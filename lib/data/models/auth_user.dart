import 'package:flutter/material.dart';

enum AccountRole {
  individualBuyer,
  wholesaleBuyer,
  individualSeller,
  professionalSeller,
  deliveryPartner,
  admin,
}

extension AccountRoleX on AccountRole {
  String get id {
    switch (this) {
      case AccountRole.individualBuyer:
        return 'client_particulier';
      case AccountRole.wholesaleBuyer:
        return 'client_grossiste';
      case AccountRole.individualSeller:
        return 'vendeur_particulier';
      case AccountRole.professionalSeller:
        return 'vendeur_professionnel';
      case AccountRole.deliveryPartner:
        return 'livreur';
      case AccountRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case AccountRole.individualBuyer:
        return 'Client particulier';
      case AccountRole.wholesaleBuyer:
        return 'Client grossiste';
      case AccountRole.individualSeller:
        return 'Partenaire particulier';
      case AccountRole.professionalSeller:
        return 'Partenaire professionnel';
      case AccountRole.deliveryPartner:
        return 'Livreur';
      case AccountRole.admin:
        return 'Administration';
    }
  }

  String get tagline {
    switch (this) {
      case AccountRole.individualBuyer:
        return 'Achetez pour vous';
      case AccountRole.wholesaleBuyer:
        return 'Achetez en gros';
      case AccountRole.individualSeller:
        return 'Proposez vos produits';
      case AccountRole.professionalSeller:
        return 'Gerez un catalogue partenaire';
      case AccountRole.deliveryPartner:
        return 'Livrez les commandes';
      case AccountRole.admin:
        return 'Gerez NovaShop';
    }
  }

  String get description {
    switch (this) {
      case AccountRole.individualBuyer:
        return 'Decouvrez et achetez des produits pour un usage personnel.';
      case AccountRole.wholesaleBuyer:
        return 'Accedez aux tarifs de gros et commandez en grande quantite.';
      case AccountRole.individualSeller:
        return 'Proposez vos produits apres validation NovaShop.';
      case AccountRole.professionalSeller:
        return 'Gerez un catalogue partenaire valide par NovaShop.';
      case AccountRole.deliveryPartner:
        return 'Recuperez et livrez les commandes aux clients.';
      case AccountRole.admin:
        return 'Validez les partenaires et les produits.';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountRole.individualBuyer:
        return Icons.shopping_bag_outlined;
      case AccountRole.wholesaleBuyer:
        return Icons.inventory_2_outlined;
      case AccountRole.individualSeller:
        return Icons.storefront_outlined;
      case AccountRole.professionalSeller:
        return Icons.store_mall_directory_outlined;
      case AccountRole.deliveryPartner:
        return Icons.local_shipping_outlined;
      case AccountRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  bool get isSeller =>
      this == AccountRole.individualSeller ||
      this == AccountRole.professionalSeller;

  bool get isBuyer =>
      this == AccountRole.individualBuyer || this == AccountRole.wholesaleBuyer;

  bool get isDriver => this == AccountRole.deliveryPartner;
  bool get isAdmin => this == AccountRole.admin;

  String get apiRole {
    if (isAdmin) return 'admin';
    if (isSeller) return 'seller';
    if (isDriver) return 'driver';
    return 'client';
  }

  bool get requiresBusinessName => this == AccountRole.professionalSeller;

  static AccountRole fromId(String? id) {
    switch (id) {
      case 'client':
        return AccountRole.individualBuyer;
      case 'seller':
        return AccountRole.individualSeller;
      case 'driver':
        return AccountRole.deliveryPartner;
      case 'admin':
        return AccountRole.admin;
    }

    return AccountRole.values.firstWhere(
      (role) => role.id == id,
      orElse: () => AccountRole.individualBuyer,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone = '',
    this.businessName = '',
    this.avatarUrl,
    this.emailVerified = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final AccountRole role;
  final String businessName;
  final String? avatarUrl;
  final bool emailVerified;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final combined = '$a$b'.toUpperCase();
    if (combined.isNotEmpty) return combined;
    return email.isNotEmpty ? email[0].toUpperCase() : 'N';
  }

  AuthUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    AccountRole? role,
    String? businessName,
    String? avatarUrl,
    bool? emailVerified,
  }) {
    return AuthUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      avatarUrl: avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.id,
      'businessName': businessName,
      'avatarUrl': avatarUrl,
      'emailVerified': emailVerified,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AccountRoleX.fromId(json['role'] as String?),
      businessName: json['businessName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }
}
