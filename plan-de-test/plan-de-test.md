Plan de tests

## Sommaire
1. Introduction  
2. Tests unitaires  
2.1 Périmètre et objectifs  
2.2 Outils et technologies  
2.3 Critères de réussite  
2.4 Commandes d'exécution et rapports  
2.5 Fréquence d'exécution  
3. Tests d'intégration  
3.1 Périmètre et objectifs  
3.2 Outils et technologies recommandés  
3.3 Scénarios de test prioritaires  
3.4 Critères de réussite  
3.5 Fréquence d'exécution recommandée  
4. Tests de performance  
4.1 Périmètre et objectifs  
4.2 Outils et technologies recommandés  
4.3 Métriques et seuils recommandés  
4.4 Scénarios de charge  
4.5 Fréquence d'exécution recommandée  
5. Tests de sécurité  
5.1 Périmètre et objectifs  
5.2 Outils et technologies recommandés  
5.3 Vulnérabilités à vérifier en priorité  
5.4 Critères de réussite recommandés  
5.5 Fréquence d'exécution recommandée  
6. Fonctionnalités à tester  
7. Fonctionnalités à ne pas tester  
8. Matrice récapitulative des tests  
Notes et références

## 1. Introduction
Ce plan couvre deux applications d'un même système :
- un backend Java (Spring Boot) exposant des API REST pour la gestion des notions et ateliers ;
- un frontend Angular qui consomme des données olympiques et expose l'interface utilisateur.

L'objectif global est de garantir la fiabilité, la qualité et la capacité d'évolution du produit avant mise en production, puis dans la durée.  
À date, les tests implémentés sont principalement des tests unitaires ; les stratégies d'intégration, performance et sécurité sont proposées comme feuille de route de mise en qualité progressive.

## 2. Tests unitaires

### 2.1 Périmètre et objectifs
**Backend Java (implémenté)**  
Tests présents :
- `JavaBasicAppApplicationTests` (test de contexte Spring)
- `WorkshopServiceTest`
- `NotionServiceTest`

Objectif : valider les règles métier des services et la non-régression de base du contexte applicatif.

**Frontend Angular (implémenté)**  
Tests présents :
- `app.component.spec.ts`
- `home.component.spec.ts`
- `not-found.component.spec.ts`
- `olympic.service.spec.ts`

Objectif : valider les composants clés (home / not-found), le composant racine et le service de récupération des données.

**Éléments non ou peu couverts aujourd'hui**
- Backend : contrôleurs REST, mapping API, accès base réel, cas d'erreur HTTP.
- Frontend : navigation complète, gestion fine des erreurs réseau, parcours utilisateur bout en bout.

### 2.2 Outils et technologies
**Backend Java**
- Java 21 (CI)
- Gradle
- Spring Boot 3.2.4
- `spring-boot-starter-test` (JUnit 5, assertions, mocks)

**Frontend Angular**
- Angular 20.x (`@angular/cli` ~20.3.7)
- Karma ~6.4.0
- Jasmine ~4.2.0
- ChromeHeadless (CI)
- `karma-junit-reporter` pour export XML
- `karma-coverage` pour couverture

### 2.3 Critères de réussite
Seuils recommandés (phase initiale réaliste, puis durcissement) :
- Backend :
  - Couverture lignes >= 70%
  - Couverture branches >= 60%
- Frontend :
  - Couverture lignes >= 65%
  - Couverture branches >= 55%

Règles de validation :
- 100% des tests unitaires passants en CI.
- Aucune régression sur les services métiers critiques.
- Tout nouveau code métier doit être accompagné de tests.

Objectif à 2-3 itérations :
- Backend lignes >= 80%, branches >= 70%
- Frontend lignes >= 75%, branches >= 65%

### 2.4 Commandes d'exécution et rapports
**Backend Java**
- Commande :
```bash
cd java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java
./gradlew clean test
```
- Rapports :
  - XML JUnit : `build/test-results/test/*.xml`
  - HTML Gradle : `build/reports/tests/test/index.html`

