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

#------------------------------------------------------------------------------
#  Logique partagée avec update.sh : utilitaires d'affichage (_log, msg_info,
#  msg_ok, msg_err) et installation par type de manifeste (install_*_from_rivet,
#  mode par défaut "install").
#------------------------------------------------------------------------------
source "$FEROX_HOME/lib/common.sh"

RIVETS_DIR="$FEROX_HOME/rivets"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
LOG_FILE="$FEROX_HOME/state/install.log"
TOOLS_DIR="$HOME/ferrox-tools"
PIP_BIN="pip"                        # « pip » ou « pip3 » selon le système

#------------------------------------------------------------------------------
#  Section 1 : vérification des prérequis Termux
#  Vérifie la présence de go, python, pip et git. Si l'un manque, affiche un
#  [✗] explicite (le paquet à installer) puis quitte — jamais de suite sans
#  prérequis. Crée aussi state/ (dossier ET fichiers) s'ils n'existent pas.
#------------------------------------------------------------------------------
check_prereqs() {
    # Sur un dépôt cloné frais, state/ peut ne pas exister : on crée le
    # dossier ET le fichier active-rivets.txt, sinon le premier `grep` dans
    # install_rivet affiche une erreur parasite ("No such file or directory")
    # même si le comportement final reste correct.
    mkdir -p "$(dirname "$STATE_FILE")"
    touch "$STATE_FILE"
    touch "$LOG_FILE"

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
#  Section 2 : installation par type de manifeste (Go / pip / clone)
#  Implémentée dans lib/common.sh (install_go_from_rivet, install_pip_from_rivet,
#  install_clone_from_rivet) — appelée ici avec mode "install" par défaut.
#------------------------------------------------------------------------------

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
#  boucle traite chaque Rivet individuellement. Un compteur global permet
#  d'afficher un résumé fidèle même en cas d'échecs mélangés.
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

    local rivets_ok=0 rivets_fail=0
    for rivet in "$@"; do
        # Un Rivet inconnu renvoie 1 : on le signale et on continue les autres.
        if install_rivet "$rivet"; then
            rivets_ok=$((rivets_ok + 1))
        else
            rivets_fail=$((rivets_fail + 1))
        fi
    done

    # Résumé global fidèle : distingue succès et échecs plutôt qu'un
    # "Installation terminée" ambigu qui masquerait un Rivet introuvable.
    if [ "$rivets_fail" -eq 0 ]; then
        msg_ok "Installation terminée : $rivets_ok Rivet(s) installé(s)."
    else
        msg_err "Installation terminée avec des erreurs : $rivets_ok Rivet(s) installé(s), $rivets_fail échec(s)."
    fi

    msg_info "Journal détaillé disponible dans : $LOG_FILE"
}

main "$@"