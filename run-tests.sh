#!/usr/bin/env bash
# Lance les tests (README Java + Angular) et regroupe les rapports JUnit XML dans test-results/
# Codes de sortie : 0 = succès, 1 = échec des tests, 2 = dépendances / environnement manquants
set -euo pipefail

readonly EXIT_SUCCESS=0
readonly EXIT_TESTS_FAILED=1
readonly EXIT_MISSING_DEPS=2

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/test-results"
JAVA_DIR="$ROOT/java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java"
ANGULAR_DIR="$ROOT/angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular"

die_deps() {
  echo "Erreur (code $EXIT_MISSING_DEPS) — prérequis manquant : $*" >&2
  exit "$EXIT_MISSING_DEPS"
}

# --- Vérification des dépendances et de l'environnement ---
[[ -f "$JAVA_DIR/build.gradle" ]] || die_deps "build.gradle introuvable sous $JAVA_DIR"
[[ -x "$JAVA_DIR/gradlew" ]] || die_deps "gradlew absent ou non exécutable dans $JAVA_DIR"
[[ -f "$JAVA_DIR/gradle/wrapper/gradle-wrapper.jar" ]] || die_deps "gradle/wrapper/gradle-wrapper.jar manquant"

command -v java >/dev/null 2>&1 || die_deps "Java (commande 'java') absent du PATH — installez un JDK (README Java : JDK 21)."
java_major=$(java -version 2>&1 | sed -n 's/.* version "\([0-9][0-9]*\).*/\1/p' | head -1)
if [[ -z "$java_major" ]] || ! [[ "$java_major" =~ ^[0-9]+$ ]]; then
  die_deps "Impossible de déterminer la version de Java."
fi
if ((java_major < 21)); then
  die_deps "JDK 21 ou supérieur requis (README Java). Version majeure détectée : $java_major"
fi

command -v node >/dev/null 2>&1 || die_deps "Node.js ('node') absent du PATH."
command -v npm >/dev/null 2>&1 || die_deps "npm absent du PATH."

[[ -f "$ANGULAR_DIR/package.json" ]] || die_deps "package.json introuvable dans $ANGULAR_DIR"
[[ -f "$ANGULAR_DIR/package-lock.json" ]] || die_deps "package-lock.json manquant — exécutez npm install dans le projet Angular pour le générer."
[[ -d "$ANGULAR_DIR/node_modules" ]] || die_deps "node_modules absent — installez les dépendances : (cd \"$ANGULAR_DIR\" && npm ci)"

# --- Nettoyage des artefacts de tests / rapports précédents ---
echo "==> Nettoyage des artefacts de tests précédents"
rm -rf "$OUT"
mkdir -p "$OUT/java" "$OUT/angular"
# Rapports Karma par défaut (hors KARMA_JUNIT_OUTPUT_DIR) pour éviter mélange avec d'anciens runs
rm -rf "$ANGULAR_DIR/reports"
# build/ Java : 'clean' dans gradlew le recrée ; on supprime les résultats de test restants si clean n'avait pas été lancé
rm -rf "$JAVA_DIR/build/test-results" "$JAVA_DIR/build/reports/tests"

copy_java_junit_xml() {
  local src="$JAVA_DIR/build/test-results/test"
  if [[ -d "$src" ]]; then
    shopt -s nullglob
    local files=("$src"/*.xml)
    shopt -u nullglob
    if ((${#files[@]})); then
      cp "${files[@]}" "$OUT/java/"
      echo "Rapports JUnit Java copiés vers $OUT/java/ (${#files[@]} fichier(s))"
    else
      echo "Avertissement : aucun XML JUnit dans $src" >&2
    fi
  else
    echo "Avertissement : répertoire absent $src" >&2
  fi
}

echo "==> Tests Java (./gradlew clean test)"
set +e
(cd "$JAVA_DIR" && ./gradlew clean test)
JAVA_EXIT=$?
set -e
copy_java_junit_xml

echo "==> Tests Angular (npm test → Karma junit)"
export KARMA_JUNIT_OUTPUT_DIR="$OUT/angular"
mkdir -p "$KARMA_JUNIT_OUTPUT_DIR"
set +e
(cd "$ANGULAR_DIR" && npm test)
ANG_EXIT=$?
set -e

shopt -s nullglob
ANG_XML=("$OUT/angular"/*.xml)
shopt -u nullglob
if ((${#ANG_XML[@]} == 0)); then
  echo "Avertissement : aucun XML JUnit Karma dans $OUT/angular" >&2
else
  echo "Rapports JUnit Angular : ${#ANG_XML[@]} fichier(s) dans $OUT/angular/"
fi

# --- Codes de sortie : 1 si au moins une suite de tests a échoué ---
if ((JAVA_EXIT != 0 && ANG_EXIT != 0)); then
  echo "Échec des tests Java et Angular (Java exit=$JAVA_EXIT, Angular exit=$ANG_EXIT). Rapports : $OUT/" >&2
  exit "$EXIT_TESTS_FAILED"
fi
if ((JAVA_EXIT != 0)); then
  echo "Échec des tests Java (exit=$JAVA_EXIT). Rapports : $OUT/" >&2
  exit "$EXIT_TESTS_FAILED"
fi
if ((ANG_EXIT != 0)); then
  echo "Échec des tests Angular (exit=$ANG_EXIT). Rapports : $OUT/" >&2
  exit "$EXIT_TESTS_FAILED"
fi

echo "==> Tous les tests se sont terminés avec succès (code $EXIT_SUCCESS). Rapports JUnit XML : $OUT/java/ et $OUT/angular/"
exit "$EXIT_SUCCESS"
