---
title: "node2nix: Wrangler 2 をビルドする"
---

このチャプターでは、node2nix というツールを使用して、Node.js アプリケーションを Nix パッケージにする方法を学びます。`buildGoModule` と異なり、node2nix では `node2nix` という CLI を用いて Nix のコードを生成するという方法で Nix パッケージを生成します。Nix に他言語のパッケージシステムを持ち込む際、コード生成はよく選択される手段です。
