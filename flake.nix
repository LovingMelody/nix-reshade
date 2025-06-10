{
  description = "Package ReShade & Shaders for nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = lib.attrNames nixpkgs.legacyPackages;
    forAllSystems2 = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    treefmtEval = forAllSystems2 (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    inherit (nixpkgs) lib;
  in {
    packages = forAllSystems2 (
      pkgs: let
        inherit (pkgs) system;
        mkShader = pkgs.callPackage ./packages/build-support/mkShader {};
        mkShaderFromSource = pkgs.callPackage ./packages/build-support/mkShaderFromSource {
          inherit mkShader;
        };
      in {
        reshade = pkgs.callPackage ./packages/reshade {};
        reshade-full = self.packages.${system}.reshade.override {withAddons = true;};
        reshade-shaders = pkgs.callPackage ./packages/reshade-shaders {inherit (self.packages.${system}) reshadeShaders;};
        reshade-shaders-full = self.packages.${system}.reshade-shaders.override {full = true;};
        reshadeShaders = import ./packages/reshade-shaders/shaders.nix {
          inherit mkShaderFromSource lib;
          sourceFile = ./sources.json;
        };
        d3dcompiler_47-dll = pkgs.callPackage ./packages/d3dcompiler_47.dll {};
        ipsuShaders = pkgs.callPackage ./packages/ipsuShaders {inherit mkShader;};
        test = self.packages.${system}.reshade-shaders.override {
          includeRequired = false;
          includeEnabled = false;
          includeByName = ["SHADERDECK by TreyM"];
        };
        complete = pkgs.symlinkJoin {
          name = "reshade-with-shaders";
          paths = with self.packages.${system}; [
            reshade-full
            reshade-shaders-full
            ipsuShaders
            d3dcompiler_47-dll
          ];
        };
      }
    );
    formatter = builtins.mapAttrs (_n: v: v.config.build.wrapper) treefmtEval;
    apps = forAllSystems2 (pkgs: let
      inherit (pkgs) system;
    in {
      default = {
        type = "app";
        program = lib.getExe (pkgs.writeShellScriptBin "update-script" ''
          PATH=${lib.makeBinPath [pkgs.nix-prefetch-git pkgs.nix-prefetch pkgs.nix pkgs.deno]}:$PATH
          git_root=$(${lib.getExe pkgs.git} rev-parse --show-toplevel)
          MANIFEST_PATH="$git_root/sources.json"
          EXTRA_SOURCES=${./extraSources.ini}
          ${lib.getExe pkgs.python3} ${./sources-generator.py}
          ${lib.getExe self.formatter.${system}}
        '');
      };
    });
  };
}
