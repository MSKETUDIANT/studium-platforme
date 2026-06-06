import 'package:flutter/material.dart';

// Accès rapide depuis n'importe quel widget :
//   context.s.navHome
extension L10n on BuildContext {
  AppStrings get s => AppStrings(Localizations.localeOf(this).languageCode);
}

class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get _fr => locale != 'en';

  //  App 
  String get appName => 'Studium';

  //  Navigation 
  String get navHome      => _fr ? 'Accueil'   : 'Home';
  String get navPrograms  => _fr ? 'Prog.'     : 'Prog.';
  String get navDossiers  => _fr ? 'Dossiers'  : 'Files';
  String get navMessages  => 'Messages';
  String get navProfile   => _fr ? 'Profil'    : 'Profile';

  //  Commun 
  String get save         => _fr ? 'Enregistrer'      : 'Save';
  String get cancel       => _fr ? 'Annuler'          : 'Cancel';
  String get confirm      => _fr ? 'Confirmer'        : 'Confirm';
  String get delete       => _fr ? 'Supprimer'        : 'Delete';
  String get edit         => _fr ? 'Modifier'         : 'Edit';
  String get back         => _fr ? 'Retour'           : 'Back';
  String get next         => _fr ? 'Suivant'          : 'Next';
  String get close        => _fr ? 'Fermer'           : 'Close';
  String get ok           => 'OK';
  String get loading      => _fr ? 'Chargement'      : 'Loading';
  String get error        => _fr ? 'Une erreur est survenue. Réessayez.' : 'An error occurred. Please try again.';
  String get noInternet   => _fr ? 'Vérifiez votre connexion internet.' : 'Check your internet connection.';
  String get optional     => _fr ? 'optionnel'        : 'optional';
  String get comingSoon   => _fr ? 'Bientôt disponible' : 'Coming soon';

  //  Auth 
  String get login                => _fr ? 'Connexion'              : 'Sign in';
  String get register             => _fr ? 'Créer un compte'        : 'Create account';
  String get email                => 'Email';
  String get password             => _fr ? 'Mot de passe'           : 'Password';
  String get confirmPassword      => _fr ? 'Confirmer le mot de passe' : 'Confirm password';
  String get forgotPassword       => _fr ? 'Mot de passe oublié ?'  : 'Forgot password?';
  String get signIn               => _fr ? 'Se connecter'           : 'Sign in';
  String get signUp               => _fr ? "S'inscrire"             : 'Sign up';
  String get signOut              => _fr ? 'Se déconnecter'         : 'Sign out';
  String get noAccount            => _fr ? 'Pas encore de compte ?' : 'No account yet?';
  String get alreadyAccount       => _fr ? 'Déjà un compte ?'       : 'Already have an account?';
  String get acceptTerms          => _fr ? "J'accepte les conditions d'utilisation" : 'I accept the terms of use';
  String get verifyEmail          => _fr ? 'Confirmez votre email'  : 'Confirm your email';
  String get verifyEmailSent      => _fr ? 'Lien envoyé. Vérifiez votre boîte mail.' : 'Link sent. Check your inbox.';
  String get resetPasswordTitle   => _fr ? 'Réinitialiser le mot de passe' : 'Reset password';
  String get resetPasswordSent    => _fr ? 'Email de réinitialisation envoyé.' : 'Reset email sent.';
  String get newPassword          => _fr ? 'Nouveau mot de passe'   : 'New password';
  String get googleSignIn         => _fr ? 'Continuer avec Google'  : 'Continue with Google';
  String get passwordStrength     => _fr ? 'Force du mot de passe'  : 'Password strength';
  String get passwordWeak         => _fr ? 'Faible'                 : 'Weak';
  String get passwordMedium       => _fr ? 'Moyen'                  : 'Medium';
  String get passwordStrong       => _fr ? 'Fort'                   : 'Strong';
  String get passwordVeryStrong   => _fr ? 'Très fort'              : 'Very strong';

  //  Dashboard 
  String get hello            => _fr ? 'Bonjour'            : 'Hello';
  String get continueGoals    => _fr ? 'Continuez à avancer vers vos objectifs académiques.' : 'Keep moving towards your academic goals.';
  String get profileCompletion => _fr ? 'Complétion du profil' : 'Profile completion';
  String get quickActions     => _fr ? 'Actions rapides'    : 'Quick actions';
  String get mySpaces         => _fr ? 'Mes espaces'        : 'My spaces';
  String get myDocuments      => _fr ? 'Mes Documents'      : 'My Documents';
  String get myApplications   => _fr ? 'Mes Candidatures'   : 'My Applications';
  String get moreThan100      => _fr ? '100+ cursus'        : '100+ programs';
  String get documentsDesc    => _fr ? 'CV, relevés de notes, recommandations' : 'CV, transcripts, recommendations';
  String get applicationsDesc => _fr ? "Suivez l'état de vos dossiers" : 'Track your application status';
  String get messagesDesc     => _fr ? 'Communiquer avec votre équipe' : 'Communicate with your team';

  //  Profil 
  String get profile              => _fr ? 'Profil'                 : 'Profile';
  String get editProfile          => _fr ? 'Modifier mes informations' : 'Edit my information';
  String get studentProfile       => _fr ? 'Profil Étudiant'        : 'Student Profile';
  String get profileComplete      => _fr ? ' Profil complet'       : ' Profile complete';
  String get personalInfo         => _fr ? 'Informations personnelles' : 'Personal information';
  String get academicBackground   => _fr ? 'Parcours académique'    : 'Academic background';
  String get experiences          => _fr ? 'Expériences'            : 'Experiences';
  String get motivation           => _fr ? 'Motivation'             : 'Motivation';
  String get contact              => _fr ? 'Contact'                : 'Contact';
  String get locationOrigin       => _fr ? 'Localisation & origine' : 'Location & origin';
  String get objectives           => _fr ? 'Objectifs'              : 'Objectives';
  String get academicObjectives   => _fr ? 'Objectifs académiques'  : 'Academic goals';
  String get careerObjectives     => _fr ? 'Objectifs professionnels' : 'Career goals';
  String get motivationLetter     => _fr ? 'Lettre de motivation'   : 'Motivation letter';
  String get phone                => _fr ? 'Téléphone'              : 'Phone';
  String get birthDate            => _fr ? 'Date de naissance'      : 'Date of birth';
  String get nationality          => _fr ? 'Nationalité'            : 'Nationality';
  String get countryResidence     => _fr ? 'Pays de résidence'      : 'Country of residence';
  String get address              => _fr ? 'Adresse'                : 'Address';
  String get firstName            => _fr ? 'Prénom'                 : 'First name';
  String get lastName             => _fr ? 'Nom'                    : 'Last name';
  String get addDegree            => _fr ? 'Ajouter un diplôme'     : 'Add a degree';
  String get addExperience        => _fr ? 'Ajouter une expérience' : 'Add an experience';
  String get noDegrees            => _fr ? 'Aucun diplôme ajouté.'  : 'No degrees added.';
  String get noExperiences        => _fr ? 'Aucune expérience ajoutée.' : 'No experiences added.';
  String get infoStep             => _fr ? 'Infos'                  : 'Info';
  String get studiesStep          => _fr ? 'Études'                 : 'Studies';
  String get expStep              => _fr ? 'Expér.'                 : 'Exp.';
  String get docsStep             => _fr ? 'Docs'                   : 'Docs';

  //  Programmes 
  String get programs             => _fr ? 'Programmes'             : 'Programs';
  String get searchPrograms       => _fr ? 'Rechercher une formation' : 'Search programs';
  String get favorites            => _fr ? 'Favoris'                : 'Favorites';
  String get noFavorites          => _fr ? 'Aucun favori'           : 'No favorites';
  String get noFavoritesDesc      => _fr ? 'Ajoutez des programmes en favoris depuis le catalogue.' : 'Add programs to favorites from the catalog.';
  String get noPrograms           => _fr ? 'Aucun programme trouvé' : 'No programs found';
  String get filterLevel          => _fr ? 'Niveau'                 : 'Level';
  String get filterCountry        => _fr ? 'Pays'                   : 'Country';
  String get filterLanguage       => _fr ? 'Langue'                 : 'Language';
  String get filterDuration       => _fr ? 'Durée'                  : 'Duration';
  String get filterCost           => _fr ? 'Coût'                   : 'Cost';
  String get filterDeadline       => _fr ? 'Deadline'               : 'Deadline';
  String get filterDomain         => _fr ? 'Domaine'                : 'Domain';
  String get allLevels            => _fr ? 'Tous niveaux'           : 'All levels';
  String get allCountries         => _fr ? 'Tous pays'              : 'All countries';
  String get allLanguages         => _fr ? 'Toutes langues'         : 'All languages';
  String get allDurations         => _fr ? 'Toutes durées'          : 'All durations';
  String get allCosts             => _fr ? 'Tous coûts'             : 'All costs';
  String get allDeadlines         => _fr ? 'Toutes deadlines'       : 'All deadlines';
  String get allDomains           => _fr ? 'Tous domaines'          : 'All domains';
  String get free                 => _fr ? 'Gratuit'                : 'Free';
  String get applyNow             => _fr ? 'Postuler maintenant'    : 'Apply now';
  String get requiredDocuments    => _fr ? 'Documents requis'       : 'Required documents';
  String get programDetails       => _fr ? 'Détails du programme'   : 'Program details';
  String get contactEmail         => _fr ? 'Email de contact'       : 'Contact email';

  //  Candidatures 
  String get applications         => _fr ? 'Candidatures'           : 'Applications';
  String get newApplication       => _fr ? 'Nouvelle candidature'   : 'New application';
  String get noApplications       => _fr ? 'Aucune candidature'     : 'No applications';
  String get noApplicationsDesc   => _fr ? 'Commencez par rechercher un programme.' : 'Start by searching for a program.';
  String get submit               => _fr ? 'Soumettre'              : 'Submit';
  String get saveDraft            => _fr ? 'Brouillon'              : 'Draft';
  String get downloadPdf          => _fr ? 'Télécharger PDF'        : 'Download PDF';
  String get generating           => _fr ? 'Génération'            : 'Generating';
  String get submitting           => _fr ? 'Envoi en cours'        : 'Submitting';
  String get submittedSuccess     => _fr ? 'Candidature soumise avec succès' : 'Application submitted successfully';
  String get draftSaved           => _fr ? 'Brouillon enregistré'   : 'Draft saved';
  String get selectProgram        => _fr ? 'Sélectionnez un programme' : 'Select a program';
  String get yourDossier          => _fr ? 'Votre dossier'          : 'Your file';
  String get selectDocuments      => _fr ? 'Sélectionnez les documents à joindre à votre candidature.' : 'Select the documents to attach to your application.';
  String get noDocumentsUploaded  => _fr ? 'Aucun document uploadé. Ajoutez des documents dans votre profil avant de soumettre.' : 'No documents uploaded. Add documents to your profile before submitting.';
  String get recap                => _fr ? 'Récapitulatif'          : 'Summary';
  String get completenessChecklist => _fr ? 'Checklist de complétude' : 'Completeness checklist';
  String get motivationOptional   => _fr ? 'Message de motivation (optionnel)' : 'Motivation message (optional)';
  String get motivationHint       => _fr ? 'Expliquez votre motivation pour ce programme' : 'Explain your motivation for this program';
  String get confirmExact         => _fr ? 'En soumettant, vous confirmez que vos informations sont exactes et vos documents à jour.' : 'By submitting, you confirm that your information is accurate and your documents are up to date.';
  String get applicationDetail    => _fr ? 'Détails de la candidature' : 'Application details';
  String get currentStatus        => _fr ? 'Statut actuel'          : 'Current status';
  String get dossierCompleteness  => _fr ? 'Complétude du dossier'  : 'File completeness';
  String get trackApplication     => _fr ? 'Suivi de candidature'   : 'Application tracking';
  String get changeHistory        => _fr ? 'Historique des changements' : 'Change history';
  String get noChanges            => _fr ? 'Aucun changement enregistré pour le moment.' : 'No changes recorded yet.';
  String get criteriaFilled       => _fr ? 'critères remplis'       : 'criteria met';
  String get dossierComplete      => _fr ? 'Dossier complet'        : 'File complete';
  String get almostComplete       => _fr ? 'Presque complet'        : 'Almost complete';
  String get incomplete           => _fr ? 'Incomplet'              : 'Incomplete';
  String get applicationSubmitted => _fr ? 'Candidature soumise'    : 'Application submitted';
  String get programSelected      => _fr ? 'Programme sélectionné'  : 'Program selected';
  String get universityFilled     => _fr ? 'Université renseignée'  : 'University filled';
  String get countryDestination   => _fr ? 'Pays de destination'    : 'Destination country';
  String get studyLevel           => _fr ? "Niveau d'études"        : 'Study level';

  //  Statuts candidature 
  String get statusDraft          => _fr ? 'Brouillon'              : 'Draft';
  String get statusSubmitted      => _fr ? 'Soumise'                : 'Submitted';
  String get statusNeedsFix       => _fr ? 'Correction requise'     : 'Correction required';
  String get statusVerified       => _fr ? 'Validée'                : 'Verified';
  String get statusSent           => _fr ? 'Envoyée'                : 'Sent';
  String get statusAccepted       => _fr ? 'Acceptée'               : 'Accepted';
  String get statusRejected       => _fr ? 'Refusée'                : 'Rejected';
  String get statusPending        => _fr ? 'Décision en attente'    : 'Pending decision';
  String get statusArchived       => _fr ? 'Archivée'               : 'Archived';

  //  Documents 
  String get documents            => _fr ? 'Documents'              : 'Documents';
  String get addDocument          => _fr ? '+ Ajouter'              : '+ Add';
  String get noDocumentsTitle     => _fr ? 'Aucun document'         : 'No documents';
  String get noDocumentsDesc      => _fr ? 'Ajoutez vos documents pour compléter votre dossier.' : 'Add your documents to complete your file.';
  String get docApproved          => _fr ? 'Approuvé'               : 'Approved';
  String get docRejected          => _fr ? 'Rejeté'                 : 'Rejected';
  String get docPending           => _fr ? 'En attente'             : 'Pending';
  String get docUnderReview       => _fr ? 'En révision'            : 'Under review';
  String get docCv                => _fr ? 'CV'                     : 'CV / Résumé';
  String get docTranscript        => _fr ? 'Relevé de notes'        : 'Transcript';
  String get docRecommendation    => _fr ? 'Lettre de recommandation' : 'Recommendation letter';
  String get docPassport          => _fr ? 'Passeport / Pièce d\'identité' : 'Passport / ID';
  String get docOther             => _fr ? 'Autre document'         : 'Other document';
  String get rejectionReason      => _fr ? 'Motif de rejet'         : 'Rejection reason';
  String get uploadTitle          => _fr ? 'Ajouter un document'    : 'Add a document';
  String get chooseFile           => _fr ? 'Choisir un fichier'     : 'Choose a file';
  String get docType              => _fr ? 'Type de document'       : 'Document type';

  //  Messages 
  String get studiumTeam          => _fr ? 'Équipe Studium'         : 'Studium Team';
  String get online               => _fr ? 'En ligne'               : 'Online';
  String get writeMessage         => _fr ? 'Écrivez un message'    : 'Write a message';
  String get noConversation       => _fr ? 'Aucun message'          : 'No messages';
  String get noConversationDesc   => _fr ? "Envoyez un message à l'équipe Studium." : 'Send a message to the Studium team.';
  String get send                 => _fr ? 'Envoyer'                : 'Send';

  //  Notifications 
  String get notifications        => _fr ? 'Notifications'          : 'Notifications';
  String get markAllRead          => _fr ? 'Tout lire'              : 'Mark all read';
  String get noNotifications      => _fr ? 'Aucune notification'    : 'No notifications';
  String get noNotificationsDesc  => _fr ? 'Vous serez notifié des mises à jour\nde vos candidatures ici.' : 'You will be notified of updates\nto your applications here.';

  //  Paramètres 
  String get settings             => _fr ? 'Paramètres'             : 'Settings';
  String get myAccount            => _fr ? 'Mon compte'             : 'My account';
  String get appearance           => _fr ? 'Apparence'              : 'Appearance';
  String get darkMode             => _fr ? 'Thème sombre'           : 'Dark mode';
  String get darkModeOn           => _fr ? 'Activé'                 : 'Enabled';
  String get darkModeOff          => _fr ? 'Désactivé'              : 'Disabled';
  String get language             => _fr ? 'Langue'                 : 'Language';
  String get accountSection       => _fr ? 'Gestion du compte'      : 'Account';
  String get changePassword       => _fr ? 'Changer le mot de passe' : 'Change password';
  String get exportData           => _fr ? 'Exporter mes données (RGPD)' : 'Export my data (GDPR)';
  String get deleteAccount        => _fr ? 'Supprimer mon compte'   : 'Delete my account';
  String get supportSection       => _fr ? 'Support'                : 'Support';
  String get faq                  => 'FAQ';
  String get contactSupport       => _fr ? 'Contacter le support'   : 'Contact support';
  String get supportEmail         => 'support@studium.app';
  String get appVersion           => _fr ? 'Version de l\'application' : 'App version';
  String get emailSent            => _fr ? 'Email envoyé'           : 'Email sent';
  String get resetLinkSent        => _fr ? 'Un lien de réinitialisation a été envoyé à' : 'A reset link has been sent to';
  String get checkEmail           => _fr ? 'Consultez votre boîte mail.' : 'Check your inbox.';
  String get exportTitle          => _fr ? 'Export de données'      : 'Data export';
  String get exportBody           => _fr ? 'Conformément au RGPD, envoyez votre demande à :\n\ndpo@studium.app\n\nVous recevrez vos données dans les 72h.' : 'Under GDPR, send your request to :\n\ndpo@studium.app\n\nYou will receive your data within 72h.';
  String get deleteTitle          => _fr ? 'Supprimer mon compte'   : 'Delete my account';
  String get deleteBody           => _fr ? 'Cette action est irréversible. Toutes vos données seront supprimées définitivement.' : 'This action is irreversible. All your data will be permanently deleted.';
  String get contactTitle         => _fr ? 'Contacter le support'   : 'Contact support';
  String get contactBody          => _fr ? 'Pour toute question, écrivez-nous à :\n\nsupport@studium.app\n\nDélai de réponse : 24-48h ouvrées.' : 'For any question, write to us at :\n\nsupport@studium.app\n\nResponse time: 24-48 business hours.';

  //  Divers 
  String get student    => _fr ? 'Étudiant'   : 'Student';
  String get retry      => _fr ? 'Réessayer'  : 'Retry';

  //  Niveaux 
  String get bachelor   => _fr ? 'Licence'    : 'Bachelor';
  String get master     => _fr ? 'Master'     : 'Master';
  String get phd        => _fr ? 'Doctorat'   : 'PhD';

  //  FAQ 
  String get faqTitle       => _fr ? 'Questions fréquentes'     : 'Frequently asked questions';
  List<(String, String)> get faqItems => _fr ? [
    ('Comment soumettre une candidature ?',
     'Allez dans l\'onglet Dossiers, appuyez sur "+" et suivez le wizard en 3 étapes : programme  documents  récapitulatif.'),
    ('Comment ajouter un document ?',
     'Depuis votre profil, accédez à "Mes Documents" et appuyez sur "+ Ajouter". Formats acceptés : PDF, JPG, PNG (max 10 Mo).'),
    ('Pourquoi mon document est rejeté ?',
     'L\'équipe Studium vérifie la conformité. Le motif de rejet est affiché dans votre espace documents. Corrigez et renvoyez.'),
    ('Comment suivre ma candidature ?',
     'Dans l\'onglet Dossiers, cliquez sur la candidature pour voir la timeline complète.'),
    ('Comment contacter l\'équipe ?',
     'Utilisez l\'onglet Messages pour discuter en temps réel avec l\'équipe Studium.'),
  ] : [
    ('How do I submit an application?',
     'Go to the Files tab, tap "+" and follow the 3-step wizard: program  documents  summary.'),
    ('How do I add a document?',
     'From your profile, go to "My Documents" and tap "+ Add". Accepted formats: PDF, JPG, PNG (max 10 MB).'),
    ('Why was my document rejected?',
     'The Studium team checks compliance. The rejection reason is shown in your documents section. Correct and resubmit.'),
    ('How do I track my application?',
     'In the Files tab, tap on the application to see the full timeline.'),
    ('How do I contact the team?',
     'Use the Messages tab to chat in real time with the Studium team.'),
  ];
}
