{
  description = "nix-dell machine configuration";
  inputs.nix-bitcoin.url = "github:erikarvstedt/nix-bitcoin/bitcoind-mutinynet";
  outputs = { self, nix-bitcoin  }: {
    nixosConfigurations = {
      nix-dell = nix-bitcoin.inputs.nixpkgs.lib.nixosSystem {
        modules = [
          nix-bitcoin.nixosModules.default
          ./configuration.nix
#          (nix-bitcoin + "/modules/presets/secure-node.nix")
        ];
      };
    };
  };
}