**Frontend Angular**
- Commande :
```bash
cd angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular
npm ci
npm test
```
- Rapports :
  - Couverture HTML : `coverage/olympic-games-starter/`
  - JUnit XML (karma-junit-reporter) : `reports/` en local, et `test-results/angular` en CI (via `KARMA_JUNIT_OUTPUT_DIR`)

**Dans la CI du projet**
- Agrégation des rapports : `test-results/**/*.xml`
- Publication des résultats de tests dans l'UI GitHub Checks.

### 2.5 Fréquence d'exécution
- À chaque push et pull request (obligatoire).
- En local avant merge sur branches principales.
- Exécution nocturne recommandée pour détecter dérives non fonctionnelles.

Responsabilités :
- Dev : écriture/maintenance des tests unitaires.
- QA : suivi qualité et couverture globale.
- Tech lead : arbitrage des seuils et dette de tests.

## 3. Tests d'intégration

### 3.1 Périmètre et objectifs
Objectif : vérifier l'interaction correcte entre couches, modules et dépendances externes.

**Backend**
- Contrôleurs REST + services + persistance.
- Contrats API (codes HTTP, formats, validations).
- Interaction base PostgreSQL.

**Frontend**
- Intégration routes + composants + service HTTP.
- Gestion erreurs API et états de chargement.

### 3.2 Outils et technologies recommandés
**Backend**
- Spring Boot Test (`@SpringBootTest`, `@AutoConfigureMockMvc`)
- Testcontainers (PostgreSQL) pour environnement réaliste
- RestAssured ou MockMvc pour assertions HTTP

**Frontend**
- Playwright (ou Cypress) pour scénarios UI intégrés
- Mock Service Worker ou API de test dédiée pour jeux de données contrôlés

Environnement recommandé :
- Données de test versionnées.
- Base isolée par exécution.
- Exécution en CI sur branche principale et PR.

