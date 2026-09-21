#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — config/motd.sh (message de bienvenue du shell)
#-----------------------------------------------------------------------------
#  Rôle : afficher au démarrage du shell Termux : version de Ferrox,
#  nombre de Rivets actifs, outils masqués par un alias, et rappel d'usage
#  responsable.
#  NB : pour détecter un alias proprement, motd.sh doit être SOURCÉ depuis
#  ~/.zshrc (un alias n'existe que dans le shell qui l'a défini) ; exécuté
#  tel quel, il vérifie juste qu'aucun process enfant n'a d'alias.
#=============================================================================

set -e

#------------------------------------------------------------------------------
#  Constantes et chemins
#  ${BASH_SOURCE[0]:-$0} : fonctionne aussi bien exécuté que sourcé, en bash
#  comme en zsh (où $0 = chemin du fichier sourcé).
#------------------------------------------------------------------------------
FEROX_HOME="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")/.." && pwd)"
RIVETS_DIR="$FEROX_HOME/rivets"
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
#  Section 3 : détection des alias qui masquent les outils Ferrox
#  Un alias shell (ex : `gau` du plugin git d'Oh-My-Zsh) passe AVANT les
#  binaires du PATH et « vole » donc la commande. Pour chaque outil listé dans
#  les manifestes des Rivets actifs, on signalé ceux que `type` rapporte comme
#  alias plutôt que comme vrai binaire. Non bloquant : simple avertissement.
#------------------------------------------------------------------------------
check_masked_aliases() {
    local rivet line tool file mf

    [ -f "$STATE_FILE" ] || return 0

    while IFS= read -r rivet || [ -n "$rivet" ]; do
        rivet="${rivet%$'\r'}"
        case "$rivet" in
            ''|'#'*) continue ;;
        esac
        [ -f "$RIVETS_DIR/$rivet/meta.json" ] || continue
        for mf in go.lock pip.list clone.list pkg.list; do
            file="$RIVETS_DIR/$rivet/$mf"
            [ -f "$file" ] || continue
            while IFS= read -r line || [ -n "$line" ]; do
                line="${line%$'\r'}"
                case "$line" in
                    ''|'#'*) continue ;;
                esac
                tool="${line%%=*}"
                if type "$tool" 2>/dev/null | grep -Eqi 'is (an alias for|aliased to)'; then
                    printf "⚠ '%s' est masqué par un alias shell — utilise 'command %s' ou corrige ton .zshrc\n" "$tool" "$tool"
                fi
            done < "$file"
        done
    done < "$STATE_FILE"
}

check_masked_aliases

#------------------------------------------------------------------------------
#  Section 4 : rappel usage responsable
#------------------------------------------------------------------------------
printf '[*] Rappel : pentest uniquement sur des cibles autorisées.\n'