import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/ai_models.dart';
import '../../data/models/category.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'widgets/seller_upload.dart';
import 'widgets/seller_widgets.dart';

/// Lets a seller publish a new product or edit an existing one.
///
/// When [listing] is provided the form runs in edit mode (`PATCH
/// /v1/listings/:id`). Otherwise it creates a new listing for [shopId]
/// (`POST /v1/listings`). [aiSuggestion] prefills the form from an AI
/// listing suggestion.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    this.shopId,
    this.listing,
    this.aiSuggestion,
    this.prefillImageUrl,
    super.key,
  });

  final String? shopId;
  final Listing? listing;
  final AiListingSuggestion? aiSuggestion;
  final String? prefillImageUrl;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

enum ProductTemplate {
  standard('standard', 'Produit standard'),
  fashion('fashion', 'Vetement'),
  bag('bag', 'Sac'),
  beauty('beauty', 'Beaute'),
  electronics('electronics', 'Electronique'),
  laptop('laptop', 'Ordinateur portable');

  const ProductTemplate(this.id, this.label);

  final String id;
  final String label;
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _inventory = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _processor = TextEditingController();
  final _ramGb = TextEditingController();
  final _storage = TextEditingController();
  final _gpu = TextEditingController();
  final _screenSize = TextEditingController();
  final _resolution = TextEditingController();
  final _operatingSystem = TextEditingController();
  final _condition = TextEditingController();
  final _batteryHealth = TextEditingController();
  final _warranty = TextEditingController();
  final _ports = TextEditingController();
  final _size = TextEditingController();
  final _color = TextEditingController();
  final _material = TextEditingController();
  final _gender = TextEditingController();
  final _fit = TextEditingController();
  final _dimensions = TextEditingController();
  final _care = TextEditingController();
  final _volume = TextEditingController();
  final _ingredients = TextEditingController();
  final _skinType = TextEditingController();

  late Future<List<Category>> _categoriesFuture;
  Category? _category;
  Category? _subCategory;
  ProductTemplate _template = ProductTemplate.standard;
  String _imageUrl = '';
  Uint8List? _pickedBytes;
  bool _busy = false;
  bool _uploading = false;

