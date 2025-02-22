{
  lib,
  callPackage,
  fetchFromGitHub,
  mkShader ? callPackage ./../mkShader {},
  ...
}: let
  inherit (lib.strings) sanitizeDerivationName removePrefix;
in
  {source, ...}:
    mkShader {
      name = sanitizeDerivationName source.name;
      version = source.commit;
      src = fetchFromGitHub {
        inherit (source) repo owner hash;
        rev = source.commit;
      };
      inherit (source) deniedEffects effects description;
      homepage = source.url;
      shaderPath = removePrefix "./" source.installPath;
      texturePath = removePrefix "./" source.texturePath;
      required = source.required or false;
      enabledByDefault = source.enabledByDefault or false;
    }
