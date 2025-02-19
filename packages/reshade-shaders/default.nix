{
  lib,
  fetchFromGitHub,
  symlinkJoin,
  mkShader,
  includeRequired ? true,
  includeEnabled ? true,
  includeByName ? [],
  blacklist ? [],
  full ? false,
  ...
}: let
  inherit (lib.strings) removePrefix;
  sources = (builtins.fromJSON (builtins.readFile ./../../sources.json)).shaders;
  fromSource = name: let
    info = sources.${name};
  in
    mkShader {
      inherit name;
      version = info.commit;
      src = fetchFromGitHub {
        inherit (info) repo owner hash;
        rev = info.commit;
      };
      inherit (info) deniedEffects effects;
      shaderPath = removePrefix "./" info.installPath;
      texturePath = removePrefix "./" info.texturePath;
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
    paths = lib.attrsets.mapAttrsToList (n: _: fromSource n) (lib.attrsets.filterAttrs filteredShader sources);
  }
