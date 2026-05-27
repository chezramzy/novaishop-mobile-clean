# NovAiShop Mobile

Application mobile Flutter pour le storefront NovAiShop. Le projet est separe du monorepo web/API et consomme directement l'API existante exposee par `apps/api`.

## Prerequis

- Installer le SDK Flutter puis verifier `flutter --version`.
- Depuis ce dossier, lancer une fois `flutter create . --platforms=android,ios,web` si les dossiers plateformes n'existent pas encore.
- Demarrer l'API NovAiShop depuis `../NovAiShop`.

## Lancer

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

Sur emulateur Android, utilisez plutot :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

Pour tester les endpoints authentifies pendant le developpement :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000 --dart-define=API_ACCESS_TOKEN=<supabase_access_token>
```

## Structure

- `lib/core/api` : client HTTP bas niveau, configurable par `API_BASE_URL`.
- `lib/data/models` : DTO Dart alignes sur `packages/types`.
- `lib/data/repositories` : acces catalogue et commandes.
- `lib/features` : ecrans client mobile.
- `lib/shared/widgets` : composants visuels reutilisables.

## API deja cablee

- `GET /v1/catalog/categories`
- `GET /v1/catalog/listings`
- `GET /v1/catalog/listings/:slug`
- `GET /v1/catalog/best-sellers`
- `GET /v1/catalog/new-arrivals`
- `GET /v1/orders` avec bearer token optionnel

## Authentification

Le marketplace etant multivendeurs, l'app demarre sur un parcours de compte
complet :

- Onboarding 3 ecrans avec acces direct connexion / inscription.
- Selection de role : client particulier, client grossiste, vendeur
  particulier, vendeur professionnel, livreur (identifiants alignes sur
  `apps/storefront`).
- Inscription avec champ entreprise conditionnel pour les vendeurs pro,
  validation de formulaire et acceptation des CGU.
- Verification email par code OTP a 4 chiffres.
- Connexion email / mot de passe, connexion sociale et mot de passe oublie
  (branche sur `POST /v1/auth/forgot-password`).
- `AuthGate` route entre onboarding et app selon la session, persistee via
  `shared_preferences`. Le `AuthController` est concu pour basculer vers
  `supabase_flutter` sans toucher aux ecrans (l'API attend deja un bearer
  token Supabase).

## Ecrans poses

- Onboarding, connexion, selection de role, inscription, verification OTP,
  mot de passe oublie.
- Home avec categories, top picks, new arrivals et salutation personnalisee.
- Shop / Tag Products avec post social et grille produits.
- Search avec grille et bottom sheet de filtres.
- Product detail avec image, rating, couleurs, tailles, buy bar et ajout panier.
- Cart / Checkout avec adresse, produits, recap prix et ecran de confirmation.
- Messages, chat detail et ecran d'appel.
- Profile (utilisateur reel, badge de role), edition de profil, changement de
  mot de passe, Seller Hub pour les vendeurs.
- Orders avec onglets actifs/livres/annules et annulation, step tracker.
- Wishlist, Addresses et Add Address.

Le catalogue mobile complete les reponses API avec quelques produits fashion locaux afin de garder les maquettes visibles meme quand le seed backend contient peu d'articles.
