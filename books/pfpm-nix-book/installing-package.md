---
title: "パッケージをインストールする"
---

Nix はパッケージマネージャですから、パッケージをインストールすることができます。GNU Hello を導入してみましょう。GNU Hello はとあるメッセージを出力するだけのごく簡単なパッケージです。

```
❯ nix profile install nixpkgs#hello
```

この操作は `apt install hello` に相当します。より正確に記すと「現在の **プロファイル** に **`nixpkgs`** という **flake** から `hello` パッケージをインストールする」という意味です。専門用語がいくつも出てきて混乱するかと思いますが、のちほど説明していきます。

`hello` を実行してみましょう。

```
❯ hello
Hello, world!
```

これで GNU Hello が導入できました。

GNU Hello がどこに導入されているか確認してみましょう。

```shell
❯ which hello
/home/u/.nix-profile/bin/hello
```

これはシンボリックリンクになっています。

```shell
❯ readlink /home/u/.nix-profile/bin/hello
/nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10/bin/hello
```

ここが Nix Store です。パッケージのアップグレードなどによって、具体的なディレクトリ名は異なっているかもしれません。

プロファイルにインストールしたパッケージの一覧を見てみましょう。

```
❯ nix profile list
```

すると、

```
3 flake:nixpkgs#legacyPackages.x86_64-linux.hello github:NixOS/nixpkgs/5c37ad87222cfc1ec36d6cd1364514a9efc2f7f2#legacyPackages.x86_64-linux.hello /nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10
```

のような行が出力されてきます。非常に長いので物怖じしてしまうかもしれませんが、内容は単純です。

- `3` は要素の番号を表しています。プロファイルは配列の形で管理されており、そのインデックスです。アップグレードやアンインストールの際に使用します。
- `flake:nixpkgs#legacyPackages.x86_64-linux.hello` は `hello` をインストールしたときの `nixpkgs#hello` のロングバージョンです。もちろん `x86_64` の部分と `linux` の部分は実行する環境によって `aarch64` や `darwin` など、変動します。
- `github:NixOS/nixpkgs/5c37ad87222cfc1ec36d6cd1364514a9efc2f7f2#legacyPackages.x86_64-linux.hello` は実際にインストールした `hello` のバージョンを示しています。この場合、上と比較すると GitHub リポジトリ NixOS/nixpkgs の特定のコミットを指し示す記述が増えています。
- `/nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10` は先ほど出てきた Nix Store の場所です。

パッケージをアップグレードするには以下のコマンドを実行します。

```
❯ nix profile upgrade 3
```

おそらく、何も起こらないでしょう。先ほどインストールしたばかりで、次のバージョンが登場していないからです。

最後に、`hello` をプロファイルから除去します。

```
❯ nix profile remove 3
```

`hello` を打って、`zsh: command not found: hello` などが出たらアンインストールは完了です。`which hello` `nix profile list` `ls /home/u/.nix-profile/bin` といったコマンドで確認してみましょう。

次の章に行く前に、Nix Store を確認しておきます。

```
❯ ls /nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10
bin  share
```

プロファイルからは除去されましたが、Nix Store からは削除されていません。
