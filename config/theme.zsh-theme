#=============================================================================
#  Ferrox — config/theme.zsh-theme (thème Zsh du prompt)
#-----------------------------------------------------------------------------
#  Rôle : thème de prompt Ferrox — format compact sur 2 lignes.
#
#    Ligne 1 : [HH:MM:SS | git(branche)-] ferrox-NOM user- ~/chemin
#    Ligne 2 : ∆-
#
#  Chaque segment est coloré avec PROMPT_THEME (lu dans config/prompt.conf) :
#    rouge→red, cyan→cyan, vert→green, violet→magenta.
#=============================================================================

setopt PROMPT_SUBST

#------------------------------------------------------------------------------
#  Section 1 : chargement de la configuration de prompt
#  (définit PROMPT_NAME et PROMPT_THEME ; nécessite FEROX_HOME exporté,
#  garanti par install_shell_environment avant la ligne "source .../theme").
#------------------------------------------------------------------------------
source "$FEROX_HOME/config/prompt.conf"

#------------------------------------------------------------------------------
#  Section 2 : palette de couleurs selon le thème choisi
#------------------------------------------------------------------------------
case "$PROMPT_THEME" in
    rouge|red)   THEME_COLOR="%F{red}"     THEME_RESET="%f" ;;
    cyan)        THEME_COLOR="%F{cyan}"    THEME_RESET="%f" ;;
    vert|green)  THEME_COLOR="%F{green}"   THEME_RESET="%f" ;;
    violet|magenta) THEME_COLOR="%F{magenta}" THEME_RESET="%f" ;;
    *)           THEME_COLOR="%F{red}"     THEME_RESET="%f" ;;
esac

#------------------------------------------------------------------------------
#  Section 3 : segment git — appelé à CHAQUE affichage du prompt (PROMPT_SUBST).
#  Retourne "git(branche)-" si on est dans un dépôt git, sinon "git()-".
#------------------------------------------------------------------------------
_ferrox_git_seg() {
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$branch" ]; then
        printf 'git(%s)-' "$branch"
    else
        printf 'git()-'
    fi
}

#------------------------------------------------------------------------------
#  Section 4 : segment user — résultat de `whoami`, appelé à chaque prompt.
#------------------------------------------------------------------------------
_ferrox_user_seg() {
    whoami 2>/dev/null
}

#------------------------------------------------------------------------------
#  Section 5 : construction du PROMPT (2 lignes)
#    Ligne 1 : [HH:MM:SS | git(branche)-] ferrox-NOM user- ~/chemin
#      - HH:MM:SS via %D{%H:%M:%S} (natif zsh)
#      - ~/chemin via %~ (natif zsh)
#    Ligne 2 : ∆- dans la couleur du thème
#
#  Timing (IMPORTANT) : les substitutions dynamiques $(_ferrox_git_seg) et
#  $(_ferrox_user_seg) sont écrites en SIMPLE guillemets → elles restent
#  en texte littéral dans $PROMPT1 et c'est PROMPT_SUBST qui les évalue À
#  CHAQUE affichage du prompt (branch git et whoami à jour en direct).
#  Les variables de thème (${THEME_COLOR}, ${THEME_RESET}) et le nom
#  (${PROMPT_NAME}) restent en DOUBLE guillemets : interpolées une seule
#  fois à l'assignation, elles n'ont pas à être réévaluées.
#------------------------------------------------------------------------------
PROMPT1="[${THEME_COLOR}%D{%H:%M:%S}${THEME_RESET} | ${THEME_COLOR}"'$(_ferrox_git_seg)'"${THEME_RESET}] ${THEME_COLOR}ferrox-${PROMPT_NAME}${THEME_RESET} ${THEME_COLOR}"'$(_ferrox_user_seg)'"-${THEME_RESET} ${THEME_COLOR}%~${THEME_RESET}"

PROMPT2="${THEME_COLOR}∆-${THEME_RESET}"

PROMPT="$PROMPT1"$'\n'"$PROMPT2"