#!/data/data/com.termux/files/usr/bin/bash
#=============================================================================
#  Ferrox — lib/common.sh (logique partagée install.sh / update.sh)
#-----------------------------------------------------------------------------
#  Chargé via `source` par install.sh et update.sh (jamais exécuté seul).
#  Pas de `set -e` ici : chaque script parent applique sa propre politique
#  d'arrêt. Variables attendues du parent : LOG_FILE, TOOLS_DIR, PIP_BIN.
#=============================================================================

#------------------------------------------------------------------------------
#  Utilitaires d'affichage
#  Chaque message est aussi journalisé avec un horodatage dans install.log,
#  pour pouvoir déboguer un souci rapporté par un utilisateur à distance
#  sans avoir à reproduire la session en direct.
#------------------------------------------------------------------------------
_log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }
msg_info() { printf '[*] %s\n' "$*"; _log "INFO  $*"; }
msg_ok()   { printf '[✓] %s\n' "$*"; _log "OK    $*"; }
msg_err()  { printf '[✗] %s\n' "$*" >&2; _log "ERR   $*"; }

#------------------------------------------------------------------------------
#  Passe partout : s'assure que ~/go/bin (où « go install » dépose ses
#  binaires) est dans le PATH, sinon ffuf, httpx… ne sont pas trouvés en
#  ligne de commande. Effet PERSISTANT : la ligne d'export est ajoutée une
#  seule fois à ~/.zshrc (sinon ~/.bashrc). Effet IMMÉDIAT : l'export est
#  appliqué à la session courante du script. Non bloquant : si l'écriture
#  du fichier rc échoue, la session courante est quand même corrigée.
#------------------------------------------------------------------------------
ensure_go_path() {
    local rc_file="$HOME/.zshrc"
    local line='export PATH="$PATH:$HOME/go/bin"'
    [ -f "$rc_file" ] || rc_file="$HOME/.bashrc"

    if ! grep -qxF "$line" "$rc_file" 2>/dev/null; then
        if printf '%s\n' "$line" >> "$rc_file" 2>/dev/null; then
            msg_info "PATH mis à jour dans $rc_file — relance ton terminal ou fais 'source $rc_file'."
        else
            msg_info "Impossible d'écrire dans $rc_file — le chemin Go est appliqué pour cette session uniquement."
        fi
    fi

    case ":$PATH:" in
        *":$HOME/go/bin:"*) ;;
        *) export PATH="$PATH:$HOME/go/bin" ;;
    esac
}

#------------------------------------------------------------------------------
#  Installation par type de manifeste (commune aux modes install/update)
#  Chaque fonction attend :
#    $1 = dossier du Rivet (ex: rivets/web)
#    $2 = mode ("install" par défaut, "update" pour re-épingler les versions)
#  Toutes les lignes vides et commentaires (#) sont ignorés à la lecture.
#  Un outil qui échoue ne bloque PAS les suivants : il est signalé et on
#  continue (le [✓] final récapitule le nombre de réussites sur le total).
#------------------------------------------------------------------------------

#  1 — Outils Go (go.lock) : ligne « nom=chemin_module@version »
#      Règle : JAMAIS "@latest" — garde-fou actif, la ligne est rejetée si
#      elle ne contient pas de version épinglée explicite.
#      Comportement identique dans les deux modes : go install est sûr à
#      rejouer (le mode n'est reçu que par souci d'uniformité).
install_go_from_rivet() {
    local rivet_dir="$1"
    local mode="${2:-install}"
    local go_lock="$rivet_dir/go.lock"
    local line name path_at_version ok=0 total=0

    [ -f "$go_lock" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"   # nettoyage d'éventuelles fins de ligne CRLF
        case "$line" in
            ''|'#'*) continue ;;
        esac
        # Split sur le premier « = » : nom d'un côté, chemin@version de l'autre.
        name="${line%%=*}"
        path_at_version="${line#*=}"
        [ -z "$path_at_version" ] && continue

        total=$((total + 1))

        # Garde-fou : refuse @latest et exige une version explicite.
        case "$path_at_version" in
            *@latest)
                msg_err "'$name' utilise @latest — refusé, épingle une version précise dans go.lock."
                continue
                ;;
            *@*) ;;  # contient bien un @version, on continue
            *)
                msg_err "'$name' n'a pas de version épinglée (format attendu : chemin@version)."
                continue
                ;;
        esac

        msg_info "Installation de '$name' (Go) ..."
        if ! go install -v "$path_at_version"; then
            msg_err "Échec de l'installation de '$name' (voir l'erreur ci-dessus)."
            continue
        fi
        ok=$((ok + 1))
        msg_ok "'$name' installé."
    done < "$go_lock"

    msg_ok "$ok outil(s) Go installé(s) sur $total."
}

