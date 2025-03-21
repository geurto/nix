{
  description = "My own Neovim flake";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    # Needed for GUI applications
    nixgl = {
      url = "github:nix-community/nixGL";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      neovim,
      flake-utils,
      ghostty,
      nixgl,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Overlays to change/extend nixpkgs
        overlayFlakeInputs = prev: final: {
          neovim = neovim.packages.${system}.neovim;
          nixgl = nixgl.packages.${system};
        };

        overlayNeovim = prev: final: {
          myNeovim = import ./packages/neovim {
            pkgs = final;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            overlayFlakeInputs
            overlayNeovim
          ];
        };

        deps = import ./packages/dependencies { inherit pkgs; };

        # Import Zsh configuration
        myZsh = import ./packages/zsh {
          inherit pkgs;
          deps = deps.packages;
        };

        # Import Ghostty configuration with nixGL support
        ghosttyWithZsh = import ./packages/ghostty {
          inherit pkgs;
          ghostty = ghostty.packages.${system}.default;
          deps = deps.packages;
        };
      in
      {
        packages = {
          default = pkgs.myNeovim;
          ghostty = ghosttyWithZsh;
          zsh = myZsh;
        };
        apps = {
          neovim = {
            type = "app";
            program = "${pkgs.myNeovim}/bin/nvim";
          };
          zsh = {
            type = "app";
            program = "${myZsh}/bin/zsh";
          };
          ghostty = {
            type = "app";
            program = "${ghosttyWithZsh}/bin/ghostty-wrapper";
          };
          default = self.apps.${system}.neovim;
        };
      }
    );
}
