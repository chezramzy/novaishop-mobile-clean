# NovaShop Mobile - Production Rules

Ce projet est considere comme un produit en production.

## Priorites absolues

- Zero fallback local pour les donnees metier.
- Supabase est la source de verite pour les produits, demandes partenaires, commandes, messages, notifications, profils et validations admin.
- Aucune sauvegarde silencieuse dans `SharedPreferences`, fichiers locaux ou mocks pour une action metier critique.
- En cas d'erreur reseau, d'authentification ou de permission, afficher une erreur claire et stopper l'action.
- Optimiser pour performance, coherence multi-appareils, securite et observabilite.

## Interdits

- Ne pas creer, valider, modifier ou lire des produits depuis un stockage local.
- Ne pas masquer une erreur Supabase par une reussite locale.
- Ne pas ajouter de mock, fake backend, seed local ou fallback in-memory dans un flux utilisateur reel.
- Ne pas exposer les vendeurs partenaires cote client.
- Ne pas reintroduire de boutique publique, "vendu par", avis boutique, profil social vendeur ou page vendeur publique.
- Ne pas publier un APK de test sans build verifie.

## Flux partenaire

- Une demande partenaire approuvee debloque l'espace partenaire.
- Les produits partenaires sont envoyes dans Supabase avec `status = pending_review`.
- L'admin valide les produits depuis une interface admin connectee a Supabase.
- Un produit devient visible cote client uniquement avec `status = published`.
- Le partenaire reste une attribution interne (`partner_user_id`, `vendor_id`, ou equivalent), jamais une identite publique.

## Flux admin

- L'admin doit travailler sur les donnees Supabase reelles.
- Les validations/refus doivent mettre a jour Supabase directement.
- Les interfaces admin ne doivent jamais lire un cache local pour decider d'une validation.

## Qualite avant livraison

Avant de livrer une modification:

- Executer au minimum une analyse ciblee ou globale.
- Executer les tests disponibles.
- Builder l'APK si la modification touche Flutter/UI/mobile.
- Reinstaller sur appareil physique quand un test manuel est demande.
- Pousser les changements GitHub si une release APK publique depend du correctif.

## Performance

- Eviter les lectures inutiles et les doubles fetchs.
- Paginer les listes admin/catalogue quand elles peuvent grossir.
- Ne charger que les champs necessaires lorsque c'est possible.
- Eviter les traitements lourds dans le build Flutter.
- Preferer des requetes Supabase filtrees (`eq`, `order`, `limit`, `range`) aux filtrages cote client.

## Securite

- RLS et policies doivent etre traitees comme obligatoires pour la production.
- Aucune policy permissive ne doit etre ajoutee sans justification explicite et plan de durcissement.
- Les roles admin/partenaire doivent a terme venir de Supabase Auth et non d'un email code en dur.
- Les donnees sensibles ne doivent pas etre exposees dans les ecrans publics.
