---
title: nullとundefinedを祓う技術 / TypeScript 4.1
type: tech
topics: [TypeScript, JavaScript]
emoji: 🈚
published: false
---

「[Null 安全でない言語は、もはやレガシー言語だ](https://qiita.com/koher/items/e4835bd429b88809ab33)」と言われて 4 年が経ちましたが、みなさんいかがお過ごしでしょうか？Null 安全してますか？それとも `undefined is not a function` とか `Cannot read property 'foo' of undefined` みたいな実行時エラーに頭を悩ませていますか？4 年間で ECMAScript の数字がいくつ上がったかご存知ですか？4 年間で TypeScript の機能がどれくらい便利になったか把握できていますか？

この 4 年の間に TypeScript は勢力を拡大し、JavaScript の世界でも **Null 安全** が浸透してきたことと思います ^[(実務やったことないので) 知らんけど]。JavaScript の規格である ECMAScript は毎年の改定により機能が増え、それに合わせて TypeScript の Null 安全機能も大きく進化してきました。本記事では 2020 年末時点での TypeScript 4.1 で使える、null と undefined をどうにかするための言語機能を網羅的に紹介していきます。

# 読むのに必要な知識 / この記事で扱わない内容

- 基礎的な JavaScript の知識
  - ECMAScript 2015 程度
  - `let` `const` `() => {}` (アロー関数) などの機能を断りなく使います
  - わかんないことがあったら [JSPrimer](https://jsprimer.net) を読むといいと思います
- 静的型と TypeScript の超基礎的な知識
  - TypeScript を使うと JavaScript に静的型チェックを導入できます
  - 難しい型については本記事で説明します

:::message
TypeScript の動作を確かめたいときは Web 上で試せる [TypeScript Playground](https://typescriptlang.org/play/) をおすすめします。CLI では ts-node, Deno が使えます。
:::

## ソースコード中の絵文字について

- 「💥」は実行時エラーです。コードを実行すると `TypeError` などのエラーが発生します
  - 実際にプログラムを運用している最中に発生して異常終了等を招くので、プログラムを書く上では可能な限り避けたいものです
  - 未定義動作ゾーンに突入して鼻から悪魔が出る状態になるよりはマシです
- 「❗」はコンパイルエラーです。TypeScript→JavaScript のトランスパイル時に `tsc` が出力します
  - 実際に運用する前に発生し、実行時エラーを事前に告知する役割があります

# Null 安全とは

**Null チェック (値が Null でないことの確認) を強制** することで、Null (および nil, None などの虚無値) による **実行時エラー** を起こさせない仕組みのことです。

「無効かもしれない値」を型で表現する、というアイデアは Option や Maybe と呼ばれ、ML, Haskell, Elm, PureScript, OCaml などの関数型言語では長く使われてきました。それが近年では Swift, Rust, Kotlin, Dart といったマルチパラダイム言語に導入されて注目されてきたわけです。

TypeScript にもバージョン 2.0 でコンパイラオプション `--strictNullChecks` により Null 安全が導入されました。`--strictNullChecks` は各種の厳格なチェックを有効化する `--strict` オプションに含まれており、`tsc --init` で生成された `tsconfig.json` でもこちらが有効化されているので、普通にやれば TypeScript は Null 安全な状態でセットアップされるはずです。

## ぬるぽ

大前提として、JavaScript では `null` `undefined` へのプロパティアクセスや関数としての呼び出しを試みると `TypeError` が発生します。Java のぬるぽ^[ｶﾞｯ] (`java.lang.NullPointerException`) に相当します。

```js:JavaScript
const str = null;
str.toUpperCase();
// 💥 TypeError: Cannot read property 'toUpperCase' of null
```

## 型安全だけど Null 安全じゃない

`--strictNullChecks` をオンにしていない (**Null 安全でない**) TypeScript で変数 `str` に `string` という型注釈をつけると、 `number` などの関係ない型の値を代入することは不可能になります。静的型付け言語としてみれば普通の挙動ですね。

```ts:Null安全じゃないTypeScript
const str: string = 42;
// ❗ Type 'number' is not assignable to type 'string'. (2322)
```

ですが、Null 安全でない状態では、`string` 型の変数に `null` `undefined` を代入することができます。**できてしまいます**。`null` や `undefined` が変数に入った状態でメソッドを呼び出したらどうなるかはもはや言うまでもありません。

```ts
const str: string = null;
str.toUpperCase();
// 💥 TypeError: Cannot read property 'toUpperCase' of null
```

これで何が悪かったのかはもうおわかりでしょう。**`string` 型に `null` が代入可能であることが間違っている** のです。`null` `undefined` は `toUpperCase()` といった `string` の機能が使えないにもかかわらず、`string` 型の一員として認められているのです。これは Java などの非 Null 安全言語が犯している大きな過ちで、世界の歪みです。Null 安全言語はこの歪みを破壊します。

## 型安全かつ Null 安全

`--strictNullChecks` を有効にし、**Null 安全になった** TypeScript で同じコードを実行すると、コンパイルエラーになります。Null 安全な TypeScript では、もはや `null` は `string` 型ではありませんから、`string` 型の変数に `null` を代入することはできなくなりました。この状態の `string` は null を含まないので **Null 非許容型** と呼ばれます。

```ts
const str: string = null;
// ❗ Type 'null' is not assignable to type 'string'. (2322)
str.toUpperCase();
```

`str` に `null` を代入したいときは `null` との Union 型をとります。これは `string` 型の値か `null` を割り当てることができる型です。`null` を許容するので **Null 許容型** 、あるいは **Nullable** とも呼びます。

```ts
const str: string | null = null;
str.toUpperCase();
// ❗ Object is possibly 'null'. (2531)s
```

代入は問題なく行われましたが、`toUpperCase()` を呼び出そうとするとコンパイルエラーが発生します。`str` は `string` だけでなく `null` の可能性 (_possibly_) があります。`null` だった場合は先程の例のように実行時に `TypeError` が発生してしまいます。実行時エラーの可能性があるので、コンパイラは型チェックを通しません。

## null チェックをしよう

実行時エラーの可能性があるので型チェックが通らないのならば、実行時エラーの可能性をなくせば型チェックは通ってくれるわけです。`if` 文を使って Null チェックを行いましょう。

```ts
let str: string | null = null;

if (str !== null) {
  str.toUpperCase();
}
```

`str !== null` という条件により、`if` の中では `str` は `null` ではありません。TypeScript コンパイラ `tsc` はこのロジックを理解し、自動的に `str` の型 `string | null` から `null` を除去して `string` にします。

`null` に関するエラーはコンパイル時にチェックされ、実行時されるより前の段階で未然に防がれました。これが Null 安全です。

# Nullish を知る

JavaScript は珍しい言語で、虚無値が 2 つあります。`null` と `undefined` です。この 2 つをあわせて呼ぶ呼び方として、ぜんぜん普及していませんが **Nullish** という言葉を使います。これは `null` と `undefined` をうまく処理するための演算子 「Nullish Coalescing Operator」 に由来していますが、日本語訳が「Null 合体演算子」となっているので微妙に伝わりづらいのが悩みの種です。

## Null

`null` は値がないことを示すプリミティブ値です。`undefined` と異なり、関数の返り値として現れることはあっても JavaScript の構文から自然発生することはありません。

たとえば ECMAScript の `String.prototype.match()` や DOM API の `document.querySelector()` は `null` を返します。

ソースコード中の `null` は `null` という値を示すリテラルです。立派な予約語でありグローバル変数ではないので、`null` とかいう名前の変数を定義するようなことはできません。これは前フリです。

## Undefined とその出現場所

未定義であることを示す値です。`null` と違い `undefined` は JavaScript の構文から勝手に誕生することが多く、予期しないエラーはこちらで起こりやすいです。

`undefined` が出現するのは以下のような場面です。

- 宣言されているが初期化されていない変数
- オブジェクトの存在しないプロパティ
- 関数の省略された引数
- 何も返さない関数の返り値
- `void` 演算子
- Optional Chaining で nullish にアクセス

どうでもいい話ですがソースコード中の `undefined` は ECMAScript の組み込みオブジェクト、すなわちグローバル変数やグローバルオブジェクトのプロパティとも言えるものです。`globalThis.undefined` で `undefined` を得られます。ECMAScript 5 以降では仕様によりグローバル変数の `undefined` には再代入できませんが、`null` と違って予約語ではないのでグローバルでないスコープでは `undefined` という名前の変数を定義できます。もちろん推奨はされていません。

# TypeScript は Nullable をユニオン型で表現する

Kotlin や Swift では Nullable 型について `int?` というように `?` で書きますが、TypeScript では **Union 型** を使って `T | null` というように書きます。

Union 型は合併型、共用体型あるいは直和型とも呼ばれ、`A | B` 型は「`A` 型か `B` 型」という意味をもちます。`number | null` は数値か null なので、受け入れられる値は例えば `3.14` とか `42` とか `-Infinity` とか (`number`) と `null` です。型を値の集合として捉えれば Union 型は和集合 $\cup$ です。

Union 型は Nullish のみならず `string | number` というような使い方も可能です。JavaScript は動的型付け言語であるため 1 つの変数や引数が複数の型をとることががしばしばあり、そのようなものも含めて Union 型なら型をつけることができます。Python に mypy で型をつけるときも Union が使え、Nullable に相当する `Optional[Foo]` は `Union[Foo, None]` ^[Python の虚無値は `None` です] と同じだそうです。

## `NonNullable<T>` でユニオン型から Nullish を除去する

既存の Nullable な型を変形して Nullable でない型にしたい、という場面がよくあります。そんな時に便利なのが `NonNullable<T>` 型です。`NonNullable<T>` とすると `T` から `null` `undefined` を除去した型を返します。TypeScript に組み込みで用意されているので、TypeScript コードならどこでもインポート不要で使うことができます。

```ts
type Foo = number | null | undefined;
type NonNullFoo = NonNullable<Foo>;
// NonNullFoo = number
```

`lib.es5.d.ts` の `NonNullable<T>` の定義は以下です。

```ts:NonNullableの定義
type NonNullable<T> = T extends null | undefined ? never : T;
```

この型は TypeScript 2.8 で追加された Conditional Types を使っています。`T extends U ? X : Y` という構文で、`T` 型が `U` 型を満たしていたら `X` 型、そうでなかったら `Y` 型に解決されます。条件演算子みたいなものです。`NonNullable<T>` においては Union distribution という挙動を使っていい感じに Union 型から `null` `undefined` を除去しています。

Conditional Types そのものの使い方は覚えておかなくても大丈夫ですが、`NonNullable<T>` はとても便利なのでぜひ使っていきましょう。Conditional Types の詳しい情報は以下の記事が参考になります。

[TypeScript 2.8 の Conditional Types について - Qiita](https://qiita.com/Quramy/items/b45711789605ef9f96de)

:::message
Conditional Types に限らず TypeScript の高度な型は便利なユーティリティ型を表現するための低レイヤーな API だと思っています。`NonNullable<T>` そのものを実装するのではなく、`NonNullable<T>` を作るための道具を実装することで、それを使って `NonNullable` 以外にもいろいろな型を書くことができるというわけです。実際に Conditional Types を使ったユーティリティ型には関数の引数の型をタプルの形で得られる `Parameters<T>`, 関数の返り値の型を得られる `ReturnType<T>` などがあります。
:::

## `Nullable<T>` 型はどこ？ `number?` って書けないのはなんで？

TypeScript では `NonNullable<T>` はありますが `Nullable<T>` はありません。プロジェクトによって `null` 使わないとか `undefined` 使わないといった宗派があるためのようです。`number?` と書けないのも同様の理由によるものと思われます。それに型中での `?` は現状すでに Conditional Types が使っているのでパースがつらそうです。あと `Nullable<T>` についてはそもそも `T | null` のほうが短いです。

ところで、配列型なんかは `T[]` と `Array<T>` のどちらでも書けますね。あれについては、Union/Intersection 型 `P | Q` の配列は `(P | Q)[]` より `Array<P | Q>` のほうが読みやすい^[これは賛否あるかと思います] し、ネストした配列なら `Array<Array<Array<number>>>` より `number[][][]` のほうが読みやすい^[これは賛しかないかと思います]ところに使い分けのポイントがあると思います。一方で nullable の場合 `P | Q | null | undefined` とか `P & Q | null | undefined`^[union 型より intersection 型 `&` のほうが優先されます。一般常識にある和と積の順序と同じです] と書けます。ネストについては Union 型の規則で `A | A` は `T` にされるので `T | null | null` は `T | null` になりそもそも不可能です。

Nullable のネスト可否は Null 安全言語の間でも雰囲気が違うところで、ざっくり言うと代数的データ型で実現してる言語はネストできますがそれ以外では不可能な場合が多いです。TypeScript は説明したとおり Union なのでネスト不可能ですが、オブジェクト型とかを駆使して代数的データ型っぽいのを模倣し、ネストできる Option データ構造を作れます。これは本筋とあまり関係がないので後で触れます。

本記事中では `null` のほうを多用しているように見えるかもしれませんが、単純にスペルが長く手の動きが複雑で typo しやすい ~~`undefiend`~~ `undefined` を打つのがめんどくさいだけです。

ちなみに TypeScript コンパイラそのもの ([microsoft/TypeScript](https://github.com/microsoft/typescript)) の開発では `undefined` のみを使っています ([Coding guidelines - microsoft/TypeScript](https://github.com/Microsoft/TypeScript/wiki/Coding-guidelines#null-and-undefined))。ただしあくまで TypeScript コンパイラでのガイドラインであり、TypeScript の開発陣として「TypeScript を使った開発ではこのガイドラインに従え」と言っているわけではないので、あなたがどう使うかは自由です。ガイドラインの最初にはこのことが `<h1>` のクソデカ太字で 2 回も書いてあります。

# オブジェクトの省略可能なプロパティ `prop?: T`

オブジェクト型において、`プロパティ名?` で省略可能 (オプショナル) な型を表現できます。Swift や Kotlin の `Hoge?` になんとなく似ていますが、オブジェクト型のプロパティに使う構文ですから勘違いして `number?` と書かないように気をつけましょう。

```ts
type User = {
  name: string; // 省略不可 Required
  age?: number; // 省略可能 Optional
};

const bob = {
  name: "Bob",
  age: 16,
};

const alice: User = {
  name: "Alice",
  // 年齢不詳
};
```

オブジェクトの存在しないプロパティにアクセスした場合の値は `undefined` になるので、`age?: T` と定義したプロパティの実際の型は `T | undefined` になります。

## Mapped Types でプロパティの省略可否を操作する

既存のオブジェクト型のプロパティを省略可能・省略不能にしたバージョンがほしい、という場面では TypeScript 組み込みの `Partial<T>` と `Required<T>` を使います。

```ts:PartialとRequiredの定義
type Partial<T> = { [P in keyof T]?: T[P] };
type Required<T> = { [P in keyof T]-?: T[P] };
```

これに登場しているのが Mapped Types という機能です^[日本語訳はよくわかりません。型の写像とか言われたりもしますし、コンパイラはマップされたオブジェクト型と言ってたような気もします。]。`{ [P in K]: T }` で、「`K` 型をプロパティ名にもちプロパティの値が `T` である」型です。Mapped Types で `:` の前に `?` や `-?` を付けることで、プロパティを省略可能にしたり省略不能にしたりできます。

例によって Mapped Types がよくわからなくても `Partial<T>` と `Required<T>` というユーティリティ的な型が TypeScript 組み込みで用意されており、オブジェクト型のプロパティを省略可能にしたり不能にしたりするのが自在にできます。

# インデックスシグネチャの `| undefined` と `--noUncheckedIndexedAccess`

TypeScript の **インデックスシグネチャ (index signature)** はオブジェクトのキー (プロパティの名前) の型を指定する記法です。

```ts:文字列型のキーと数値型の値をもつオブジェクト
type StringRecord = {
  [key: string]: number;
};
```

この型には罠があります。実行時に存在しないキーにアクセスして `undefined` が返る可能性を無視しています。具体的なコードで示します。

```ts
const populations: StringRecord = {
  yokohama: 3.757,
  kawasaki: 1.539,
  sagamihara: 0.722,
};

// 🤬タイポしてる！！！！！！！！！
const yokohama = strRecord.yokohma;

// 🤬numberとして扱えちゃってる！！！！！！！
console.log(`人口は${yokohama * 100}万人を数える大都市`);
```

プロパティ名を打ち間違えて `yokohama` でなく `yokohma` の値を取得してしまっています。そんな名前のプロパティはないので実行時に変数 `yokohama` に入る値は `undefined` になり算術演算で `NaN` が爆誕して `人口はNaN万人を数える大都市` と出力されます。結局なん万人なんでしょうか。今回は算術演算なのでへんな出力が出る程度[要出典]で済みましたがプロパティアクセスとかしてたら `TypeError` になってたでしょう。

もっと身近な例を出すと ECMAScript の配列 (`Array`) 型もインデックスシグネチャで定義されています。

```ts
type Array<T> = {
  [index: number]: T;
  length: number;
  // 以降pop()、map()、flat()等のメソッド定義が続く
};

const names: Array<string> = ["Choso", "Eso", "Kechizu"];

const yuuji: string = names[3]; // 存在しないプロパティ 実際の値はundefined
```

Mapped Types `{ [P in K]: T }` の `K` が `string` `number` `string | number` になる場合も最終的な型が等価なインデックスシグネチャ (`{ [x: string]: T }` など) に書き換えられるためやはり同じ危険があります。これの代表例は TypeScript 組み込みの `Record<K, V>` 型です。

```ts
const record: Record<string, string> = {
  ja: "Japanese",
  en: "English",
  zh: "Chinese",
};

const de: string = record.de; // 実際はundefined
```

TypeScript 4.1 でこれらの問題を解決するコンパイラオプション `--noUncheckedIndexedAccess` が導入されました。`--noUncheckedIndexedAccess` が有効化されている場合、インデックスシグネチャによるアクセスで得られる値に `| undefined` が付きます。

```ts
// 実際の型は { [x: string]: string }
const record: Record<string, string> = {
  ja: "Japanese",
  en: "English",
  zh: "Chinese",
};

const de: string | undefined = record.de; // string | undefined
```

# タプルと empty

TypeScript では固定長の配列をタプルとして扱います。

```ts
type Tp = [string, number, boolean];
```

TypeScript 4.0 でタプル型の各要素にラベルをつけられるようになりました。あくまで型の上だけです。

```ts
type TpLabeled = [first: string, middle: number, last: boolean];
```

タプルのラベル付けは関数との相互変換のサポートとして導入されました。そのため、各要素のラベルは関数の引数として利用された時にのみ使われます。これは例えば、ラベルが違うタプル型でも型の並びが同じならまったく同じように扱えるということです。

```ts
const tpl: TpLabeled = ["hey", 192, true];
const tpl2: [head: string, body: number, tail: boolean] = tpl;
```

ここはオブジェクト型のキーとは大きく違う部分です。

ラベルに `?` をつけるとその要素は省略可能になり、型は `undefined` との Union 型になります。この省略は完全な省略で、`length` の型は `1 | 2` になります。

```ts
type ToStrParam1 = [num: number, radix?: number];
const a1: ToStrParam1 = [3, 10];
const b1: ToStrParam1 = [1];
```

`?` ではなく `undefined` との Union 型にした `ToStrParam2` を用意しました。これは一見 `ToStrParam1` と同じように見えますが、`length` が `2` で固定になっています。そのため `[1]` のような値は入れることができません。

```ts
type ToStrParam2 = [num: number, radix: number | undefined];
const a2: ToStrParam2 = [3, 10];
const b2: ToStrParam2 = [1];
// Type '[number]' is not assignable to type 'ToStrParam2'.
// Source has 1 element(s) but target requires 2.(2322)
```

JavaScript の配列には **empty item** という概念があります。empty は `length` のカウントには含まれるものの値は `undefined` すら入っていません。そのため `.forEach` や `.map` では無視されます。しかし `c2[1]` のようなプロパティアクセスを行うと「存在しないプロパティへのアクセスは `undefined`」の規則により `undefined` が返ります。ややこしいですね。

で、さらに、プロパティアクセスすると `undefined` になるので TypeScript では empty item は `undefined` 型扱いになります。そのため `[1,,].map()` のコールバック関数の引数は (本来 `undefined` が渡ることはないのに) `number | undefined` 扱いになります。面倒ですね。`map` で面倒だからといってこんな難解な仕様のために `empty` 型を導入するのもアレなので一定の妥協ではあると思います。とりあえずややこしいのでこれを使うのは控えたほうが良いと思います。

```ts
const c2: ToStrParam2 = [1, ,];
```

# 「Nullish 以外の値」を表す型

`null` `undefined` 以外ならどんな値でもいい、という場合には `{}` 型か `Object` 型を使います。`{}` は「プロパティを 0 個以上もつ型」、`Object` は「`Object` のインスタンス」です。字面での意味はまるっきり違いますがこの 2 つは本質的に同じ型です。

`{}` 型は JS の空のオブジェクトリテラル `{}` が指す値の型です。しかし TypeScript の型システムは構造的部分型なので「プロパティを 0 個以上もつオブジェクト」という解釈がなされ、`3` などのプリミティブ値も含めたあらゆる非 nullish 値が代入できます。

```ts
let bar: {} = {};
bar = 3;
bar = () => {};
bar = "チェンソーマン";
```

:::details プリミティブと構造的部分型についてもっと詳しく
`length` というプロパティをもっている型を定義します。

```ts
interface Length {
  length: number;
}
```

数値型の `length` プロパティをもつ値はわりと存在します。

```ts
const arr: Length = [1, 3, 5];
arr.length; // => 3

const fun: Length = (n: number) => n ** 2;
fun.length; // => 1

const str: Length = "Hello";
str.length; // => 5
```

`"Hello"` はプリミティブですがオブジェクトと同様に `length` にアクセスできるので `Length` を満たす値として扱えます。

:::

`Object` 型は「JS の組み込みオブジェクト `Object` のインスタンス (と同等の型)」を表します。TypeScript の値はプリミティブ含めてすべて `Object.prototype` を継承している `Object` のインスタンスなのでやはり nullish 以外ならなんでも代入できます。`Object` を継承しない値を `Object.create(null)` で作ることもできますが **TypeScript でそれの型を表現する手段がない** ので TypeScript に飼われている限りは気にする必要はありません。

ちなみに `@typescript-eslint` を推奨設定で使うと `{}` `Object` を使うなと言われます。「何らかの (プリミティブでない) オブジェクト」を表したいときに `object` を知らないと誤って `Object` `{}` を使ってしまいがちなのでこういう設定になっているものと思われます。これがウザい場合は `@typescript-eslint/ban-types` を無効化するか、`{}` とほぼ等価な型 `boolean | string | number | bigint | symbol | object` を外延的に書いてゴリ押す方法もあります (実はこちらのほうが型推論する上で有利に働くことがあります)。

# `unknown` 型は Nullish を内包している

`unknown` 型はトップ型とも呼ばれます。部分型関係の頂点に位置し、あらゆる型のあらゆる値を内包する型です。`unknown` 型の変数にはなんでも代入できますし、`unknown` を引数に取る関数にはなんでも渡せます。「あらゆる値」には nullish も含まれるため、Nullable とかどこにも書いてありませんが本質的には Nullable な型です。そのため素の状態ではほとんど何の操作もできません。

```ts
declare const u: unknown;

u.toString(); // ❗ Object is of type 'unknown'.(2571)
```

`unknown` 型は `{} | null | undefined` 型とほぼ同じ ^[実際は `{} | null | undefined` が `unknown` の部分型になっています。] ですが実際にユニオン型として定義されているわけではないので、`if (u != null)` といった「Nullish であることの否定」で `{}` 型を導く ^[ところでもしかしてこの手法って選言三段論法じゃないですか？] ことはできません。ほしい型があるなら `typeof u === "string"` や `u instanceof Date` のように直接言って推論させましょう。nullish だけ除去した `{}` を得たい場合は `u instanceof Object` すれば同等の `Object` を得られます。

# `void` 型

関数が「何も返さない」ことを示す型です。`return` が無い関数、`return;` で値を返さない関数が該当します。

```ts
const boido = (): void => {};
```

JavaScript の仕様上「何も返さない」といっても実際には `undefined` が返っていますから、`undefined` は `void` 型の値として使用できます。

```ts
const boido = (): void => undefined;
```

## `void` 演算子

実は `void` は ECMAScript の予約語で、これを使った `void` 演算子というものがあります。`void 何らかの式` と書くと `undefined` を得られるというものです。先ほど `undefined` に別の値が入っていることがある、という話をしましたが `void 0` のように `void` を使うとグローバル変数の `undefined` を使わず `undefined` 値を得ることができます。見た目と活用方法が直感的でなさすぎて、「JavaScript とかいう難解プログラミング言語」という話題で登場しがちです。

あとは、式を実行したいけど返り値は `undefined` であってほしい場面で使うそうです。式しか書けない場所で副作用のある関数を実行したいときに使う感じですかね？

```ts
const pop = (arr: unknown[]): void => void arr.pop();
```

この場合は

```ts
const pop = (arr: unknown[]): void => {
  arr.pop();
};
```

これでも十分じゃないかと思いますが。

# 値が nullish かを判別したい！

`if` や条件演算子 `?:` を使って Null チェックする場合、条件部分に真偽値を入れなければいけません、じゃあどうやって nullish か否かを判定したものだろう、という話題です。

## 非厳密比較演算子 `==` `!=`

JavaScript の闇要素としてしばしばネタにされているのが等価演算子 `==` `!=` のガバガバな挙動です。(厳密でない) 等価演算子は左右のオペランドで型が合わない場合 _親切にも_ 暗黙的な型変換を行ってから等価判定してくれます。普通はそんなおせっかいは不要なのでわざわざ 1 タイプ多い厳密等価演算子 `===` `!==` を打つのですが、null チェックの場合は厳密でないことが逆に便利で、具体的に言うと `null == undefined` が `true` になります。

```js
null == undefined; // => true
null === undefined; // => false
```

この挙動を使うと nullish のチェックを簡単にできます。

```ts
declare n: number | null | undefined;

if(n === null || n === undefined) { // 👈
  console.log(`n is ${n}`);
}

// ----------------------------------

declare n: number | null | undefined;

if (n == null) {                   // 👈
  console.log(`n is ${n}`);
}
```

ESLint は `==` `!=` を使っていると怒ってくるのですが、`== null` `!= null` の場合だけは許してくれます。意味は同じですが `undefined` で比較した場合は怒られます。

## `typeof` 演算子と歴史的経緯

`typeof 変数` は変数の型を表す文字列を返します。文字列と聞くと不安な気持ちになるかもしれませんが、TypeScript にはリテラル型という機能があり `typeof` の返り値はエディタの補完が効いてくれます。

```ts
(n: number | string | undefined) => {
  if (typeof n === "number") {
    // ここではnはnumber
  } else if (typeof n === "string") {
    // ここではnはstring
  } else {
    // ここではnはundefined
  }
};
```

`typeof` の表はこちらです。

| `typeof` の評価結果 | 対応する TS の型 |
| ------------------- | ---------------- | ----- |
| `"number"`          | `number`         |
| `"string"`          | `string`         |
| `"boolean"`         | `boolean `       |
| `"symbol"`          | `symbol`         |
| `"function"`        | `Function`       |
| `"undefined"`       | `undefined`      |
| `"object"`          | `object          | null` |

歴史的経緯により `typeof null === "object"` となることに注意してください。`if (typeof foo === "object")` でチェックすると `object | null` 型に推論されます。

> JavaScript の最初の実装では、JavaScript の値は型タグと値で表現されていました。オブジェクトの型タグは `0` で、`null` は NULL ポインター (ほとんどのプラットフォームで `0x00`) として表されていました。その結果、`null` はタグの型として `0` を持っていたため、`typeof` の戻り値は `"object"` です。([リファレンス](http://www.2ality.com/2013/10/typeof-null.html))
> ECMAScript の修正案が (オプトインを使用して) 提案されましたが、[却下されました](https://web.archive.org/web/20160331031419/http://wiki.ecmascript.org:80/doku.php?id=harmony:typeof_null)。それは `typeof null === 'null'` という結果になるものでした。

https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Operators/typeof#typeof_null

`typeof` は宣言していない変数に使用しても `ReferenceError` にならず `"undefined"` に評価されるという稀有な特徴を持っています。

## `instanceof` 演算子

`typeof` では `Function` 以外のオブジェクトは全て `'object'` になり (さらに `null` も混入してしまい) ますが、`foo instanceof Foo` なら適当なクラスのインスタンスであるかを確認できます^[厳密にはクラスじゃなくコンストラクタだと思います]。nullish がインスタンスであるはずがないので null チェックになります。

```ts
const localeStr = (date?: Date) => {
  if (date instanceof Date) {
    date.toLocaleString("jp");
  }
};
```

## nullish は falsy だから/だけど

`null` `undefined` は真偽値に変換すると `false` になります (**falsy** な値)。

```ts
Boolean(null); // => false
Boolean(undefined); // => false
```

JavaScript のオブジェクト ^[プリミティブ、`boolean` `number` `string` `symbol` `bigint` 以外のことです] は全て truthy なので、`function | undefined` や `Klass | null | undefined` といった `truthyな値しかない型 | null | undefined` の形をしたユニオン型は false だった時点で null か undefined と推論でき、条件式を少し短くできます。

```ts
declare const date: Date | null;

if (date) {
  date.toLocaleTimeString("ja"); // date: Date
}

// --------------------------

if (date != null) {
  date.toLocaleTimeString("ja"); // date: Date
}
```

ちょっと便利というか「分かってる感」を演出できますが、falsy な値は null と undefined 以外にもあることに注意してください。number 型では `0` `-0` `NaN` が、string 型では `''` (空文字列) が、そして boolean 型では当然ですが `false` が falsy になるため、このショートハンドをうっかり使ってしまうと 0 や空文字列が来たときに Nullish 用の (つもりで書いた) コードが走ってしまいます。

```ts
const fn = (n: number | undefined) => {
  if (n) {
    return 2 + n;
  }
  throw new Error(`${n}`);
};

fn(0); // 💥 Error: 0
```

これをやらかすと逆に恥ずかしいので、自信がないなら避けたほうがいいかもしれません。ちなみにお利口な TypeScript が下側の行では `n` を `0 | undefined` ^[`NaN` にはリテラル型がないのでこのような不完全な推論になっています。] に推論しますから、マウスホバーすると出てくる型情報をちゃんと見れば気付けるかもしれません。

## `is` カスタム型ガード - Nullish かどうか判別する関数がほしい

いままで `foo != null` というような式を `if` などの条件に書いてきました。この処理は正攻法では関数に切り出すことができません。

```ts
const notNullish = (foo: unknown) => foo != null;

(str: string | null | undefined) => {
  if (notNullish(str)) {
    str.codePointAt(0); // ❗ Object is possibly 'null' or 'undefined'.(2533)
    //
  }
};
```

これは関数の中身までチェックしていると推論が追いつかない、という制御フロー解析の限界によるものです。推論が無理なので我々人間がコンパイラ様に畏れながら「この関数が `true` に評価されたなら `foo` は Nullish ではない」と明示してさしあげなければなりません。それが `is` です。関数の返り値の位置で `foo is T` というような注釈を書き、それが成立するときは `true`、成立しないときは `false` を返します。

```ts
const notNullish = <T extends {}>(foo: T | null | undefined): foo is T =>
  foo != null; // 👈

(str: string | null | undefined) => {
  if (notNullish(str)) {
    str.codePointAt(0);
    //
  }
};
```

`unknown` のままだと表現できないのでジェネリクスを生やしました。ちなみに今回は Nullish を排除した型を `T` にしていますが、返り値の型を `NonNullable<T>` にして `<T>(foo: T): foo is NonNullable<T>` というシグネチャに書き換えても大丈夫です。

`is` で言っている内容はあくまで人間がそう言っているだけであって、実際に「この関数が `true` だったら `foo` は Nullish でない」ということはコンパイラはチェックしてくれません ^[if の条件等に使うので返り値は `boolean` に制限されており、その点に関してはコンパイラはちゃんとチェックします。]。コードで嘘をつかないようにしましょう。

# Nullish かもしれない値にプロパティアクセスしたい！

記事の投稿者の GitHub アカウントのユーザー名を取得したい季節ですね。以下のインターフェースがあると想定します。関数は `declare` で返り値の型だけ書いています。`.d.ts` ファイルみたいなものと考えるといいです。

```ts
interface User {
  name: string;
  githubUrl?: string;
}

interface Article {
  title: string;
  author: User;
}

declare function fetchArticle(): Article | null | undefined;
```

GitHub アカウントの名前ですが、直接は取得できませんね。API ドキュメントが完備されているので `githubUrl` には `https://github.com/AumyF` ^[末尾スラッシュはありません] という形式で URL が入っていることがわかりました。この場合 `str.match(/https:\/\/github\.com\/([a-zA-Z\d][a-zA-Z\d\-]+[a-zA-Z\d])` ^[プロ正規表現 er の方のマサカリをお待ちしております] で取得できそうです。

では `fetchArticle` で記事を取得するところからやってみましょう。

```ts
const regex = /https:\/\/github\.com\/([a-zA-Z\d][a-zA-Z\d\-]+[a-zA-Z\d])/;

const article = fetchArticle(); // Article | null | undefined

const githubUrl = article.author.githubUrl; //
```

言い忘れてましたが `fetchArticle` の返り値は `Article | null | undefined` です。`article` が nullish な可能性があるので `article.author` にアクセスすることはできません。しからば Null チェックすればいいわけです。`article` のほかに `User.githubUrl` は省略可能なので undefined の可能性があり、 `String.prototype.match()` はマッチしなかった場合 `null` を返します。

```ts
const githubUrl = article && article.author.githubUrl;
const matchResult = githubUrl != null ? githubUrl.match(regex) : undefined;
const githubName = matchResult != null ? matchResult[1] : undefined;
```

全体的に繰り返しが多くてつらいですね。ここで ES2020 で Nullish Coalescing と一緒に導入された Optional Chaining を使えば解決できます。

## Optional Chaining

Optional Chaining は `?.` です。プロパティアクセスの `.` の代わりに使って `foo?.bar` とすると、`foo` が nullish だった場合もエラーにならず `undefined` を返します。

`foo?.bar.baz` と繋げると、`foo` が nullish であった場合全体が `undefined` になります。`foo?.bar` が `undefined` になって `undefined.baz` でエラーになると誤解しがちで、実際そのような挙動を示す言語もありますが、JavaScript ではエラーになりません。

```ts
const githubUrl: string | null = article?.author.githubUrl;
const matchResult = githubUrl?.match(regex);
const githubName = matchResult?.[1];
```

`[]` を使ったプロパティアクセスの場合も `?.[]` と書けます。

さらに Optional Chaining があれば余計な変数を用意せず直接繋げて書けます。

```ts
const githubName = fetchArticle()?.author.githubUrl?.match(regex)?.[1];
```

ここまでやるとやりすぎというか、`fetchArticle()` の結果は変数にしといたほうがのちのち便利そうですが。

# Nullish かもしれない値を関数として呼び出したい！

以下のような値を関数として呼び出せます。

```ts
declare const fn: Function | null | undefined;
```

```ts
fn && fn();
fn?.();
```

わりとありそうな例はライフサイクルフック的なものですかね？

```ts
class BuildChan {
  onBuildStart?: (arg: OnBuildStartParams) => void;
  onBuildFinish?: (arg: OnBuildFinishParams) => void;
  build() {
    this.onBuildStart?.();

    // ここでなんかビルドの処理する

    this.onBuildFinish?.();
  }
}
```

:::message
`?.()` や `?.[]` の見た目が気持ち悪いと思う人もいるようですが、`?[]` `?()` だと条件演算子と紛らわしいようです。if が式だったらこんなことで悩む必要なかったと思うんですがねえ。
:::

# 関数版 Optional Chaining がほしい！

引数が nullish だったら `undefined` を返す関数とかわりと便利そうですね。**作りましょう**。

```ts
const map = <T extends {}, R>(f: (t: T) => R) => {
  function r(t: null | undefined): undefined;
  function r(t: T): R;
  function r(t: T | null | undefined): R | undefined;
  function r(t: T | null | undefined): R | undefined {
    return t != null ? f(t) : undefined;
  }
  return r;
};
```

これはカリー化された関数です。`map(fn)` すると `fn` を nullish に対応させた新しい関数 (`r`) を返します。`r` はオーバーロードされており、

- `t: null | undefined` ならば `undefined`
- `t: T` ならば `R`
- `t: T | null | undefined` ならば `R | undefined`

を返します。オーバーロードせず `function r(t: T | null | undefined): R | undefined;` だけだと `r(3)` とか `r(null)` など返り値が自明に `R` や `undefined` である場合も `R | undefined` になってしまいます。

`T` の制約を取り払って Conditional Types で `T extends null | undefined ? undefined : R` としてもよいのですが、関数の返り値に Conditional Types が来た場合は `as` がないとコンパイルが通らないので行っていません。オーバーロードもオーバーロードで `as` こそ見えていませんが実装側で嘘がつけてしまうので普通に危険です。同じ危険ならより見た目がよく見える方を、オーバーロードした理由なんてそんなものです。

実際の使い方はこんな感じです。

```ts
const add5 = (n: number) => n + 5;

const add5N = map(add5);

add5N(undefined);
add5N(124);
map(add5)(null);
```

# `!` - 型は Nullable だけど Non-Null として扱わせたい

どうしても「ロジックの上では絶対に Null にならないけど型は Nullable になってる」という状況というのはあります。その時に値を Non-Null として扱わせるための後置演算子 (のようなもの) が Non-null assertion `!` です。「ようなもの」と書いたのは、この `!` はランタイムに何の影響も及ぼさないからです。ここでだけは Null 安全を投げ捨てるという意味です。

```ts
const toString = (n: number) => n.toString(10);
declare const num: number | null | undefined;

toString(num!);
```

当たり前ですが `!` を使っている場合、その値が nullable でないことを保証する役割はコンパイラからプログラマに移ります。むやみやたらに使うと危険です。

まあ、うっかり落ちると言っても非 Null 安全言語で null チェックすっぽかしてエラー落ちするのと完全に同じですからね。しかも危ない箇所が `!` で可視化されるので、どこに注意を払えばいいのかも一目瞭然です。

# 早期 `return` パターン - nullish なら適当な値を返してさっさと終了したい

関数内で、早期に `return` することで型を絞り込むことができます。単純に `if-else` で分岐するよりもネストが浅くなってコードが読みやすくなります (効果には個人差があります)。

```ts:数値の3倍を返す。undefinedだった場合は0を返す
const fn = (n: number | undefined) => {
  if (n === undefined) return 0;
  return n * 3; // n: number
};
```

```ts:if-elseのコード。ネストが深い
const fn = (n: number | undefined) => {
  if (n === undefined) {
    return 0
  }
  else {
    return n * 3;
  }
}
```

```ts:三項条件演算子のコード。やりすぎると読めない
const fn = (n: number | undefined) => n === undefined ? 0 : n * 3;
```

三項演算子に書き換えられる程度の関数だと微妙ですが、`n` の Null チェック後が長い場合にとくに効果が高いです。

# `throw` - nullish だったら例外を投げたい

`return` と同じように `throw` でエラーを投げ (ることで大域脱出を行っ) ても推論されます。`return` との違いは

- 関数の外でも使えること
- 返り値のことを考えなくてもよいこと
- `catch` しそこねるとアプリケーションごと落ちること

の 3 つです。

```ts:数値の平方を返し、nullishだった場合はthrowする
const square = (n: number | null | undefined): number => {
  if (n == null) {
    throw new Error();
  }
  return n * n;
};
```

実行時エラーが飛んでる時点で Nullish の扱いでヘマしたのとそう変わらないような気もしますが、「nullish なら落ちても構わない」という `!` に比べると「nullish だったら問答無用で落とす」 `throw` のほうが行儀はいいとも考えられます。

# `for` `while` `再帰` で Null チェック

`for` `while` も条件分岐を含んでるので制御フロー解析の対象になります。

*実践的な例*として数値の平方を返し、nullish を渡す不届き者には無限ループにより負荷をかける関数を定義します。

```ts:間違えてもプロダクションで使わないように
function square (n: number | undefined) {
  for (; n == null;);

  return n ** 2;
}
```

どんなループでも再帰に書き換えることができるので、再帰による実装例も載せておきます。この場合は返り値の型注釈は推論できません。

```ts
function square(n: number | null | undefined): number {
  return n == null ? square(n) : n ** 2;
}
```

冗談はともかくとして、`for` `while` を使った実用的な null チェックコードをご存知の方はどうぞコメントください。

# `never` を返す関数 - nullish だったらプログラムを終了させたい

TypeScript の `never` 型はいわゆるボトム型です。集合でいうと空集合 $\emptyset$ です。空集合は元が存在しない集合で、それと同じように `never` 型の値は存在しません。たとえばある変数が `never` に制御フロー解析でキャストされたら、その部分のコードは **型システム上実行されることがありえない** ということを表しています。

```ts
(n: number) => {
  if (n == null) {
    // nはnever
  }
};
```

`n` は数値なのだから `n == null` が true になって if の中が実行されることはありえません。ありえないので never になっています。

変数が never 型になったらその部分のコードは実行されません。引数に never 型の値をとる関数は呼び出すことができません。never 型の値を返す関数は値を返しません。

never を返す関数は **関数が正常に終了して値を返すことがありえない** ことを表します。たとえば必ずエラーを投げる関数は呼び出されたら期待通りにエラーを投げ、呼び出し元に戻って `catch` に捕まるまで次々に関数を抜けていくわけです。正常終了して返り値をくれることはありえません。なので `never` が返り値にきます。

```ts
const panic = (e: unknown) => {
  throw e;
};
// panic: (e: unknown) => never
```

Node.js ではプログラムを終了するのに `process.exit()` が使えます。このメソッドも呼び出されたらプロセスが終了するので後続のコードは実行されません。したがって返り値は `never` です。

`never` は制御フロー解析に影響を与えることができます。たとえば Node.js で引数が足りないとき終了コード 1 でプロセスを終了させたいとします。

```ts
const argv1 = process.argv[1]; // (string | undefined)[]

if (argv1 == null) {
  console.error("Not enough arguments");
  process.exit(1); // ここでneverが返る => 後続のコードは実行されない
}

// ここ以降ではargv1: string
```

`process.exit(1)` でプロセスは終了コード 1 を返して終了するので後続の処理は実行されません。これは undefined である可能性を排除したことになります。結果的に下の方では `argv1` が `string` に推論されました。

## `asserts` - `throw` や `never` でのチェックを関数に切り出したい

`if` を使ったチェックの条件部分を関数に切り出すのが `is` なら `asserts` は `throw` や `never` でのチェックを切り出せるようにします。`asserts foo is U` は「この関数が何らかの値を返したら `foo` は `U` 型として扱っていいよ」という意味です。

何らかの値を返さない場合というのは例えば、

- エラーが `throw` された
- `process.exit()` などでコードの実行が終了した

という場面です。

引数が Nullish だった場合は `throw` する (ので、正常に関数が終了したら引数は `null` でも `undefined` でもないと推論させる) 関数を書きました。

```ts
const assertsNonNull = <T>(foo: T): asserts foo is NonNullable<T> => {
  if (foo == null) {
    throw new TypeError("assertsNonNullがnullishを受け取った");
  }
};
```

`throw` の例で出した `square` を簡単に書けるようになります。

```ts
const square = (n: number | null | undefined): number => {
  assertsNonNull(n);
  return n * n;
};
```

`is` と同じように、`asserts` においてもアノテーションと実装の整合性はプログラマが責任を持ちます。

## コンマ演算子 `,` - `asserts` Null チェックと値の使用を 1 つの式にしたい

**あなたはコンマ演算子を知っていますか？** カンマで区切った複数の式を左から評価し、最後の式の値を返します。シンタックスエラーとかでたまに見かけるかもしれません。

```ts
let a = 0;
let b = (a++, a * 2); // b => 2;
```

末尾以外の式は基本的に副作用を起こすものが選ばれるでしょう。再代入、インクリメント、デクリメント、 `console.log()` などの副作用持ち関数、等々。そして `asserts` 型述語をもつ関数にも (TypeScript の型システム上の) 副作用があります。つまり、コンマ演算子を使うと `asserts` 関数による Null チェックとチェック済みの変数を使う式を 1 つの式としてまとめることができます。

```ts:assertsNonNull() が定義済みだと思って読んでください
const square = (n: number | null | undefined): number => (assertsNonNull(n), n * n);
```

この使い方、コンマ演算子の知名度が低すぎたのかごく最近まで TypeScript の推論対象になっていませんでした。Issue ができたのが今年の 10 月で [microsoft/TypeScript#41264: Assertions do not narrow types when used as operand of the comma operator.](https://github.com/microsoft/TypeScript/issues/41264) 修正が取り込まれたのが現時点の最新版である 4.1 です。

参考: [asserts で assert 関数 - Qiita](https://qiita.com/sugoroku_y/items/bd82009001973ddfa3d4)

# 式が Nullish だった場合の代替値を与えたい！

これは非常によくあるパターンです。非常によくあるので ES2020 で専用の演算子 **Nullish Coalescing Operator** (**Null 合体演算子**) が導入されました。こいつがあれば今まで苦労して書いてきた冗長なコードは全部不要なので先に説明します。

Null 合体演算子は「左オペランドを返す。ただし、左が nullish だったときは右オペランドを返す」という演算子です。リテラルで挙動を見てみましょう。

```ts
null ?? 1; // 1
undefined ?? 1; // 1
0 ?? 1; // 0
12 ?? 1; // 12
```

もっと実践的に「データを取得してきて nullish だった場合デフォルト値 `1` を与える」という形にしましょう。`fetchData()` は `number | null | undefined` を返します。

```ts
const data: number = fetchData() ?? 1;
```

`??` のありがたみを理解し、古いコードを読む際に困らないように `??` 以前の方法も解説します。

まず、`||` が使われることがそこそこありました。

```ts
const data: number = fetchData() || 1;
```

文字数同じ、アレッじゃあ `??` はいらない子？いえいえそうではありません。実は**この場面で `||` を使うのはバッドプラクティス**です。どの場面かと言うと左オペランドが `number` `bigint` `string` `boolean` 型のときです。

このコードは falsy な値、たとえば `0` が渡ってきた場合もデフォルト値 `1` が入ってしまいます。リテラルで確認してみましょう。

```ts
null || 1; // 1
undefined || 1; // 1
0 || 1; // 1
12 || 1; // 12
```

3 つ目の例は `??` と挙動が違いますね。`??` が nullish を捕捉するのに対して `||` は **falsy の場合に** 右オペランドを返す、つまり `0` `NaN` `""` `false` といった値が来たときも右オペランドを返してしまいます。これは nullish だけを排除したい場合には意図しない挙動を引き起こします。

この場合 `??` を使わないで書き換えるには条件演算子を使います。

```ts
const fetched: number | null | undefined = fetchData();
const data: number = fetched != null ? fetched : 1;
```

新しい一時変数 `fetched` が必要になっています。これは条件演算子の中で null チェックする値が 2 回評価されるからです。

`object` `symbol` などの「すべての値が truthy である型」と nullish との Union になっている場合、左辺が falsy だった場合は確実に nullish と判別できます。

```ts
declare const date: Date | null | undefined;

const foo = date || new Date(Date.now());
```

しかしこの例も `??` で完全に置き換えることができます。「左辺が nullish のときのデフォルト値を与える」場合は全部 `??` を使っておけば間違いありません。`??` を使いましょう。

# 変数やプロパティの初期化チェック

`let` で再代入できる変数を定義しました。JS の仕様で未初期化の変数の値は `undefined` になるのでこの変数の値も `undefined` です。

```ts
let str: string;
```

「`str` は型が `string` なのに実際の値は `undefined` だなんて危険にも程がある！TypeScript は危険な言語！█████(任意の AltJS)を使うべき！」と高らかに糾弾したいところですが、実は TS では初期化していない変数を使おうとするとコンパイルエラーになります。したがってうっかり未初期化の変数にアクセスすることはありません。安全です。

```ts
str.toUpperCase(); // ❗ Variable 'str' is used before being assigned. (2454)
```

もちろん、値を代入して初期化すれば普通に使えるようになります。

```ts
str = "hello";
str.toUpperCase(); // => "HELLO"
```

初期値として `undefined` を渡したいときもあるかと思いますが、そのときは当然 `undefined` を型注釈に書く必要があります。その場合でも NonNullish 値で再代入すれば Nullish を除去した形に自動キャストしてくれます。

```ts
let str: string | undefined = undefined;

str = "hello";
str.toUpperCase(); // => "HELLO"
```

switch, try-catch といった構文が出てきて `const` が使いづらいときも心配はいりません。

```ts:何らかのasync関数の中だと想定してください
let data: Data | undefined = undefined;

switch (process.NODE_ENV) {
  case "development": {
    data = new Data(["Denji", "Aki", "Power", "Makima"]);
  }
  case "production": {
    data = await Data.fetch("https://example.com");
  }
}

doSomethingWith(data); // Data型
```

## クラスのフィールド

TypeScript 2.7 で導入されたコンパイラオプション `--strictPropertyInitialization` を有効にすると、クラスのフィールドを初期化しないとコンパイラに怒られるようになります。変数の場合は未初期化のものを使おうとしたときにエラーですが、クラスのフィールドではクラスの定義時にエラーが出るところが違います。

```ts
class User {
  name: string;
  // ❗ Property 'name' has no initializer and is not definitely assigned in the constructor.(2564)
}
```

このエラーを解消するにはフィールド定義かコンストラクタ内で初期化する必要があります。

```ts:定義で初期化
class User {
  name: string = "Makima";
}
```

```ts:コンストラクタで初期化
class User {
  name: string;
  constructor(name: string) {
    this.name = name;
  }
}
```

未初期化でインスタンス化させたい場合はやはり変数同様に `T | undefined` にします。再代入で値を割り当てると `undefined` が取り除かれた型になります。

```ts
class User {
  name?: string;
}

const user = new User();
user.name = "Chito";

console.log(`My name is ${user.name}.`);
```

## 未初期化警告の無視 `!`

TypeScript は変数やフィールドの初期化について面倒を見てくれますが、流石に関数内での代入操作までは見てくれません。特にコンストラクタ内ですね。

```ts
class User {
  name: string;
  // ❗ Property 'name' has no initializer and is not definitely assigned in the constructor.(2564)
  constructor(name: string) {
    this.initName(name);
  }
  initName(n: string) {
    this.name = n;
  }
}
```

というか真偽値での絞り込みも `throw` での絞り込みも `is` `asserts` なしでは関数には切り出せませんし、中で変数に代入することを表す型述語は (まだ？) 存在しません。そんなこんなで未初期化警告とか出さなくていいから型チェック通してくれ～～ってなったときのために `!` という修飾子的ななんかがあります。省略可能の `?` みたいな感じで `!` を書くだけであら不思議、初期化してなくても怒られが発生しなくなりました！

```ts
class User {
  name!: string;
  constructor(name: string) {
    this.initName(name);
  }
  initName(n: string) {
    this.name = n;
  }
}
```

## 省略可能な引数 `(t?: T) => T`

オブジェクト型のプロパティと同様に、関数の引数も `?` を使って省略可能にできます。省略された引数は `undefined` になるので、省略可能な仮引数 `t?: T` の型は `T | undefined` になります。

```ts
function fiveTimes(n?: number): number {
  if (n == null) return 0;
  return n * 5;
}
```

## ラベル付きタプルと関数の引数

TypeScript では関数の引数を配列で指定することができます。

```ts
type StrStrNum = [string, string, number];
const strStrNumFunc = (...args: StrStrNum) => `${args[0]}${args[1]}${args[2]}`;
const strStrNumFunc2: (...args: StrStrNum) => string = (s) => `${args}`;
```

## 引数のデフォルト値

関数の仮引数で `arg: number = 0` とすると、引数が省略された (厳密には `undefined` が渡った) 場合のデフォルト値を設定できます。デフォルト値を設定すると呼び出し側は (TypeScript の型システム上で) その引数を省略できるようになります。`arg?: number = 0` という形にすると `Parameter cannot have question mark and initializer.(1015)` でコンパイルエラーになります。

```ts
// add42: (n?: number) => number
const add42 = (n: number = 0) => {
  return n + 42;
};
```

デフォルト値が適用されるのは値が **`undefined` だった場合** です。**`null` は含まれません。**

```ts
// add42: (n: number | null) => number
const add42 = (n: number | null = 0) => {
  return n + 42; // ❗ Object is possibly 'null'.(2531)
};
```

`null` の可能性がある場合のデフォルト値はどう与えたらいいかというと、**Null 合体代入演算子** `??=` を使います。

## Null 合体代入 (Logical nullish assignment)

TypeScript 4.0 で追加された新しい代入演算子 (Logical assignment operators) の 1 つです。ECMAScript では 2020 年末現在 Stage 4 で `esnext` 扱い、年次のバージョンには来年の ES2021 で追加される予定です。左辺が nullish だった場合右辺値を代入します。デフォルト値を与えるように再代入できるので地味に便利です。

```ts
let foo: number | null | undefined = null;

foo ??= 0; // ここ以降では foo: number
// ---
foo ?? (foo = 0);
foo != null ? foo : (foo = 0);
```

`foo ??= 1` と `foo = foo ?? 1` には少し違いがあります。`foo` の評価回数が違うのもそうですし、Null 合体演算子の短絡評価により `foo ??= 1` は `foo` が nullish でない場合は代入自体が行われません。

関数のデフォルト引数が `null` を潰せない問題もこれがあれば解決します。

```ts
const threeTimes = (n?: number | null) => {
  n ??= 1;
  return n * 3;
};
```

# Nullish を含む配列から Nullish を削除したい！

`Array<T | null | undefined>` という配列から Nullish な値を排除して `T[]` にしたい場合、もっとも簡単なのが `Array.prototype.flatMap` を使う方法です。

```ts
const compact = <T extends {}>(arr: Array<T | null | undefined>): T[] =>
  arr.flatMap((n) => n ?? []);
```

`Array.prototype.flatMap(fn)` は ES2017 で追加されたメソッドで、`array.map(fn).flat()` と等価です。関数 `fn` で `[]` (長さ 0 の配列) を返すとその要素が削除されます。このコードでは Null 合体演算子 `??` を使って Nullish だった場合は `[]` を返し、その要素を削除するようになっています。このように `flatMap` は `[]` で要素を削除したり、`[n, n * 3]` で要素を挿入したりできます。たのしいのでぜひ使いましょう。

`is` つき関数と `Array.prototype.filter` を合わせることもできます。もちろん関数本体の処理が正当かはプログラマが責任を負う…といってもこの場合は見りゃわかりますが。

```ts
const compact = <T extends {}>(arr: Array<T | null | undefined>): T[] =
  arr.filter((n): n is T => n != null);
```

配列そのものが Nullable の場合もあると思います。型としては `Array<string | null | undefined> | null | undefined` のような形です。そんなときは Optional Chaining と Nullish Coalescing を組み合わせます。

```ts
declare const tags: Array<string | null | undefined> | null | undefined;
arr?.flatMap((n) => n ?? []) ?? [];
```

# コラム: 代数的データ型

Haskell, Rust, Elm, PureScript 等 (特に ML 系) の関数型プログラミング言語で主流である Null 安全を実現するアプローチが代数的データ型 (Algebraic data types) です。TypeScript でも文字列リテラル型とユニオン型を使って代数的データ型を模倣したものが作れます。

```ts
interface None {
  readonly _tag: "None";
}

interface Some<A> {
  readonly _tag: "Some";
  readonly value: A;
}

type Option<A> = None | Some<A>;
```

この定義はほとんど fp-ts そのものです。これを使うと Union では不可能だった Nullable のネストが可能になります。ネストができると Nullable の発生箇所が複数ある場合にどこで発生したのか見つけれてちょっと便利です。その代わりというか、言語の標準ライブラリなど含めて `Option` `Maybe` になっている Rust や Elm と異なり TypeScript のこれは JavaScript のエコシステムから離れてしまい、ネイティブの言語機能との相性が悪かったり、人気のライブラリ等々との変換がやや冗長になったりします。結果的にユーティリティ関数がたくさん必要になります。fp-ts はそのへんの関数もちゃんと用意してますが、自力で定義していくのはつらいかもしれません。そしてそんなにがんばるならもう最初から `/(LiveScript|ReScript|Elm|PureScript)/` でいいんじゃないか、というのが筆者の個人的意見です。

…などと書きましたがこれは `Option` の話で、The Elm Architecture の Action は代数的データ型なので TypeScript で TEA っぽいことをする場合は Action にだいたいこれが登場します。

# コラム: `document.all`

`document.all`という地獄のようなオブジェクトがあります。簡単に言うと

- `Boolean(document.all) === false`
  - **オブジェクトなのに falsy**
- `document.all == null && document.all == undefined`
  - **オブジェクトなのに nullish との非厳密比較が真**
- `typeof document.all === "undefined"`
  - **オブジェクトなのに `typeof` が `undefined`**

です。まさにやりたい放題ですね。さすがに nullish ではないので `document.all ?? 0` で 0 が返ってきたりはしないんですが、実はここに Nullish coalescing の面白いところがあります。`v != null ? v : u` と `v ?? u` はだいたいの場合等価ですが、`document.all` については `document != null` が `false` なので前者では `u` が、そして説明したとおり nullish ではないので後者では `v` が返るわけです。

だからといってこんなののために気を遣った実装をする必要はないと思いますが。
