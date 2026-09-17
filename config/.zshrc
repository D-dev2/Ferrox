#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — config/.zshrc (configuration Zsh pour Termux)
#-----------------------------------------------------------------------------
#  Rôle : fichier de configuration Zsh facturable Ferrox. Il peut servir de
#  modèle à ~/.zshrc de l'utilisateur OU être sourcé partiellement depuis lui.
#  Sections : PATH / alias / motd / thème.
#=============================================================================

#------------------------------------------------------------------------------
#  Section 1 : promotion de Ferrox dans le PATH
#  TODO(ferrox) : export PATH ajoutant $FEROX_HOME/bin (le CLI ferrox) et
#  $HOME/ferrox-tools/*/bin (binaires des outils clonés).
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 2 : alias rapides du quotidien
#------------------------------------------------------------------------------
alias ferrox-update='ferrox update'
# TODO(ferrox) : autres alias utiles (ex: lancement rapide d'un outil).

#------------------------------------------------------------------------------
#  Section 3 : motd (message de bienvenue) au démarrage du shell
#  TODO(ferrox) : appeler config/motd.sh en fin de .zshrc.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  Section 4 : thème Ferrox
#  TODO(ferrox) : appliquer le prompt via config/theme.zsh-theme.
#------------------------------------------------------------------------------