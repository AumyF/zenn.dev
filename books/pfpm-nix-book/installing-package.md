---
title: "パッケージをインストールする"
---

このチャプターでは、`nix` コマンドを使って、環境にパッケージを追加したり削除したりする操作を学ぶ。

GNU Hello を導入してみよう。GNU Hello はとあるメッセージを出力するだけのごく簡単なパッケージだ。

```
❯ nix profile install nixpkgs#hello
```

この操作は `apt install hello` に相当する操作だ。

`hello` を実行しよう。

```
❯ hello
Hello, world!
```

これで GNU Hello が導入できた。

# プロファイル

GNU Hello がどこに導入されているか確認しよう。

```shell
❯ which hello
/home/u/.nix-profile/bin/hello # ユーザ名 u は人によって異なる
```

このパスにある `~/.nix-profile` があなたが今使用しているプロファイルだ。より正確には、`nix profile install nixpkgs#hello` 現在のプロファイルに `hello` パッケージをインストールするというコマンドだった。

`~/.nix-profile` はシンボリックリンクになっているので、リンク先をたぐっていく。

```shell
❯ readlink ~/.nix-profile
/nix/var/nix/profiles/per-user/u/profile

❯ readlink /nix/var/nix/profiles/per-user/u/profile
profile-77-link # 数 77 は人によって異なる

❯ readlink /nix/var/nix/profiles/per-user/u/profile-77-link
/nix/store/sym6apx2d35xdjabz1nnp79sxm7nzw28-profile
# sym6apx2d35xdjabz1nnp79sxm7nzw28 部分は人によって異なる
```

`profile-数-link` というディレクトリ名がある。

```shell
❯ readlink /home/u/.nix-profile/bin/hello
/nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10/bin/hello
```

ここが Nix Store の中にある、先ほどインストールした `hello` の実体だ。パッケージのアップグレードなどによって、具体的なディレクトリ名は異なっているかもしれない。

プロファイルにインストールしたパッケージの一覧を見てみよう。

```
❯ nix profile list
```

すると、

```
3 flake:nixpkgs#legacyPackages.x86_64-linux.hello github:NixOS/nixpkgs/5c37ad87222cfc1ec36d6cd1364514a9efc2f7f2#legacyPackages.x86_64-linux.hello /nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10
```

のような行が出力されてくる。非常に長いが、内容は単純なので落ち着いて読み進めていこう。

- `3` は要素の番号を表している。プロファイルは配列の形で管理されており、そのインデックスを表す。アップグレードやアンインストールの際に使う。
- `flake:nixpkgs#legacyPackages.x86_64-linux.hello` は `hello` をインストールしたときの `nixpkgs#hello` のロングバージョンだ。もちろん `x86_64` の部分と `linux` の部分は実行する環境によって `aarch64` や `darwin` など、変動する。
- `github:NixOS/nixpkgs/5c37ad87222cfc1ec36d6cd1364514a9efc2f7f2#legacyPackages.x86_64-linux.hello` は実際にインストールした `hello` のバージョンを示している。この場合、上と比較すると GitHub リポジトリ NixOS/nixpkgs の特定のコミットを指し示す記述が増えている。
- `/nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10` は先ほど出てきた Nix Store にある `hello` の実体のパスだ。

パッケージをアップグレードするには `nix profile upgrade インデックス` コマンドを実行する。

```
❯ nix profile upgrade 3
```

おそらく、何も起こらないだろう。先ほどインストールしたばかりで、次のバージョンが登場していないからだ。

最後に、`hello` をプロファイルから除去する。`nix profile remove インデックス` と打つ。

```
❯ nix profile remove 3
```

`hello` を打って、`zsh: command not found: hello` などが出たらアンインストールは完了だ。`which hello` `nix profile list` `ls /home/u/.nix-profile/bin` といったコマンドで確認してもよい。

次の章に行く前に、Nix Store を確認しておく。

```
❯ ls /nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10
bin  share
```

プロファイルからは除去されたが、Nix Store からは削除されていないことがわかる。

# もっと読みたい

https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile.html
