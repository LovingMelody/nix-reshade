# nix-shade

Flake packaging [reshade](https://reshade.me/) & shaders

## Whats Here

| Package                                            | Description                                        |
| -------------------------------------------------- | -------------------------------------------------- |
| [reshade](./packages/reshade)                      | ReShade without addons                             |
| [reshade-full](./packages/reshade)                 | ReShade with addons (not intended for online play) |
| [reshade-shaders](./packages/reshade-shaders)      | Default ReShade shaders                            |
| [reshade-shaders-full](./packages/reshade-shaders) | All ReShade shaders defined in EffectPackages.init |

## Install

### Not using flakes? [go here](#nix-stable) or [learn](https://thiscute.world/en/posts/nixos-and-flake-basics/)

### ❄️ Flakes

Add these packages to `home.packages` or `environment.systemPackages` after
adding `nix-reshade` as an input:

```nix
# flake.nix
{
  inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     home-manager.url = "github:nix-community/home-manager";

     nix-reshade.url = "github:LovingMelody/nix-reshade";
     # Optional, probably best to not to prevent pointless rebuilds
     # nix-reshade.inputs.nixpkgs.follows = "nixpkgs"
  };
  outputs = {self, nixpkgs, ...}@inputs: {
    # NixOS
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        # ...
      ];
    };

    # Home Manager
    homeConfigurations.HOSTNAME = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {inherit inputs;};

      modules = [
        ./home.nix
        # ...
      ];
    }
  };
}
```

Add the package(s):

```nix
{ pkgs, inputs, ...}:  {
  environment.systemPackages = [ inputs.packages.${pkgs.system}.<package> ];
}
```

### Nix Stable

Note: I don't test against this

```nix
{pkgs, ...}: let
  nix-reshade = import (builtins.fetchTarball "https://github.com/fufexan/nix-reshade/archive/main.tar.gz");
in {
  # install packages
  environment.systemPackages = [ # or home.packages
    nix-reshade.packages.${pkgs.hostPlatform.system}.<package>
  ];
}
```

## Configuring

### reshade-shaders

Shaders have options to control whats saved

Full list can be found here:
[EffectPackages.ini](https://github.com/crosire/reshade-shaders/blob/list/EffectPackages.ini)

```nix
{
  includeRequired ? true,   # include shaders marked as required upstream
  includeEnabled  ? true,   # include shaders enabled by default upstream
  includeByName   ? [],     # specify the name of the shader for install
  blacklist       ? [],     # Filter out a specific shader by name
  full            ? false,  # Install everything
}
```

Example

```nix
nix-reshade.packages.${system}.reshade-shaders.override {
    includeRequired = false;
    includeEnabled = false;
    includeByName = ["SHADERDECK by TreyM"];
};
```

## Updating

Package can be updated with

```bash
nix run .
```

## Tips

ReShade requires
[d3dcompiler_47.dll](https://lutris.net/files/tools/dll/d3dcompiler_47.dll") for
Final Fantasy XIV (probably other games)

```nix
# home.nix
# ...
home.file."Games/my-game/dxgi.dll".source = "${packages.${system}.reshade-full}/lib/reshade/Reshade64.dll"
home.file."Games/my-game/d3dcompiler_47.dll".source = "${packages.${system}.d3dcompiler_47-dll}/lib/d3dcompiler_47.dll";
# ...
```
