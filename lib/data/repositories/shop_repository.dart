import 'catalog_repository.dart';
import 'repository_error.dart';

class ShopRepository {
  ShopRepository({String? accessToken});

  Future<ShopPage> getShop(String slug) {
    throw RepositoryException(
        'Les pages boutique publiques ne sont plus exposees.');
  }
}
