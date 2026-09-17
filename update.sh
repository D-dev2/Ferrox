#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — update.sh (mise à jour de Ferrox + Rivets installés)
#-----------------------------------------------------------------------------
#  Rôle : comparer la version locale (VERSION) à la version distante, puis
#  mettre à jour le cœur de Ferrox et TOUS les Rivets listés dans
#  state/active-rivets.txt.
#
#  Appel : bash update.sh
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
VERSION_FILE="$FEROX_HOME/VERSION"

#------------------------------------------------------------------------------
#  Utilitaires d'affichage
#------------------------------------------------------------------------------
msg_info() { printf '[*] %s\n' "$*"; }
msg_ok()   { printf '[✓] %s\n' "$*"; }
msg_err()  { printf '[✗] %s\n' "$*" >&2; }

#------------------------------------------------------------------------------
#  Section 1 : comparaison de versions
#  TODO(ferrox) : récupérer la version distante (dépôt git officiel de
#  Ferrox) et la comparer à VERSION. Si déjà à jour → message clair et arrêt.
#------------------------------------------------------------------------------
check_update() { :; }

#------------------------------------------------------------------------------
#  Section 2 : mise à jour du cœur de Ferrox (scripts bin/, rivets/, ...)
#  TODO(ferrox) : git pull des fichiers du projet, SANS écraser state/,
#  config/ ni les manifestes modifiés localement par l'utilisateur.
#------------------------------------------------------------------------------
update_ferrox_core() { :; }

#------------------------------------------------------------------------------
#  Section 3 : re-ping des outils des Rivets actifs
#  TODO(ferrox) : pour chaque ligne de state/active-rivets.txt, relancer
#  l'installation (go/pip/clone) afin de re-épingler les versions à jour.
#------------------------------------------------------------------------------
update_installed_rivets() { :; }

#------------------------------------------------------------------------------
#  Section 4 : boucle principale
#------------------------------------------------------------------------------
main() {
    check_update
    update_ferrox_core
    update_installed_rivets
    msg_ok "Ferrox est à jour."
}

main "$@"