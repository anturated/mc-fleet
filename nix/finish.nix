{ name }:

''
  echo "• ───────────────────── Done ───────────────────── •"
  ok   "${name} is up."
  say  "Logs:"
  info "    docker compose -f $DEST/compose.yaml logs -f"
  say  "Attach:"
  info "    docker attach minecraft-${name}"
  echo "• ──────────────────────────────────────────────── •"
  echo -ne "> What's next? (''${R}l''${N})ogs / (''${R}a''${N})ttach / (''${R}N''${N})o action"

  read -n 1 -r choice
  echo  # move to next line after keypress

  case "$choice" in
    l|L)
      ok   "Opening logs for ${name}..."
      echo "• ──────────────────────────────────────────────── •"
      docker compose -f "$DEST/compose.yaml" logs -f
      ;;
    a|A)
      ok   "Attaching to ${name}..."
      echo "• ──────────────────────────────────────────────── •"
      docker attach "minecraft-${name}"
      ;;
    *)
      say  "Goodbye."
      echo "• ──────────────────────────────────────────────── •"
      ;;
  esac
''