#  2 — Outils pip (pip.list) : ligne « nom=paquet_pypi » ou « nom=paquet==version »
#      Si la ligne contient déjà « == », la version épinglée est passée telle
#      quelle à pip ; sinon pip installe la dernière version du paquet.
#      En mode "update", on ajoute --upgrade pour re-épingler une version
#      plus récente (le paquet est déjà installé).
install_pip_from_rivet() {
    local rivet_dir="$1"
    local mode="${2:-install}"
    local pip_list="$rivet_dir/pip.list"
    local line name pkg ok=0 total=0
    local upgrade=()

    [ -f "$pip_list" ] || return 0

    if [ "$mode" = "update" ]; then
        upgrade=(--upgrade)
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in
            ''|'#'*) continue ;;
        esac
        name="${line%%=*}"
        pkg="${line#*=}"
        [ -z "$pkg" ] && continue

        total=$((total + 1))
        if [[ "$pkg" == *==* ]]; then
            msg_info "Installation de '$name' ($pkg) ..."
        else
            msg_info "Installation de '$name' (paquet : $pkg, dernière version) ..."
        fi
        if ! "$PIP_BIN" install "${upgrade[@]}" "$pkg"; then
            msg_err "Échec de l'installation de '$name' (voir l'erreur ci-dessus)."
            continue
        fi
        ok=$((ok + 1))
        msg_ok "'$name' installé."
    done < "$pip_list"

    msg_ok "$ok outil(s) pip installé(s) sur $total."
}

#------------------------------------------------------------------------------
#  4 — Environnement shell zsh : installation de zsh, Oh-My-Zsh et plugins
#------------------------------------------------------------------------------
install_shell_environment() {
    msg_info "Installation de l'environnement shell zsh ..."

    # Installation de zsh
    if ! command -v zsh >/dev/null 2>&1; then
        if pkg install -y zsh 2>/dev/null; then
            msg_ok "zsh installé."
        else
            msg_err "Échec de l'installation de zsh — continuation sans zsh."
        fi
    else
        msg_info "zsh déjà présent, on passe."
    fi

    # Installation non-interactive d'Oh-My-Zsh si absent
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        msg_info "Installation d'Oh-My-Zsh (non-interactif) ..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
            msg_ok "Oh-My-Zsh installé."
        else
            msg_err "Échec de l'installation d'Oh-My-Zsh — continuation."
        fi
    else
        msg_info "Oh-My-Zsh déjà présent, on passe."
    fi

    # Clonage de zsh-autosuggestions dans le dossier custom d'Oh-My-Zsh
    local zsh_autosuggestions_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$zsh_autosuggestions_dir" ]; then
        msg_info "Clone de zsh-autosuggestions ..."
        if ! git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_autosuggestions_dir" 2>/dev/null; then
            msg_err "Échec du clone de zsh-autosuggestions — continuation."
        else
            msg_ok "zsh-autosuggestions cloné."
        fi
    else
        msg_info "zsh-autosuggestions déjà présent, on passe."
    fi

    # Ajout de zsh-autosuggestions à la liste des plugins actifs dans .zshrc
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        local plugins_line
        plugins_line=$(grep -E '^plugins=\(.*\)$' "$zshrc" 2>/dev/null || true)
        local existing_plugins=""
        if [ -n "$plugins_line" ]; then
            existing_plugins="${plugins_line#plugins=(}"
            existing_plugins="${existing_plugins%)}"
        fi

        local plugin_to_add="zsh-autosuggestions"
        local new_plugins

        # Déjà présent ? on ne duplique pas
        if [[ " $existing_plugins " == *" $plugin_to_add "* ]]; then
            msg_info "zsh-autosuggestions déjà dans les plugins, on ne duplique pas."
        else
            if [ -n "$existing_plugins" ]; then
                new_plugins="${existing_plugins} $plugin_to_add"
            else
                new_plugins="$plugin_to_add"
            fi

            # Remplacer la ligne plugins= par la nouvelle version (sans écraser d'autres plugins)
            # Si la ligne n'existe pas, on l'ajoute à la fin du fichier
            if grep -qE '^plugins=' "$zshrc" 2>/dev/null; then
                if sed -i "s/^plugins=(.*)$/plugins=(${new_plugins})/" "$zshrc" 2>/dev/null; then
                    msg_info "Plugins mis à jour dans $zshrc — relance ton terminal ou fais 'source $zshrc'."
                else
                    msg_info "Impossible de modifier $zshrc — plugins mis à jour pour cette session uniquement."
                fi
            else
                # Ajout de la ligne plugins= en fin de fichier
                if printf 'plugins=%s
' "$new_plugins" >> "$zshrc" 2>/dev/null; then
                    msg_info "Plugins mis à jour dans $zshrc — relance ton terminal ou fais 'source $zshrc'."
                else
                    msg_info "Impossible d'ajouter les plugins dans $zshrc — plugins mis à jour pour cette session uniquement."
                fi
            fi
        fi
    else
        msg_info "Fichier $zshrc introuvable — plugins mis à jour pour cette session uniquement."
    fi
}

