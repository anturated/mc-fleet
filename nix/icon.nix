{ pkgs }:

{
  type = "app";
  program = toString (
    pkgs.writeShellApplication {
      name = "icon";
      runtimeInputs = [ pkgs.imagemagick pkgs.coreutils ];
      text = ''
        NAME="''${1:?Usage: icon <packname> </path/to/image>}"
        IMG="''${2:?Usage: icon <packname> </path/to/image>}"
        DEST="$PWD/servers/$NAME/server-icon.png"

        if [ ! -f "$IMG" ]; then
          echo "✗ Image not found: $IMG"
          exit 1
        fi

        if [ ! -d "$PWD/servers/$NAME" ]; then
          echo "✗ No such server: servers/$NAME"
          exit 1
        fi

        echo "━━━ Converting $IMG → $DEST (64x64) ━━━"

        convert "$IMG" \
          -resize 64x64^ \
          -gravity Center \
          -extent 64x64 \
          "$DEST"

        echo "✓ Saved to $DEST"
      '';
    } + "/bin/icon"
  );
}
