---
title: "TypeScriptで代数的データ型入門"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["TypeScript", "関数型プログラミング", "Rust", "Elm"]
published: false
---

**代数的データ型** (Algebraic Data Type) は関数型プログラミング言語によくある言語機能です。何ができるかというと… _直和の直積_ と言うのはかんたんなんですけど…実際のコード例を見たほうがよいでしょう。

# n 個の値をもつ型

n 個の値をもつ型

## 1 個の値をもつ型

1 個の値をもつ型は意外とありふれています。もっとも代表的なものが `null` ですね。TS なら `undefined` も加わります。

```ts
const hoge: null = null;
const fuga: undefined = undefined;
```

`null` を直接型に書ける言語もそう多くないかもしれませんね。

関数型とよばれる言語では `null` の代わりに空タプルや空リストを使うことが多いです。例は Rust ですが Scala や Haskell もたしかそうです。

```rust
let point: (i32, i32) = (4, 2); // 2要素タプル
let unit: () = (); // 空タプル
```

TypeScript では配列を使ってタプルっぽいことが実現でき、`[]` あるいは `never[]` 型が唯一の値 `[]` をもつ型になります。

さらに TypeScript には **リテラル型** というヤバげな機能があります。`42` とか `"hello"` といった数値や文字列リテラルそのものを型にでき、もちろん `42` 型には `42` しか割り当てることができません。つまり、型のもつ値が 1 つなんですね。数値が小数ふくめたくさん、文字列がなんかすごいたくさんあって凄まじい数の $1$ 型をつくることができますね。

$1$ 型の `undefined` と `null` を相互変換する関数を書いてみましょう。

```ts
const from = (und: undefined) => null;
const to = (nul: null) => undefined;
```

ところでこの関数を 2 個つなげて値を渡すと元に戻りますよね。

```ts
from(to(null)); // => null
to(from(undefined)); // => undefined
```

:::details パイプライン演算子を使うと
TC39 で ECMAScript 仕様に入れるか検討中のパイプライン演算子を使うとこんな感じでたくさん関数を連ねて書くことができます。

```ts
undefined |> from |> to |> from |> to |> from |> to; // undefined
null |> to |> from |> to |> from |> to |> from; // undefined
```

どれだけ重ねても情報のロスなくもとの値に戻っていることがわかります。

パイプライン演算子もっと有名になって入れてほしいの声が増えてくれないかな～～という宣伝でした。
:::

これは数学的に型を集合、関数`from`, `to`を射として考えて **同型** と呼びます。`null` と `undefined` がそれぞれ持てる情報量はどちらも 1 つです。

もちろん `"hello"` と `undefined` と `42` と `[]` も同型です。

## 0 個の値をもつ型

数学的な文脈だと _0 個の値をもつ型_ というような言い回しが頻出することかと思いますが、 **値をもたない** ということです。値をもたない型なんてあるのかと思いたくなりますが TypeScript を書いているとわりと遭遇することができます。`never` 型と呼ばれており、おおよその意味合いは「そこに値が割り当てられることは **ありえない**」です。

必ず `throw` する関数は正常終了して値を返すことが絶対にありえないため返り値の型は `never` です。

```ts
// () => never
const panic = () => {
  throw new Error();
};
```

またはロジック上そこを通ることがありえない場合には変数が `never` になります。これは制御フロー解析といって `if(typeof hoge === "number") { }` が真のときの分岐では `hoge` を自動で `number` 型に推論してくれるおばけのような機能です。このコードでは `strOrNum` が `string` `number` である以上 `switch` のアームは上 2 つのどっちかに必ずヒットするため `default` 節が走ることはありえない^[`any` を渡す不届き者がいた場合は別です]とコンパイラが理解してくれます。

```ts
const fuga = (strOrNum: string | number) => {
  switch (typeof strOrNum) {
    case "string":
      return strOrNum.length; // ここではstring
    case "number":
      return strOrNum; // number
    default:
      console.log(strOrNum); // never(ここは通らないはず)
      return 0;
  }
};
```

## 2 個の値をもつ型

TypeScript に限らず「2 個の値をもつ型がある」言語は非常に多いです。C でも Java でも Rust でも Ruby でも存在します。そうです、boolean (真偽値) 型です。あれは `true` か `false` で、それ以外の値をとることはありません。

# 列挙型

最初の例は Rust です。いきなり関数型か微妙なラインですが、少なくとも代数的データ型は関数型のそれだと思います。

IP(Internet Protocol) には v4 と v6 の 2 バージョンがあり、IP アドレスにも 2 つバージョンがありますよね。これをコードで表現してみましょう。

```rust
enum IPAddr {
	V4,
	V6,
}
```

`V4`, `V6` という新しい値と、2 つを含む集合 (型) として `IPAddr` を定義しました。1 個で IPv4, IPv6 の両方に ping できる関数はこんな感じで書けそうです。

```rust
fn ping(ip_version: IPAddr, ip_address: String) {
	match(ip_version) {
		IPAddr::V4 => ping4(ip_address),
		IPAddr::V6 => ping6(ip_address),
	}
}
```
