alter table public.categories
  add column if not exists parent_id text references public.categories(id);

insert into public.categories (id, parent_id, name, slug, type, description)
values
  ('cat-product-electronics', null, 'Electronique', 'electronique', 'product', 'Telephones, ordinateurs et accessoires.'),
  ('cat-product-phones', 'cat-product-electronics', 'Telephones', 'telephones', 'product', 'Smartphones, accessoires et pieces mobiles.'),
  ('cat-product-laptops', 'cat-product-electronics', 'Ordinateur portable', 'ordinateur-portable', 'product', 'PC portables avec champs techniques predefinis.'),
  ('cat-product-audio', 'cat-product-electronics', 'Audio', 'audio', 'product', 'Ecouteurs, enceintes, casques et accessoires audio.'),
  ('cat-product-fashion', null, 'Vetements', 'vetements', 'product', 'Mode femme, homme et enfant.'),
  ('cat-product-dresses', 'cat-product-fashion', 'Robes', 'robes', 'product', 'Robes casual, soiree, ceremonie et tenues longues.'),
  ('cat-product-tops', 'cat-product-fashion', 'Hauts', 'hauts', 'product', 'T-shirts, chemises, blouses, polos et debardeurs.'),
  ('cat-product-swimwear', 'cat-product-fashion', 'Maillots', 'maillots', 'product', 'Maillots de bain, ensembles plage et tenues sport.'),
  ('cat-product-pants', 'cat-product-fashion', 'Pantalons', 'pantalons', 'product', 'Jeans, pantalons habilles, leggings et shorts.'),
  ('cat-product-skirts', 'cat-product-fashion', 'Jupes', 'jupes', 'product', 'Jupes courtes, longues, plissees et tailleurs.'),
  ('cat-product-shoes', 'cat-product-fashion', 'Chaussures', 'chaussures', 'product', 'Sneakers, sandales, talons, bottes et chaussures ville.'),
  ('cat-product-accessories', null, 'Accessoires', 'accessoires', 'product', 'Sacs, bijoux, lunettes, ceintures et accessoires mode.'),
  ('cat-product-bags', 'cat-product-accessories', 'Sacs', 'sacs', 'product', 'Sacs a main, sacs dos, pochettes et cabas.'),
  ('cat-product-jewelry', 'cat-product-accessories', 'Bijoux', 'bijoux', 'product', 'Colliers, bracelets, bagues et boucles oreille.'),
  ('cat-product-watches', 'cat-product-accessories', 'Montres', 'montres', 'product', 'Montres classiques, connectees et accessoires.'),
  ('cat-product-glasses', 'cat-product-accessories', 'Lunettes', 'lunettes', 'product', 'Lunettes soleil, optiques et accessoires.'),
  ('cat-product-beauty', null, 'Beaute', 'beaute', 'product', 'Soins, parfums, maquillage et produits capillaires.'),
  ('cat-product-haircare', 'cat-product-beauty', 'Cheveux', 'cheveux', 'product', 'Soins capillaires, perruques, extensions et accessoires.'),
  ('cat-product-skincare', 'cat-product-beauty', 'Soins visage', 'soins-visage', 'product', 'Nettoyants, cremes, serums et routines visage.'),
  ('cat-product-home', null, 'Maison', 'maison', 'product', 'Articles pour la maison et le quotidien.'),
  ('cat-product-kitchen', 'cat-product-home', 'Cuisine', 'cuisine', 'product', 'Ustensiles, rangement, vaisselle et petits equipements.'),
  ('cat-product-decor', 'cat-product-home', 'Decoration', 'decoration', 'product', 'Decoration, textiles, luminaires et objets maison.'),
  ('cat-product-kids', null, 'Enfants', 'enfants', 'product', 'Vetements, jeux, puericulture et accessoires enfants.'),
  ('cat-product-baby', 'cat-product-kids', 'Bebe', 'bebe', 'product', 'Puericulture, vetements bebe et accessoires.'),
  ('cat-product-toys', 'cat-product-kids', 'Jouets', 'jouets', 'product', 'Jeux educatifs, figurines, loisirs et cadeaux.'),
  ('cat-product-food', null, 'Alimentation', 'alimentation', 'product', 'Epicerie, boissons, produits frais et specialites.'),
  ('cat-product-sport', null, 'Sport', 'sport', 'product', 'Vetements sportifs, accessoires et equipements.'),
  ('cat-service', null, 'Services', 'services', 'service', 'Prestations et services locaux.'),
  ('cat-property', null, 'Immobilier', 'immobilier', 'property', 'Locations et biens immobiliers.')
on conflict (id) do update set
  parent_id = excluded.parent_id,
  name = excluded.name,
  slug = excluded.slug,
  type = excluded.type,
  description = excluded.description;

create index if not exists categories_parent_id_idx
  on public.categories(parent_id);
