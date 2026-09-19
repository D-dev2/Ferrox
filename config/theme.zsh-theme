#=============================================================================
#  Ferrox — config/theme.zsh-theme (thème Zsh du prompt)
#-----------------------------------------------------------------------------
#  Rôle : thème de prompt Ferrox — construit à partir de config/prompt.conf.
#  Affiche : [date] ferrox-NAME /chemin # avec couleurs thématiques.
#=============================================================================

#------------------------------------------------------------------------------
#  Section 1 : chargement de la configuration de prompt
#------------------------------------------------------------------------------
source "$FEROX_HOME/config/prompt.conf"

#------------------------------------------------------------------------------
#  Section 2 : palette de couleurs selon le thème choisi
#------------------------------------------------------------------------------
case "$PROMPT_THEME" in
    rouge|red)   THEME_COLOR="%F{red}"   THEME_RESET="%f" ;;
    cyan)        THEME_COLOR="%F{cyan}"  THEME_RESET="%f" ;;
    vert|green)  THEME_COLOR="%F{green}" THEME_RESET="%f" ;;
    violet|magenta) THEME_COLOR="%F{magenta}" THEME_RESET="%f" ;;
    *)           THEME_COLOR="%F{red}"   THEME_RESET="%f" ;;
esac

#------------------------------------------------------------------------------
#  Section 3 : segment de chemin dynamique
#    • Si l'utilisateur est dans $HOME/workspace ou un sous-dossier → "/workspace"
#    • Sinon → chemin normal avec ~ pour $HOME (%~ behaviour)
#------------------------------------------------------------------------------
_ferrox_pwd_seg() {
    if [[ "$PWD" == "${HOME}/workspace"* ]]; then
        echo "/workspace"
    else
        echo "${PWD/#$HOME/~}"
    fi
}

#------------------------------------------------------------------------------
#  Section 4 : construction du PROMPT zsh
#  Format exact : [Sep 19, 2026 - 06:36:52 (GMT)] ferrox-Arkane /workspace #
#  - Date dynamique via %D{FORMAT} (natif zsh, pas de date en sous-shell)
#  - Segment "ferrox-$PROMPT_NAME" avec couleur du thème
#  - Segment chemin dynamique (voir _ferrox_pwd_seg)
#  - "#" final neutre, pas de couleur spécifique
#  - Chaque segment (date, nom, chemin) possède sa propre couleur issue du thème
#------------------------------------------------------------------------------
PROMPT="[${THEME_COLOR}%D{%b %d, %Y - %H:%M:%S (%Z)}${THEME_RESET}] ${THEME_COLOR}ferrox-${THEME_RESET}${PROMPT_NAME} ${THEME_COLOR}$(_ferrox_pwd_seg)${THEME_RESET} %#"