g
**Ferrox** est un outil de pentest léger pour **Android/Termux** : natif, sans root, sans PRoot, sans Docker.

## Concept : les Rivets

Un **Rivet** est un profil thématique (ex. `web`, `api`, `phishing`) qui regroupe un ensemble d'outils. L'utilisateur choisit un ou plusieurs Rivets à installer ; chaque Rivet possède **son propre manifeste d'outils**.

## Arborescence

```
ferrox/
├── bin/ferrox                  # CLI principal (point d'entrée unique)
├── install.sh                  # installation initiale d'un Rivet
├── update.sh                   # mise à jour de Ferrox + outils installés
├── uninstall.sh                # désinstallation propre
├── VERSION                     # version courante (0.1.0)
├── rivets/
│   ├── web/        meta.json, go.lock, pip.list, clone.list
│   ├── api/        meta.json, go.lock, pip.list, clone.list
│   └── phishing/   meta.json, go.lock, pip.list, clone.list (vides pour l'instant)
├── state/
│   └── active-rivets.txt       # UNIQUE source de vérité des Rivets installés
├── config/                     # .zshrc, theme.zsh-theme, motd.sh
├── docs/tools/                 # une fiche .md par outil (nom, usage, exemple)
├── helper-ia/helper.sh         # placeholder (pas encore de logique)
└── README.md
```

## Format des manifestes (par Rivet)

| Fichier      | Type d'outil  | Format de ligne                    | Installation                            |
|--------------|---------------|-------------------------------------|-----------------------------------------|
| `go.lock`    | Outils Go     | `nom=chemin_module@version`         | `go install -v chemin@version`           |
| `pip.list`   | Paquets pip   | `nom=paquet[==version]`             | `pip install paquet[==version]`        |
| `clone.list` | Outils git    | `nom=url_git`                       | `git clone --depth 1 url ~/ferrox-tools/nom` |

Règle d'or : **jamais `@latest`** — les versions sont toujours épinglées dans les manifestes.

## Commandes du CLI

```
ferrox rivet list                     liste des Rivets (actif/inactif)
ferrox rivet install <nom>            installe un Rivet
ferrox rivet remove <nom>             désinstalle un Rivet
ferrox tool list [--rivet <nom>]      outils d'un Rivet (ou de tous les actifs)
ferrox tool add <nom> --rivet <nom>   ajoute un outil à un Rivet
ferrox tool remove <nom> --rivet <nom> retire un outil d'un Rivet
ferrox update                         mise à jour de Ferrox + Rivets actifs
ferrox uninstall                      désinstallation complète
```

## Syntaxe des messages

Tous les scripts affichent des messages clairs pour un débutant :

- `[*]` étape en cours
- `[✓]` succès
- `[✗]` erreur

## État actuel

Le dépôt contient le **squelette** du projet : les scripts sont structurés et commentés section par section, mais leur logique métier détaillée reste à implémenter (marquée `TODO(ferrox)`).# Ferrox
