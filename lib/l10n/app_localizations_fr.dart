// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'iSuite - Gestionnaire de Fichiers Owlfiles';

  @override
  String get wifiScreenTitle => 'Gestion du Réseau';

  @override
  String get ftpScreenTitle => 'Client FTP';

  @override
  String get filesTabTitle => 'Fichiers';

  @override
  String get networkTabTitle => 'Réseau';

  @override
  String get ftpTabTitle => 'FTP';

  @override
  String get aiTabTitle => 'IA';

  @override
  String get settingsTabTitle => 'Paramètres';

  @override
  String get currentConnectionLabel => 'Connexion Actuelle';

  @override
  String get wifiNetworksLabel => 'Réseaux WiFi';

  @override
  String get ftpHostLabel => 'Hôte';

  @override
  String get ftpPortLabel => 'Port';

  @override
  String get ftpUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get ftpPasswordLabel => 'Mot de passe';

  @override
  String get connectButtonLabel => 'Se connecter';

  @override
  String get disconnectButtonLabel => 'Se déconnecter';

  @override
  String get scanButtonLabel => 'Scanner les Réseaux';

  @override
  String get uploadButtonLabel => 'Téléverser un Fichier';

  @override
  String get downloadButtonLabel => 'Télécharger';

  @override
  String get noNetworksFound => 'Aucun réseau trouvé';

  @override
  String get remoteFiles => 'Fichiers Distants';

  @override
  String get connectionFailed => 'Échec de connexion';

  @override
  String get fileUploaded => 'Fichier téléversé avec succès';

  @override
  String get fileDownloaded => 'Téléchargé';

  @override
  String get portScanCompleted => 'Scan de ports terminé';

  @override
  String get pinging => 'Ping en cours';

  @override
  String get tracingRoute => 'Tracer la route vers';

  @override
  String get scanningPorts => 'Scanner les ports';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos';

  @override
  String get help => 'Aide';

  @override
  String get generalSettings => 'Paramètres Généraux';

  @override
  String get darkTheme => 'Thème Sombre';

  @override
  String get darkThemeSubtitle =>
      'Activer le mode sombre pour une meilleure visibilité en faible luminosité';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Sélectionnez votre langue préférée';

  @override
  String get autoSave => 'Sauvegarde Automatique';

  @override
  String get autoSaveSubtitle =>
      'Sauvegarder automatiquement les changements et préférences';

  @override
  String get networkSettings => 'Paramètres Réseau';

  @override
  String get networkTimeout => 'Délai d\'attente Réseau';

  @override
  String get networkTimeoutSubtitle =>
      'Délai d\'attente pour les opérations réseau (secondes)';

  @override
  String get batchSize => 'Taille du Lot';

  @override
  String get batchSizeSubtitle => 'Nombre d\'éléments à traiter par lots';

  @override
  String get aiAssistantSettings => 'Paramètres de l\'Assistant IA';

  @override
  String get responseStyle => 'Style de Réponse';

  @override
  String get responseStyleSubtitle =>
      'Choisir les préférences de réponse de l\'assistant IA';

  @override
  String get concise => 'Concise';

  @override
  String get detailed => 'Détaillé';

  @override
  String get stepByStep => 'Étape par Étape';

  @override
  String get smartSuggestions => 'Suggestions Intelligentes';

  @override
  String get smartSuggestionsSubtitle =>
      'Activer les suggestions d\'organisation de fichiers avec IA';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Numéro de Build';

  @override
  String get framework => 'Framework';

  @override
  String get database => 'Base de Données';

  @override
  String get settingsSaved => 'Paramètres sauvegardés avec succès !';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get askAiPlaceholder =>
      'Demandez-moi à propos de la gestion de fichiers, organisation, recherche...';

  @override
  String get aiWelcomeMessage =>
      'Bonjour ! Je suis votre assistant de gestion de fichiers IA. Comment puis-je vous aider aujourd\'hui ?';

  @override
  String get aiOrganizeResponse =>
      '🤖 Organisation de Fichiers IA :\n\nJe peux vous aider à organiser vos fichiers intelligemment ! Basé sur la recherche avec les LLMs comme ceux dans LlamaFS et Local-File-Organizer, voici des suggestions d\'organisation avec IA :\n\n📁 Par Type de Contenu : Documents, Images, Vidéos, Musique, Archives\n📅 Par Date : Récent, Ce Mois, Cette Année, Plus Ancien\n📊 Par Utilisation : Fréquemment Utilisé, Rarement Utilisé, Archive\n🔍 Par Analyse Intelligente : Travail, Personnel, Projets, Téléchargements\n\nSouhaitez-vous que j\'aide à implémenter l\'une de ces stratégies d\'organisation ?';

  @override
  String get aiSearchResponse =>
      '🔍 Recherche Alimentée par IA :\n\nJe peux améliorer votre recherche de fichiers avec la compréhension sémantique basée sur LLM :\n\n📝 Langage Naturel : \"Trouver mes documents fiscaux de l\'année dernière\"\n🖼️ Recherche de Contenu : \"Trouver des images de chats\" (analyse le contenu des images)\n📄 Analyse de Texte : \"Trouver des documents sur l\'apprentissage automatique\"\n🔗 Correspondance Intelligente : Comprend les synonymes et termes connexes\n\nEssayez la recherche avancée dans l\'onglet Fichiers !';

  @override
  String get aiNetworkResponse =>
      '🌐 Diagnostics Réseau :\n\nVos outils réseau incluent :\n\n📡 Scanner WiFi : Découvrir et analyser les réseaux sans fil\n🏓 Outil Ping : Tester la connectivité avec les hôtes\n🗺️ Traceroute : Cartographier les chemins réseau et identifier les problèmes\n🔍 Scanner de Ports : Vérifier les ports ouverts sur les hôtes distants\n\nUtilisez l\'onglet Réseau pour une gestion réseau complète !';

  @override
  String get aiFtpResponse =>
      '☁️ Transfert de Fichiers FTP :\n\nPartage efficace de fichiers avec :\n\n🔗 Connexion Serveur : Se connecter à n\'importe quel serveur FTP/SFTP\n📁 Navigation Répertoire : Parcourir les systèmes de fichiers distants\n⬆️ Gestionnaire de Téléversement : Transférer des fichiers avec suivi de progression\n⬇️ File d\'attente de Téléchargement : Télécharger plusieurs fichiers par lots\n\nAccédez aux outils FTP dans l\'onglet FTP !';

  @override
  String get aiHelpResponse =>
      '🧠 Capacités de l\'Assistant IA :\n\n📂 Organisation de Fichiers : Catégorisation intelligente et gestion de dossiers\n🔎 Recherche Intelligente : Recherche en langage naturel et basée sur le contenu\n🌐 Outils Réseau : Diagnostics, surveillance et dépannage\n📤 Transfert de Fichiers : Client FTP/SFTP avec fonctionnalités avancées\n📊 Analyses : Statistiques d\'utilisation des fichiers et recommandations\n🔒 Sécurité : Opérations de fichiers sûres et protection de la confidentialité\n\nQuelle tâche spécifique aimeriez-vous de l\'aide ?';

  @override
  String aiDefaultResponse(Object query) {
    return '🤔 Je comprends que vous demandez à propos de : \"$query\"\n\nJe suis conçu pour aider avec la gestion de fichiers, l\'organisation, la recherche, les outils réseau et les opérations FTP. Essayez de demander :\n\n• Organiser les fichiers par type ou contenu\n• Rechercher des fichiers spécifiques\n• Diagnostics et outils réseau\n• Transferts de fichiers FTP\n• Aide générale de gestion de fichiers\n\nComment puis-je vous aider aujourd\'hui ?';
  }

  @override
  String get selectProject => 'Sélectionner un Projet';

  @override
  String get flutterDoctor => 'Flutter Doctor';

  @override
  String get cleanCache => 'Nettoyer le Cache';

  @override
  String get pubCacheRepair => 'Réparer le Cache Pub';

  @override
  String get exit => 'Quitter';

  @override
  String get ready => 'Prêt';

  @override
  String get running => 'En cours d\'exécution';

  @override
  String get completed => 'Terminé';

  @override
  String get failed => 'Échoué';
}
