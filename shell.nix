{ pkgs ? import <nixpkgs> {
    inherit system;
  }
, system ? builtins.currentSystem
}:
let
  zenn-cli = import ./zenn-cli.nix {
    inherit pkgs system;
  };
in
pkgs.mkShell {
  nativeBuildInputs = [
    zenn-cli.zenn-cli
  ];
}
