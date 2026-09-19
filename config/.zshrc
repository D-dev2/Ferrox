#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — config/.zshrc (configuration Zsh pour Termux)
#-----------------------------------------------------------------------------
#  Rôle : fichier de configuration Zsh facturable Ferrox. Il peut servir de
#  modèle à ~/.zshrc de l'utilisateur OU être sourcé partiellement depuis lui.
#  Sections : PATH / Oh-My-Zsh / alias / motd / thème.
#=============================================================================

#------------------------------------------------------------------------------
#  Section 1 : promotion de Ferrox dans le PATH
#  TODO(ferrox) : export PATH ajoutant $FEROX_HOME/bin (le CLI ferrox) et
#  $HOME/ferrox-tools/*/bin (binaires des outils clonés).
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 2 : Oh-My-Zsh (compatibilité alias) + alias rapides du quotidien
#  Le plugin git d'Oh-My-Zsh définit un alias `gau` = « git add --update » qui
#  MASQUE le binaire gau (getallurls) installé par Ferrox dans le Rivet web :
#  taper `gau` exécuterait alors git au lieu de l'outil de pentest. On annule
#  donc cet alias juste après le chargement d'Oh-My-Zsh (et on ne réveille
#  jamais ce conflit dans les sections d'alias ci-dessous).
#------------------------------------------------------------------------------
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"
unalias gau 2>/dev/null || true

#------------------------------------------------------------------------------
#  Section 3 : alias rapides du quotidien
#------------------------------------------------------------------------------
alias ferrox-update='ferrox update'
# TODO(ferrox) : autres alias utiles (ex: lancement rapide d'un outil).

#------------------------------------------------------------------------------
#  Section 4 : motd (message de bienvenue) au démarrage du shell
#  TODO(ferrox) : appeler config/motd.sh en fin de .zshrc.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 5 : thème Ferrox
#  Sourcing du thème personnalisé qui lit config/prompt.conf et construit
#  le PROMPT avec couleurs, nom utilisateur et chemin dynamique.
#------------------------------------------------------------------------------
[ -f "$FEROX_HOME/config/theme.zsh-theme" ] && source "$FEROX_HOME/config/theme.zsh-theme"