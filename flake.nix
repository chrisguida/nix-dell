{
  description = "nix-dell machine configuration";
#  inputs.nix-bitcoin.url = "github:erikarvstedt/nix-bitcoin/bitcoind-mutinynet";
  inputs.nix-bitcoin.url = "github:chrisguida/nix-bitcoin/no-err-zero-feerate";
  inputs.vscode-server.url = "github:nix-community/nixos-vscode-server";
  inputs.nixpkgs.follows = "nix-bitcoin/nixpkgs";
  outputs = { self, nix-bitcoin, nixpkgs, vscode-server }: {
    nixosConfigurations = {
      nix-dell = nix-bitcoin.inputs.nixpkgs.lib.nixosSystem {
        modules = [
          nix-bitcoin.nixosModules.default
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
          ./configuration.nix
#          (nix-bitcoin + "/modules/presets/secure-node.nix")
        ];
      };
    };
  };
}

