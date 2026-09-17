#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — helper-ia/helper.sh
#-----------------------------------------------------------------------------
#  Statut : PLACEHOLDER — aucune logique métier pour l'instant.
#  Rôle prévu : assister l'utilisateur dans l'usage des outils de Ferrox
#  (générateur de commandes, exemples, rappels de syntaxe par Rivet),
#  en s'appuyant sur la documentation locale docs/tools/*.md.
#=============================================================================

set -e

msg_info() { printf '[*] %s\n' "$*"; }

#------------------------------------------------------------------------------
#  Section 1 : détection des Rivets actifs (état courant)
#  TODO(ferrox) : lire state/active-rivets.txt pour contextualiser l'aide.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 2 : suggestions d'usage par outil
#  TODO(ferrox) : lire les fiches docs/tools/<outil>.md et proposer des
#  commandes d'exemple adaptées au Rivet concerné.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 3 : génération de la réponse (à brancher sur une ressource IA)
#------------------------------------------------------------------------------
main() {
    msg_info "Helper IA : à implémenter."
}

main "$@"