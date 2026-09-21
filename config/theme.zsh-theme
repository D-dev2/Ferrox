#=============================================================================
#  Ferrox — config/theme.zsh-theme (thème Zsh du prompt)
#-----------------------------------------------------------------------------
#  Rôle : thème de prompt Ferrox — format « carte d'identité avec cadre ».
#
#    Ligne 1 : ╭─ HH:MM:SS ─ git(branche) ─ ferrox-NOM
#    Ligne 2 : ╰─ ~/chemin ➜
#
#  3 couleurs par thème (une par segment, jamais une seule répétée) :
#    rouge : C_TIME=160 (rouge)       C_GIT=94 (marron)   C_NAME=223 (crème)
#    cyan  : C_TIME=44  (cyan)        C_GIT=17  (bleu marine) C_NAME=189 (lavande)
#    vert  : C_TIME=61  (indigo)      C_GIT=34  (vert)    C_NAME=230 (crème)
#    violet: C_TIME=92  (violet)      C_GIT=132 (mauve)   C_NAME=183 (lavande)
#  Le cadre lui-même (╭─ ╰─ ➜) reprend C_TIME (couleur dominante du thème).
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
#  Chaque segment reçoit une couleur distincte (jamais une seule répétée).
#------------------------------------------------------------------------------
case "$PROMPT_THEME" in
    cyan)
        C_TIME="%F{44}"   C_GIT="%F{17}"   C_NAME="%F{189}" ;;
    vert|green)
        C_TIME="%F{61}"   C_GIT="%F{34}"   C_NAME="%F{230}" ;;
    violet|magenta)
        C_TIME="%F{92}"   C_GIT="%F{132}"  C_NAME="%F{183}" ;;
    rouge|red|*)
        C_TIME="%F{160}"  C_GIT="%F{94}"   C_NAME="%F{223}" ;;
esac
C_RESET="%f"

#------------------------------------------------------------------------------
#  Section 3 : segment git — appelé à CHAQUE affichage du prompt (PROMPT_SUBST).
#  Retourne "git(branche)" si on est dans un dépôt git, sinon "git()".
#------------------------------------------------------------------------------
_ferrox_git_seg() {
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$branch" ]; then
        printf 'git(%s)' "$branch"
    else
        printf 'git()'
    fi
}

#------------------------------------------------------------------------------
#  Section 4 : construction du PROMPT (cadre sur 2 lignes)
#
#    Ligne 1 : ╭─ HH:MM:SS ─ git(branche) ─ ferrox-NOM
#    Ligne 2 : ╰─ ~/chemin ➜        (l'espace après la flèche = position du curseur)
#
#  Timing (IMPORTANT) : $(_ferrox_git_seg) est écrit en SIMPLE guillemets dans
#  PROMPT1 → il reste en texte littéral au moment de l'assignation et c'est
#  PROMPT_SUBST qui l'évalue À CHAQUE affichage du prompt (branche à jour en
#  direct). Les variables de thème (${C_TIME}, ${C_GIT}, ${C_NAME}, ${C_RESET})
#  et le nom (${PROMPT_NAME}) restent en DOUBLE guillemets : interpolées une
#  seule fois à l'assignation, elles n'ont pas à être réévaluées.
#  Le cadre (╭─ ╰─ ➜) est coloré avec C_TIME, la couleur dominante du thème.
#------------------------------------------------------------------------------
PROMPT1="${C_TIME}╭─ %D{%H:%M:%S}${C_RESET} ─ ${C_GIT}"'$(_ferrox_git_seg)'"${C_RESET} ─ ${C_NAME}ferrox-${PROMPT_NAME}${C_RESET}"

PROMPT2="${C_TIME}╰─ %~ ➜ ${C_RESET}"

PROMPT="$PROMPT1"$'\n'"$PROMPT2"