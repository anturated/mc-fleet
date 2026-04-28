{ name }:

''
  CONTAINER_NAME="minecraft-${name}"

  _fail_install=0
  _fail_api=0
  _shown_downloading_modpack=0
  _shown_processing_modpack=0
  _shown_downloading_mods=0
  _shown_copying_mods=0
  _shown_copying_configs=0
  _shown_server_props=0
  _shown_aikar=0
  _shown_mem=0
  _shown_modloader_install=0
  _shown_loading_mods=0
  _shown_initializing_mods=0
  _shown_starting_server=0
  _world_progress=-1
  _server_ready=0

  once() {
    local flag="$1"; shift
    local varname="_shown_''${flag}"
    if [ "''${!varname}" = "0" ]; then
      printf -v "$varname" '%s' '1'
      "$@"
    fi
  }

  stop_container() {
    say "Eliminating ${name}..."
    docker stop -t 1 "$CONTAINER_NAME" >/dev/null || true
    echo "• ──────────────────────────────────────────────── •"
    exit 1
  }


  echo "• ──────────────────── >Pilot ──────────────────── •"
  say "Babysitting this launch."
  say "Boarding ${name}..."

  shopt -s extglob lastpipe
  docker compose -f "$DEST/compose.yaml" logs \
      --follow --no-log-prefix --timestamps=false --tail 0 2>&1 \
  | while IFS= read -r line; do

    # strip ANSI in pure bash (no subshell)
    clean="''$line"
    clean="''${clean//$'\x1b'[*([0-9;?])[a-zA-Z]/}"
    clean="''${clean//$'\x0f'/}"
    clean="''${clean//$'\r'/}"

    case "$clean" in
      *"exited with code 0"*) ;;
      *"exited with code"*|*"Error response from daemon"*)
        _fail_crash=1
        break ;;

      *"This crash report has been saved to"*)
        fail "Crashed with report." ;;

      *"Exception stopping the server"*)
        say  "Won't stop on it's own, helping."
        stop_container ;;

      *"not allowed for project distribution"*)
        _fail_api=1 ;;
      *"mc-image-helper"*"ERROR"*"install-curseforge"*"command failed"*)
        _fail_install=1 ;;

      *"Downloading modpack zip for"*)
        once downloading_modpack say "Downloading modpack..." ;;
      *"Processing modpack '"*)
        once processing_modpack say "Processing modpack..." ;;
      *"Downloaded mod file mods/"*|*"Downloaded /data/mods"*)
        once downloading_mods say "Downloading mods..." ;;
      *"Copying any mods from /mods"*)
        once copying_mods say "Copying mods..." ;;
      *"Copying any configs from /config"*)
        once copying_configs say "Copying configs..." ;;

      *"Creating server properties"*|*"Created/updated"*"properties"*)
        once server_props say "Creating server properties..." ;;
      *"Using Aikar's flags"*)
        once aikar say "Applying Aikar flags..." ;;
      *"Setting initial memory"*|*"max to"*)
        once mem say "Memory configured." ;;

      *"Running "*" installer for Minecraft"*|*"Installing Fabric"*)
        once modloader_install say "Installing modloader... this can take a while" ;;

      *"Found mod file"*)
        once loading_mods say "Loading mods..." ;;
      *"[modloading-worker-"*"/INFO]"*)
        once initializing_mods say "Initializing mods... this usually takes a while" ;;

      *"Starting "*"inecraft server"*)
        once starting_server say "Starting server..." ;;

      *"Preparing spawn area: "*"%"*)
        pct="''${clean##*Preparing spawn area: }"
        pct="''${pct%%%*}%"
        if [ "$pct" != "$_world_progress" ]; then
          _world_progress="$pct"
          printf "\r%s>%s Loading world: %s   " "$N" "$B" "$pct"
        fi ;;

      *"Time elapsed:"*|*"Done ("*)
        if [ "$_world_progress" != "-1" ]; then
          printf '\n'
          _world_progress=-1
        fi
        if [[ "$clean" == *"Done ("*"For help, type"* ]]; then
          ok "Server is up and running!"
          say "Pilot out. See ya."
          _server_ready=1
          break 2
        fi ;;
    esac

  done || true # safety net

  if [ "$_server_ready" -eq 0 ]; then
    if [ "$_fail_api" -eq 1 ]; then
      fail "API safeguard failed."
      say "One of the mods prevents third-party downloads."
      say "Leaving the other guys a message..."
      touch "$DEST/.force-zip"
      warn "You can restart the command"
      say "There should be a zip download warning next time."
      stop_container
    elif [ "$_fail_install" -eq 1 ]; then
      fail "Install failed for some reason."
      stop_container
    elif [ "$_fail_crash" -eq 1 ]; then
      fail "Crashed for some reason."
      stop_container
    else
      fail "Can't see anything, bailing out."
      warn "${name} might still be running."
      echo "• ──────────────────────────────────────────────── •"
      exit 1
    fi
  fi
''
