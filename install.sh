#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — install.sh (installation initiale d'un ou plusieurs Rivets)
#-----------------------------------------------------------------------------
#  Rôle : installer TOUS les outils d'un Rivet depuis ses 3 manifestes
#  (go.lock, pip.list, clone.list), puis enregistrer le Rivet dans
#  state/active-rivets.txt.
#
#  Appel : bash install.sh <rivet1> [rivet2 ...]
#          bash install.sh all            → installe tous les Rivets
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#  install.sh se situe À LA RACINE de Ferrox : FEROX_HOME = son répertoire.
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
RIVETS_DIR="$FEROX_HOME/rivets"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
TOOLS_DIR="$HOME/ferrox-tools"
PIP_BIN="pip"                        # « pip » ou « pip3 » selon le système

#------------------------------------------------------------------------------
#  Utilitaires d'affichage
#------------------------------------------------------------------------------
msg_info() { printf '[*] %s\n' "$*"; }
msg_ok()   { printf '[✓] %s\n' "$*"; }
msg_err()  { printf '[✗] %s\n' "$*" >&2; }

#------------------------------------------------------------------------------
#  Section 1 : vérification des prérequis Termux
#  Vérifie la présence de go, python, pip et git. Si l'un manque, affiche un
#  [✗] explicite (le paquet à installer) puis quitte — jamais de suite sans
#  prérequis. Crée aussi state/ s'il n'existe pas encore.
#------------------------------------------------------------------------------
check_prereqs() {
    # Sur un dépôt cloné frais, state/ peut ne pas exister :
    # on le crée pour que l'écriture dans active-rivets.txt ne plante pas.
    mkdir -p "$(dirname "$STATE_FILE")"

    if ! command -v go >/dev/null 2>&1; then
        msg_err "go est introuvable. Installe-le avec : pkg install golang"
        exit 1
    fi
    if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
        msg_err "python est introuvable. Installe-le avec : pkg install python"
        exit 1
    fi
    if command -v pip >/dev/null 2>&1; then
        PIP_BIN="pip"
    elif command -v pip3 >/dev/null 2>&1; then
        PIP_BIN="pip3"
    else
        msg_err "pip est introuvable. Installe-le avec : pkg install python"
        exit 1
    fi
    if ! command -v git >/dev/null 2>&1; then
        msg_err "git est introuvable. Installe-le avec : pkg install git"
        exit 1
    fi
    msg_ok "Prérequis vérifiés : go, python, pip ($PIP_BIN), git."
}

#------------------------------------------------------------------------------
#  Section 2 : installation par type de manifeste
#  Chaque fonction attend $1 = dossier du Rivet (ex: rivets/web).
#  Toutes les lignes vides et commentaires (#) sont ignorés à la lecture.
#  Un outil qui échoue ne bloque PAS les suivants : il est signalé et on
#  continue (le [✓] final récapitule le nombre de réussites sur le total).
#------------------------------------------------------------------------------

