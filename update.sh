#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — update.sh (mise à jour de Ferrox + Rivets installés)
#-----------------------------------------------------------------------------
#  Rôle : comparer la version locale (VERSION) à la version distante, puis
#  mettre à jour le cœur de Ferrox et TOUS les Rivets listés dans
#  state/active-rivets.txt.
#
#  Appel : bash update.sh
#  Conventions : messages [*]/[✓]/[✗], journal des étapes dans install.log.
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#  update.sh se situe À LA RACINE de Ferrox : FEROX_HOME = son répertoire.
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
RIVETS_DIR="$FEROX_HOME/rivets"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
VERSION_FILE="$FEROX_HOME/VERSION"
LOG_FILE="$FEROX_HOME/state/install.log"
TOOLS_DIR="$HOME/ferrox-tools"
PIP_BIN="pip"                        # « pip » ou « pip3 » selon le système
command -v "$PIP_BIN" >/dev/null 2>&1 || PIP_BIN="pip3"

#------------------------------------------------------------------------------
#  Logique partagée avec install.sh : utilitaires d'affichage (_log, msg_info,
#  msg_ok, msg_err) et installation par type de manifeste (install_*_from_rivet,
#  appelées ici avec mode "update").
#------------------------------------------------------------------------------
source "$FEROX_HOME/lib/common.sh"

#------------------------------------------------------------------------------
#  Branche suivie sur le dépôt distant.
#  Le projet public utilise « main » par défaut ; on bascule sur « master »
#  si le dépôt local provient encore de cette ancienne branche par défaut.
#------------------------------------------------------------------------------
REMOTE_BRANCH="main"
git -C "$FEROX_HOME" rev-parse --verify --quiet "refs/remotes/origin/$REMOTE_BRANCH" >/dev/null 2>&1 || REMOTE_BRANCH="master"

#------------------------------------------------------------------------------
#  Section 1 : comparaison de versions
#  Vérifie que Ferrox est bien un dépôt git, synchronise avec le distant,
#  lit la version distante et la compare à VERSION. Si déjà à jour : message
#  clair et arrêt immédiat (exit 0). Sinon : annonce les deux versions et
#  laisse main() continuer la mise à jour.
#------------------------------------------------------------------------------
check_update() {
    # Ré-applique le correctif PATH (~/go/bin) pour les comptes installés
    # avant son introduction (idempotent, ne touche le rc que si besoin).
    ensure_go_path

    if [ ! -d "$FEROX_HOME/.git" ]; then
        msg_err "Ferrox n'a pas été installé via git clone, mise à jour impossible."
        exit 1
    fi

    if ! git -C "$FEROX_HOME" fetch origin "$REMOTE_BRANCH" --quiet; then
        msg_err "Impossible de joindre le dépôt distant (git fetch origin $REMOTE_BRANCH)."
        exit 1
    fi

    version_remote="$(git -C "$FEROX_HOME" show "origin/$REMOTE_BRANCH:VERSION" 2>/dev/null)" || {
        msg_err "Impossible de lire la version distante (origin/$REMOTE_BRANCH:VERSION)."
        exit 1
    }
    version_locale="$(cat "$VERSION_FILE" 2>/dev/null)" || {
        msg_err "Impossible de lire la version locale ($VERSION_FILE)."
        exit 1
    }

    # Nettoyage (CRLF / espaces) pour une comparaison fiable.
    version_remote="$(printf '%s' "$version_remote" | tr -d '[:space:]')"
    version_locale="$(printf '%s' "$version_locale" | tr -d '[:space:]')"

    if [ "$version_remote" = "$version_locale" ]; then
        msg_ok "Ferrox est déjà à jour (v$version_locale)."
        exit 0
    fi

    msg_info "Nouvelle version disponible : v$version_remote (locale actuelle : v$version_locale)."
    return 0
}

