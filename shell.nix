{ pkgs ? import <nixpkgs> {
    inherit system;
  }
, system ? builtins.currentSystem
, zenn-channel ? import <zenn-cli> {}
}:
pkgs.mkShell {
  nativeBuildInputs = [
    zenn-channel.zenn-cli
  ];
}
