---
title: "Nix Expression Language の文法"
---

前のチャプターでは、簡単な Nix Expression を書いて、C 言語のプログラムをビルドしました。このチャプターでは、Nix Expression のより詳細な文法に踏み込んで説明し、NixOS/nixpkgs などのパッケージ定義を読み解けるようにします。

Nix の REPL を起動するには `nix repl` を実行します。

```
❯ nix repl
Welcome to Nix 2.4. Type :? for help.

nix-repl>
```

:::message
`nix-repl>` は Nix REPL のプロンプトです。
:::

# 基本

# 基本的な型とリテラル

Nix は動的型付け言語です。関数に渡す値や、関数から返す値の型は実行時まで確定しません。この節では、型ごとにリテラル表現を示します。

## `Boolean` 真偽値

`Boolean` 型は一般的な真偽値を表し、`true` か `false` のどちらかの値をとります。`if` や `assert` で使われます。

## `integer` 整数

`integer` 型は整数を表します。64bit 符号付き整数で、`-9223372036854775807` から `9223372036854775807` までが使用可能です。

## `float` 浮動小数点数

`float` 型は浮動小数点数を表します。

## `string` 文字列

文字列リテラルには 3 つの種類があります。

### ダブルクオート

`"hoge fuga"` のようにダブルクオートで囲う形式の文字列です。`\` によるエスケープが可能で、また `${式}` によって式を埋め込むことができます。

```nix
let x = "3"; in "${x} apples"
```

- `list` リスト
- `set` セット
- `path` パス
- `function` 関数
- `null`
