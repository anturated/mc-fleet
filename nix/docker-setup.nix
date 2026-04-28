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
  docker compose up -d --build 2>/dev/null
''
