---
title: "Nixを導入する"
---

Nix は一般的な Linux ディストリビューションと macOS に対応している。また、NixOS を導入すれば最初から Nix を使用することができる。

# Linux に Nix を導入する

以下のコマンドを実行すると、Nix のインストールスクリプトをダウンロードし、実行する。もちろん、一回スクリプトをファイルに保存し、中身を精査してから実行してもよい。

```shell
❯ curl -L https://nixos.org/nix/install | sh
```

:::message
この本において、`❯` はシェルのプロンプトを表す。
:::

インストールスクリプトは `~/.profile` に以下の内容を追記する。

```shell:~/.profile
if [ -e /home/u/.nix-profile/etc/profile.d/nix.sh ]; then . /home/u/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
```

# macOS に Nix を導入する

macOS Catalina 以降でルートファイルシステムが read-only になった影響で、macOS への Nix インストールは煩雑になってしまった。この本では macOS での導入方法は扱わない。

# NixOS を導入する

[KDE Plasma デスクトップ環境が導入された NixOS の VirtualBox OVA ファイル](https://nixos.org/download.html#nixos-virtualbox) が配布されているので、それを使うとインストール作業が不要で NixOS を使い始めることができる。

---

`nix --version` を実行して、以下のようにバージョンが出力されたらインストールは完了だ。

```shell
❯ nix --version
nix (Nix) 2.4
```

# もっと読みたい

https://nixos.org/manual/nix/stable/installation/installing-binary.html

https://nixos.org/guides/nix-pills/install-on-your-running-system.html
