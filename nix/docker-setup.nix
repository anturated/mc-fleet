{ name, composeSrc }:

''
  # shut down other servers #

  echo "• ──────────────────── Docker ──────────────────── •"
  CONTAINERS=$(docker ps --format '{{.Names}}' \
    | grep -E '^(minecraft-|mc-)' || true)

  if [ -n "$CONTAINERS" ]; then
    echo "> Stopping $CONTAINERS"
    echo "$CONTAINERS" | xargs docker stop --timeout 60
    echo "> All stopped."
  else
    echo "> No minecraft containers running."
  fi

  echo "> Deploying ${name}"
  rm -f "$DEST/compose.yaml" # need to delete cuz its readonly
  cp ${composeSrc} "$DEST/compose.yaml"

  # bring up new servers #

  cd "$DEST"
  docker compose up -d --build

  # print exit options #

  echo "• ───────────────────── Done ───────────────────── •"
  echo "> ${name} is up ✓"
  echo "> Logs:"
  echo "    ''${G}docker compose -f $DEST/compose.yaml logs -f''${N}"
  echo "> Attach:"
  echo "    ''${G}docker attach minecraft-${name}''${N}"
  echo "• ──────────────────────────────────────────────── •"

  echo -ne "> What's next? (l)ogs / (a)ttach / (N)o action"

  read -n 1 -r choice
  echo  # move to next line after keypress

  case "$choice" in
    l|L)
      echo "> Opening logs for ${name}..."
      echo "• ──────────────────────────────────────────────── •"
      docker compose -f "$DEST/compose.yaml" logs -f
      ;;
    a|A)
      echo "> Attaching to ${name}..."
      echo "• ──────────────────────────────────────────────── •"
      docker attach "minecraft-${name}"
      ;;
    *)
      echo "> Goodbye."
      echo "• ──────────────────────────────────────────────── •"
      ;;
  esac
''
