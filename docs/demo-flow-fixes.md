# Correctifs du parcours démo (branche `develop`)

_Session des 06–08/11/2026. Contexte global : `infra-control/docs/demo-flow-fixes.md`._

## Résumé

| Branche (mergée en `--no-ff` dans `develop`) | Contenu |
|---|---|
| `fix/demo-stack` | Contexte de build `ups_manager`, priorités du seed, script de reset rapide |
| `feature/demo-prometheus` | Prometheus dans la stack démo |
| `fix/demo-vcenter-port` | Seed et docs alignés sur le port 443 du vCenter |

`origin/develop` (PR #1 `fix/demo-vcenter-connectivity`) a aussi été mergé : il avait déjà ajouté `additional_contexts` et le mapping `8989:443` de vcsim.

## Changements

### Contexte de build du backend
`additional_contexts: ups_manager: ../ups_manager` sur le service `backend`, pour que l'image embarque les scripts Python (même changement que la PR #1, fusionné sans doublon).

### Seed `demo-seed.json`
- ESXi en priorités 2, 3, 4. Le vCenter n'a pas de priorité : le backend lui attribue désormais le premier rang libre **après** les ESXi (5 ici). Avant, il prenait 1 par défaut et entrait en conflit avec esxi-host-01.
- Le vCenter n'est volontairement rattaché à aucun onduleur (le wizard affiche un simple avertissement).
- `adminUrl` du vCenter : `https://vcsim` (port 443 par défaut). Un vCenter sur un autre port se déclare dans l'URL admin, par exemple `https://vcenter:8443`.

### Prometheus
- Service `prometheus` (`prom/prometheus:v2.53.5`, rétention 7 jours, volume `demo_prometheus_data`), exposé sur http://localhost:9090.
- `prometheus.demo.yml` scrape `backend:3000/metrics` (séries `upstra_*`) toutes les 15 s.
- `PROMETHEUS_URL=http://prometheus:9090` ajouté à `.env.demo` et `.env.demo.example`.
- Alimente les graphes d'historique et le composant « Prometheus » du widget santé.

### `reset-db-fast.sh`
Vide le schéma PostgreSQL et Redis puis redémarre le backend (migrations auto), sans reconstruire les images. Attention : le flag `setup_completed` vit dans le navigateur ; depuis cette session, le front revérifie auprès du backend et rouvre bien le wizard.

### Docs
README et CLAUDE.md : Prometheus dans les tableaux de services, port vCenter (443 interne, 8989 côté hôte, surchargeable via l'URL admin).

## Vérifié

`down -v` puis `up` : 10 conteneurs démarrés, cibles Prometheus `up`, `/health` vert, parcours wizard complet avec le seed, télémétrie vCenter fraîche sur le port 443.

## Non commité

`.env.demo` contient, en local uniquement, les identifiants `DEMO_ADMIN_*` du compte admin de test créé pour le parcours UI.
