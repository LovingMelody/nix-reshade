{pkgs}: {
  reshade = pkgs.callPackage ./reshade {};
  reshade-full = pkgs.callPackage ./reshade {withAddons = true;};
  reshade-shaders = pkgs.callPackage ./reshade-shaders {};
  reshade-shaders-full = pkgs.callPackage ./reshade-shaders {full = true;};
}
