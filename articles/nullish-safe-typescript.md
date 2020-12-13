---
title: TypeScript で null, undefined とうまく付き合う
type: tech
topics: [TypeScript, JavaScript]
emoji: 🈚
published: false
---

「[Null 安全でない言語は、もはやレガシー言語だ](https://qiita.com/koher/items/e4835bd429b88809ab33)」と言われて 4 年が経ちましたが、みなさんいかがお過ごしでしょうか？4 年という歳月の長さは凄まじいものです。当時の中 1 が高 2 になり、ポケモンが第 7 世代から第 8 世代に移行し、Flash が死に、TypeScript が 2.0 から 4.1 に到達し、ECMAScript の数字が 4 つ上がるほどの長さです。それほどの時間をもってしても IE は殺せませんでしたが。

4 年の間に TypeScript は勢力を拡大し、JavaScript の世界でも Null 安全が浸透してきたことと思います ^[実はここで書いていることはわりと適当です。筆者には実務経験がありませんし、そもそも 4 年前のフロントエンドがどんなだったかもほとんど知りません]。JavaScript の規格である ECMAScript は毎年新しいバージョンが出され次々と機能が追加されてきました。それに合わせて TypeScript の Null 安全機能も大きく進化してきました。本記事では 2020 年末時点での TypeScript 4.1 で null と undefined をどうにかする言語機能を網羅的に紹介していきます。

# 読むのに必要な知識 / この記事で扱わない内容

- 基礎的な JavaScript の知識
  - ECMAScript 2015 程度
  - `let` `const` `() => ` (アロー関数) などの機能を断りなく使います
- TypeScript の超基礎的な知識
  - TypeScript を使うと JavaScript に静的型チェックを導入できる、程度で十分です
  - ユニオン型などは本記事で説明します

:::message
TypeScript を実行したい場合は ts-node または [TypeScript Playground](https://typescriptlang.org/play/) を使います。
:::

## ソースコード中の絵文字について

- 「💥」は実行時エラーです。コードを実行すると `TypeError` などのエラーが throw されます。
  - 実際に運用している最中に発生するので、プログラムを書く上では可能な限り避けたい
- 「❗」はコンパイルエラーです。TypeScript→JavaScript のトランスパイル時に `tsc` が出力します。
  - 実際に運用する前に発生し、実行時エラーを事前に告知する役割がある

# Null 安全とは

**Null チェック (値が Null でないことの確認) を強制** することで、Null (および nil, None などの虚無値) による **実行時エラー** を起こさせない仕組みのことです。

「無効かもしれない値」を型で表現する、という思想は Option や Maybe と呼ばれ、ML, Haskell, Elm, PureScript, OCaml などの関数型言語では長く使われてきました。近年では Swift, Rust, Kotlin, Dart といったマルチパラダイム言語にも導入されています。TypeScript にもバージョン 2.0 でコンパイラオプション `--strictNullChecks` により導入されました。各種の厳格なチェックを有効化する `--strict` オプションに含まれており、`tsc --init` で生成された `tsconfig.json` でもこちらが有効化されているので、普通にやれば TypeScript は Null 安全な状態でセットアップされるはずです。

## ぬるぽ

大前提として、JavaScript では `null` `undefined` へのプロパティアクセスが起きると `TypeError` が発生します。Java でいうぬるぽ (`java.lang.NullPointerException`) です。ｶﾞｯ

```js
const str = null;
str.toUpperCase();
// 💥 TypeError: Cannot read property 'toUpperCase' of null
```

## 型安全だけど Null 安全じゃない

`--strictNullChecks` をオンにしていない (**Null 安全でない**) TypeScript で変数 `str` に `string` という型注釈をつけると、 `number` などの関係ない型の値を代入することは不可能になります。静的型付け言語としてみれば普通の挙動ですね。

```ts
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

`--strictNullChecks` を有効にし、**Null 安全になった** TypeScript で同じコードを実行すると、コンパイルエラーになります。Null 安全な TypeScript では、もはや `null` は `string` 型ではありませんから、`string` 型の変数に `null` を代入することはできなくなりました (**Null 非許容型** と言ったりもします) 。

```ts
const str: string = null;
// ❗ Type 'null' is not assignable to type 'string'. (2322)
str.toUpperCase();
```

`str` に `null` を代入したいときは `null` との Union 型をとります (**Null 許容型** とか Nullable 型と言ったりもします)。これは `string` 型の値か `null` を割り当てることができる型です。

```ts
const str: string | null = null;
str.toUpperCase();
// ❗ Object is possibly 'null'. (2531)s
```

代入は問題なく行われましたが、`toUpperCase()` を呼び出すときにコンパイルエラーが発生します。`str` は `string` だけでなく `null` の可能性 (_possibly_) があります。`null` だった場合は先程の例のように実行時に `TypeError` が発生してしまいます。実行時エラーの可能性があるので、コンパイラは型チェックを通しません。

## null チェックをしよう

実行時エラーの可能性があるので型チェックが通らないのならば、実行時エラーの可能性をなくせば型チェックは通ってくれるわけです。`if` 文を使って Null チェックを行うと、その中では `str` が `string`、すなわち `null` で実行時エラーを起こす可能性が排除されたことをコンパイラが理解してくて自動的に型を絞り込んでくれます。

```ts
let str: string | null = null;

if (str !== null) {
  str.toUpperCase();
}
```

`null` に関するエラーはコンパイル時にチェックされ、実行時されるより前の段階で未然に防がれました。これが Null 安全です。

- Null 安全言語では虚無値は他の型と明確に区別される
- コンパイル時 / エディタ上で Null に起因するバグを発見できる

# Nullish を知る

JavaScript は珍しい言語で、虚無値が 2 つあります。`null` と `undefined` です。この 2 つをあわせて呼ぶ呼び方として、ぜんぜん普及していませんが **Nullish** という言葉を使います。これは `null` と `undefined` をうまく処理するための演算子 「Nullish Coalescing Operator」 に由来していますが、日本語訳が「Null 合体演算子」となっているので微妙に伝わりづらいのが悩みの種です。

## Null

`null` は値がないことを示すプリミティブ値です。`undefined` と異なり、関数の返り値として現れることはあっても JavaScript の構文から自然発生することはありません。

WHATWG が策定している Web API はどちらかというと `null` を返す傾向が強いようです。Web DOM API の `document.querySelector("div#hoge")` は `<div id="hoge">` に当てはまる要素がない場合 `null` を返します。これは Web API が言語に依存しない仕様ということになっているためだと思います。

## Undefined とその出現場所

未定義であることを示す値です。`null` と違い `undefined` は JavaScript の構文から勝手に誕生することが多く、予期しないエラーはこちらで起こりやすいです。`Uncaught TypeError: undefined is not a function` というエラーメッセージを見たことがない人はいないはずです。

どうでもいい話ですがソースコード中の `undefined` は ECMAScript の組み込みオブジェクト、すなわちグローバル変数やグローバルオブジェクトのプロパティとも言えるものです。`globalThis.undefined` で `undefined` を得られます。ECMAScript 5 以降では仕様によりグローバル変数の `undefined` には再代入できませんが、`null` と違って予約語ではないのでグローバルでないスコープでは `undefined` という名前の変数を定義できます。もちろん推奨はされていません。

### 宣言されているが初期化されていない変数

- TypeScript ではアクセス不可

```js
let s; // undefined
```

### 存在しないプロパティ

- TypeScript ではアクセス不可

```js
const o = { name: "denji", devil: { name: "chainsaw" } };

o.debil; // undefined
//  ^
o.debil.name; // 💥 TypeError: Cannot read property 'name' of undefined
```

### 省略された引数

- 明示的に省略可能にしければ (使う側が TypeScript である限りは) `undefined` は来ない

```js
const toStr = (num, radix) => num.toString(radix);

upper(3); // radix = undefined
```

### 何も返さない関数の返り値

- 何も返さず単なる `return;` で抜けている
- そもそも `return` なしで終了している

```js
() => {
  console.log("hello");
};

// windowがない (Node.js, Service Worker などの) とき undefinedを返す
() => {
  if (typeof window === "undefined") return;
  return window.document;
};
```

### `void` 式

`void` というと TypeScript で何も返さない関数の返り値の型として使われている (のちほど解説します) イメージがありますが、実はこの `void` は ECMAScript の予約語で、これを使った `void` 式というものがあります。`void 何らかの式` と書くと `undefined` を得られるというものです。先ほど `undefined` に別の値が入っていることがある、という話をしましたが `void 0` のように `void` を使うとグローバル変数の `undefined` を使わず `undefined` 値を得ることができます。見た目と活用方法が直感的でなさすぎて、JavaScript のヤバ要素入門として人気のトピックです。

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

### Optional Chaining で Nullish にアクセス

Optional Chaining については後ほど解説します。

```ts
// font要素がなかった場合querySelectorがnullを返し、Optional Chainingでundefinedになる
document.querySelector("font")?.innerText;
```

# TypeScript は Nullable をユニオン型で表現する

まずはじめに TypeScript の型で Nullable をどう表現するかについて説明します。実装に関する話は一切出てきません。全て型の上での話です。TypeScript の設計思想としてランタイムに影響を与えないというものがあり、究極的には型アノテーションさえ除去すれば JavaScript コードとして扱えるように設計されています。

Kotlin や Swift では Nullable 型について `int?` というように `?` で書きますが、TypeScript では **Union 型** を使って `T | null` というように書きます。

Union 型は合併型、共用体型とも呼ばれ、`A | B` 型は「`A` 型か `B` 型」という意味をもちます。`number | null` は数値か null なので、受け入れられる値は例えば `3.14` とか `42` とか `-Infinity` とか (`number`) と `null` です。

JavaScript は動的型付け言語であるため 1 つの変数や仮引数が複数の型をとることがしばしばあり、Union 型はそのようなコードをサポートするために導入されたという節もあります。Python に mypy で型をつけるときも Union が使え、Nullable に相当する `Optional[Foo]` は `Union[Foo, None]` ^[Python の虚無値は `None` です] と同じだそうです。

## Conditional Types でユニオン型から Nullish を除去する

Conditional Types という機能があります。`T extends U ? X : Y` という構文で、`T` 型が `U` 型を満たしていたら `X` 型、そうでなかったら `Y` 型に解決されます。条件演算子みたいなものです。

`U` のところには好きな型を書けて、しかも `infer` を使うとパターンマッチ的なことができます。これを使って `null | undefined` との Union 型から NonNull な型を抽出できる `NonNullable<T>` 型が書けます。というか TS 標準で組み込まれてます。

```ts:NonNullableの定義
type NonNullable<T> = T extends infer R | null | undefined ? R : never;
```

Conditional Types そのものの使い方は覚えておかなくても大丈夫ですが、`NonNullable<T>` はとても便利なのでぜひ使っていきましょう。

:::message
Conditional Types に限らず TypeScript の高度な型は便利なユーティリティ型を表現するための低レイヤーな API だと思っています。`NonNullable<T>` そのものを実装するのではなく、`NonNullable<T>` を作るための道具を実装することで、それを使って `NonNullable` 以外にもいろいろな型を書くことができるというわけです。実際に Conditional Types を使ったユーティリティ型には関数の引数の型をタプルの形で得られる `Parameters<T>`, 関数の返り値の型を得られる `ReturnType<T>` などがあります。
:::

### `Nullable<T>` 型はどこ？ `number?` って書けないのはなんで？

TypeScript では `NonNullable` はありますが `Nullable` はありません。`T | null` と `T | undefined` と `T | null | undefined` というバリエーションがあって名前付けが面倒だし、プロジェクトによって `null` 使わないとかどっちも使うとかがあるからだと思います。`number?` と書けないのも同様の理由によるものと思われます。それに型中での `?` は現状すでに Conditional Types が使っているので文法的に大丈夫じゃなさそうです。

本記事中では `null` のほうを多用しているように見えるかもしれませんが、単純にスペルが長く手の動きが typo しやすい ~~`undefiend`~~ `undefined` を 打つのがめんどくさいだけです。

:::message
TypeScript コンパイラそのもの ([microsoft/TypeScript](https://github.com/microsoft/typescript)) の開発では `undefined` のみを使っています ([Coding guidelines - microsoft/TypeScript](https://github.com/Microsoft/TypeScript/wiki/Coding-guidelines#null-and-undefined))。ただしあくまで TypeScript コンパイラでのガイドラインであり、TypeScript の開発陣として「TypeScript を使った開発ではこのガイドラインに従え」と言っているわけではないので、あなたがどう使うかは自由です。ガイドラインの最初にはこのことが `<h1>` のクソデカ太字で 2 回も書いてあります。OSS メンテナという仕事のつらさが垣間見えるコラムでした。
:::

## 省略可能なプロパティ `prop?: T`

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

### Mapped Types でプロパティの省略可否を操作する

Mapped Types という機能があります^[日本語訳はよくわかりません。型の写像とか言われたりもしますしコンパイラはマップされたオブジェクト型と言ってたような気もします。]。`{[P in K]: T}` で、「`K` に当てはまる型変数 `P` をプロパティ名にもちプロパティの値が `T` である」型です。Mapped Types で `:` の前に `?` や `-?` を付けることで、プロパティを省略可能にしたり省略不能にしたりできます。

Mapped Types がよくわからなくても `Partial<T>` と `Required<T>` というユーティリティ的な型が TypeScript 組み込みで用意されており、オブジェクト型のプロパティを省略可能にしたり不能にしたりが自在にできます。

```ts:Partialの定義
type Partial<T> = { [P in keyof T]?: T[P] };
```

```ts:Requiredの定義
type Required<T> = { [P in keyof T]-?: T[P] };
```

## 「Nullish 以外の値」を表す型

`null` `undefined` 以外ならどんな値でもいい、という場合には `{}` 型か `Object` 型を使います。`{}` は「プロパティを 0 個以上もつ型」、`Object` は「`Object` のインスタンス」です。

`{}` 型は JS の空のオブジェクトリテラル `{}` が指す値の型です。しかし TypeScript の型システムは構造的部分型なので「プロパティを 0 個以上もつオブジェクト」という解釈がなされ、`3` などのプリミティブ値も代入できます。

```ts
let bar: {} = {};
bar = 3;
bar = () => {};
bar = "チェンソーマン";
```

`Object` 型は「JS の組み込みオブジェクト `Object` のインスタンス (と同等の型)」を表します。JS の値はプリミティブ含めてすべて `Object.prototype` を継承している `Object` のインスタンスなのでやはり nullish 以外ならなんでも代入できます。

`Object` を継承しない値というのは `Object.create(null)` で作れますが **TypeScript でそれの型を表現する手段がない** ので TypeScript に飼われている限りは気にする必要はありません。

ちなみに `@typescript-eslint` を推奨設定で使うと `{}` `Object` を使うなと言われます。`boolean | string | number | bigint | symbol | object` と外延的なゴリ押しで等価な型を書けます (実はこちらのほうが型推論する上で有利に働くことがあります)。

## `unknown` 型

`unknown` 型はトップ型とも呼ばれます。部分型関係の頂点に位置し、あらゆる型のあらゆる値を内包する型です。`unknown` 型の変数にはなんでも代入できますし、`unknown` を引数に取る関数にはなんでも渡せます。「あらゆる値」には nullish も含まれるため、Nullable とかどこにも書いてありませんが本質的には Nullable な型です。そのため素の状態ではほとんど何の操作もできません。

```ts
declare const u: unknown;

u.toString(); // ❗ Object is of type 'unknown'.(2571)
```

`unknown` 型は `{} | null | undefined` 型とほぼ同じ ^[実際は `{} | null | undefined` が `unknown` の部分型になっています。] ですが実際にユニオン型として定義されているわけではないので、`if (u != null)` といった「Nullish であることの否定」で `{}` 型を導く ^[ところでもしかしてこの手法って選言三段論法じゃないですか？] ことはできません。ほしい型があるなら `typeof u === "string"` や `u instanceof Date` のように直接言って推論させましょう。nullish だけ除去した `{}` を得たい場合は `u instanceof Object` すれば同等の `Object` を得られます。

## `void` 型

関数が「何も返さない」ことを示す型です。`return` が無い関数、`return;` で値を返さない関数が該当します。

```ts
const boido = (): void => {};
```

`return` が無い関数、`return;` で値を返さない関数は JS の上では `undefined` を返り値として持っていますから、`undefined` は `void` 型の値として使用できます。

何も返さない関数の返り値を `undefined` と定めて、`undefined` を生み出す `void` を作り、そして TypeScript が何も返さない関数の返り値の型を `void` と定めるの、なんかロマンを感じませんか？

## 省略可能な引数 `(t?: T) => T`

# Null チェックと制御フロー解析

TypeScript コンパイラはコードの制御フローを解析し、「ここは `typeof foo === "string"` が true だった分岐なので `foo` は `string` 型である」というように推論することができます。もちろん Nullish も例外ではありません。`if` で Null チェックを行うとチェック後のコードでは値が Non-Null な型に全自動でキャストされます。

いろいろな Null チェックを見てみましょう。

## `if` 文

いかなる言語においても、最も基礎的な Null チェックといえば `if` です。

```ts
// maybe: {hoge: unknown} | null | undefined

if (maybe != null) {
  maybe.hoge;
}
```

## それは nullish か？

`if` を使って Null チェックする場合、条件部分に真偽値を入れなければいけません、じゃあどうやって nullish か否かを判定したものだろう、という話題です。

### ESLint を怒らせない 非厳密比較演算子 `==` `!=` の使い方

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

### `typeof` 演算子と歴史的経緯

`typeof 変数` は変数の型を表す文字列を返します。文字列と聞くと不安な気持ちになるかもしれませんが、TypeScript にはリテラル型という機能があり `typeof` の返り値はエディタの補完が効いてくれます。

```ts
(n: number | string | undefined) => {
  if (typeof n === "number") {
    // ここではnはnumber
  } else if (typeof n === "string") {
    // ここではnはstring
  } else {
    //ここではnはundefined
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

### `instanceof` 演算子

`typeof` では `Function` 以外のオブジェクトは全て `'object'` になり (さらに `null` も混入してしまい) ますが、`foo instanceof Foo` なら適当なクラスのインスタンスであるかを確認できます^[厳密にはクラスじゃなくコンストラクタだと思います]。nullish がインスタンスであるはずがないので null チェックになります。

```ts
(date?: Date) => {
  if (date instanceof Date) {
    date.toLocaleString("jp");
  }
};
```

### nullish は falsy だから/だけど

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

### `is` 型述語

いままで `foo != null` というような式を `if` などの条件に書いてきました。この処理は正攻法では関数に切り出すことができません。
単一のプリミティブを null チェックするならともかく、オブジェクト型のプロパティ name, age, gender をまとめてチェックしたいというようなことになると関数に切り出したくなるところです。

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
    str.codePointAt(0); // ❗ Object is possibly 'null' or 'undefined'.(2533)
    //
  }
};
```

`unknown` のままだと表現できないのでジェネリクスを生やしました。ちなみに今回は Nullish を排除した型を `T` にしていますが、返り値の型を `NonNullable<T>` にして `<T>(foo: T): foo is NonNullable<T>` というシグネチャに書き換えても大丈夫です。

`is` で言っている内容はあくまで人間がそう言っているだけであって、実際に「この関数が `true` だったら `foo` は Nullish でない」ということはコンパイラはチェックしてくれません ^[if の条件等に使うので返り値は `boolean` に制限されており、その点に関してはコンパイラはちゃんとチェックします。]。コードで嘘をつかないようにしましょう。

# 式から nullish を除去する

## 条件演算子 `cond ? posi : nega`

非常に惜しいことに JavaScript は `if` が式ではありません。なので条件演算子 (三項演算子) があります。式として使えること以外は `if` と同じです。Null チェックでの使い方も変わりません。多用しすぎると可読性があれになるので自重しましょう。

```ts
nuru != null ? nuru : 0;
```

オペランドには式しか書けないので `throw` などができない点に注意してください。

## 論理演算子 `||` `&&` の短絡評価

JavaScript の論理演算子 `||` と `&&` は**短絡評価** します。これを使って、条件演算子の特定のパターンをより短く書けます。Null チェックにも応用されていました。

論理和 `||` は、「どちらか片方が `true` なら `true`」となる演算子です。

$$
P \lor Q
$$

このとき $P$ が true だった場合、Q が true だろうと false だろうと論理和の結果は true になります。

## Null 合体演算子 `??`

Optional Chaining と同じ ES2020 で登場した演算子が Nullish Coalescing Operator (**Null 合体演算子**) です。本記事の Nullish という単語はこの機能の英語名称から採っています。

Null 合体演算子は `??` という 2 項演算子です。左オペランドが Nullish (null か undefined) だった場合は右オペランドを返します。それ以外の場合は左オペランドを返します。実際のコードで見るとこんな感じです。

```ts
3 ?? 0; // 3
"hello" ?? "world"; // "hello"
"" ?? "world"; // ""
null ?? "world"; // "world"
undefined ?? 0; // "0"
```

`||` との大きな違いは左辺が nullish のときだけ右辺を返すことです。`||` だと左辺が `0` などの falsy な値でも右辺を返してしまいますから、`string` `number` `boolean` には使えませんでした。

```ts
const num = 0;

num || 1 === 1;
num ?? 1 === 0;
```

ふたりで襲来してきただけあって Optional Chaining とは小指と小指が赤い糸で結ばれてるのかチクショウというほど相性抜群です。

```ts
(num: number | null) => {
  const piyo = num?.toString(16)?.toUpperCase() ?? 0; // num
};
```

`num` のメソッドを Optional Chaining で繋げていき、最後に残った `undefined` を Nullish Coalescing でキャッチしてデフォルト値を与えています。

Optional Chaining と Nullish Coalescing は多くの Null 安全言語に導入されてきた非常に強力な道具です。ぜひ使っていきましょう。

## Optional Chaining `?.`

Nullish な値にプロパティアクセスすると TypeError が飛ぶのでした。

```ts
const nuru = null;

nuru.toString(8); // 💥 TypeError
```

ES2020 で導入された **Optional Chaining** は **Nullish にアクセスした場合 `undefined` が返ります**。

```ts
nuru?.toString(8); // => undefined
```

### プロパティアクセス `?.prop`

### ブラケットアクセス `?.[prop]`

構文が気持ち悪いと思う人もいるようですが、`?[]` だと条件演算子と紛らわしいようです。話を蒸し返すようですが if が式だったらこんなことで悩む必要なかったと思うんですよ。

```ts
const hoge = Symbol("hogehoge");

declare const andifaindo: { [hoge]: string };

andifaindo?.[hoge]; // ✔
```

### 関数呼び出し `?.()`

`Function | null | undefined` のような型の値を呼び出します。

```ts
(fn?: () => void) => {
  fn?.();

  // この2つと等価
  fn && fn();
  fn != null ? fn() : undefined;
};
```

## 「関数版 Optional Chaining とかってないんですか？」

**作りましょう**。

```ts
const map = <T extends {}, R>(f: (t: T) => R) => {
  function r(t: null | undefined): undefined;
  function r(t: T): R;
  function r(t: T | null | undefined): R | undefined {
    return isNN(t) ? f(t) : undefined;
  }
  return r;
};
```

これはカリー化された関数です。`map(fn)` すると `fn` を nullish に対応させた新しい関数 (`map` の本体では `r` という名前) を返します。

# Non-null assertion `!`

どうしても「ロジックの上では絶対に Null にならないけど型は Nullable になってる」という状況というのはあります。その時に値を Non-Null として扱わせるための後置演算子 (のようなもの) です。「ようなもの」と書いたのは、この `!` はランタイムに何の影響も及ぼさないからです。ここでだけは Null 安全を投げ捨てるという意味です。

```ts
declare const num: number | null | undefined;
```

当たり前ですが `!` を使っている場合、その値が nullable でないことを保証する責任はコンパイラからプログラマに移ります。むやみやたらに使っていいものではありません。TypeScript の推論力があなたのコードについていけてないのか、あなたが TypeScript の言語機能を理解できていないのか、あるいは TypeScript もあなた自身もコードを理解できてないのか、しっかり見極めてください。まあ、かく言う筆者もめんどくさがって `!` を使うことはわりとありますが。

それに、危険と言っても非 Null 安全言語で null チェックすっぽかしてエラー落ちするのと完全に同じですからね。しかも使っている箇所が `!` で可視化されるので、どこに注意を払えばいいのかも一目瞭然です。

# 処理の打ち切りで Null チェックする

## 早期 `return`

関数内で、早期に `return` することで型を絞り込むことができます。単純に `if-else if-else` で分岐するよりもネストが浅くなってコードが読みやすくなります (効果には個人差があります)。

```ts
const fn = (n: number | undefined) => {
  if (n === undefined) return 0;
  return n * 3; // n: number
};
```

## `throw`

`return` と同じように `throw` でエラーを投げても推論されます。`return` との違いは関数の外でも使えることと、`catch` しそこねるとアプリケーションごと落ちることです。実行時エラーが飛んでる時点で Nullish の扱いでヘマしたのとそう変わらないような気もしますが。「nullish なら落ちても構わない」という `!` に比べると「nullish だったら問答無用で落とす」 `throw` のほうが行儀はいいかもしれません。。

```ts:数値の平方を返し、nullishだった場合はthrowする
const square = (n: number | null | undefined): number => {
  if (n == null) {
    throw new Error();
  }
  return n * n;
};
```

## `never` を返す関数と Null チェック

TypeScript の `never` 型はいわゆるボトム型です。集合論的には空集合 $\emptyset$ です。`never` 型の値は存在しません。たとえばある変数が `never` に制御フロー解析でキャストされたら、その部分のコードは **型システム上実行されることがありえない** ということを表しています。

```ts
(n: number) => {
  if (n == null) {
    // nはnever
  }
};
```

`n` は数値なのだから `n == null` が true になって if の中が実行されることはありえません。ありえないので never になっています。

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

## `asserts` 型述語

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

## コンマ演算子 `,` と `asserts`

**あなたはコンマ演算子を知っていますか？** [asserts で assert 関数 - Qiita](https://qiita.com/sugoroku_y/items/bd82009001973ddfa3d4) を読んでいて気づいたのですが、コンマ演算子を使うと `asserts` 関数による Null チェックとチェック済みの変数を使う式をまとめることができます。

```ts:assertsNonNull() が定義済みだと思って読んでください
const square = (n: number | null | undefined): number => (assertsNonNull(n), n * n);
```

この使い方、コンマ演算子の知名度が低すぎたのか、Issue ができたのが今年の 10 月で [microsoft/TypeScript#41264: Assertions do not narrow types when used as operand of the comma operator.](https://github.com/microsoft/TypeScript/issues/41264) 修正が取り込まれたのが現時点の最新版である 4.1 なんですね。

# 初期化と再代入

TypeScript は変数の初期化や再代入についても面倒を見てくれます。

## 変数

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

初期値として `undefined` を渡したいときもあるかと思いますが、そのときは当然 `undefined` を型注釈する必要があります。その場合でも NonNullish 値で再代入すれば Nullish を除去した形に自動キャストしてくれます。

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

## 関数のデフォルト値

関数の仮引数と分割代入の変数名で、値が省略された場合のデフォルト値を設定できます。省略できるようになりますが `?` は不要です。つけると `Parameter cannot have question mark and initializer.(1015)` でコンパイルエラーになります。

```ts
// add42: (n?: number) => number
const add42 = (n: number = 0) => {
  return n + 42;
};
```

値が **`undefined` だった場合** です。**`null` は含まれません。**

```ts
// add42: (n: number | null) => number
const add42 = (n: number | null = 0) => {
  return n + 42; // ❗ Object is possibly 'null'.(2531)
};
```

## Null 合体代入 (Logical nullish assignment)

TypeScript 4.0 で追加された新しい代入演算子の 1 つです。ECMAScript の規格としては 2020 年末の現在 Stage 4 で `esnext` 扱い、年次のバージョンには来年の ES2021 で追加される予定です。左辺が nullish だった場合右辺値を代入します。デフォルト値を与えるように再代入できるので地味に便利です。

```ts
let foo: number | null | undefined = null;

foo ??= 0; // ここ以降では foo: number
// ---
foo ?? (foo = 0);
foo != null ? foo : (foo = 0);
```

:::message
`foo += 1` は `foo = foo + 1` と同じですが、`foo ??= 1` は `foo = foo ?? 1` とは等価ではありません。これはなぜかというと Null 合体演算子が短絡評価されるせいで、`foo ??= 1` は `foo` が nullish でない場合は代入自体が行われないからです。
:::

関数のデフォルト引数が `null` を潰せない問題もこれがあれば解決します。

```ts
const threeTimes = (n?: number | null) => {
  n ??= 1;
  return n * 3;
};
```

## クラスのフィールド

クラスのフィールドも変数同様、初期化しないとコンパイラに怒られます。

```ts
class User {
  name: string;
  // ❗ Property 'name' has no initializer and is not definitely assigned in the constructor.(2564)
}
```

このエラーを解消するためには定義で初期化するか、

```ts
class User {
  name: string = "Makima";
}
```

コンストラクタで初期化しておく必要があります。

```ts
class User {
  name: string;
  constructor(name: string) {
    this.name = name;
  }
}
```

未初期化で取り回したい場合もやはり変数同様に `T | undefined` にします。再代入で値を割り当てると `undefined` が取り除かれた型になります。

```ts
class User {
  name?: string;
}

const user = new User();
user.name = "Chito";

console.log(`My name is ${user.name}.`);
```

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

## 未初期化警告の無視 `!`

TypeScript は変数やフィールドの初期化について面倒を見てくれますが、流石に関数内での代入操作までは見てくれません。というか真偽値での絞り込みも `throw` での絞り込みも `is` `asserts` なしでは関数には切り出せませんし、中で変数に代入することを表す型述語は (まだ？) 存在しません。

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

# コラム: Nullable の配列から Nullish な値を削除する

`(T | null | undefined)[]` の形になる、Nullish な値を含む配列から Nullish な値を排除したい場合、もっとも簡単なのが `Array.prototype.flatMap` を使う方法です。

```ts
declare const arr: Array<number | null | undefined>;
arr.flatMap((n) => n ?? []);
```

`Array.prototype.flatMap(fn)` は ES2017 で追加されたメソッドで、`array.map(fn).flat()` と等価です。`flatMap` の高階関数で `[]` (長さ 0 の配列) を返すとその要素が削除されます。このコードでは Null 合体演算子 `??` を使って Nullish だった場合は `[]` を返し、その要素を削除するようになっています。このように `flatMap` は要素を削除したり、`[n, n * 3]` というようにすれば要素の挿入もできます。たのしいのでぜひ使いましょう。

`is` 関数と `Array.prototype.filter` を合わせることもできます。もちろん関数本体の処理が正当かはプログラマが責任を負います。この場合は見りゃわかりますが。

```ts
arr.filter((n): n is number => n != null);
```

# コラム: 代数的データ型

Haskell, Rust, Elm, PureScript 等の関数型プログラミング言語、特に ML 系の言語で主流の Null 安全を実現するアプローチが代数的データ型 (Algebraic data types) です。Tagged union と呼んだりもします。TypeScript でも文字列リテラル型とユニオン型を使って代数的データ型を模倣したものが作れます。

```ts
interface None {
  readonly _tag: "None";
}

interface Some<A> {
  readonly _tag: "Some";
  readonly value: A;
}

export type Option<A> = None | Some<A>;
```

この定義はほとんど fp-ts そのものですが、このパターンだと `Option` がメソッドを持てず、めっちゃ関数が増えます。そうするとどうなるかというと `getOrElse(...)(map(...)(o))` とネスト地獄が生まれます。fp-ts では `pipe` を使って `pipe(o, map(...), getOrElse(..))` と書けますが、自力定義だと辛そうです。ECMAScript Proposal の Pipeline Operator を使えば`o |> map(...) |> getOrElse(...)` と素直に書けますが 2 年ぐらい Stage 1 で放置されてる上 2 種類の仕様が対立しており実装されるのは ES2030 ぐらいになると思われます。というかそもそも代数的データ型 (っぽいの) を定義するのが長くて辛いしパターンマッチもないので扱いがつらいです。TypeScript はランタイムに影響の出る機能は絶対入れませんから ECMAScript が動くのを待たなければいけません。

それはともかくとしてオブジェクト型のユニオン型を取る場合は罠がある `in` より文字列リテラル型を使った Tagged union パターンのほうが良い、ということでわりと TypeScript ではよく見ます。文字列リテラル型を `"NetworkError"` みたいな感じにすればどういう事象なのかも表せますしね。
