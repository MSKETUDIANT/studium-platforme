# Instructions de mise à jour — Rapport PFE Studium

**Contexte :** le rapport déposé documente honnêtement deux écarts au cahier des charges :
1. le **pack de soumission assemblé** (§5.2, B5/B6) n'était pas implémenté — la candidature était
   envoyée à l'université sous forme de documents individuels (pièces jointes ou liens séparés) ;
2. la **documentation technique**, le **guide utilisateur** et le **plan de maintenance** (§14,
   US-11.3/US-11.4) étaient absents du dépôt.

Les deux ont depuis été réalisés (vérifié : migration appliquée, fonctions déployées et testées,
fichiers versionnés). Ce document liste, section par section, chaque passage du rapport à corriger
pour refléter l'état réel, avec citation exacte du texte actuel et texte de remplacement proposé.
Je n'ai pas accès aux sources LaTeX du rapport (seulement au PDF rendu) — ces instructions sont à
appliquer manuellement ou via l'outil qui a accès aux sources.

**Preuves disponibles** (à l'appui de chaque changement, vérifiées dans cette session) :
- `supabase/functions/generate-application-pack/index.ts` — Edge Function complète (pdf-lib)
- `supabase/functions/generate-application-pack/pack_utils.ts` + `pack_utils.test.ts` — 9 tests Deno, tous passants (`deno test`)
- `supabase/functions/send-application-email/index.ts` — appelle désormais `generate-application-pack` et joint le pack (plus les documents non fusionnables) au lieu des documents individuels
- `supabase/functions/send-application-email/email_templates.test.ts` — 12 tests Deno, tous passants (préexistants, non mentionnés dans le rapport actuel)
- `supabase/migrations/20260916_recreate_application_packs.sql` — recrée `application_packs` (RLS étudiant/staff en lecture, écriture service_role) + bucket `application-packs` (public)
- `DOCUMENTATION_TECHNIQUE.md`, `GUIDE_UTILISATEUR_EQUIPE.md`, `PLAN_DE_MAINTENANCE.md`, `CAHIER_DE_RECETTE.md` — à la racine du dépôt applicatif

---

## PARTIE A — Pack de soumission assemblé (désormais implémenté)

### A1. Chapitre 2, §2.1.3, Tableau 2.1 — ligne "Pack PDF généré"

**Texte actuel (Description) :**
> Jalon de la conception initiale, sans statut dédié. Le flux actuel envoie les documents approuvés sans assemblage en pack ; le résumé PDF de l'agent est indépendant.

**Remplacer par :**
> Le pack PDF assemblé (couverture, profil, parcours académique, expériences, lettre de motivation, documents approuvés fusionnés) est généré automatiquement lors du premier envoi de la candidature à l'université, via l'Edge Function `generate-application-pack`, puis réutilisé pour les envois suivants tant que le profil et les documents approuvés n'ont pas changé depuis sa génération (régénéré automatiquement sinon, avec incrément de version). Le résumé PDF de l'agent (tableau de bord) reste indépendant.

**Texte actuel (Déclencheur) :**
> Conception initiale : génération avant envoi ; réalisation actuelle : résumé PDF à la demande

**Remplacer par :**
> Agent Admissions : action « Envoyer à l'université » — génération automatique au premier appel, réutilisation ensuite

**Paragraphe qui suit le tableau — texte actuel :**
> Ces douze libellés ne correspondent pas tous à une valeur de statut distincte persistée en base : neuf d'entre eux [...] correspondent chacun à une valeur enregistrée [...]. Les trois autres désignent des étapes intermédiaires sans valeur de statut dédiée : « Documents en attente » précède la soumission (complétude du dossier calculée côté client) ; « À vérifier » désigne la file d'attente de l'agent pour un dossier au statut « Soumise » ; « Pack PDF généré » est un jalon de la conception initiale, non intégré au flux d'envoi actuel. La génération du résumé PDF côté agent est indépendante de cet envoi.

**Remplacer la dernière partie** (à partir de « ; « Pack PDF généré »... ») par :
> ; « Pack PDF généré » correspond désormais à une étape réelle du flux d'envoi (génération ou réutilisation automatique du pack lors de l'action « Envoyer à l'université »), sans valeur de statut dédiée en base — le pack est une ressource associée à la candidature (table `application_packs`), pas un état du cycle de vie. La génération du résumé PDF côté agent reste indépendante de cet envoi.

---

### A2. Chapitre 2, §2.5.1 Périmètre du MVP

**Texte actuel :**
> **MVP** : fonctionnalités retenues pour la réalisation au cours du stage, couvrant l'authentification, le profil étudiant, le catalogue de programmes, la création et la soumission de candidatures, la validation par l'équipe, ainsi que la génération PDF et l'envoi des candidatures. Leur réalisation et leurs limites de validation sont détaillées aux chapitres 3 à 5 ; en particulier, l'envoi actuel transmet les documents approuvés individuellement, sans assemblage du pack initialement prévu ;

**Remplacer par :**
> **MVP** : fonctionnalités retenues pour la réalisation au cours du stage, couvrant l'authentification, le profil étudiant, le catalogue de programmes, la création et la soumission de candidatures, la validation par l'équipe, ainsi que la génération et l'envoi d'un pack PDF assemblé aux universités. Leur réalisation et leurs limites de validation sont détaillées aux chapitres 3 à 5 ;

*(Optionnel, fin du paragraphe suivant sur US-11.3/US-11.4 — voir PARTIE B, ne pas modifier ici sans lire B.)*

---

### A3. Chapitre 3, §3.2 — légende Figure 3.1

**Texte actuel :**
> Figure 3.1 : Architecture globale de Studium (réalisé par l'auteur). Ce diagramme reflète l'architecture prévue en conception initiale ; le pack PDF assemblé n'a pas été implémenté (voir chapitre 4).

**Remplacer par :**
> Figure 3.1 : Architecture globale de Studium (réalisé par l'auteur). Le pack PDF assemblé qu'illustre ce diagramme (« Application Pack PDF » dans Supabase Storage) est désormais implémenté et conforme à ce schéma (voir chapitre 4, §4.2.3 et §4.2.6).

*(Aucune modification du diagramme lui-même : il montrait déjà "Application Pack PDF" dans Supabase Storage — l'implémentation réelle suit ce schéma initial.)*

---

### A4. Chapitre 3, §3.3 — légende Figure 3.2

**Texte actuel :**
> Figure 3.2 : Diagramme de déploiement de Studium (réalisé par l'auteur). Ce diagramme reflète l'architecture prévue en conception initiale ; le pack PDF assemblé n'a pas été implémenté (voir chapitre 4).

**Remplacer par :**
> Figure 3.2 : Diagramme de déploiement de Studium (réalisé par l'auteur). Le composant "Application Pack PDF" (généré par l'Edge Function `generate-application-pack`, stocké via Supabase Storage) est désormais implémenté, conformément à ce schéma (voir chapitre 4, §4.2.3 et §4.2.6).

---

### A5. Chapitre 4, §4.2.3 — section "Distinction entre les documents PDF"

**Texte actuel (3e puce) :**
> — **Le pack de soumission** : un document unique prévu par le cahier des charges (B5/B6), regroupant page de couverture, profil, motivation et documents joints, destiné à l'université. Ce pack assemblé n'est pas implémenté ; voir le paragraphe « Adaptation du pack de soumission prévu ».

**Remplacer par :**
> — **Le pack de soumission** : un document unique prévu par le cahier des charges (B5/B6), regroupant page de couverture, profil, motivation et documents joints, destiné à l'université. Ce pack est assemblé automatiquement par l'Edge Function `generate-application-pack` lors du premier envoi ; voir le paragraphe « Génération et persistance du pack de soumission ».

**Paragraphe suivant — texte actuel :**
> Les deux résumés sont générés à la volée et remis directement à l'utilisateur par partage natif ou téléchargement dans le navigateur, sans persistance dans Supabase Storage et indépendamment de l'envoi à l'université. Supabase Storage héberge les documents déposés par les étudiants, et non ces PDF générés. Les mentions ultérieures précisent lequel de ces trois éléments est concerné.

**Remplacer par :**
> Les deux résumés sont générés à la volée et remis directement à l'utilisateur par partage natif ou téléchargement dans le navigateur, sans persistance dans Supabase Storage et indépendamment de l'envoi à l'université. Le pack de soumission, à l'inverse, est **persisté** dans un bucket Storage dédié (`application-packs`) et réutilisé d'un envoi à l'autre — c'est le seul des trois PDF à ne pas être régénéré systématiquement. Les mentions ultérieures précisent lequel de ces trois éléments est concerné.

**Paragraphe "Flux d'envoi et traçabilité" — texte actuel :**
> Dans l'implémentation actuelle, les documents approuvés sont transmis individuellement, en pièces jointes ou sous forme de liens signés, à l'adresse de contact du programme via l'API Resend, appelée depuis une Edge Function Supabase.

**Remplacer par :**
> Dans l'implémentation actuelle, le pack PDF assemblé (et, en complément, les documents approuvés dont le format ne peut être fusionné, tels que `.doc`/`.docx`) sont transmis à l'adresse de contact du programme via l'API Resend, en pièces jointes ou sous forme de liens signés selon la taille totale, appelés depuis une Edge Function Supabase.

---

### A6. Chapitre 4, §4.2.4 — paragraphe d'introduction aux diagrammes UML

**Texte actuel :**
> Les figures 4.12, 4.13 et 4.14 présentent les modèles de conception du Sprint 4, et non un relevé exhaustif de la version finale. La mention « conception initiale » est conservée pour les cas d'utilisation et la séquence d'envoi, car ils prévoient l'assemblage d'un pack PDF absent du flux implémenté. Le diagramme de classes conserve également des éléments prévus mais non réalisés, notamment `ApplicationPack` et `ApplicationField`, distingués des classes utilisées dans le commentaire qui l'accompagne.

**Remplacer par :**
> Les figures 4.12, 4.13 et 4.14 présentent les modèles de conception du Sprint 4, et non un relevé exhaustif de la version finale. La mention « conception initiale » est conservée pour le diagramme de séquence d'envoi (figure 4.14), qui simplifie le flux réel (il ne montre pas la réutilisation d'un pack existant ni le cas des documents non fusionnables — voir §4.2.6 pour le comportement exact). Le diagramme de classes conserve un élément prévu mais non réalisé, `ApplicationField` (champs dynamiques par programme, cf. A4.1) ; en revanche, `ApplicationPack` est désormais une classe implémentée (table `application_packs`, recréée par la migration `20260916_recreate_application_packs.sql`).

---

### A7. Chapitre 4, §4.2.4 — légende Figure 4.12 (cas d'utilisation Sprint 4)

**Dernière phrase du paragraphe qui suit le diagramme — texte actuel :**
> L'inclusion de la génération préalable du pack PDF décrit la conception initiale, et non le flux d'envoi actuellement implémenté, qui transmet directement les documents approuvés.

**Remplacer par :**
> L'inclusion de la génération préalable du pack PDF correspond désormais au flux d'envoi réellement implémenté : chaque envoi à l'université déclenche la génération (ou la réutilisation, si un pack à jour existe déjà) du pack avant transmission.

---

### A8. Chapitre 4, §4.2.4 — texte sous Figure 4.13 (diagramme de classes Sprint 4)

**Texte actuel :**
> [...] La classe `ApplicationField` représente les champs dynamiques par programme prévus en A4.1 du cahier des charges, mais non implémentés dans la version actuelle ; leur réalisation constitue une évolution possible, et non une fonctionnalité simplement en attente de validation. La classe `ApplicationPack` représente le pack prévu dans la conception initiale ; le flux d'envoi actuel ne crée pas ce pack et les PDF générés à la volée ne sont pas persistés dans Supabase Storage. Les classes `Task`, `Role` et `UserRole` restent en périphérie du périmètre strict.

**Remplacer par :**
> [...] La classe `ApplicationField` représente les champs dynamiques par programme prévus en A4.1 du cahier des charges, mais non implémentés dans la version actuelle ; leur réalisation constitue une évolution possible, et non une fonctionnalité simplement en attente de validation. La classe `ApplicationPack` est désormais implémentée : chaque pack généré par `generate-application-pack` est enregistré dans `application_packs` (URL, version, auteur, date), et le fichier PDF correspondant est persisté dans le bucket Storage `application-packs`. Les classes `Task`, `Role` et `UserRole` restent en périphérie du périmètre strict.

---

### A9. Chapitre 4, §4.2.6 — paragraphe "Gestion des pièces jointes volumineuses"

**Texte actuel :**
> Lors de l'envoi de la candidature par email, la fonction Edge `send-application-email` calcule la taille cumulée des documents approuvés du dossier. En dessous d'un seuil de 20 Mo, les documents sont téléchargés puis joints directement à l'email. Au-delà, l'envoi bascule automatiquement sur un mode alternatif : un lien de téléchargement signé est généré pour chaque document via l'API de stockage Supabase, valable 7 jours, et inséré dans le corps de l'email à la place de la pièce jointe. Son déclenchement effectif au-delà du seuil de 20 Mo n'a pas encore été observé en conditions réelles.

**Remplacer par :**
> Lors de l'envoi de la candidature par email, la fonction Edge `send-application-email` appelle d'abord `generate-application-pack` (génération ou réutilisation du pack assemblé), puis calcule la taille cumulée du pack PDF et des documents approuvés dont le format n'a pas pu être fusionné dans le pack (ex. `.doc`/`.docx`). En dessous d'un seuil de 20 Mo, le pack et ces documents sont téléchargés puis joints directement à l'email. Au-delà, l'envoi bascule automatiquement sur un mode alternatif : un lien de téléchargement signé est généré pour le pack et pour chaque document non fusionné via l'API de stockage Supabase, valable 7 jours, et inséré dans le corps de l'email à la place de la pièce jointe. Son déclenchement effectif au-delà du seuil de 20 Mo n'a pas encore été observé en conditions réelles.

---

### A10. Chapitre 4, §4.2.6 — remplacer le paragraphe "Adaptation du pack de soumission prévu"

**Texte actuel (paragraphe entier à remplacer) :**
> **Adaptation du pack de soumission prévu** L'envoi individuel des documents ou de leurs liens remplace le pack de soumission prévu au cahier des charges (§5.2, B5/B6). L'université reçoit ainsi plusieurs pièces ou liens séparés plutôt qu'un dossier assemblé en un fichier unique. Les résumés destinés à l'étudiant et à l'agent ne satisfont pas cette exigence de pack de soumission. Cette adaptation n'est, à ce jour, appuyée par aucune validation formelle documentée avec l'encadrant.

**Remplacer par :**
> **Génération et persistance du pack de soumission** Conformément au cahier des charges (§5.2, B5/B6), l'université reçoit désormais un dossier assemblé en un fichier PDF unique plutôt que des pièces séparées. Le pack est construit par l'Edge Function `generate-application-pack` (bibliothèque `pdf-lib`) : une page de couverture (identité du candidat, programme, université, informations personnelles), une section formations et expériences, la lettre de motivation et les objectifs académiques/de carrière, une page listant les documents inclus, puis la fusion effective des documents approuvés au format PDF (fusion de pages) ou image JPG/PNG (intégrées comme pages), chaque page annexe portant une étiquette de traçabilité discrète (numéro d'annexe, type de document, référence de la candidature) et une pagination globale.
>
> Les formats non pris en charge par la fusion (`.doc`/`.docx`) ne sont pas convertis : ils sont listés explicitement dans le pack comme « transmis séparément » et restent joints ou liés individuellement en complément du pack lors de l'envoi email.
>
> Le pack est généré une seule fois par candidature et persisté dans le bucket Storage `application-packs` (table `application_packs` : URL, version, auteur, date de génération). Les envois suivants réutilisent le pack existant sans le régénérer, sauf si le profil de l'étudiant ou l'un des documents approuvés a été modifié après sa génération (détection de péremption), auquel cas une nouvelle version est produite. Cette logique est couverte par 9 tests unitaires Deno (`pack_utils.test.ts` : classification fusionnable/non-fusionnable, détection de péremption, découpage du texte, extraction du chemin de stockage), tous passants à la date de rédaction.
>
> Cette réalisation reste vérifiée au niveau de la logique pure par tests unitaires et par lecture du code du flux d'envoi ; elle n'a pas encore fait l'objet d'un test d'intégration bout-en-bout téléchargeant et ouvrant un pack réel généré contre une instance Supabase, ni d'une confirmation de réception par un destinataire universitaire réel — cette dernière restant de toute façon conditionnée par la levée de la restriction Resend documentée en anomalie A04.

---

### A11. Chapitre 4, §4.3 — Tableau 4.3, ligne "PDF"

**Texte actuel :**
> | PDF | Téléchargement côté étudiant et résumé de candidature à la demande côté agent, indépendants de l'envoi email |

**Remplacer par :**
> | PDF | Téléchargement côté étudiant, résumé à la demande côté agent (tous deux indépendants de l'envoi), et pack de soumission assemblé généré et persisté pour chaque envoi à l'université |

---

### A12. Chapitre 4 — Conclusion de la Release 2

**Texte actuel :**
> Cette seconde release a permis de compléter Studium avec les principales fonctions de pilotage opérationnel des candidatures : traitement et validation par l'équipe Admissions, envoi des documents approuvés aux universités et génération indépendante de résumés PDF, communication continue avec les étudiants, et outils de reporting et d'audit pour l'équipe. Combinée à la Release 1, elle prend en charge les principales étapes du cycle de vie d'une candidature, du brouillon jusqu'à l'archivage. Cette couverture ne signifie pas que toutes les exigences du cahier des charges sont satisfaites ni que le parcours complet est validé en conditions réelles. Les adaptations décrites dans ce chapitre et les résultats de recette du chapitre 5 délimitent le périmètre démontré et les vérifications restant à effectuer.

**Remplacer par :**
> Cette seconde release a permis de compléter Studium avec les principales fonctions de pilotage opérationnel des candidatures : traitement et validation par l'équipe Admissions, génération d'un pack PDF assemblé et envoi aux universités, génération indépendante de résumés PDF (mobile et tableau de bord), communication continue avec les étudiants, et outils de reporting et d'audit pour l'équipe. Combinée à la Release 1, elle prend en charge les principales étapes du cycle de vie d'une candidature, du brouillon jusqu'à l'archivage. Cette couverture ne signifie pas que toutes les exigences du cahier des charges sont satisfaites ni que le parcours complet est validé en conditions réelles. Les résultats de recette du chapitre 5 délimitent le périmètre démontré et les vérifications restant à effectuer, en particulier la validation de bout en bout de l'envoi email sous restriction Resend (anomalie A04).

---

## PARTIE B — Tests Deno pour les Edge Functions (jamais mentionnés dans le rapport)

Le rapport actuel ne mentionne aucun test automatisé côté Edge Functions (Deno), alors que
`send-application-email/email_templates.test.ts` (12 tests, préexistant) et le nouveau
`generate-application-pack/pack_utils.test.ts` (9 tests) existent et passent tous. C'est une
omission indépendante du pack PDF, à corriger en même temps puisqu'elle concerne la même zone du
rapport (chapitre 5).

### B1. Chapitre 5, §5.3 — ajouter une sous-section après §5.3.3 "Logique métier pure"

**Nouvelle sous-section 5.3.4 à insérer :**

> #### 5.3.4 Tests unitaires des Edge Functions (Deno)
>
> Les Edge Functions Supabase, exécutées dans le runtime Deno, ne peuvent pas être testées par la
> suite `flutter_test` du mobile. La même stratégie d'extraction de logique pure a été appliquée
> côté serveur : les fonctions sans effet de bord (construction du HTML/texte d'un email,
> substitution de variables, encodage base64, extraction de chemin depuis une URL Supabase Storage,
> classification des documents fusionnables, détection de péremption d'un pack) sont regroupées
> dans des modules dédiés (`email_templates.ts`, `pack_utils.ts`) et testées via le test runner
> intégré de Deno (`deno test`), indépendamment de tout appel réseau vers Supabase ou Resend.
>
> | Module | Fichier de test | Tests |
> |---|---|---|
> | `send-application-email` | `email_templates.test.ts` | 12 |
> | `generate-application-pack` | `pack_utils.test.ts` | 9 |
>
> Ces 21 tests s'exécutent en quelques millisecondes et sont indépendants de la suite mobile de
> 137 tests présentée en §5.9 — les deux suites couvrent des runtimes distincts (Flutter/Dart côté
> mobile, Deno côté Edge Functions) et ne se recoupent pas.

*(Si le gabarit du document numérote les tableaux/figures automatiquement, laisser LaTeX gérer la numérotation — ne pas figer "Tableau 5.x" en dur si `\ref` est utilisé ailleurs dans le document.)*

### B2. Chapitre 5, §5.9 Bilan de Validation — note sur le total de tests

**Juste avant ou après le paragraphe qui introduit le tableau 5.6, ajouter :**

> Ce bilan porte sur la suite automatisée mobile (`flutter test`). La suite Deno des Edge Functions
> (§5.3.4), au nombre de 21 tests, s'exécute séparément (`deno test` dans chaque dossier de
> fonction) et n'est pas incluse dans les 137 tests ni dans la figure 5.7.

### B3. Chapitre 5, Tableau 5.5 — ligne "Pack PDF assemblé (B5/B6)"

Cette ligne existe déjà dans le tableau avec l'ancien contenu (voir citation en A10 pour le
contexte). La remplacer entièrement par :

| Exigence | Réalisation | Preuve | Limite |
|---|---|---|---|
| Pack PDF assemblé (B5/B6) | Implémenté : pack assemblé (couverture, profil, parcours, motivation, documents PDF/image fusionnés) généré par `generate-application-pack` (pdf-lib), persisté dans le bucket `application-packs`, réutilisé tant qu'il n'est pas périmé | 9 tests Deno (`pack_utils.test.ts`) sur la logique pure (classification, péremption, découpage de texte, extraction de chemin) + lecture du code du flux d'envoi | Logique pure testée unitairement ; pas de test d'intégration bout-en-bout téléchargeant un pack réel depuis un vrai bucket Supabase ni de confirmation de réception par une université |

### B4. Chapitre 5, Tableau 5.4 — ajouter une anomalie A05

| ID | Anomalie | Correction apportée | Détectée via |
|---|---|---|---|
| A05 | Le filtre `status = 'approved'` était absent de la branche « pivot » (`application_documents`) de la requête récupérant les documents approuvés dans `send-application-email`, au contraire de sa branche de repli — risque d'inclure un document non approuvé dans l'envoi | Récupération des documents centralisée dans `generate-application-pack`, avec le filtre `approved` appliqué systématiquement dans les deux branches (pivot et repli) ; `send-application-email` ne fait plus sa propre requête, il consomme le résultat du pack | Revue de code lors de l'implémentation du pack PDF assemblé |

### B5. Chapitre 5, Tableau 5.3 — désambiguïser T10 (mobile) du nouveau pack serveur

Le scénario T10 et la figure 5.2 utilisent le terme « pack PDF » pour désigner le **résumé PDF
mobile** (`pdf_generation_integration_test.dart`), ce qui prête désormais à confusion avec le vrai
pack de soumission serveur. Renommer :

- **Légende Figure 5.2**, texte actuel : « Résultat des tests d'intégration (téléversement de documents et génération du pack PDF) » → remplacer par : « Résultat des tests d'intégration (téléversement de documents et génération du résumé PDF mobile) »
- **Tableau 5.3, ligne T10**, colonne « Scénario » actuelle : « Générer pack PDF » → remplacer par « Générer résumé PDF mobile » ; colonne « Résultat attendu » actuelle : « Pack généré » → remplacer par « Résumé généré »

### B6. Chapitre 5, Tableau 5.5 — ligne "Génération PDF côté mobile (A4.3)"

**Texte actuel (colonne Limite) :**
> PDF non persisté ; ne valide ni le résumé du tableau de bord ni le pack de soumission assemblé

**Remplacer par :**
> PDF non persisté ; ne valide ni le résumé du tableau de bord ni le pack de soumission assemblé (voir ligne dédiée « Pack PDF assemblé (B5/B6) » ci-dessus, avec sa propre preuve)

---

## PARTIE C — Livrables documentaires (désormais fournis)

Les 4 documents suivants existent maintenant à la racine du dépôt applicatif, versionnés :
`DOCUMENTATION_TECHNIQUE.md`, `GUIDE_UTILISATEUR_EQUIPE.md`, `PLAN_DE_MAINTENANCE.md`,
`CAHIER_DE_RECETTE.md`. Le rapport affirme actuellement leur absence à plusieurs endroits.

### C1. Chapitre 5, §5.10 — remplacer le paragraphe "Livrables documentaires restant à fournir"

**Texte actuel (paragraphe entier) :**
> **Livrables documentaires restant à fournir** Le paragraphe 14 du cahier des charges prévoit une documentation technique de l'application (installation et configuration), un guide utilisateur pour l'équipe et un plan de maintenance (sauvegardes et monitoring). L'inspection du dépôt applicatif, hors dépendances, n'a identifié aucun de ces trois livrables, ni de README projet, à la racine ou dans les répertoires du mobile, du tableau de bord et de Supabase. Ce constat concerne le dépôt de l'application, distinct des sources LaTeX et des instructions de compilation du présent rapport. Aucune remise séparée de ces documents n'est établie dans les éléments disponibles : ils ne peuvent donc pas être considérés comme livrés. Les user stories US-11.3 (manuel utilisateur) et US-11.4 (documentation technique), ainsi que le plan de maintenance demandé, restent à satisfaire ou à justifier par des livrables remis séparément.

**Remplacer par :**
> **Livrables documentaires** Le paragraphe 14 du cahier des charges prévoit une documentation technique de l'application (installation et configuration), un guide utilisateur pour l'équipe et un plan de maintenance (sauvegardes et monitoring). Ces trois livrables, ainsi qu'un cahier de recette détaillé par module fonctionnel, ont été rédigés et versionnés à la racine du dépôt applicatif : `DOCUMENTATION_TECHNIQUE.md` (architecture, structure des dossiers, variables d'environnement, installation, migrations, tests, déploiement), `GUIDE_UTILISATEUR_EQUIPE.md` (prise en main du tableau de bord par rôle), `PLAN_DE_MAINTENANCE.md` (sauvegardes, migrations, monitoring, rétention, sécurité, checklist périodique) et `CAHIER_DE_RECETTE.md` (92 scénarios de recette répartis en 15 modules, avec statut et notes de vérification). Les user stories US-11.3 et US-11.4 sont ainsi satisfaites.

### C2. Chapitre 5, Tableau 5.5 — ligne "Livrables documentaires (§14)"

**Texte actuel :**
> | Livrables documentaires (§14) | Documentation technique, guide utilisateur et plan de maintenance absents du dépôt applicatif | Recherche dans le dépôt, hors dépendances | Aucune remise séparée établie ; livrables à fournir ou à justifier |

**Remplacer par :**
> | Livrables documentaires (§14) | Documentation technique, guide utilisateur, plan de maintenance et cahier de recette rédigés | Fichiers versionnés à la racine du dépôt applicatif (`DOCUMENTATION_TECHNIQUE.md`, `GUIDE_UTILISATEUR_EQUIPE.md`, `PLAN_DE_MAINTENANCE.md`, `CAHIER_DE_RECETTE.md`) | Contenu relu par l'auteur ; pas de validation par un tiers externe à l'équipe |

### C3. Chapitre 2, §2.5.1 Périmètre du MVP — dernière phrase

**Texte actuel :**
> Les user stories US-11.3 (manuel utilisateur) et US-11.4 (documentation technique), bien que classées MVP, n'ont pas pu être intégrées au plan de sprint sur huit semaines, faute de temps.

**Remplacer par :**
> Les user stories US-11.3 (manuel utilisateur) et US-11.4 (documentation technique), bien que classées MVP, n'ont pas pu être intégrées au plan de sprint sur huit semaines, faute de temps ; elles ont depuis été réalisées en dehors de ce plan initial (voir chapitre 5, §5.10).

### C4. Conclusion générale — paragraphe sur la livraison documentaire

**Texte actuel :**
> La livraison documentaire reste également incomplète : la documentation technique de l'application, le guide utilisateur et le plan de maintenance prévus au cahier des charges sont absents du dépôt applicatif, sans remise séparée établie dans les éléments disponibles (section 5.10). Leur fourniture doit accompagner la poursuite de la recette et la préparation de la reprise du projet.

**Remplacer par :**
> La documentation technique de l'application, le guide utilisateur et le plan de maintenance prévus au cahier des charges ont été rédigés et versionnés à la racine du dépôt applicatif (section 5.10), satisfaisant les user stories US-11.3 et US-11.4.

---

## Résumé des fichiers/tableaux touchés

| Chapitre | Nombre de modifications | Nature |
|---|---|---|
| Chapitre 2 | 3 | Tableau 2.1, §2.5.1 (×2) |
| Chapitre 3 | 2 | Légendes figures 3.1 et 3.2 |
| Chapitre 4 | 6 | §4.2.3, §4.2.4 (×3), §4.2.6 (×2), Tableau 4.3, Conclusion Release 2 |
| Chapitre 5 | 7 | Nouvelle §5.3.4, §5.9, Tableau 5.5 (×2), Tableau 5.4, Tableau 5.3/Fig 5.2 |
| Conclusion générale | 2 | Livraison documentaire, (pack déjà couvert en ch.4) |

Aucune modification des diagrammes UML eux-mêmes (figures 2.3 à 2.6, 3.1, 3.2, 4.12 à 4.15) n'est
nécessaire : ils représentaient déjà le pack assemblé dans leur conception d'origine — seules les
légendes et le texte d'accompagnement, qui signalaient son absence, doivent changer.