  bool get _isEdit => widget.listing != null;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
    final listing = widget.listing;
    final suggestion = widget.aiSuggestion;
    if (listing != null) {
      _title.text = listing.title;
      _description.text = listing.description;
      _price.text = listing.price.toStringAsFixed(2).replaceAll('.', ',');
      _inventory.text = '${listing.inventory}';
      _imageUrl = listing.imageUrl ?? '';
      _hydrateAttributes(listing.attributes);
    } else if (suggestion != null) {
      _title.text = suggestion.suggestedTitle;
      _description.text = _withAttributes(
        suggestion.suggestedDescription,
        suggestion.extractedAttributes,
      );
      _imageUrl = widget.prefillImageUrl ?? '';
    } else {
      _imageUrl = widget.prefillImageUrl ?? '';
    }
  }

  String _withAttributes(String description, Map<String, String> attributes) {
    if (attributes.isEmpty) return description;
    final lines = attributes.entries
        .map((entry) => '• ${entry.key} : ${entry.value}')
        .join('\n');
    return '$description\n\n$lines';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _inventory.dispose();
    _brand.dispose();
    _model.dispose();
    _processor.dispose();
    _ramGb.dispose();
    _storage.dispose();
    _gpu.dispose();
    _screenSize.dispose();
    _resolution.dispose();
    _operatingSystem.dispose();
    _condition.dispose();
    _batteryHealth.dispose();
    _warranty.dispose();
    _ports.dispose();
    _size.dispose();
    _color.dispose();
    _material.dispose();
    _gender.dispose();
    _fit.dispose();
    _dimensions.dispose();
    _care.dispose();
    _volume.dispose();
    _ingredients.dispose();
    _skinType.dispose();
    super.dispose();
  }

  Future<List<Category>> _loadCategories() async {
    final collection = await context.read<CatalogRepository>().getCategories();
    return collection.items
        .where((category) => category.type == 'product')
        .toList();
  }

  double? _parsePrice(String raw) {
    final normalized = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return double.parse(value.toStringAsFixed(2));
  }

  int? _parsePositiveInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  void _hydrateAttributes(Map<String, dynamic> attributes) {
    if (attributes['productTemplate'] == ProductTemplate.laptop.id ||
        attributes['productKind'] == 'laptop') {
      _template = ProductTemplate.laptop;
    }
    _brand.text = _readAttr(attributes, 'brand');
    _model.text = _readAttr(attributes, 'model');
    _processor.text = _readAttr(attributes, 'processor');
    _ramGb.text = _readAttr(attributes, 'ramGb');
    _storage.text = _readAttr(attributes, 'storage');
    _gpu.text = _readAttr(attributes, 'gpu');
    _screenSize.text = _readAttr(attributes, 'screenSize');
    _resolution.text = _readAttr(attributes, 'resolution');
    _operatingSystem.text = _readAttr(attributes, 'operatingSystem');
    _condition.text = _readAttr(attributes, 'condition');
    _batteryHealth.text = _readAttr(attributes, 'batteryHealth');
    _warranty.text = _readAttr(attributes, 'warranty');
    _ports.text = _readAttr(attributes, 'ports');
    _size.text = _readAttr(attributes, 'size');
    _color.text = _readAttr(attributes, 'color');
    _material.text = _readAttr(attributes, 'material');
    _gender.text = _readAttr(attributes, 'gender');
    _fit.text = _readAttr(attributes, 'fit');
    _dimensions.text = _readAttr(attributes, 'dimensions');
    _care.text = _readAttr(attributes, 'care');
    _volume.text = _readAttr(attributes, 'volume');
    _ingredients.text = _readAttr(attributes, 'ingredients');
    _skinType.text = _readAttr(attributes, 'skinType');
  }

  String _readAttr(Map<String, dynamic> attributes, String key) {
    final value = attributes[key];
    return value == null ? '' : '$value';
  }

  String _normalizedCategoryText(Category? category) {
    return '${category?.name ?? ''} ${category?.slug ?? ''}'
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e');
  }

  bool _isLaptopCategory(Category? category) {
    final text = _normalizedCategoryText(category);
    return text.contains('laptop') ||
        text.contains('portable') ||
        text.contains('ordinateur');
  }

  bool _isElectronicsCategory(Category? category) {
    final text = _normalizedCategoryText(category);
    return text.contains('electronic') ||
        text.contains('electronique') ||
        text.contains('ordinateur') ||
        text.contains('laptop') ||
        text.contains('portable');
  }

  bool _isFashionCategory(Category? category) {
    final text = _normalizedCategoryText(category);
    return text.contains('vetement') ||
        text.contains('robe') ||
        text.contains('haut') ||
        text.contains('maillot') ||
        text.contains('pantalon') ||
        text.contains('jupe') ||
        text.contains('chaussure');
  }

  bool _isBagCategory(Category? category) {
    final text = _normalizedCategoryText(category);
    return text.contains('sac') || text.contains('bag');
  }

  bool _isBeautyCategory(Category? category) {
    final text = _normalizedCategoryText(category);
    return text.contains('beaute') ||
        text.contains('cheveux') ||
        text.contains('soin') ||
        text.contains('visage');
  }

  ProductTemplate _templateFor(Category? category) {
    if (_isLaptopCategory(category)) return ProductTemplate.laptop;
    if (_isBagCategory(category)) return ProductTemplate.bag;
    if (_isFashionCategory(category)) return ProductTemplate.fashion;
    if (_isBeautyCategory(category)) return ProductTemplate.beauty;
    if (_isElectronicsCategory(category)) return ProductTemplate.electronics;
    return ProductTemplate.standard;
  }

  void _selectCategory(Category category) {
    setState(() {
      _category = category;
      _subCategory = null;
      _template = _templateFor(category);
    });
  }

  void _selectSubCategory(Category category) {
    setState(() {
      _subCategory = category;
      _template = _templateFor(category);
    });
  }

  Map<String, dynamic> _buildAttributes() {
    final attributes = <String, dynamic>{
      'productTemplate': _template.id,
      'productKind': _template.id,
      'brand': _brand.text.trim(),
      'model': _model.text.trim(),
      'condition': _condition.text.trim(),
      'warranty': _warranty.text.trim(),
      'size': _size.text.trim(),
      'color': _color.text.trim(),
      'material': _material.text.trim(),
      'gender': _gender.text.trim(),
      'fit': _fit.text.trim(),
      'dimensions': _dimensions.text.trim(),
      'care': _care.text.trim(),
      'volume': _volume.text.trim(),
      'ingredients': _ingredients.text.trim(),
      'skinType': _skinType.text.trim(),
    };
    if (_template == ProductTemplate.laptop) {
      final ram = _parsePositiveInt(_ramGb.text);
      attributes.addAll({
        'processor': _processor.text.trim(),
        'storage': _storage.text.trim(),
        'gpu': _gpu.text.trim(),
        'screenSize': _screenSize.text.trim(),
        'resolution': _resolution.text.trim(),
        'operatingSystem': _operatingSystem.text.trim(),
        'batteryHealth': _batteryHealth.text.trim(),
        'ports': _ports.text.trim(),
      });
      if (ram != null) attributes['ramGb'] = ram;
    }
    attributes.removeWhere(
      (_, value) => value is String && value.trim().isEmpty,
    );
    return attributes;
  }

  Future<void> _pickImage() async {
    if (_uploading) return;
    final media = MediaRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    try {
      final picked = await SellerUploadPicker.pickGalleryImage();
      if (picked == null) return;
      setState(() {
        _pickedBytes = picked.bytes;
        _uploading = true;
      });
      final asset = await media.uploadImage(
        bytes: picked.bytes,
        fileName: picked.fileName,
        contentType: picked.contentType,
      );
      if (!mounted) return;
      final url = asset.publicUrl;
      if (url == null || url.isEmpty) {
        showSellerSnack(
          context,
          "L'image a été envoyée mais aucune URL n'a été renvoyée.",
          error: true,
        );
        setState(() => _uploading = false);
        return;
      }
      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
      showSellerSnack(context, 'Photo ajoutée.');
    } on RepositoryException catch (error) {
      if (mounted) {
        setState(() => _uploading = false);
        showSellerSnack(context, error.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploading = false);
        showSellerSnack(
          context,
          "L'envoi de la photo a échoué. Réessayez.",
          error: true,
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = '';
      _pickedBytes = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || _uploading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final selectedCategory = _subCategory ?? _category;
    if (selectedCategory == null && !_isEdit) {
      showSellerSnack(context, 'Choisissez une catégorie.', error: true);
      return;
    }

    final price = _parsePrice(_price.text);
    final inventory = int.tryParse(_inventory.text.trim());
    if (price == null) {
      showSellerSnack(context, 'Saisissez un prix valide.', error: true);
      return;
    }
    if (inventory == null || inventory < 0) {
      showSellerSnack(context, 'Saisissez un stock valide.', error: true);
      return;
    }

    final repository = SellerRepository(
      accessToken: context.read<AuthController>().accessToken,
    );

    setState(() => _busy = true);
    try {
      if (_isEdit) {
        await repository.updateListing(
          widget.listing!.id,
          title: _title.text,
          description: _description.text,
          price: price,
          inventory: inventory,
          imageUrl: _imageUrl,
          attributes: _buildAttributes(),
        );
        if (!mounted) return;
        showSellerSnack(context, 'Produit mis à jour.');
      } else {
        await repository.createListing(
          shopId: widget.shopId ?? '',
          categoryId: selectedCategory!.id,
          title: _title.text,
          description: _description.text,
          price: price,
          inventory: inventory,
          imageUrl: _imageUrl,
          attributes: _buildAttributes(),
        );
        if (!mounted) return;
        showSellerSnack(
          context,
          'Produit envoyé. Il sera visible après validation.',
        );
      }
      Navigator.of(context).pop(true);
    } on SellerException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } on RepositoryException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSellerSnack(
          context,
          'Une erreur est survenue. Veuillez réessayer.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovaLoadingView(label: 'Chargement…');
          }
          if (snapshot.hasError) {
            return NovaErrorState(
              message: 'Impossible de charger les catégories.',
              onRetry: () =>
                  setState(() => _categoriesFuture = _loadCategories()),
            );
          }
          return _buildForm(snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildForm(List<Category> categories) {
    final rootCategories = categories
        .where((category) =>
            category.parentId == null || category.parentId!.isEmpty)
        .toList();
    final subCategories = _category == null
        ? const <Category>[]
        : categories
            .where((category) => category.parentId == _category!.id)
            .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: StaggeredEntrance.all([
          ScreenHeader(
            title: _isEdit ? 'Modifier le produit' : 'Ajouter un produit',
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.aiSuggestion != null) ...[
            const SellerInfoBanner(
              icon: Icons.auto_awesome_outlined,
              message: 'Fiche pré-remplie par l\'assistant IA. Vérifiez et '
                  'ajustez les informations avant de publier.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Stack(
            children: [
              SellerImagePreview(
                bytes: _pickedBytes,
                url: _imageUrl.isEmpty ? null : _imageUrl,
                placeholderLabel: 'Aucune photo',
              ),
              if (_uploading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66202623),
                    child: Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppColors.lime,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_imageUrl.isNotEmpty && !_uploading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleIconButton(
                    icon: Icons.close_rounded,
                    size: 36,
                    backgroundColor: Colors.white,
                    tooltip: 'Retirer la photo',
                    onPressed: _removeImage,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          NovaButton.secondary(
            label: _imageUrl.isEmpty ? 'Choisir une photo' : 'Changer la photo',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: _uploading ? () {} : _pickImage,
          ),
          const SizedBox(height: AppSpacing.md),
          NovaTextField(
            controller: _title,
            label: 'Nom du produit',
            hint: 'Ex. Pull en laine mérinos',
            icon: Icons.label_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'Le nom est obligatoire.';
              if (text.length < 5) {
                return 'Le nom doit contenir au moins 5 caractères.';
              }
              return null;
            },
          ),
          if (!_isEdit) ...[
            const SizedBox(height: AppSpacing.md),
            _CategoryField(
              label: 'Catégorie',
              placeholder: 'Choisir une catégorie',
              categories: rootCategories,
              value: _category,
              onChanged: _selectCategory,
            ),
          ],
          if (!_isEdit && _category != null && subCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _CategoryField(
              label: 'Sous-catégorie',
              placeholder: 'Choisir une sous-catégorie',
              categories: subCategories,
              value: _subCategory,
              onChanged: _selectSubCategory,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          NovaTextField(
            controller: _description,
            label: 'Description',
            hint: "Matières, coupe, conseils d'entretien…",
            icon: Icons.notes_outlined,
            maxLines: 6,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'La description est obligatoire.';
              if (text.length < 20) {
                return 'Décrivez le produit (20 caractères min.).';
              }
              return null;
            },
          ),
          if (_template == ProductTemplate.laptop) ...[
            const SizedBox(height: AppSpacing.md),
            _LaptopSpecsForm(
              brand: _brand,
              model: _model,
              processor: _processor,
              ramGb: _ramGb,
              storage: _storage,
              gpu: _gpu,
              screenSize: _screenSize,
              resolution: _resolution,
              operatingSystem: _operatingSystem,
              condition: _condition,
              batteryHealth: _batteryHealth,
              warranty: _warranty,
              ports: _ports,
            ),
          ] else if (_template != ProductTemplate.standard) ...[
            const SizedBox(height: AppSpacing.md),
            _AdaptiveSpecsForm(
              template: _template,
              brand: _brand,
              model: _model,
              size: _size,
              color: _color,
              material: _material,
              gender: _gender,
              fit: _fit,
              dimensions: _dimensions,
              care: _care,
              volume: _volume,
              ingredients: _ingredients,
              skinType: _skinType,
              condition: _condition,
              warranty: _warranty,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NovaTextField(
                  controller: _price,
                  label: 'Prix (FCFA)',
                  hint: '150000',
                  icon: Icons.sell_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) => _parsePrice(value ?? '') == null
                      ? 'Prix invalide.'
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NovaTextField(
                  controller: _inventory,
                  label: 'Stock',
                  hint: '10',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final stock = int.tryParse((value ?? '').trim());
                    return (stock == null || stock < 0)
                        ? 'Stock invalide.'
                        : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_isEdit)
            const SellerInfoBanner(
              icon: Icons.shield_outlined,
              color: AppColors.deepInk,
              message: 'Chaque produit passe par une validation avant d\'être '
                  'visible par les acheteurs.',
            ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: _isEdit ? 'Enregistrer' : 'Publier le produit',
            icon: _isEdit ? Icons.check_rounded : Icons.publish_outlined,
            busy: _busy,
            onPressed: _submit,
          ),
        ]),
      ),
    );
  }
}

class _LaptopSpecsForm extends StatelessWidget {
  const _LaptopSpecsForm({
    required this.brand,
    required this.model,
    required this.processor,
    required this.ramGb,
    required this.storage,
    required this.gpu,
    required this.screenSize,
    required this.resolution,
    required this.operatingSystem,
    required this.condition,
    required this.batteryHealth,
    required this.warranty,
    required this.ports,
  });

  final TextEditingController brand;
  final TextEditingController model;
  final TextEditingController processor;
  final TextEditingController ramGb;
  final TextEditingController storage;
  final TextEditingController gpu;
  final TextEditingController screenSize;
  final TextEditingController resolution;
  final TextEditingController operatingSystem;
  final TextEditingController condition;
  final TextEditingController batteryHealth;
  final TextEditingController warranty;
  final TextEditingController ports;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fiche ordinateur portable',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const SellerInfoBanner(
          icon: Icons.tune_rounded,
          message:
              'Les champs utiles aux PC sont prêts. Remplissez uniquement ce que vous connaissez.',
        ),
        const SizedBox(height: AppSpacing.md),
        _SpecRow(
          first: NovaTextField(
            controller: brand,
            label: 'Marque',
            hint: 'Dell, HP, Lenovo',
            icon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          second: NovaTextField(
            controller: model,
            label: 'Modèle',
            hint: 'ThinkPad T14',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        NovaTextField(
          controller: processor,
          label: 'Processeur',
          hint: 'Intel Core i5-1235U, Ryzen 7 7730U',
          icon: Icons.memory_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        _SpecRow(
          first: NovaTextField(
            controller: ramGb,
            label: 'RAM (Go)',
            hint: '16',
            icon: Icons.developer_board_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
          ),
          second: NovaTextField(
            controller: storage,
            label: 'Stockage',
            hint: '512 Go SSD',
            icon: Icons.storage_outlined,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SpecRow(
          first: NovaTextField(
            controller: gpu,
            label: 'Carte graphique',
            hint: 'Intel Iris Xe, RTX 4060',
            icon: Icons.videogame_asset_outlined,
            textInputAction: TextInputAction.next,
          ),
          second: NovaTextField(
            controller: operatingSystem,
            label: 'Système',
            hint: 'Windows 11 Pro',
            icon: Icons.laptop_windows_outlined,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SpecRow(
          first: NovaTextField(
            controller: screenSize,
            label: 'Écran',
            hint: '14 pouces',
            icon: Icons.monitor_outlined,
            textInputAction: TextInputAction.next,
          ),
          second: NovaTextField(
            controller: resolution,
            label: 'Résolution',
            hint: '1920 x 1080',
            icon: Icons.aspect_ratio_outlined,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SpecRow(
          first: NovaTextField(
            controller: condition,
            label: 'État',
            hint: 'Neuf, occasion très bon état',
            icon: Icons.verified_outlined,
            textInputAction: TextInputAction.next,
          ),
          second: NovaTextField(
            controller: batteryHealth,
            label: 'Batterie',
            hint: '95%, neuve, 4 h',
            icon: Icons.battery_charging_full_outlined,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        NovaTextField(
          controller: ports,
          label: 'Connectique',
          hint: 'USB-C, HDMI, RJ45, lecteur SD',
          icon: Icons.settings_input_hdmi_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        NovaTextField(
          controller: warranty,
          label: 'Garantie',
          hint: '6 mois boutique, garantie constructeur',
          icon: Icons.workspace_premium_outlined,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class _AdaptiveSpecsForm extends StatelessWidget {
  const _AdaptiveSpecsForm({
    required this.template,
    required this.brand,
    required this.model,
    required this.size,
    required this.color,
    required this.material,
    required this.gender,
    required this.fit,
    required this.dimensions,
    required this.care,
    required this.volume,
    required this.ingredients,
    required this.skinType,
    required this.condition,
    required this.warranty,
  });

  final ProductTemplate template;
  final TextEditingController brand;
  final TextEditingController model;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController material;
  final TextEditingController gender;
  final TextEditingController fit;
  final TextEditingController dimensions;
  final TextEditingController care;
  final TextEditingController volume;
  final TextEditingController ingredients;
  final TextEditingController skinType;
  final TextEditingController condition;
  final TextEditingController warranty;

  String get _title => switch (template) {
        ProductTemplate.fashion => 'Fiche vetement',
        ProductTemplate.bag => 'Fiche sac',
        ProductTemplate.beauty => 'Fiche beaute',
        ProductTemplate.electronics => 'Fiche electronique',
        _ => 'Details produit',
      };

  @override
  Widget build(BuildContext context) {
    final fields = switch (template) {
      ProductTemplate.fashion => <Widget>[
          _SpecRow(
            first: NovaTextField(
              controller: size,
              label: 'Taille',
              hint: 'S, M, L, 38, 42',
              icon: Icons.straighten_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: color,
              label: 'Couleur',
              hint: 'Noir, rouge, imprime',
              icon: Icons.palette_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
          _SpecRow(
            first: NovaTextField(
              controller: material,
              label: 'Matiere',
              hint: 'Coton, satin, jean',
              icon: Icons.texture_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: fit,
              label: 'Coupe',
              hint: 'Slim, ample, droite',
              icon: Icons.checkroom_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
          NovaTextField(
            controller: gender,
            label: 'Public',
            hint: 'Femme, homme, enfant, mixte',
            icon: Icons.groups_outlined,
            textInputAction: TextInputAction.next,
          ),
          NovaTextField(
            controller: care,
            label: 'Entretien',
            hint: 'Lavage main, machine 30 degres',
            icon: Icons.local_laundry_service_outlined,
            textInputAction: TextInputAction.next,
          ),
        ],
      ProductTemplate.bag => <Widget>[
          _SpecRow(
            first: NovaTextField(
              controller: material,
              label: 'Matiere',
              hint: 'Cuir, simili, tissu',
              icon: Icons.texture_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: color,
              label: 'Couleur',
              hint: 'Marron, noir, beige',
              icon: Icons.palette_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
          NovaTextField(
            controller: dimensions,
            label: 'Dimensions',
            hint: '30 x 22 x 12 cm',
            icon: Icons.aspect_ratio_outlined,
            textInputAction: TextInputAction.next,
          ),
          NovaTextField(
            controller: condition,
            label: 'Etat',
            hint: 'Neuf, tres bon etat',
            icon: Icons.verified_outlined,
            textInputAction: TextInputAction.next,
          ),
        ],
      ProductTemplate.beauty => <Widget>[
          _SpecRow(
            first: NovaTextField(
              controller: brand,
              label: 'Marque',
              hint: 'Marque ou gamme',
              icon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: volume,
              label: 'Volume',
              hint: '50 ml, 250 g',
              icon: Icons.water_drop_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
          NovaTextField(
            controller: skinType,
            label: 'Type adapte',
            hint: 'Peau grasse, cheveux crepus, tous types',
            icon: Icons.spa_outlined,
            textInputAction: TextInputAction.next,
          ),
          NovaTextField(
            controller: ingredients,
            label: 'Ingredients cles',
            hint: 'Karite, aloe vera, niacinamide',
            icon: Icons.science_outlined,
            textInputAction: TextInputAction.next,
          ),
        ],
      ProductTemplate.electronics => <Widget>[
          _SpecRow(
            first: NovaTextField(
              controller: brand,
              label: 'Marque',
              hint: 'Samsung, Apple, JBL',
              icon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: model,
              label: 'Modele',
              hint: 'Galaxy A55, AirPods Pro',
              icon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
          _SpecRow(
            first: NovaTextField(
              controller: condition,
              label: 'Etat',
              hint: 'Neuf, reconditionne',
              icon: Icons.verified_outlined,
              textInputAction: TextInputAction.next,
            ),
            second: NovaTextField(
              controller: warranty,
              label: 'Garantie',
              hint: '3 mois, 1 an',
              icon: Icons.workspace_premium_outlined,
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      _ => const <Widget>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const SellerInfoBanner(
          icon: Icons.tune_rounded,
          message:
              'Le formulaire s adapte a la categorie choisie. Renseignez les infos utiles pour mieux vendre.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < fields.length; i++) ...[
          fields[i],
          if (i != fields.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.md),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.label,
    required this.placeholder,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String placeholder;
  final List<Category> categories;
  final Category? value;
  final ValueChanged<Category> onChanged;

  void _openPicker(BuildContext context) {
    showNovaSheet<void>(
      context: context,
      title: label,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final category in categories)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: value?.id == category.id
                  ? Icon(Icons.check_rounded,
                      color: sheetContext.colors.textPrimary)
                  : null,
              onTap: () {
                onChanged(category);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: categories.isEmpty ? null : () => _openPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: AppColors.muted, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selected?.name ?? placeholder,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected == null
                            ? AppColors.muted
                            : context.colors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
