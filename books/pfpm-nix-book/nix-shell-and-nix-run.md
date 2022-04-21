---
title: "環境を汚さずにソフトウェアを試す"
---

Nix を使うと、普段使っているプロファイルにインストールすることなくソフトウェアを試すことができる。

# `nix shell`

ls オルタナティブ CLI の exa を試したいとする。

まず、exa が導入されていないことを確認する。

```shell
❯ which exa
exa not found
```

`nix shell` を実行する。

```
❯ nix shell nixpkgs#exa
```

実行すると、exa が環境に追加された状態の新しいシェルが開く。`exa` を実行してみよう。

```
❯ exa
atcoder  forks  fsp  github  haskell  labo  play      rust       rwhttp  table
fastify  fs     ghq  go      kyou     nix   rescript  rust_test  saty    work
```

exa はどこにあるのだろうか。

```shell
❯ which exa
/nix/store/wss2wlqvmcrrzvhdzqq19y91zlgwprsq-exa-0.10.1/bin/exa
```

Nix Store 上の実行ファイルを直接参照している。つまり、プロファイルには導入されていない。

# `nix run`

`nix run` を使うと、アプリケーションを直接実行できる。grep オルタナティブの ripgrep を試してみよう。なお、「--」 以降の引数は ripgrep に渡される。

```
❯ nix run nixpkgs#ripgrep -- --version
ripgrep 13.0.0
-SIMD -AVX (compiled)
+SIMD +AVX (runtime)
```

grep ですから、何か検索してみたい。`$PATH` をエントリ (`:` で区切られている) ごとに行で分割し、`exa` を含む行を抽出する、というのはどうだろう。

```shell
❯ echo $PATH | sed -e "s/:/\n/g" | nix run nixpkgs#ripgrep -- "exa"
/nix/store/wss2wlqvmcrrzvhdzqq19y91zlgwprsq-exa-0.10.1/bin
```

コードブロックでは伝えきれないのだが、ripgrep はマッチした箇所を赤く太字でハイライトしてくれる。

# `nix shell` の終了

`nix shell` を終了するには、普通にシェルを終了するのと同じく `^D` を入力するか `exit` コマンドを実行する。

# もっと読みたい

https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-run.html

https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-shell.html
