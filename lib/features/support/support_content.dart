/// Contenu statique francais du module Support.
library;

class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<LegalSection> sections;
}

class SupportContent {
  const SupportContent._();

  static const supportEmail = 'support@novaishop.com';
  static const supportPhone = '+33 1 84 80 12 34';

  static const Map<String, List<FaqEntry>> faq = {
    'Commandes & livraison': [
      FaqEntry(
        'Comment suivre ma commande ?',
        'Votre commande se suit dans la conversation NovaShop ouverte depuis '
            'votre panier. Les messages et statuts y sont mis a jour en temps '
            'reel jusqu a la confirmation de livraison.',
      ),
      FaqEntry(
        'Quels sont les delais de livraison ?',
        'NovaShop confirme les delais dans la conversation de commande selon '
            'votre adresse et la disponibilite des produits.',
      ),
      FaqEntry(
        'Puis-je annuler une commande ?',
        'Envoyez un message dans la conversation de commande. NovaShop vous '
            'confirme les options possibles selon l avancement.',
      ),
    ],
    'Paiements & remboursements': [
      FaqEntry(
        'Quels moyens de paiement sont acceptes ?',
        'NovAiShop accepte les cartes bancaires ainsi que les principaux '
            'portefeuilles mobiles. Vos donnees de paiement sont chiffrees.',
      ),
      FaqEntry(
        'Comment obtenir un remboursement ?',
        'En cas de retour accepte par NovaShop, le remboursement est effectue '
            'sur votre moyen de paiement d origine sous 3 a 10 jours ouvres.',
      ),
    ],
    'Compte & securite': [
      FaqEntry(
        'Comment modifier mes informations ?',
        'Depuis votre profil, ouvrez Modifier le profil pour mettre a jour '
            'votre nom, votre telephone et vos coordonnees.',
      ),
      FaqEntry(
        'J ai oublie mon mot de passe, que faire ?',
        'Sur l ecran de connexion, utilisez Mot de passe oublie. Un lien de '
            'reinitialisation vous sera envoye par e-mail.',
      ),
      FaqEntry(
        'Comment devenir partenaire ou livreur ?',
        'Les acces partenaires sont actives par NovaShop. Les livreurs '
            'accedent a leur espace dedie depuis leur profil.',
      ),
    ],
  };

  static const LegalDocument legalNotice = LegalDocument(
    title: 'Mentions legales',
    intro: 'Les presentes mentions legales s appliquent a l application '
        'mobile NovAiShop et a l ensemble de ses services.',
    sections: [
      LegalSection(
        'Editeur',
        'L application NovAiShop est editee par NovAiShop SAS, catalogue '
            'centralise avec partenaires operationnels et livreurs.',
      ),
      LegalSection(
        'Hebergement',
        'Les services et donnees de l application sont heberges au sein de '
            'centres de donnees situes dans l Union europeenne.',
      ),
      LegalSection(
        'Propriete intellectuelle',
        'L ensemble des elements de l application (marque, logo, interface, '
            'contenus) est protege. Toute reproduction sans autorisation est '
            'interdite.',
      ),
      LegalSection(
        'Responsabilite',
        'NovAiShop presente les produits sous sa marque et coordonne les '
            'partenaires operationnels necessaires au traitement des commandes.',
      ),
    ],
  );

  static const LegalDocument privacyPolicy = LegalDocument(
    title: 'Politique de confidentialite',
    intro: 'Nous attachons une grande importance a la protection de vos '
        'donnees personnelles et a la transparence sur leur usage.',
    sections: [
      LegalSection(
        'Donnees collectees',
        'Nous collectons les informations necessaires a la creation de votre '
            'compte, au traitement de vos commandes et a l amelioration de nos '
            'services.',
      ),
      LegalSection(
        'Utilisation des donnees',
        'Vos donnees servent a executer vos commandes, communiquer les '
            'informations utiles et proposer des offres personnalisees avec '
            'votre accord.',
      ),
      LegalSection(
        'Partage des donnees',
        'Vos donnees ne sont jamais vendues. Elles peuvent etre partagees avec '
            'les partenaires operationnels et livreurs concernes uniquement '
            'pour mener a bien vos commandes.',
      ),
      LegalSection(
        'Vos droits',
        'Vous disposez d un droit d acces, de rectification et de suppression '
            'de vos donnees. Contactez le support pour exercer ces droits.',
      ),
    ],
  );

  static const LegalDocument termsOfUse = LegalDocument(
    title: 'Conditions generales d utilisation',
    intro: 'L utilisation de l application NovAiShop implique l acceptation '
        'pleine et entiere des presentes conditions.',
    sections: [
      LegalSection(
        'Acces au service',
        'L application est accessible gratuitement. La creation d un compte '
            'est requise pour passer commande ou livrer.',
      ),
      LegalSection(
        'Engagements de l utilisateur',
        'L utilisateur s engage a fournir des informations exactes et a '
            'utiliser la plateforme dans le respect de la loi.',
      ),
      LegalSection(
        'Commandes',
        'Toute commande passee constitue un engagement d achat. Les conditions '
            'de retour et de remboursement sont precisees pour chaque produit.',
      ),
      LegalSection(
        'Modification des conditions',
        'NovAiShop se reserve le droit de faire evoluer les presentes '
            'conditions. Les utilisateurs sont informes de toute modification.',
      ),
    ],
  );
}
