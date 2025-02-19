{
  lib,
  fetchFromGitHub,
  mkShader,
  ...
}: let
  inherit (lib.strings) removePrefix;
  sources = (builtins.fromJSON (builtins.readFile ./../../sources.json)).shaders;
  name = "ipsuShade by ipsusu";
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
  }
