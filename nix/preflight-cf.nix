{ cfg }: # you didn't have to do this, CurseForge...

let
  slug = cfg.slug;
in
''
  echo "• ────────────────── CurseForge ────────────────── •"

  # check if curseforge key exists, no can do without it #

  KEY_FILE="$HOME/mc-servers/key.txt"
  if [ ! -f "$KEY_FILE" ]; then
    fail "$KEY_FILE not found."
    say  "Paste your CurseForge API key there."
    say  "You can get your key here:"
    info "https://console.curseforge.com/#/api-keys"
    echo "• ──────────────────────────────────────────────── •"
    exit 1
  fi

  # cleanup the key #

  CF_KEY=$(tr -d ' \t\r\n' < "$KEY_FILE")
  if [ -z "$CF_KEY" ]; then
      fail "$KEY_FILE is empty."
      echo "• ──────────────────────────────────────────────── •"
    exit 1
  fi

  ENV_DEST="$DEST/.env"
  rm -f "$ENV_DEST"
  printf "CF_API_KEY='%s'\n" "$CF_KEY" > "$ENV_DEST" # echo no work, newline necessary

  # check CF API for manual download #

  if [ -f "$DEST/pack/modpack.zip" ]; then
    say "modpack.zip exists. Good."
    echo "CF_MODPACK_ZIP=\"/pack/modpack.zip\"" >> "$DEST/.env.runtime"
  else
    ${
      # override the api checks if we know it's gonna be a zip
      if cfg.requiresZip then
        "NEEDS_ZIP=true"
      else
        ''
          NEEDS_ZIP=false

          if [ -f "$DEST/.api-checked" ]; then
            say "API got greenlit earlier. Good."
            if [ -f "$DEST/.force-zip" ]; then
              say "Pilot said you need a zip."
              NEEDS_ZIP=true
            fi
          else
            say "Verifying key..."

            SEARCH_RES=$(curl -s -w "\n%{http_code}" -H "x-api-key: $CF_KEY" -H "Accept: application/json" "https://api.curseforge.com/v1/mods/search?gameId=432&classId=4471&slug=${slug}")
            HTTP_STATUS=$(echo "$SEARCH_RES" | tail -n1)
            BODY=$(echo "$SEARCH_RES" | head -n-1)

            if [ "$HTTP_STATUS" != "200" ]; then
              fail "CurseForge API denied the request ($HTTP_STATUS)"
              say  "Check your API key."
              echo "• ──────────────────────────────────────────────── •"
              exit 1
            fi

            say "Checking API..."

            MOD_ID=$(echo "$BODY" | jq -r '.data[0].id')

            if [ "$MOD_ID" == "null" ] || [ -z "$MOD_ID" ]; then
              fail "Could not find ${slug}"
              say  "Check your slug."
              echo "• ──────────────────────────────────────────────── •"
              exit 1
            fi

            ALLOWS_DIST=$(echo "$BODY" | jq -r '.data[0].allowModDistribution')

            if [ "$ALLOWS_DIST" == "false" ]; then
              NEEDS_ZIP=true
            else
              ok "API looks clear."
              touch "$DEST/.api-checked"
            fi
          fi
        ''
    }

    if [ "$NEEDS_ZIP" == "true" ]; then
      say "Addng modpack zip to .env..."
      # looks hacky but eh, there's no way i'll know that at eval time
      echo "CF_MODPACK_ZIP=\"/pack/modpack.zip\"" >> "$DEST/.env.runtime"
      rm -rf "$DEST/pack"
      mkdir -p "$DEST/pack"
      URL="https://www.curseforge.com/minecraft/modpacks/${slug}"

      OPENED=false
      if   command -v xdg-open >/dev/null; then xdg-open "$URL" >/dev/null 2>&1 && OPENED=true
      elif command -v open     >/dev/null; then open     "$URL" >/dev/null 2>&1 && OPENED=true
      fi

      warn "This server requires a modpack zip."
      say  "Please download it manually."
      if ''$OPENED; then
        say "Opening CurseForge page in your browser..."
      else
        say  "No browser found. Open this link manually:"
        info "$URL"
      fi
      say "Watching ~/Downloads for a new .zip file..."

      mkdir -p "$HOME/Downloads"
      shopt -s nullglob
      EXISTING_ZIPS=("$HOME/Downloads"/*.zip)
      while true; do
        CURRENT_ZIPS=("$HOME/Downloads"/*.zip)
        for zip in "''${CURRENT_ZIPS[@]}"; do
          is_new=true
          for e_zip in "''${EXISTING_ZIPS[@]}"; do
            if [[ "$zip" == "$e_zip" ]]; then
              is_new=false
              break
            fi
          done
          if $is_new; then
            sleep 1
            mv "$zip" "$DEST/pack/modpack.zip"
            ok  "Moved $(basename "$zip")"
            say "to $DEST/pack/modpack.zip"
            break 2
          fi
        done
        sleep 2
      done
      shopt -u nullglob
    fi
  fi
''
