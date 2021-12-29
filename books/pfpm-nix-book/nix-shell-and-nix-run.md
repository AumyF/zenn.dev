---
title: "環境を汚さずにソフトウェアを試す"
---

Nix を使うと、普段使っているプロファイルにインストールすることなくソフトウェアを試すことができます。

# `nix shell`

ls オルタナティブ CLI の exa を試してみましょう。

まず、exa が導入されていないことを確認します。

```shell
❯ which exa
exa not found
```

`nix shell` を実行します。

```
❯ nix shell nixpkgs#exa
```

実行すると、exa が環境に追加された状態の新しいシェルが開きます。`exa` を試してみます。

```
❯ exa
atcoder  forks  fsp  github  haskell  labo  play      rust       rwhttp  table
fastify  fs     ghq  go      kyou     nix   rescript  rust_test  saty    work
```

exa はどこにあるのでしょうか。

```shell
❯ which exa
/nix/store/wss2wlqvmcrrzvhdzqq19y91zlgwprsq-exa-0.10.1/bin/exa
```

プロファイルにインストールしたときとは異なり、Nix Store 上の実行ファイルを直接参照しています。

# `nix run`

`nix run` を使うと、アプリケーションを直接実行できます。grep オルタナティブの ripgrep を試してみましょう。

```
❯ nix run nixpkgs#ripgrep -- --version
ripgrep 13.0.0
-SIMD -AVX (compiled)
+SIMD +AVX (runtime)
```

grep ですから、何か検索してみます。`$PATH` をエントリごとに行で分割し、`exa` を含む行を抽出します。

```shell
❯ echo $PATH | sed -e "s/:/\n/g" | nix run nixpkgs#ripgrep -- "exa"
/nix/store/wss2wlqvmcrrzvhdzqq19y91zlgwprsq-exa-0.10.1/bin
```

いい感じですね。
