# Dossier de sauvegardes

Ce dossier centralise les sauvegardes locales du projet.

Arborescence recommandee :

- `backup/YYYY-MM-DD/HHMMSS/db/` : dumps PostgreSQL + checksum
- `backup/YYYY-MM-DD/HHMMSS/config/` : archives de configuration compose
- `backup/YYYY-MM-DD/HHMMSS/logs/` : exports de logs critiques (optionnel)

Exemple :

- `backup/2026-05-10/021500/db/workshopsdb_2026-05-10_021500.dump`
- `backup/2026-05-10/021500/db/workshopsdb_2026-05-10_021500.dump.sha256`
- `backup/2026-05-10/021500/config/p8_config_2026-05-10_021500.tar.gz`