### 3.3 Scénarios de test prioritaires
**Backend Java**
1. Création d'un workshop valide, puis lecture par identifiant.
2. Listing workshops et notions avec format attendu.
3. Rejet des payloads invalides (champs manquants/invalides).
4. Gestion des identifiants inexistants (code d'erreur cohérent).

**Frontend Angular**
1. Résolution des données olympiques à l'arrivée sur la route `/`.
2. Affichage correct de la page home avec données valides.
3. Navigation vers route inconnue et affichage NotFound.
4. Gestion d'échec de chargement des données (message/état utilisateur).

Données de test :
- Jeux nominaux (entités valides)
- Jeux limites (champs vides, tailles limites, IDs inexistants)
- Jeux en erreur (réponses HTTP 4xx/5xx simulées)

### 3.4 Critères de réussite
- 100% des scénarios critiques passants.
- Aucune anomalie bloquante ou majeure non corrigée.
- Contrats API stables (pas de rupture non maîtrisée).
- Temps d'exécution acceptable en CI (< 10 min pour la suite intégration initiale).

### 3.5 Fréquence d'exécution recommandée
- À chaque PR sur les branches de livraison.
- Exécution complète quotidienne (nightly) sur `main`.
- Exécution ciblée avant release.

Responsables :
- Dev : implémentation et maintenance.
- QA : validation des scénarios et non-régression.

## 4. Tests de performance

### 4.1 Périmètre et objectifs
Mesurer :
- Performance API backend (latence, débit, stabilité).
- Performance frontend (temps de chargement, interactivité).

Cibles prioritaires :
- API de listing/création notions et workshops.
- Page d'accueil Angular (chargement des données + rendu initial).

### 4.2 Outils et technologies recommandés
- k6 (ou Gatling) pour charge API.
- Lighthouse CI pour métriques web.
- Playwright pour scénarios UI chronométrés.
- Export métriques dans artefacts CI.

### 4.3 Métriques et seuils recommandés

| Métrique | Seuil recommandé | Justification |
|---|---:|---|
| API p95 latence (nominal) | <= 300 ms | Expérience fluide sur endpoints CRUD |
| API taux d'erreur sous charge nominale | < 1% | Stabilité minimale en exploitation |
| API p95 latence (pic) | <= 600 ms | Tolérance en montée en charge |
| Frontend LCP (home) | <= 2.5 s | Bonne pratique web perf |
| Frontend TTI/INP | <= 3 s (TTI) / INP < 200 ms | Interactivité acceptable |

### 4.4 Scénarios de charge
1. **Nominal** : 20 utilisateurs virtuels, 10 min, trafic mixte lecture majoritaire.
2. **Pic** : montée progressive 20 -> 100 utilisateurs, maintien 5 min.
3. **Endurance** : 30 utilisateurs, 60 min, surveillance stabilité/mémoire.
4. **Stress léger** : augmentation jusqu'au point de dégradation contrôlé.

### 4.5 Fréquence d'exécution recommandée
- Campagne perf allégée hebdomadaire.
- Campagne complète avant release majeure.
- Campagne ponctuelle après changement architecture/DB.

Responsables :
- Dev + Ops (analyse conjointe).
- Tech lead valide les plans d'action d'optimisation.

## 5. Tests de sécurité

### 5.1 Périmètre et objectifs
Objectifs :
- Réduire l'exposition aux vulnérabilités applicatives et dépendances.
- Vérifier les configurations de sécurité web/API.
- Détecter tôt les risques exploitables.

### 5.2 Outils et technologies recommandés
- SAST : Semgrep ou SonarQube (règles sécurité).
- SCA dépendances :
  - Java : OWASP Dependency-Check / Snyk
  - Frontend : `npm audit` / Snyk
- DAST : OWASP ZAP sur environnement de test.
- Secret scanning : Gitleaks ou GitHub secret scanning.

Intégration :
- Exécution automatisée en CI (SAST/SCA).
- DAST planifié sur environnement d'intégration.

### 5.3 Vulnérabilités à vérifier en priorité
- Dépendances critiques vulnérables (CVEs).
- Validation insuffisante des entrées API (risques injection).
- Exposition non maîtrisée d'informations techniques (erreurs, stacktrace).
- Mauvaise configuration HTTP (headers sécurité, CORS trop permissif).
- Présence accidentelle de secrets dans le dépôt.

### 5.4 Critères de réussite recommandés
- 0 vulnérabilité critique en production.
- 0 vulnérabilité haute non traitée au-delà du SLA.
- SLA correction :
  - Critique : < 48h
  - Haute : < 7 jours
  - Moyenne : < 30 jours
  - Faible : planification backlog

### 5.5 Fréquence d'exécution recommandée
- SCA/SAST à chaque PR et push.
- DAST hebdomadaire (ou à chaque release candidate).
- Revue sécurité mensuelle (DevSecOps/lead).

Responsables :
- Dev : correction code/dépendances.
- DevSecOps : outillage, alerting, reporting.
- Ops : déploiement correctifs et configuration runtime.

## 6. Fonctionnalités à tester
Fonctionnalités critiques à couvrir en priorité :
1. API création et consultation de workshops.
2. API création et listing de notions.
3. Services backend associés (règles métier et mapping).
4. Chargement des données olympiques au démarrage de la home Angular.
5. Affichage page home et comportement route inconnue (NotFound).
6. Génération/publication des rapports de tests en CI.
7. Build Docker Java/Angular et publication des images (pipeline).

## 7. Fonctionnalités à ne pas tester
Exclusions (phase actuelle) :
1. Tests multi-navigateurs exhaustifs (focus ChromeHeadless en CI) : coût élevé vs valeur immédiate.
2. Tests mobile natifs : hors périmètre (application web).
3. Chaos engineering / résilience avancée infra : prématuré à ce stade.
4. Tests de montée en charge extrême longue durée : non prioritaire avant stabilisation fonctionnelle.
5. Tests d'internationalisation avancée : non pertinent sur le jeu de fonctionnalités actuel.

## 8. Matrice récapitulative des tests

| Type de test | Outil(s) | Fréquence | Responsable (Dev / QA / Ops / DevSecOps) | Critères de réussite | Statut |
|---|---|---|---|---|---|
| Unitaires Backend | Gradle, JUnit 5, Spring Boot Test | PR + push + local pré-merge | Dev | 100% pass, couverture >= 70% lignes | Implémenté |
| Unitaires Frontend | Angular CLI, Karma, Jasmine, ChromeHeadless | PR + push + local pré-merge | Dev | 100% pass, couverture >= 65% lignes | Implémenté |
| Publication rapports tests | GitHub Actions + publish-unit-test-result-action | PR + push | Dev / QA | Rapports XML disponibles et publiés | Implémenté |
| Intégration Backend | SpringBootTest, MockMvc/RestAssured, Testcontainers | PR (ciblé) + nightly + pré-release | Dev / QA | 100% scénarios critiques passants | Recommandé |
| Intégration Frontend | Playwright ou Cypress | Nightly + pré-release | QA / Dev | Parcours critiques passants, 0 blocant | Recommandé |
| Performance API | k6 (ou Gatling) | Hebdo + pré-release | Dev / Ops | p95 <= 300 ms nominal, erreurs < 1% | Recommandé |
| Performance Frontend | Lighthouse CI + Playwright | Hebdo + pré-release | Dev / QA | LCP <= 2.5 s, INP < 200 ms | Recommandé |
| Sécurité SAST/SCA | Semgrep/Sonar, Dependency-Check/Snyk, npm audit | PR + push | Dev / DevSecOps | 0 critique, SLA respectés | Recommandé |
| Sécurité DAST | OWASP ZAP | Hebdo + avant release | DevSecOps / QA | 0 vulnérabilité critique exploitable | Recommandé |

## Notes et références
- Références techniques projet :
  - Backend : `java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java/build.gradle`
  - Frontend : `angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular/package.json`
  - CI : `.github/workflows/ci.yml`
  - Tests frontend : `angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular/karma.conf.js`
- Documentation utile :
  - Spring Testing : https://docs.spring.io/spring-boot/reference/testing/index.html
  - Angular Testing : https://angular.dev/guide/testing
  - k6 : https://k6.io/docs/
  - OWASP ASVS : https://owasp.org/www-project-application-security-verification-standard/

## Glossaire
- **API** : Application Programming Interface, interface d'acces aux services backend.
- **CI** : Continuous Integration, execution automatique des tests a chaque changement.
- **CRUD** : Create, Read, Update, Delete (operations de base sur les donnees).
- **DAST** : Dynamic Application Security Testing, tests de securite en execution.
- **DevSecOps** : approche qui integre securite, developpement et exploitation.
- **E2E** : End-to-End, test d'un parcours complet utilisateur.
- **HTTP 4xx/5xx** : familles de codes d'erreur client (4xx) et serveur (5xx).
- **INP** : Interaction to Next Paint, metrique de reactivite de l'interface.
- **JPA** : Java Persistence API, standard d'acces ORM aux donnees en Java.
- **JUnit** : framework de tests unitaires Java.
- **Karma/Jasmine** : outils de tests unitaires frontend Angular.
- **LCP** : Largest Contentful Paint, metrique de performance de chargement percu.
- **Nightly** : execution planifiee quotidienne (souvent la nuit).
- **p95** : 95e percentile de latence (95% des requetes sont en dessous de cette valeur).
- **PR** : Pull Request, proposition de changement de code revue avant fusion.
- **QA** : Quality Assurance, role de validation qualite.
- **SAST** : Static Application Security Testing, analyse de securite du code source.
- **SCA** : Software Composition Analysis, analyse des dependances et CVE associees.
- **SLA** : Service Level Agreement, delai/cible de traitement defini.
- **Testcontainers** : bibliotheque pour lancer des services de test (ex: PostgreSQL) en conteneurs.