#  2.1 — Outils Go (go.lock) : ligne « nom=chemin_module@version »
#       Règle : JAMAIS "@latest", la version est TOUJOURS épinglée.
#       Installation : go install -v "$chemin@$version"
install_go_from_rivet() {
    local rivet_dir="$1"
    local go_lock="$rivet_dir/go.lock"
    local line name path_at_version ok=0 total=0

    [ -f "$go_lock" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        # Split sur le premier « = » : nom d'un côté, chemin@version de l'autre.
        name="${line%%=*}"
        path_at_version="${line#*=}"
        [ -z "$path_at_version" ] && continue

        total=$((total + 1))
        msg_info "Installation de '$name' (Go) ..."
        if ! go install -v "$path_at_version"; then
            msg_err "Échec de l'installation de '$name' (voir l'erreur ci-dessus)."
            continue
        fi
        ok=$((ok + 1))
        msg_ok "'$name' installé."
    done < "$go_lock"

    msg_ok "$ok outil(s) Go installé(s) sur $total."
}

#  2.2 — Outils pip (pip.list) : ligne « nom=paquet_pypi » ou « nom=paquet==version »
#       Si la ligne contient déjà « == », la version épinglée est passée telle
#       quelle à pip ; sinon pip installe la dernière version du paquet.
install_pip_from_rivet() {
    local rivet_dir="$1"
    local pip_list="$rivet_dir/pip.list"
    local line name pkg ok=0 total=0

    [ -f "$pip_list" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        # Split sur le premier « = » : nom d'un côté, paquet de l'autre.
        name="${line%%=*}"
        pkg="${line#*=}"
        [ -z "$pkg" ] && continue

        total=$((total + 1))
        if [[ "$pkg" == *==* ]]; then
            msg_info "Installation de '$name' ($pkg) ..."
        else
            msg_info "Installation de '$name' (paquet : $pkg, dernière version) ..."
        fi
        if ! "$PIP_BIN" install "$pkg"; then
            msg_err "Échec de l'installation de '$name' (voir l'erreur ci-dessus)."
            continue
        fi
        ok=$((ok + 1))
        msg_ok "'$name' installé."
    done < "$pip_list"

    msg_ok "$ok outil(s) pip installé(s) sur $total."
}

#  2.3 — Outils clonés (clone.list) : ligne « nom=url_git »
#       Clone dédié dans $TOOLS_DIR (idempotent : si le dossier existe déjà,
#       on passe), puis installation des dépendances si requirements.txt.
install_clone_from_rivet() {
    local rivet_dir="$1"
    local clone_list="$rivet_dir/clone.list"
    local line name url ok=0 total=0

    [ -f "$clone_list" ] || return 0
    mkdir -p "$TOOLS_DIR"

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        # Split sur le premier « = » : nom d'un côté, URL git de l'autre.
        name="${line%%=*}"
        url="${line#*=}"
        [ -z "$url" ] && continue

        total=$((total + 1))
        if [ -d "$TOOLS_DIR/$name" ]; then
            msg_info "'$name' : déjà cloné, on passe."
            continue
        fi

        msg_info "Clone de '$name' ..."
        if ! git clone --depth 1 "$url" "$TOOLS_DIR/$name"; then
            msg_err "Échec du clone de '$name' (voir l'erreur ci-dessus)."
            continue
        fi
        ok=$((ok + 1))
        msg_ok "'$name' cloné."

        # Dépendances Python éventuelles du repo cloné.
        if [ -f "$TOOLS_DIR/$name/requirements.txt" ]; then
            msg_info "Installation des dépendances de '$name' ..."
            if ! "$PIP_BIN" install -r "$TOOLS_DIR/$name/requirements.txt"; then
                msg_err "Échec des dépendances de '$name' (voir l'erreur ci-dessus)."
            fi
        fi
    done < "$clone_list"

    msg_ok "$ok outil(s) cloné(s) sur $total."
}

#------------------------------------------------------------------------------
#  Section 3 : installation complète d'un Rivet
#  Vérifie l'existence de rivets/$rivet/meta.json, appelle les 3 fonctions
#  ci-dessus, puis ajoute $rivet à state/active-rivets.txt (sans doublon —
#  ce fichier est l'unique source de vérité). Un Rivet inconnu renvoie 1
#  (pas exit) pour ne pas couper les autres Rivets demandés en ligne de
#  commande.
#------------------------------------------------------------------------------
install_rivet() {
    local rivet="$1"

    if [ ! -f "$RIVETS_DIR/$rivet/meta.json" ]; then
        msg_err "Rivet '$rivet' introuvable dans $RIVETS_DIR."
        return 1
    fi

    msg_info "Installation du Rivet '$rivet' ..."
    install_go_from_rivet "$RIVETS_DIR/$rivet"
    install_pip_from_rivet "$RIVETS_DIR/$rivet"
    install_clone_from_rivet "$RIVETS_DIR/$rivet"

    # Idempotent : on n'ajoute la ligne que si elle n'y est pas déjà.
    if ! grep -qxF "$rivet" "$STATE_FILE"; then
        printf '%s\n' "$rivet" >> "$STATE_FILE"
        msg_ok "Rivet '$rivet' ajouté à l'état actif."
    else
        msg_info "Rivet '$rivet' déjà actif dans l'état, rien à ajouter."
    fi

    msg_ok "Rivet '$rivet' installé."
}

#------------------------------------------------------------------------------
#  Section 4 : boucle principale + gestion du pseudo-Rivet "all"
#  « all » est remplacé par la liste des Rivets disponibles (sous-dossiers
#  de rivets/ contenant un meta.json) avant la boucle for, de sorte que la
#  boucle traite chaque Rivet individuellement.
#------------------------------------------------------------------------------
main() {
    if [ $# -eq 0 ]; then
        msg_err "Usage : bash install.sh <rivet1> [rivet2 ...]"
        exit 1
    fi

    check_prereqs

    if [ "$1" = "all" ]; then
        local rivets_list=()
        for meta in "$RIVETS_DIR"/*/meta.json; do
            [ -f "$meta" ] || continue
            rivets_list+=("$(basename "$(dirname "$meta")")")
        done
        if [ ${#rivets_list[@]} -eq 0 ]; then
            msg_err "Aucun Rivet disponible dans $RIVETS_DIR."
            exit 1
        fi
        msg_info "Installation de tous les Rivets : ${rivets_list[*]}"
        set -- "${rivets_list[@]}"
    fi

    for rivet in "$@"; do
        # Un Rivet inconnu renvoie 1 : on le signale et on continue les autres.
        install_rivet "$rivet" || true
    done
    msg_ok "Installation terminée."
}

main "$@"