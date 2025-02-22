{
  lib,
  stdenvNoCC,
  findutils,
  gnused,
  coreutils,
  ...
}: let
  inherit (lib.strings) concatMapStringsSep toLower sanitizeDerivationName;
in
  {
    name,
    version,
    src,
    shaderPath,
    texturePath,
    effects,
    deniedEffects ? [],
    required ? false,
    enabledByDefault ? false,
    description ? "",
    homepage ? "",
    ...
  }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      name = sanitizeDerivationName name;
      inherit version;
      inherit src;
      buildInputs = [findutils gnused coreutils];
      installPhase = let
        shaders = builtins.filter (f: ! (builtins.elem f deniedEffects)) effects;
        # Install the shader file ensure the path is lowercase to catch conflicts
        shaderInstall = _shader: ''
          find "$shaders_path" -type f \( -iname '*.fx' -o -iname '*.fxh' \) -printf "%P\n" \
            | while IFS= read -r file; do
                install -Dm644 -v "$shaders_path/$file" "$out/${toLower shaderPath}/$(echo "$file" | tr '[:upper:]' '[:lower:]')"
              done
        '';
      in ''
        shaders_path=""
        textures_path=""
        presets_path=""
        # Check standard paths
        shaders_path=$(find . -type d -iname "Shaders" | head -n 1)
        textures_path=$(find . -type d -iname "Textures" | head -n 1)
        presets_path=$(find . -type d -iname 'reshade-presets' | head -n 1)

        if [ -z "$shaders_path" ]; then
          shaders_path=$(find . -type f -iname '*.fx' -printf "%P\n" | xargs -I {} dirname {} | sort | uniq | head -n 1)
        fi
        echo "Shaders Path: $shaders_path"
        if [ -e "$shaders_path" ]; then
          ${
          if ((builtins.length effects) == 0) && ((builtins.length deniedEffects) == 0)
          then shaderInstall "*.fx"
          else concatMapStringsSep "\n" shaderInstall shaders
        }
        else
          "WARN: No Shaders found"
        fi

        if [ -z "$textures_path" ]; then
           textures_path=$(find . -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' | xargs -I {} dirname {} | sort | uniq | head -n 1)
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

        if [ -z "$presets_path" ]; then
          presets_path=$(find . -type f -iname '*.ini' | xargs -I {} dirname {} | sort | uniq | head -n 1)
        fi
        echo "Preset Path: $presets_path"
        if [ -e "$presets_path" ]; then
          find "$presets_path" -iname '*.ini' -printf "%P\n" \
            | while IFS= read -r file; do
                install -Dm644 -v "$presets_path/$file" "$out/reshade-presets/$(echo "$file" | tr '[:upper:]' '[:lower:]')"
              done
        else
          echo 'WARN: No Presets'
        fi
      '';
      passthru = {
        inherit (finalAttrs) installPhase;
        inherit required enabledByDefault;
      };
      meta = {
        inherit description homepage;
      };
    })
