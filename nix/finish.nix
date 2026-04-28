{ name }:

''
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
