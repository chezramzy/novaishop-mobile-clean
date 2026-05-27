import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/category.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../design/design_system.dart';
import '../catalog/catalog_kit.dart';
import '../catalog/category_listings_screen.dart';

/// Browse every category, grouped by type (produit / service / immobilier).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _loading = true;
  bool _failed = false;
  List<Category> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final collection =
          await context.read<CatalogRepository>().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = collection.items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ScreenHeader(title: 'Catégories'),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SkeletonList(
        itemCount: 7,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 110),
      );
    }
    if (_failed) {
      return NovaErrorState(
        message: 'Impossible de charger les catégories.',
        onRetry: _load,
      );
    }
    if (_categories.isEmpty) {
      return NovaEmptyState(
        icon: Icons.grid_view_rounded,
        title: 'Aucune catégorie',
        message: 'Les catégories apparaîtront ici prochainement.',
        actionLabel: 'Actualiser',
        onAction: _load,
      );
    }

    final groups = <CatalogType, List<Category>>{};
    for (final category in _categories) {
      final type = CatalogTypeX.fromApi(category.type);
      groups.putIfAbsent(type, () => []).add(category);
    }

    final sections = <Widget>[];
    var index = 0;
    for (final type in CatalogType.values) {
      final items = groups[type];
      if (items == null || items.isEmpty) continue;
      sections.add(
        StaggeredEntrance.item(
          index++,
          _TypeSection(
            type: type,
            categories: items,
            onBrowseAll: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryListingsScreen(
                  args: CategoryListingsArgs(
                    categoryType: type.apiValue,
                    title: type.label,
                  ),
                ),
              ),
            ),
            onTapCategory: (category) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryListingsScreen(
                  args: CategoryListingsArgs(
                    categoryId: category.id,
                    categoryType: category.type,
                    title: category.name,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: sections,
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.categories,
    required this.onBrowseAll,
    required this.onTapCategory,
  });

  final CatalogType type;
  final List<Category> categories;
  final VoidCallback onBrowseAll;
  final ValueChanged<Category> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: type.tintOf(context.colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type.icon,
                  size: 20,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onBrowseAll,
                child: Text(
                  'Tout voir',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                onTap: () => onTapCategory(category),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: softTintFor(category.id, context.colors),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              categoryIcon(category.slug, category.type),
              size: 19,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.15,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}
