{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      mkSystem = hostName: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit hostName; };
        modules = [
          {
            nix.registry = {
              nixpkgs.flake = nixpkgs;
              nixpkgs-unstable.flake = nixpkgs-unstable;
            };
            nixpkgs.overlays = [ overlay-unstable ];
            system.configurationRevision = self.rev or "dirty";
          }
          (./hosts/${hostName} + ".nix") # rnix-lsp complains about this.
          ./common.nix
          ./modules/dunst.nix
          ./modules/i3status-rust.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        iron = mkSystem "iron";
        kevlar = mkSystem "kevlar";
      };
    };
}
