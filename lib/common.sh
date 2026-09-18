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