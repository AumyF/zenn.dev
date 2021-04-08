{ pkgs ? import <nixpkgs> {
    inherit system;
  }
, system ? builtins.currentSystem
}:

let
  nodePackages = import ./default.nix {
    inherit pkgs system;
  };
in
nodePackages // {
  zenn-cli = nodePackages.zenn-cli.override {
    buildInputs = with pkgs; [ pkgconfig vips ];
  };
}
