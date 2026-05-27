import 'catalog_repository.dart';
import 'repository_error.dart';

class ShopRepository {
  ShopRepository({String? accessToken});

  Future<ShopPage> getShop(String slug) {
    throw RepositoryException('Boutique indisponible en mode local.');
  }
}
