import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/models/search_suggestion.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../cart/cart_controller.dart';
import 'catalog_kit.dart';

/// The active filter state applied to a search.
class SearchFilters {
  const SearchFilters({
    this.categoryType,
    this.minPrice,
    this.maxPrice,
    this.sort = CatalogSort.newest,
  });

  final CatalogType? categoryType;
  final double? minPrice;
  final double? maxPrice;
  final CatalogSort sort;

  bool get hasAny =>
      categoryType != null ||
      minPrice != null ||
      maxPrice != null ||
      sort != CatalogSort.newest;

  int get activeCount {
    var count = 0;
    if (categoryType != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (sort != CatalogSort.newest) count++;
    return count;
  }

  SearchFilters copyWith({
    CatalogType? categoryType,
    bool clearCategoryType = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    CatalogSort? sort,
  }) {
    return SearchFilters(
      categoryType:
          clearCategoryType ? null : (categoryType ?? this.categoryType),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }
}

/// The catalogue search screen: debounced autocomplete suggestions, a
/// results grid and an applied filter sheet.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  SearchFilters _filters = const SearchFilters();
  List<SearchSuggestion> _suggestions = const [];
  bool _showSuggestions = false;

  bool _loading = false;
  bool _searched = false;
  RepositoryException? _error;
  List<Listing> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final suggestions =
          await context.read<CatalogRepository>().getSearchSuggestions(query);
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _runSearch() async {
    _debounce?.cancel();
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _loading = true;
      _searched = true;
      _error = null;
    });
    final query = _controller.text.trim();
    try {
      final collection = await context.read<CatalogRepository>().getListings(
            query: query.isEmpty ? null : query,
            categoryType: _filters.categoryType?.apiValue,
            sort: _filters.sort.apiValue,
            minPrice: _filters.minPrice,
            maxPrice: _filters.maxPrice,
            pageSize: 40,
          );
      if (!mounted) return;
      setState(() {
        _results = collection.items;
        _loading = false;
      });
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = RepositoryException('La recherche est indisponible.');
        _loading = false;
      });
    }
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _controller.text = suggestion.title;
    if (suggestion.isCategory) {
      _filters = _filters.copyWith(
        categoryType: CatalogTypeX.fromApi(suggestion.subtitle),
      );
    }
    _runSearch();
  }

  Future<void> _openFilters() async {
    final updated = await showNovaSheet<SearchFilters>(
      context: context,
      title: 'Filtres de recherche',
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (updated != null) {
      setState(() => _filters = updated);
      if (_searched) _runSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'Recherche',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleIconButton(
                      icon: Icons.tune_rounded,
                      onPressed: _openFilters,
                    ),
                    if (_filters.activeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: AppColors.deepInk,
                          child: Text(
                            '${_filters.activeCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.lime,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: 'Produits, services, biens…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                            _suggestions = const [];
                            _showSuggestions = false;
                          });
                        },
                      ),
              ),
            ),
          ),
          if (_filters.hasAny)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ActiveFiltersBar(
                filters: _filters,
                onClear: () {
                  setState(() => _filters = const SearchFilters());
                  if (_searched) _runSearch();
                },
              ),
            ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_showSuggestions && _suggestions.isNotEmpty) {
      return _SuggestionList(
        suggestions: _suggestions,
        onTap: _onSuggestionTap,
      );
    }
    if (_loading) {
      return const SkeletonGrid(
        itemCount: 6,
        padding: EdgeInsets.fromLTRB(20, 0, 20, 110),
      );
    }
    if (_error != null) {
      return NovaErrorState(message: _error!.message, onRetry: _runSearch);
    }
    if (!_searched) {
      return const NovaEmptyState(
        icon: Icons.search_rounded,
        title: 'Trouvez tout sur NovAiShop',
        message: 'Saisissez un mot-clé ou ajustez les filtres pour démarrer.',
      );
    }
    if (_results.isEmpty) {
      return NovaEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucun résultat',
        message: 'Aucune annonce ne correspond à votre recherche.',
        actionLabel: 'Modifier les filtres',
        onAction: _openFilters,
      );
    }
    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _runSearch,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: _results.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
          childAspectRatio: .66,
        ),
        itemBuilder: (context, index) {
          final listing = _results[index];
          return StaggeredEntrance.item(
            index,
            ProductCard(
              listing: listing,
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.productDetail,
                arguments: listing.slug,
              ),
              onAdd: () {
                context.read<CartController>().add(listing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${listing.title} ajouté au panier')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.filters, required this.onClear});

  final SearchFilters filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filters.categoryType != null) {
      chips.add(filters.categoryType!.label);
    }
    if (filters.minPrice != null || filters.maxPrice != null) {
      final min = formatPrice(filters.minPrice ?? 0);
      final max = filters.maxPrice == null
          ? 'Illimité'
          : formatPrice(filters.maxPrice!);
      chips.add('$min - $max');
    }
    if (filters.sort != CatalogSort.newest) {
      chips.add(filters.sort.label);
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) => NovaBadge(
                label: chips[index],
                tone: NovaBadgeTone.primary,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          child: const Text('Effacer'),
        ),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.suggestions, required this.onTap});

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onTap;

  IconData _iconFor(SearchSuggestion suggestion) {
    if (suggestion.isCategory) return Icons.category_outlined;
    if (suggestion.isVendor) return Icons.storefront_outlined;
    return Icons.search_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return StaggeredEntrance.item(
          index,
          NovaCard(
            onTap: () => onTap(suggestion),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (suggestion.imageUrl != null &&
                    suggestion.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: NovaImage(
                      url: suggestion.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: const ColoredBox(color: AppColors.butter),
                      error: const ColoredBox(
                        color: AppColors.butter,
                        child: Icon(Icons.image_outlined, size: 16),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: softTintFor(suggestion.id, context.colors),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _iconFor(suggestion),
                      size: 19,
                      color: context.colors.textPrimary,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (suggestion.subtitle != null &&
                          suggestion.subtitle!.isNotEmpty)
                        Text(
                          suggestion.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.north_west_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ------------------------------ filter sheet ----------------------------- */

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CatalogType? _type = widget.initial.categoryType;
  late CatalogSort _sort = widget.initial.sort;
  late RangeValues _priceRange = RangeValues(
    widget.initial.minPrice ?? 0,
    widget.initial.maxPrice ?? _maxPrice,
  );

  static const double _maxPrice = 2000000;

  void _apply() {
    final usesMin = _priceRange.start > 0;
    final usesMax = _priceRange.end < _maxPrice;
    Navigator.of(context).pop(
      SearchFilters(
        categoryType: _type,
        minPrice: usesMin ? _priceRange.start : null,
        maxPrice: usesMax ? _priceRange.end : null,
        sort: _sort,
      ),
    );
  }

  void _reset() {
    setState(() {
      _type = null;
      _sort = CatalogSort.newest;
      _priceRange = const RangeValues(0, _maxPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FilterLabel('Type de catégorie'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NovaChip(
                label: 'Tout',
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              for (final type in CatalogType.values)
                NovaChip(
                  label: type.label,
                  icon: type.icon,
                  selected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const _FilterLabel('Fourchette de prix'),
              const Spacer(),
              Text(
                '${formatPrice(_priceRange.start)} - '
                '${_priceRange.end >= _maxPrice ? '2M+ FCFA' : formatPrice(_priceRange.end)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxPrice,
            divisions: 40,
            activeColor: context.colors.textPrimary,
            inactiveColor: context.colors.border,
            labels: RangeLabels(
              formatPrice(_priceRange.start),
              formatPrice(_priceRange.end),
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 12),
          const _FilterLabel('Trier par'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in CatalogSort.values)
                NovaChip(
                  label: option.label,
                  icon: option.icon,
                  selected: _sort == option,
                  onTap: () => setState(() => _sort = option),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NovaButton.ghost(
                  label: 'Réinitialiser',
                  onPressed: _reset,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NovaButton.primary(
                  label: 'Appliquer',
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );
  }
}
