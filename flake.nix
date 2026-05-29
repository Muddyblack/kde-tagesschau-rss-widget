{
  description = "KDE Plasma 6 premium Tagesschau news widget with breaking news notifications and inline expandable stories";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
      metadata = builtins.fromJSON (builtins.readFile ./package/metadata.json);
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "tagesschau-widget";
            version = metadata.KPlugin.Version;
            src = ./package;

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              runHook preInstall
              
              # Install plasmoid package
              root=$out/share/plasma/plasmoids/org.muddyblack.tagesschauWidget
              mkdir -p "$root"
              cp -r . "$root/"

              # Register icon in hicolor theme so Plasma Widget Explorer picks it up
              mkdir -p "$out/share/icons/hicolor/scalable/apps"
              cp contents/icons/org.muddyblack.tagesschauWidget.svg "$out/share/icons/hicolor/scalable/apps/org.muddyblack.tagesschauWidget.svg"

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "KDE Plasma 6 premium Tagesschau news widget with breaking news notifications and inline expandable stories";
              license = licenses.mit;
              platforms = platforms.linux;
              homepage = "https://github.com/Muddyblack/tagesschau-widget";
            };
          };
        });

      apps = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          view = {
            type = "app";
            program = toString (pkgs.writeShellScript "view" ''
              exec nix shell nixpkgs#kdePackages.plasma-sdk -c plasmoidviewer \
                -a "$PWD/package" -f "''${1:-planar}"
            '');
          };
          pack = {
            type = "app";
            program = toString (pkgs.writeShellScript "pack" ''
              set -euo pipefail
              here="$PWD"
              ver="$(grep -oE '"Version":[[:space:]]*"[^"]+"' "$here/package/metadata.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
              name="$(basename "$here")"
              out="$here/$name-$ver.plasmoid"
              rm -f "$out"
              (cd "$here/package" && ${pkgs.zip}/bin/zip -r "$out" . -x '*.swp' '*~')
              echo "wrote $out"
            '');
          };
        });

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            name = "tagesschau-widget-dev";
            packages = with pkgs; [
              qt6.qtdeclarative
              kdePackages.kpackage
              kdePackages.plasma-sdk
              zip
            ];
            shellHook = ''
              echo "tagesschau-widget dev shell ready"
              echo "  make help        — list targets (view, install, pack)"
            '';
          };
        });
    };
}
