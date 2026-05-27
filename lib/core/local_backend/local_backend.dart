import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/auth_user.dart';

class LocalBackendException implements Exception {
  const LocalBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalBackend {
  LocalBackend._();

  static final LocalBackend instance = LocalBackend._();

  static const _usersKey = 'novaishop.local.users';
  static const _shopsKey = 'novaishop.local.shops';
  static const _vendorsKey = 'novaishop.local.vendors';
  static const _listingsKey = 'novaishop.local.listings';

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required AccountRole role,
    String phone = '',
    String businessName = '',
  }) async {
    final users = await _readList(_usersKey);
    final normalizedEmail = email.trim().toLowerCase();
    if (users.any((user) => user['email'] == normalizedEmail)) {
      throw const LocalBackendException(
          'Un compte existe deja avec cet email.');
    }

    final user = AuthUser(
      id: _id('user'),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: role,
      businessName: businessName.trim(),
      emailVerified: true,
    );
    users.add({
      ...user.toJson(),
      'password': password,
      'createdAt': _now(),
    });
    await _writeList(_usersKey, users);
    return _authPayload(user);
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final users = await _readList(_usersKey);
    final identifier = email.trim().toLowerCase();
    final phoneIdentifier = _normalizePhone(identifier);
    final raw = users.cast<Map<String, dynamic>?>().firstWhere(
          (user) =>
              user?['email'] == identifier ||
              _normalizePhone('${user?['phone'] ?? ''}') == phoneIdentifier,
          orElse: () => null,
        );
    if (raw == null || raw['password'] != password) {
      throw const LocalBackendException(
        'Identifiant ou mot de passe incorrect.',
      );
    }
    return _authPayload(AuthUser.fromJson(raw));
  }

  Future<void> updateUser(AuthUser user) async {
    final users = await _readList(_usersKey);
    final index = users.indexWhere((item) => item['id'] == user.id);
    if (index == -1) return;
    users[index] = {
      ...users[index],
      ...user.toJson(),
    };
    await _writeList(_usersKey, users);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    return [
      {
        'id': 'cat-product-electronics',
        'name': 'Electronique',
        'slug': 'electronique',
        'type': 'product',
        'description': 'Telephones, ordinateurs et accessoires.',
      },
      {
        'id': 'cat-product-phones',
        'parentId': 'cat-product-electronics',
        'name': 'Telephones',
        'slug': 'telephones',
        'type': 'product',
        'description': 'Smartphones, accessoires et pieces mobiles.',
      },
      {
        'id': 'cat-product-laptops',
        'parentId': 'cat-product-electronics',
        'name': 'Ordinateur portable',
        'slug': 'ordinateur-portable',
        'type': 'product',
        'description': 'PC portables avec champs techniques predefinis.',
      },
      {
        'id': 'cat-product-fashion',
        'name': 'Vetements',
        'slug': 'vetements',
        'type': 'product',
        'description': 'Mode femme, homme et enfant.',
      },
      {
        'id': 'cat-product-dresses',
        'parentId': 'cat-product-fashion',
        'name': 'Robes',
        'slug': 'robes',
        'type': 'product',
        'description': 'Robes casual, soiree, ceremonie et tenues longues.',
      },
      {
        'id': 'cat-product-tops',
        'parentId': 'cat-product-fashion',
        'name': 'Hauts',
        'slug': 'hauts',
        'type': 'product',
        'description': 'T-shirts, chemises, blouses, polos et debardeurs.',
      },
      {
        'id': 'cat-product-swimwear',
        'parentId': 'cat-product-fashion',
        'name': 'Maillots',
        'slug': 'maillots',
        'type': 'product',
        'description': 'Maillots de bain, ensembles plage et tenues sport.',
      },
      {
        'id': 'cat-product-shoes',
        'parentId': 'cat-product-fashion',
        'name': 'Chaussures',
        'slug': 'chaussures',
        'type': 'product',
        'description':
            'Sneakers, sandales, talons, bottes et chaussures ville.',
      },
      {
        'id': 'cat-product-pants',
        'parentId': 'cat-product-fashion',
        'name': 'Pantalons',
        'slug': 'pantalons',
        'type': 'product',
        'description': 'Jeans, pantalons habilles, leggings et shorts.',
      },
      {
        'id': 'cat-product-skirts',
        'parentId': 'cat-product-fashion',
        'name': 'Jupes',
        'slug': 'jupes',
        'type': 'product',
        'description': 'Jupes courtes, longues, plissees et tailleurs.',
      },
      {
        'id': 'cat-product-accessories',
        'name': 'Accessoires',
        'slug': 'accessoires',
        'type': 'product',
        'description': 'Sacs, bijoux, lunettes, ceintures et accessoires mode.',
      },
      {
        'id': 'cat-product-bags',
        'parentId': 'cat-product-accessories',
        'name': 'Sacs',
        'slug': 'sacs',
        'type': 'product',
        'description': 'Sacs a main, sacs dos, pochettes et cabas.',
      },
      {
        'id': 'cat-product-jewelry',
        'parentId': 'cat-product-accessories',
        'name': 'Bijoux',
        'slug': 'bijoux',
        'type': 'product',
        'description': 'Colliers, bracelets, bagues et boucles oreille.',
      },
      {
        'id': 'cat-product-watches',
        'parentId': 'cat-product-accessories',
        'name': 'Montres',
        'slug': 'montres',
        'type': 'product',
        'description': 'Montres classiques, connectees et accessoires.',
      },
      {
        'id': 'cat-product-glasses',
        'parentId': 'cat-product-accessories',
        'name': 'Lunettes',
        'slug': 'lunettes',
        'type': 'product',
        'description': 'Lunettes soleil, optiques et accessoires.',
      },
      {
        'id': 'cat-product-home',
        'name': 'Maison',
        'slug': 'maison',
        'type': 'product',
        'description': 'Articles pour la maison et le quotidien.',
      },
      {
        'id': 'cat-product-kitchen',
        'parentId': 'cat-product-home',
        'name': 'Cuisine',
        'slug': 'cuisine',
        'type': 'product',
        'description':
            'Ustensiles, rangement, vaisselle et petits equipements.',
      },
      {
        'id': 'cat-product-decor',
        'parentId': 'cat-product-home',
        'name': 'Decoration',
        'slug': 'decoration',
        'type': 'product',
        'description': 'Decoration, textiles, luminaires et objets maison.',
      },
      {
        'id': 'cat-product-beauty',
        'name': 'Beaute',
        'slug': 'beaute',
        'type': 'product',
        'description': 'Soins, parfums, maquillage et produits capillaires.',
      },
      {
        'id': 'cat-product-haircare',
        'parentId': 'cat-product-beauty',
        'name': 'Cheveux',
        'slug': 'cheveux',
        'type': 'product',
        'description':
            'Soins capillaires, perruques, extensions et accessoires.',
      },
      {
        'id': 'cat-product-skincare',
        'parentId': 'cat-product-beauty',
        'name': 'Soins visage',
        'slug': 'soins-visage',
        'type': 'product',
        'description': 'Nettoyants, cremes, serums et routines visage.',
      },
      {
        'id': 'cat-product-kids',
        'name': 'Enfants',
        'slug': 'enfants',
        'type': 'product',
        'description': 'Vetements, jeux, puericulture et accessoires enfants.',
      },
      {
        'id': 'cat-product-baby',
        'parentId': 'cat-product-kids',
        'name': 'Bebe',
        'slug': 'bebe',
        'type': 'product',
        'description': 'Puericulture, vetements bebe et accessoires.',
      },
      {
        'id': 'cat-product-toys',
        'parentId': 'cat-product-kids',
        'name': 'Jouets',
        'slug': 'jouets',
        'type': 'product',
        'description': 'Jeux educatifs, figurines, loisirs et cadeaux.',
      },
      {
        'id': 'cat-product-food',
        'name': 'Alimentation',
        'slug': 'alimentation',
        'type': 'product',
        'description': 'Epicerie, boissons, produits frais et specialites.',
      },
      {
        'id': 'cat-product-sport',
        'name': 'Sport',
        'slug': 'sport',
        'type': 'product',
        'description': 'Vetements sportifs, accessoires et equipements.',
      },
      {
        'id': 'cat-service',
        'name': 'Services',
        'slug': 'services',
        'type': 'service',
        'description': 'Prestations et services locaux.',
      },
      {
        'id': 'cat-property',
        'name': 'Immobilier',
        'slug': 'immobilier',
        'type': 'property',
        'description': 'Locations et biens immobiliers.',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> listings({
    String? query,
    String? categoryType,
    String? categoryId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    var items = await _readList(_listingsKey);
    items = items.where((listing) {
      if (categoryType != null &&
          categoryType.isNotEmpty &&
          listing['categoryType'] != categoryType) {
        return false;
      }
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          listing['categoryId'] != categoryId) {
        return false;
      }
      if (status != null && status.isNotEmpty && listing['status'] != status) {
        return false;
      }
      final q = query?.trim().toLowerCase() ?? '';
      if (q.isNotEmpty) {
        final haystack =
            '${listing['title']} ${listing['description']}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));

    final start = (page - 1).clamp(0, items.length);
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Future<Map<String, dynamic>> listingBySlug(String slug) async {
    final listings = await _readList(_listingsKey);
    final listing = listings.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['slug'] == slug || item?['id'] == slug,
          orElse: () => null,
        );
    if (listing == null) {
      throw const LocalBackendException('Produit introuvable.');
    }
    return listing;
  }

  Future<Map<String, dynamic>?> dashboard(String? accessToken) async {
    final userId = _userIdFromToken(accessToken);
    if (userId == null) return null;

    final vendors = await _readList(_vendorsKey);
    final vendor = vendors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['userId'] == userId,
          orElse: () => null,
        );
    if (vendor == null) return null;

    final shops = await _readList(_shopsKey);
    final shop = shops.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id'] == vendor['shopId'],
          orElse: () => null,
        );
    if (shop == null) return null;

    final sellerListings = (await _readList(_listingsKey))
        .where((listing) => listing['vendorId'] == vendor['id'])
        .toList();

    return {
      'vendor': vendor,
      'shop': shop,
      'listings': sellerListings,
      'activeOrders': <Map<String, dynamic>>[],
      'pendingPayouts': <Map<String, dynamic>>[],
      'moderationQueue': <Map<String, dynamic>>[],
      'kycDocuments': <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>> createShop({
    required String? accessToken,
    required String shopName,
    required String shopDescription,
    required String sellerType,
    required String legalFullName,
    required String supportEmail,
    required String contactPhone,
    required String country,
    required String city,
    required String addressLine,
    required String customerPromise,
    List<String> focus = const ['product'],
    String shopTagline = '',
    String businessName = '',
  }) async {
    final userId = _requireUserId(accessToken);
    final vendors = await _readList(_vendorsKey);
    final existing = vendors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['userId'] == userId,
          orElse: () => null,
        );
    if (existing != null) return existing;

    final vendorId = _id('vendor');
    final shopId = _id('shop');
    final now = _now();
    final vendor = {
      'id': vendorId,
      'userId': userId,
      'shopId': shopId,
      'kycStatus': 'approved',
      'payoutAccountStatus': 'pending',
      'commissionRate': 0,
      'documentsComplete': false,
      'sellerType': sellerType,
      'legalFullName': legalFullName,
      'createdAt': now,
    };
    final shop = {
      'id': shopId,
      'vendorId': vendorId,
      'name': shopName.trim(),
      'slug': _slug(shopName),
      'description': shopDescription.trim(),
      'tagline': shopTagline.trim(),
      'focus': focus,
      'supportEmail': supportEmail.trim().toLowerCase(),
      'supportPhone': contactPhone.trim(),
      'country': country.trim(),
      'city': city.trim(),
      'addressLine': addressLine.trim(),
      'customerPromise': customerPromise.trim(),
      'businessName': businessName.trim(),
      'createdAt': now,
    };

    vendors.add(vendor);
    final shops = await _readList(_shopsKey)
      ..add(shop);
    await _writeList(_vendorsKey, vendors);
    await _writeList(_shopsKey, shops);
    return vendor;
  }

  Future<Map<String, dynamic>> ensurePartnerWorkspace({
    required String? accessToken,
  }) async {
    final userId = _requireUserId(accessToken);
    final vendors = await _readList(_vendorsKey);
    final existing = vendors.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['userId'] == userId,
          orElse: () => null,
        );
    if (existing != null) return existing;

    final users = await _readList(_usersKey);
    final user = users.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id'] == userId,
          orElse: () => null,
        );
    final vendorId = _id('partner');
    final shopId = _id('catalog');
    final now = _now();
    final vendor = {
      'id': vendorId,
      'userId': userId,
      'shopId': shopId,
      'kycStatus': 'approved',
      'payoutAccountStatus': 'pending',
      'commissionRate': 0,
      'documentsComplete': false,
      'sellerType': 'partner',
      'legalFullName':
          '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim(),
      'createdAt': now,
    };
    final shop = {
      'id': shopId,
      'vendorId': vendorId,
      'name': 'Catalogue partenaire',
      'slug': _slug('catalogue-partenaire-$userId'),
      'description': 'Catalogue partenaire interne NovaShop.',
      'tagline': '',
      'focus': const ['product'],
      'supportEmail': '${user?['email'] ?? ''}'.trim().toLowerCase(),
      'supportPhone': '${user?['phone'] ?? ''}'.trim(),
      'country': '',
      'city': '',
      'addressLine': '',
      'customerPromise': '',
      'businessName': '',
      'visibility': 'internal',
      'createdAt': now,
    };

    vendors.add(vendor);
    final shops = await _readList(_shopsKey)
      ..add(shop);
    await _writeList(_vendorsKey, vendors);
    await _writeList(_shopsKey, shops);
    return vendor;
  }

  Future<Map<String, dynamic>> createListing({
    required String? accessToken,
    required String shopId,
    required String categoryId,
    required String categoryType,
    required String title,
    required String description,
    required double price,
    required String currency,
    required int inventory,
    String imageUrl = '',
    Map<String, dynamic>? attributes,
  }) async {
    final userId = _requireUserId(accessToken);
    final dashboard = await this.dashboard(accessToken);
    if (dashboard == null) {
      throw const LocalBackendException(
        'Creez votre boutique avant de publier un produit.',
      );
    }
    final vendor = Map<String, dynamic>.from(dashboard['vendor'] as Map);
    final now = _now();
    final listing = {
      'id': _id('listing'),
      'vendorId': vendor['id'],
      'shopId': shopId.isNotEmpty ? shopId : vendor['shopId'],
      'categoryId': categoryId,
      'categoryType': categoryType,
      'slug': _slug('$title-${DateTime.now().millisecondsSinceEpoch}'),
      'title': title.trim(),
      'description': description.trim(),
      'status': 'published',
      'price': price,
      'currency': currency,
      'inventory': inventory,
      'featured': false,
      'imageUrl': imageUrl.trim(),
      'attributes': attributes ?? const {},
      'createdAt': now,
      'updatedAt': now,
      'ownerUserId': userId,
    };
    final listings = await _readList(_listingsKey)
      ..add(listing);
    await _writeList(_listingsKey, listings);
    return listing;
  }

  Future<Map<String, dynamic>> updateListing(
    String listingId,
    Map<String, dynamic> patch,
  ) async {
    final listings = await _readList(_listingsKey);
    final index = listings.indexWhere((listing) => listing['id'] == listingId);
    if (index == -1) {
      throw const LocalBackendException('Produit introuvable.');
    }
    listings[index] = {
      ...listings[index],
      ...patch,
      'updatedAt': _now(),
    };
    await _writeList(_listingsKey, listings);
    return listings[index];
  }

  Map<String, dynamic> _authPayload(AuthUser user) {
    return {
      'user': {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.id,
        'businessName': user.businessName,
      },
      'accessToken': 'local:${user.id}',
    };
  }

  String? _userIdFromToken(String? accessToken) {
    if (accessToken == null || !accessToken.startsWith('local:')) return null;
    return accessToken.substring('local:'.length);
  }

  String _requireUserId(String? accessToken) {
    final userId = _userIdFromToken(accessToken);
    if (userId == null || userId.isEmpty) {
      throw const LocalBackendException('Reconnectez-vous pour continuer.');
    }
    return userId;
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _now() => DateTime.now().toUtc().toIso8601String();

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[^0-9+]'), '');

  String _slug(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? _id('item') : normalized;
  }
}