#  3 — Outils clonés (clone.list) : ligne « nom=url_git »
#      Clone dédié dans $TOOLS_DIR, puis installation des dépendances si
#      requirements.txt.
#      - mode "install" : idempotent — si le dossier existe déjà, on passe.
#      - mode "update"  : si le dossier existe déjà, git pull pour re-cloner ;
#        sinon clone normal (même comportement que install).
install_clone_from_rivet() {
    local rivet_dir="$1"
    local mode="${2:-install}"
    local clone_list="$rivet_dir/clone.list"
    local line name url ok=0 total=0
    local etat="cloné(s)"

    [ -f "$clone_list" ] || return 0
    mkdir -p "$TOOLS_DIR"

    if [ "$mode" = "update" ]; then
        etat="mis à jour"
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in
            ''|'#'*) continue ;;
        esac
        name="${line%%=*}"
        url="${line#*=}"
        [ -z "$url" ] && continue

        total=$((total + 1))
        if [ -d "$TOOLS_DIR/$name" ]; then
            if [ "$mode" = "update" ]; then
                msg_info "Mise à jour de '$name' (git pull) ..."
                if ! git -C "$TOOLS_DIR/$name" pull; then
                    msg_err "Échec du git pull de '$name' (voir l'erreur ci-dessus)."
                    continue
                fi
                ok=$((ok + 1))
                msg_ok "'$name' mis à jour."
            else
                msg_info "'$name' : déjà cloné, on passe."
                continue
            fi
        else
            msg_info "Clone de '$name' ..."
            if ! git clone --depth 1 "$url" "$TOOLS_DIR/$name"; then
                msg_err "Échec du clone de '$name' (voir l'erreur ci-dessus)."
                continue
            fi
            ok=$((ok + 1))
            msg_ok "'$name' cloné."
        fi

        # Dépendances Python éventuelles du repo cloné / mis à jour.
        if [ -f "$TOOLS_DIR/$name/requirements.txt" ]; then
            msg_info "Installation des dépendances de '$name' ..."
            if ! "$PIP_BIN" install -r "$TOOLS_DIR/$name/requirements.txt"; then
                msg_err "Échec des dépendances de '$name' (voir l'erreur ci-dessus)."
            fi
        fi
    done < "$clone_list"

    msg_ok "$ok outil(s) $etat sur $total."
}
#------------------------------------------------------------------------------
#  Fonction : configure_prompt
#  Role : configuration interactive du prompt (nom +.theme), appelée UNE SEULE FOIS
#  lors du premier install.sh. Si config/prompt.conf existe déjà, on skip entirely.
#  Pose deux questions :
#    1. Nom à afficher dans le prompt (validation : non vide)
#    2. Choix de thème couleur (menu numéroté 1-4, défaut 1)
#  Écrit PROMPT_NAME et PROMPT_THEME dans config/prompt.conf.
#------------------------------------------------------------------------------
configure_prompt() {
    local prompt_conf="$FEROX_HOME/config/prompt.conf"

    # Si config/prompt.conf existe déjà → skip entirely (première update ou réinstall)
    [ -f "$prompt_conf" ] && {
        msg_info "config/prompt.conf déjà présent — configuration prompt ignorée."
        return 0
    }

    # Question 1 : nom du prompt
    local name=""
    while [ -z "$name" ]; do
        read -p "Quel nom veux-tu afficher dans ton prompt Ferrox ? (ex: Arkane) : " name
        # Si vide, réinviter (pas de chaîne vide acceptée)
        if [ -z "$name" ]; then
            msg_err "Le nom ne peut pas être vide. Réessaie."
        fi
    done
    PROMPT_NAME="$name"

    # Question 2 : choix du thème couleur
    local theme_choice=""
    echo "Choisis un thème de couleurs :"
    echo "  1) Ferrox Rouge   (rouge/orange)"
    echo "  2) Ferrox Cyan    (bleu/cyan)"
    echo "  3) Ferrox Vert    (vert/lime)"
    echo "  4) Ferrox Violet  (violet/magenta)"
    while [ -z "$theme_choice" ]; do
        read -p "Choisis un thème de couleurs (1-4, défaut 1) : " theme_choice
        # Validation : doit être 1-4, entrée = défaut 1
        case "$theme_choice" in
            1) theme_choice="rouge" ;;
            2) theme_choice="cyan" ;;
            3) theme_choice="vert" ;;
            4) theme_choice="violet" ;;
            "")  # entrée vide → défaut 1 (rouge)
                 theme_choice="rouge"
                 ;;
            *)   # invalide → défaut 1 (rouge)
                 theme_choice="rouge"
                 ;;
        esac
    done
    PROMPT_THEME="$theme_choice"

    # Écriture dans config/prompt.conf
    mkdir -p "$FEROX_HOME/config"
    printf 'PROMPT_NAME="%s"\nPROMPT_THEME="%s"\n' "$PROMPT_NAME" "$PROMPT_THEME" > "$prompt_conf"
    msg_ok "Configuration prompt enregistrée dans $prompt_conf"
    msg_info "PROMPT_NAME=$PROMPT_NAME"
    msg_info "PROMPT_THEME=$PROMPT_THEME"
}