#------------------------------------------------------------------------------
#  Section 2 : mise à jour du cœur de Ferrox (scripts bin/, rivets/, ...)
#  Toute modification locale non commitée des fichiers SUIVIS par git est
#  d'abord mise de côté dans un stash nommé, récupérée après le pull
#  (--untracked-files=no : les fichiers non suivis comme state/install.log ne
#  déclenchent pas de stash). Si la restauration entre en conflit, on s'arrête
#  net (exit 1) : on ne continue JAMAIS vers l'update des Rivets avec un état
#  de dépôt incohérent.
#------------------------------------------------------------------------------
update_ferrox_core() {
    local stash_made=0

    if [ -n "$(git -C "$FEROX_HOME" status --porcelain --untracked-files=no)" ]; then
        msg_info "Modifications locales (fichiers suivis) détectées, sauvegarde temporaire (stash) ..."
        if ! git -C "$FEROX_HOME" stash push -m "ferrox-update-autostash"; then
            msg_err "Impossible de créer le stash des modifications locales."
            exit 1
        fi
        stash_made=1
        msg_ok "Modifications locales mises de côté (stash : ferrox-update-autostash)."
    fi

    if ! git -C "$FEROX_HOME" pull origin "$REMOTE_BRANCH"; then
        msg_err "Échec de la mise à jour de Ferrox (git pull)."
        if [ "$stash_made" -eq 1 ]; then
            msg_info "Tes modifications sont conservées dans le stash : git stash list"
        fi
        exit 1
    fi

    if [ "$stash_made" -eq 1 ]; then
        if ! git -C "$FEROX_HOME" stash pop; then
            msg_err "Conflit en restaurant tes modifications locales."
            msg_err "Résous-le à la main avec : git status / git stash list, puis git stash drop une fois réglé."
            exit 1
        fi
        msg_ok "Modifications locales restaurées après la mise à jour."
    fi
}

#------------------------------------------------------------------------------
#  Section 3 : re-ping des outils des Rivets actifs
#  Pour chaque ligne de state/active-rivets.txt : vérifie que le Rivet existe
#  encore (il a pu être supprimé dans une nouvelle version de Ferrox), puis
#  relance les 3 installations en mode "update". Un rivet absent est signalé
#  [✗] et ne bloque PAS les suivants. Les compteurs (succès/échec) alimentent
#  le récapitulatif final de main().
#------------------------------------------------------------------------------
update_installed_rivets() {
    RIVETS_UPDATED_OK=0
    RIVETS_UPDATED_FAIL=0

    if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
        msg_info "Aucun Rivet actif à mettre à jour."
        return 0
    fi

    while IFS= read -r rivet || [ -n "$rivet" ]; do
        rivet="${rivet%$'\r'}"
        case "$rivet" in
            ''|'#'*) continue ;;
        esac

        if [ ! -f "$RIVETS_DIR/$rivet/meta.json" ]; then
            msg_err "Rivet '$rivet' absent après la mise à jour (supprimé de Ferrox ?)."
            RIVETS_UPDATED_FAIL=$((RIVETS_UPDATED_FAIL + 1))
            continue
        fi

        msg_info "Mise à jour du Rivet '$rivet' ..."
        install_go_from_rivet "$RIVETS_DIR/$rivet" update
        install_pip_from_rivet "$RIVETS_DIR/$rivet" update
        install_clone_from_rivet "$RIVETS_DIR/$rivet" update
        install_pkg_from_rivet "$RIVETS_DIR/$rivet" update
        RIVETS_UPDATED_OK=$((RIVETS_UPDATED_OK + 1))
    done < "$STATE_FILE"
}

#------------------------------------------------------------------------------
#  Section 4 : boucle principale
#  check_update sort (exit 0 / exit 1) si déjà à jour ou distant indisponible.
#  VERSION n'est alignée qu'APRÈS le succès complet : si une étape plante avant
#  (pull, conflit de stash), le fichier reste sur l'ancienne version pour que
#  le prochain check_update détecte encore l'écart.
#------------------------------------------------------------------------------
main() {
    check_update
    update_ferrox_core

    update_installed_rivets

    # Alignement de VERSION uniquement après la réussite de tout le reste.
    printf '%s\n' "$version_remote" > "$VERSION_FILE"
    msg_ok "Version de Ferrox alignée : v$version_remote."

    if [ "$RIVETS_UPDATED_FAIL" -eq 0 ]; then
        msg_ok "Mise à jour terminée : $RIVETS_UPDATED_OK Rivet(s) mis à jour."
    else
        msg_err "Mise à jour terminée avec des erreurs : $RIVETS_UPDATED_OK Rivet(s) mis à jour, $RIVETS_UPDATED_FAIL échec(s)."
    fi

    msg_info "Journal détaillé disponible dans : $LOG_FILE"
}

main "$@"