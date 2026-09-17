#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — uninstall.sh (désinstallation propre)
#-----------------------------------------------------------------------------
#  Rôle : désinstaller TOUS les outils de TOUS les Rivets confondus, vider
#  l'état (state/), le répertoire $HOME/ferrox-tools, retirer la config
#  shell injectée, puis supprimer le dossier Ferrox lui-même.
#
#  Appel : bash uninstall.sh
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
TOOLS_DIR="$HOME/ferrox-tools"

#------------------------------------------------------------------------------
#  Utilitaires d'affichage
#------------------------------------------------------------------------------
msg_info() { printf '[*] %s\n' "$*"; }
msg_ok()   { printf '[✓] %s\n' "$*"; }
msg_err()  { printf '[✗] %s\n' "$*" >&2; }

#------------------------------------------------------------------------------
#  Section 1 : désinstallation de chaque Rivet actif
#  TODO(ferrox) : parcourir state/active-rivets.txt et retirer les outils
#  (binaires Go, paquets pip, dossiers clonés dans $HOME/ferrox-tools).
#------------------------------------------------------------------------------
remove_all_rivets() { :; }

#------------------------------------------------------------------------------
#  Section 2 : nettoyage des données Ferrox
#  TODO(ferrox) : vider state/active-rivets.txt puis supprimer $TOOLS_DIR.
#------------------------------------------------------------------------------
cleanup_data() { :; }

#------------------------------------------------------------------------------
#  Section 3 : retrait de la config shell injectée
#  TODO(ferrox) : retirer l'appel à config/.zshrc / motd.sh et les alias
#  ajoutés par Ferrox dans ~/.zshrc de l'utilisateur.
#------------------------------------------------------------------------------
remove_shell_config() { :; }

#------------------------------------------------------------------------------
#  Section 4 : suppression des fichiers Ferrox eux-mêmes
#  TODO(ferrox) : demander une confirmation avant de rm -rf "$FEROX_HOME".
#------------------------------------------------------------------------------
remove_ferrox_dir() { :; }

#------------------------------------------------------------------------------
#  Section 5 : confirmation + boucle principale
#  TODO(ferrox) : afficher un avertissement clair et demander oui/non avant
#  toute suppression définitive.
#------------------------------------------------------------------------------
main() {
    remove_all_rivets
    cleanup_data
    remove_shell_config
    remove_ferrox_dir
    msg_ok "Ferrox a été désinstallé."
}

main "$@"