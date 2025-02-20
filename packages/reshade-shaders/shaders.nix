{
  mkShaderFromSource,
  lib,
  sourcesFile ? ../../sources.json,
  ...
}: let
  inherit (lib.strings) sanitizeDerivationName;
  inherit (lib.attrsets) mapAttrs mapAttrs' nameValuePair;
  inherit (lib.trivial) importJSON;
  sources = mapAttrs' (n: v: nameValuePair (sanitizeDerivationName n) v) (importJSON sourcesFile).shaders;
in
  mapAttrs (_name: source: mkShaderFromSource {inherit source;}) sources
