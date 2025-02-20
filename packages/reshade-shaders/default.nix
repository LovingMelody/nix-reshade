{
  lib,
  symlinkJoin,
  includeRequired ? true,
  includeEnabled ? true,
  includeByName ? [],
  blacklist ? [],
  full ? false,
  reshadeShaders,
  ...
}: let
  filteredShader = n: v:
    (full
      || (v.passthru.required && includeRequired)
      || (builtins.elem n includeByName)
      || (v.passthru.enabledByDefault && includeEnabled))
    && (! builtins.elem n blacklist);
in
  symlinkJoin {
    name = "reshade-shaders";
    paths = lib.attrsets.mapAttrsToList (_n: v: v) (lib.attrsets.filterAttrs filteredShader reshadeShaders);
  }
