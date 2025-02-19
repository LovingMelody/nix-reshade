{
  description = "Package ReShade & Shaders for nix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = function: builtins.mapAttrs function nixpkgs.legacyPackages;
    inherit (nixpkgs) lib;
  in {
    packages = forAllSystems (
      system: pkgs: {
        reshade = pkgs.callPackage ./packages/reshade {};
        reshade-full = pkgs.callPackage ./packages/reshade {withAddons = true;};
        reshade-shaders = pkgs.callPackage ./packages/reshade-shaders {};
        reshade-shaders-full = pkgs.callPackage ./packages/reshade-shaders {full = true;};
        complete = pkgs.symlinkJoin {
          name = "reshade-with-shaders";
          paths = with self.packages.${system}; [reshade-full reshade-shaders-full];
        };
        test = self.packages.${system}.reshade-shaders.override {
          includeRequired = false;
          includeEnabled = false;
          includeByName = ["SHADERDECK by TreyM"];
        };
        update-script = pkgs.writeShellScriptBin "update-script" ''
          git_root=$(${lib.getExe pkgs.git} rev-parse --show-toplevel)
          MANIFEST_PATH="$git_root/sources.json"
          ${lib.getExe pkgs.python3} ${./sources-generator.py}
          ${lib.getExe self.formatter.${system}}
        '';
      }
    );
    formatter = let
      config = pkgs: (pkgs.writeText "treefmt-config.toml"
        ''
          [formatter.alejandra]
          command = "${lib.getExe pkgs.alejandra}"
          excludes = []
          includes = ["*.nix"]
          options = []


          [formatter.black]
          command = "${lib.getExe pkgs.python3Packages.black}"
          excludes = []
          includes = ["*.py", "*.pyi"]
          options = []

          [formatter.deadnix]
          command = "${lib.getExe pkgs.deadnix}"
          excludes = []
          includes = ["*.nix"]
          options = ["--edit", "--no-lambda-pattern-names"]

          [formatter.deno]
          command = "/nix/store/k9rjv96rpcb44w8wfjdyfis509qsmf7m-deno-2.1.10/bin/deno"
          excludes = []
          includes = [
              "*.css",
              "*.html",
              "*.js",
              "*.json",
              "*.jsonc",
              "*.jsx",
              "*.less",
              "*.markdown",
              "*.md",
              "*.sass",
              "*.scss",
              "*.ts",
              "*.tsx",
              "*.yaml",
              "*.yml",
          ]
          options = ["fmt"]

          [formatter.isort]
          command = "${lib.getExe pkgs.python3Packages.isort}"
          excludes = []
          includes = ["*.py", "*.pyi"]
          options = []

          [global]
          excludes = [
              "*.lock",
              "*.patch",
              "package-lock.json",
              "go.mod",
              "go.sum",
              ".gitignore",
              ".gitmodules",
              ".hgignore",
              ".svnignore",
          ]
          on-unmatched = "warn"
        '');
    in
      forAllSystems (_system: pkgs:
        pkgs.writeShellScriptBin "formatter" ''
          unset PRJ_ROOT
          ${lib.getExe pkgs.treefmt} \
             --config-file ${(config pkgs)} \
             --tree-root-file=flake.nix \
             "$@"
        '');
    apps = forAllSystems (system: _pkgs: {
      default = {
        type = "app";
        program = lib.getExe self.packages.${system}.update-script;
      };
    });
  };
}
