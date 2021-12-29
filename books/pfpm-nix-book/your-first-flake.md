---
title: "はじめてのFlake、はじめてのNix expression"
---

これまでの章では、Nix を apt や yum、pacman のようなパッケージマネージャとして使ってきました。これからの章では、**Nix Expression Language** を使い、実際に Nix パッケージを書いていきます。まずはじめに、自分で書いた C 言語のプログラムを、Nix 経由でビルドしてみましょう。

# Flake とは

Nix 2.4 で Nix Flakes という新しい Nix プロジェクトの管理方法が導入されました。Nix Flakes において「**flake**」とは `flake.nix` **というファイルを含んだディレクトリ** のことを指します。`flake.nix` は簡単にいえば、Cargo でいう `Cargo.toml`、npm でいう `package.json` のようなもので、プロジェクトがどのパッケージに依存しているか、プロジェクトがどのようなパッケージを提供しているかなどを書きます。

新しく flake を作るには

```
❯ nix flake init
```

を実行すると、`flake.nix` が生成されます。その内容は以下のようになっているはずです。

```nix
{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;

  };
}
```

これが Nix expression です。どこか JSON のような印象を受けるかもしれません。まずこのファイルを元に、Nix expressions の文法を説明していきます。

# Set

JSON でいうオブジェクト、他の言語ではハッシュマップやレコードと呼ばれる連想配列の形をした `{}` は、Nix ではセット (Set) と呼ばれます。Nix ファイルはトップレベルに単一の式を置きますが、`flake.nix` ではこのようなセットを置く必要があります。

キーとバリューを区別する記号は `=` で、キーバリューペアどうしの区切りは `;` で行います。セットのプロパティにアクセスする場合は JavaScript などと同じように `foo.bar` で行います。また、`foo.bar = 42` のように書かれている部分は `foo = { bar = 42 }` の略記法です。

# 関数

Nix では関数は第 1 級の値であり、すべてが無名関数です。関数の文法は少し独特で、`引数:本体` という形をしています。

引数部に `{ self, nixpkgs }` というような文法は Nix において頻出で、「引数としてセットを受け取り、`self` `nixpkgs` を分解して使う」という意味です。JavaScript でいう分割代入、レコードに対するパターンマッチといえるでしょう。

# Flake をビルドする

`nix build` で、flake に含まれるパッケージをビルドできます。

```
❯ nix build
warning: creating lock file '/home/u/kyou/2021/12/29/nix/flake.lock'
```

「creating lock file」という表示が出てきていますね。`flake.lock` ファイルは flake が依存している物体 ^[flake など。flake に限らないので物体という書き方をしています。] の詳細なリビジョンを保存する役割をもつ、いわゆるロックファイルです。Cargo でいう `Cargo.lock`、npm でいう `package-lock.json` ですね。

```json:flake.lock
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1640418986,
        "narHash": "sha256-a8GGtxn2iL3WAkY5H+4E0s3Q7XJt6bTOvos9qqxT5OQ=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "5c37ad87222cfc1ec36d6cd1364514a9efc2f7f2",
        "type": "github"
      },
      "original": {
        "id": "nixpkgs",
        "type": "indirect"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

この flake は nixpkgs に依存しているため `nixpkgs` があります。

さて、`nix build` に戻りましょう。`nix build` の実行によって、`result` というシンボリックリンクが生成されたことが確認できるはずです。

```shell
❯ ls -l
total 8
-rw-r--r-- 1 u u 508 Dec 29 17:09 flake.lock
-rw-r--r-- 1 u u 229 Dec 29 16:48 flake.nix
lrwxrwxrwx 1 u u  54 Dec 29 17:09 result -> /nix/store/xcp9cav49dmsjbwdjlmkjxj10gkpx553-hello-2.10
```

この `result` というシンボリックリンクは文字通りビルド結果のある Nix store を指し示しています。

`result` をたどって `hello` を実行しましょう。

```
❯ result/bin/hello
Hello, world!
```
