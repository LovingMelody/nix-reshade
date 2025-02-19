{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  writeScript,
  withAddons ? false,
  ...
}: let
  sources = (builtins.fromJSON (builtins.readFile ./../../sources.json)).reshade;
  inherit (sources) version;
  inherit (lib.strings) optionalString;
in
  stdenvNoCC.mkDerivation {
    name = "reshade-full";
    inherit version;
    src = fetchurl {
      url = "https://reshade.me/downloads/ReShade_Setup_${version}${optionalString withAddons "_Addon"}.exe";
      hash =
        sources
        .${
          if withAddons
          then "addon"
          else "base"
        };
    };

    nativeBuildInputs = [p7zip];
    unpackPhase = ''
      mkdir -p $out/lib/reshade
      cd $out/lib/reshade
      7z e $src
    '';
    passthru.updateScript = writeScript "update-reshade" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i python3 nix-prefetch-git

      set -eu -o pipefail

      ${./sources-generator.py}
    '';
  }
