{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  symlinkJoin,
  findutils,
  gnused,
  coreutils,
  includeRequired ? true,
  includeEnabled ? true,
  includeByName ? [],
  blacklist ? [],
  full ? false,
  ...
}: let
  sources = (builtins.fromJSON (builtins.readFile ./../../sources.json)).shaders;
  inherit (lib.strings) concatMapStringsSep removePrefix toLower;
  mkShader = name: let
    info = sources.${name};
  in
    stdenvNoCC.mkDerivation {
      inherit name;
      version = info.commit;
      src = fetchFromGitHub {
        inherit (info) repo owner hash;
        rev = info.commit;
      };
      buildInputs = [findutils gnused coreutils];
      installPhase = let
        shaders = builtins.filter (f: ! (builtins.elem f info.deniedEffects)) info.effects;
        shaderPath = removePrefix "./" info.installPath;
        texturePath = removePrefix "./" info.texturePath;
        # Install the shader file ensure the path is lowercase to catch conflicts
        shaderInstall = shader: ''
          find "$shaders_path" -type f -iname '${shader}' -printf "%P\n" \
            | while IFS= read -r file; do
                install -Dm644 -v "$shaders_path/$file" "$out/${toLower shaderPath}/$(echo "$file" | tr '[:upper:]' '[:lower:]')"
              done
        '';
      in
        # ''
        #   shader-install() {
        #      find "$1" -type f -name "$2" -prinf '%P\n' \
        #        | ' | xargs -I {} install -Dm644 "$1"'/{}' "$out"'/${shaderPath}/{}'
        #   }
        #   ${concatMapStringsSep "\n" shaderInstall shaders}
        #   find Textures -type f | sed 's|^Textures/||' | xargs -I {} install -Dm644 Textures/{} "$out/${texturePath}/{}"
        # '';
        ''
          local shaders_path=""
          local textures_path=""
          # Check standard paths
          shaders_path=$(find . -type d -iname "Shaders" | head -n 1)
          textures_path=$(find . -type d -iname "Textures" | head -n 1)
          echo $textures_path

          if [ -z "$shaders_path" ]; then
            shaders_path=$(find . -type f -iname '*.fx' -printf "%P\n" | xargs -I {} dirname {} | sort | uniq | head -n 1)
          else
            echo '${name}: Standard Shaders Path'
          fi
          echo "Shaders Path: $shaders_path"
          if [ -e "$shaders_path" ]; then
            ${concatMapStringsSep "\n" shaderInstall shaders}
          else
            "WARN: No Shaders found"
          fi

          if [ -z "$textures_path" ]; then
             textures_path=$(find . -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' | xargs -I {} dirname {} | sort | uniq | head -n 1)
          else
             echo '${name}: Standard Textures Path'
          fi
          echo "Texture Path: $textures_path"
          if [ -e "$textures_path" ]; then
            find "$textures_path" \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -printf "%P\n" \
              | while IFS= read -r file; do
                  install -Dm644 -v "$textures_path/$file" "$out/${toLower texturePath}/$(echo "$file" | tr '[:upper:]' '[:lower:]')"
                done
          else
            echo 'WARN: No Textures'
          fi
        '';
    };
  filteredShader = n: v:
    (full
      || (v.required && includeRequired)
      || (builtins.elem n includeByName)
      || (v.enabledByDefault && includeEnabled))
    && (! builtins.elem n blacklist);
in
  symlinkJoin {
    name = "reshade-shaders";
    paths = lib.attrsets.mapAttrsToList (n: _: mkShader n) (lib.attrsets.filterAttrs filteredShader sources);
  }
