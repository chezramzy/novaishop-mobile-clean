/// Shared French strings reused across features.
///
/// Feature-specific copy stays inside each feature; this file holds only
/// strings that recur (states, generic actions, generic errors) so the
/// wording stays consistent everywhere.
class AppStrings {
  const AppStrings._();

  // Generic actions.
  static const retry = 'Réessayer';
  static const cancel = 'Annuler';
  static const confirm = 'Confirmer';
  static const save = 'Enregistrer';
  static const close = 'Fermer';
  static const delete = 'Supprimer';
  static const edit = 'Modifier';
  static const next = 'Suivant';
  static const back = 'Retour';
  static const seeAll = 'Voir tout';
  static const search = 'Rechercher';
  static const send = 'Envoyer';
  static const continueLabel = 'Continuer';
  static const validate = 'Valider';
  static const refresh = 'Actualiser';

  // Empty / error / loading states.
  static const loading = 'Chargement…';
  static const emptyTitle = 'Rien à afficher';
  static const emptyMessage = 'Aucun élément pour le moment.';
  static const errorTitle = 'Une erreur est survenue';
  static const genericError = 'Une erreur est survenue. Veuillez réessayer.';
  static const networkError =
      'Connexion au serveur impossible. Vérifiez votre réseau.';
  static const sessionExpired =
      'Votre session a expiré. Reconnectez-vous pour continuer.';
  static const invalidData = 'Données invalides. Vérifiez le formulaire.';
  static const notFound = 'Élément introuvable.';
  static const forbidden = "Vous n'avez pas accès à cette ressource.";

  // Generic success.
  static const saved = 'Modifications enregistrées.';
  static const done = 'Terminé';

  // Pull-to-refresh.
  static const pullToRefresh = 'Tirez pour actualiser';

  // App identity.
  static const appName = 'NovaShop';
  static const appTagline = 'Le catalogue NovaShop unifie';
}
