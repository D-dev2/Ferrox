#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — config/motd.sh (message de bienvenue du shell)
#-----------------------------------------------------------------------------
#  Rôle : afficher au démarrage du shell Termux : version de Ferrox,
#  nombre de Rivets actifs et rappel d'usage responsable.
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
STATE_FILE="$FEROX_HOME/state/active-rivets.txt"
VERSION_FILE="$FEROX_HOME/VERSION"

#------------------------------------------------------------------------------
#  Section 1 : bannière de bienvenue
#  TODO(ferrox) : afficher une bannière ASCII « Ferrox ».
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 2 : état courant de l'installation
#  TODO(ferrox) : lire VERSION et compter les lignes de active-rivets.txt,
#  puis afficher « Ferrox <version> — N Rivet(s) actif(s) ».
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 3 : rappel usage responsable
#------------------------------------------------------------------------------
printf '[*] Rappel : pentest uniquement sur des cibles autorisées.\n'