---
title: "Nixを導入する"
---

Nix は一般的な Linux ディストリビューションと macOS に対応しています。また、NixOS を導入すれば最初から Nix を使用することができます。

# Linux に Nix を導入する

以下のコマンドを実行すると、Nix のインストールスクリプトをダウンロードし、実行します。

```shell
❯ curl -L https://nixos.org/nix/install | sh
```

:::message
この本において、`❯` はシェルのプロンプトを表します。
:::

# macOS に Nix を導入する

macOS Catalina 以降でルートファイルシステムが read-only になった影響で、macOS への Nix インストールはやや煩雑になってしまいました。

# NixOS を導入する

[KDE Plasma デスクトップ環境が導入された NixOS の VirtualBox OVA ファイル](https://nixos.org/download.html#nixos-virtualbox) が配布されています。

---

`nix --version` を実行してみましょう。以下のような出力が表示されたらインストールは完了です。

```shell
❯ nix --version
nix (Nix) 2.4
```
