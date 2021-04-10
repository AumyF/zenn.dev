---
title: TypeScript v4.3.0-beta 変更点
topics: ["TypeScript"]
type: tech
emoji: 🌄
---

おーみーです。2020/04/01^[エイプリルフールではない]^[もしかしたら日本では 04/02 だったかもしれない] に TypeScript 4.3 Beta が公開されました。「Announcing TypeScript 4.3 Beta」の内容を中心に新機能を紹介していきます。

- [Announcing TypeScript 4.3 Beta](https://devblogs.microsoft.com/typescript/announcing-typescript-4-3-beta)
- [TypeScript 4.3 Iteration Plan](https://github.com/microsoft/TypeScript/issues/42762)
- [TypeScript Roadmap: January - June 2021](https://github.com/microsoft/TypeScript/issues/42673)

`npm i typescript@beta` で導入できます。バージョンは `4.3.0-beta` です。[TypeScript Playground でも試すことができます](https://www.typescriptlang.org/play?ts=4.3.0-beta)。

# Beta での変更点まとめ

- 型引数が制御フロー解析で絞り込まれるように (Improve Narrowing of Generic Types in Control Flow Analysis)
- getter と setter で別々の型を書けるように (Separate Write Types on Properties)
- `override` と `--noImplicitOverride` の追加 (`override` and the `--noImplicitOverride` Flag)
- Tempalate string type の推論の改善 (Template String Type Improvements)
- ECMAScript の `#private` なメソッド/getter/setter のサポート (ECMAScript `#private` Class Elements)
- 条件式での `Promise` チェック (Always-Truthy Promise Checks)
- `static` インデックスシグネチャ (`static` Index Signatures)
- import 文での補完の改善 (Import Statement Completions)
- `@link` タグのエディタサポート (Editor Support for `@link` Tags)
- Union Enum を範囲外の数値と比較できなくなる (Union Enums Cannot Be Compared to Arbitrary Numbers)

# 型引数が制御フロー解析で絞り込まれるように

https://github.com/microsoft/TypeScript/pull/43183

Announcing TypeScript 4.3 Beta にも Iteration Plan にも載っていませんが、重要な変更でこの Beta にも含まれているので紹介しておきます。RC のリリースノートには載るかもしれません。

`T extends string | undefined` のように `T` の制約が union 型になっている場合に「ある `T` 型の値 (ここでは `t`) が `extends string` なのか `undefined` なのか」を絞り込むことができるようになりました^[`T` の制約が `null` `undefined` との union でかつ `t` にプロパティアクセスか関数としての呼び出しを行う場合は以前から型チェックが通っていました。https://github.com/microsoft/TypeScript/pull/15576 の挙動だと思いますが、なんでこんなことになってるのかはわかりません。もしかしてプロパティアクセス/関数呼び出しと return/関数適用って型推論の方法がまるっきり違うんですか？]。

```ts
function f1<T extends string | undefined>(t: T): string {
  if (x) {
    // TS 4.2:
    // Type 'T' is not assignable to type 'string'.
    //  Type 'string | undefined' is not assignable to type 'string'.
    //    Type 'undefined' is not assignable to type 'string'. ts(2322)
    // TS 4.3: Ok 🎉🚀
    return x;
  }
  return "";
}
```

Tagged union もバッチリ推論されます。

```ts
type Left<T> = {
  kind: "left";
  left: T;
};
type Right<T> = {
  kind: "right";
  right: T;
};

function f2<T extends Left<Error> | Right<string>>(t: T) {
  switch (t.kind) {
    case "left":
      // TS 4.2: Property 'left' does not exist on type 'T'. ts(2339)
      return `MATATABISTEP ${t.left.message}`;
    case "right":
      // TS 4.2: Property 'right' does not exist on type 'T'. ts(2339)
      return `SLEEPWALK ${t.right}`;
  }
}
```

# getter と setter で別々の型を書けるように

https://github.com/microsoft/TypeScript/pull/42425

これ知らなかったんですが、getter の返り値と setter の引数は異なる型にできなかったみたいです。

```ts
// ↓型チェックが通る
class Foo {
  #size: number = 0;
  get size() {
    return this.#size;
  }
  // getter の返り値から value: number が推論される
  set size(value) {
    this.#size = value;
  }
}

// ↓4.3 未満では通らない
// getter の返り値を number に、setterの引数を unknown に指定

class Foo {
  #size: number = 0;
  // 'get' and 'set' accessor must have the same type. ts(2380)
  get size(): number {
    return this.#size;
  }
  set size(value: unknown) {
    this.#size = Number(value);
  }
}
```

TS 4.3 ではこの制限が撤廃されるので、後者のコードも合法になります。もちろん、クラス定義だけでなくオブジェクトリテラルやインターフェース、オブジェクト型でも同様に使えます。

```ts:使用例
const foo = {
  get size(): number {
    return Math.random();
  },
  set size(value: unknown) {},
};

// setter が unknown なのでなんでも代入できる
foo.size = null;
foo.size = "8900";

// getter は number なので数値が返る
foo.size.toExponential();
```

ただ、VS Code で見た限り `foo.size` をパッと確認しただけでは setter が `unknown` であることが見えませんでした (definition まで飛ばないとわからない)。`number` なのに `unknown` が代入できる、という事象が起きたときはこれを疑いましょう。

なお、わかりやすさを確保するため、**getter の返り値の型は setter の引数の型の部分型でなければならない** という制限が設けられています。

```ts
class Foo {
  // The return type of a 'get' accessor must be assignable to its 'set' accessor type. ts(2380)
  get size(): number {
    return 1925;
  }
  set size(value: 1925) {}
}
```

型引数で `get value(): T` `set value(v: U)` とするなら `T extends U` という制約が必要となります。getter の上に `// @ts-expect-error` か `// @ts-ignore` を書くと無視できますが、これをやると「`foo.size: number` に代入しようとしたら `Type '433' is not assignable to type '1925'. ts(2322)` で型エラーになる」という挙動になってとても易しくないのでやめたほうがよいです。

# `override` キーワードと `--noImplicitOverride` フラグの追加

https://github.com/microsoft/TypeScript/pull/39669

`override` によって、そのメソッド/プロパティが基底クラスのメソッド/プロパティをオーバーライドしていることを明示できるようになりました。`override` によるオーバーライドを強制するオプション `--noImplicitOverride` も追加されています。これらは ECMAScript とは特に関係ない、TypeScript 独自の機能です。

基底になるクラス `Base` と、それを継承するクラス `Derived` を用意しました。`Derived` は `show` `hide` を (暗黙的に) オーバーライドしています。

```ts
class Base {
  show() {}
  hide() {}
}

class Derived extends Base {
  show() {}
  hide() {}
}
```

暗黙的なオーバーライドでは、`Base` の構造を変更しても `Derived` でオーバーライド定義されていたメソッドはそのまま残ってしまいます。

```ts
class Base {
  setVisiblity(visiblity: boolean) {}
}

class Derived extends Base {
  show() {}
  hide() {}
}
```

`override` 修飾子 (modifier) を付けると、基底クラスに同名のメソッドが存在しない場合はコンパイルエラーになるため、基底クラスの変更に追従しやすくなります。

```ts
class Base {
  setVisiblity(visiblity: boolean) {}
}

class Derived extends Base {
  // This member cannot have an 'override' modifier because it is not declared in the base class 'Base'. ts(4113)
  override show() {}
  override hide() {}
}
```

新しいコンパイラオプション `--noImplicitOverride` も追加されました。その名の通り暗黙的なオーバーライドを禁止し、`override` による **明示的な** オーバーライドを強制するオプションです。

```ts:noImplicitOverride
class Base {
  show() {}
  hide() {}
}

class Derived extends Base {
  // This member must have an 'override' modifier because it overrides a member in the base class 'Base'. ts(4114)
  show() {}
  hide() {}
}
```

オーバーライドするつもりはなかったのにうっかり名前がかぶって上書きされてしまっていた、というミスを防止できます。新規プロジェクトでは積極的に有効化していくべきでしょう。

# Template Literal Types の改善

Template literal types、あるいは template string types の改善が 2 つ入りました。開発チームの中でも呼称が統一されてないんじゃないかと思っています。

## テンプレートリテラルへの推論

https://github.com/microsoft/TypeScript/pull/43376

これまでは、関数からテンプレートリテラルを返す場合、返り値の型が `string` 型の値として扱われて `` Type 'string' is not assignable to type '`hello ${string}`'. ts(2322) `` になってしまうことから `as const` をつける必要がありました。

```ts
const hello = (n: string): `hello ${string}` => {
  return `hello ${n}` as const;
};
```

4.3 ではここの推論が改善され、

```ts
const hello = (n: string): `hello ${string}` => {
  return `hello ${n}`;
};
```

のように書いても型が通るようになりました。

実は TS 4.2 Beta で **すべての** テンプレートリテラルに template literal types を適用する変更が導入されたものの、互換性の問題により[最終リリースでは撤回された](https://devblogs.microsoft.com/typescript/announcing-typescript-4-2/#reverting-template-literal-inference)、という経緯があります。すべてのテンプレートリテラルを template literal types として扱うようにすると、テンプレートリテラルを返している既存の関数の返り値がすべて書き換わってしまうからだと思われます。

> In [#41891](https://github.com/microsoft/TypeScript/pull/41891) we introduced template literal types for all template literal expressions. That turned out to be too much of a breaking change, and it was reverted in [#42588](https://github.com/microsoft/TypeScript/pull/42588).

> 拙訳: #41891 ですべてのテンプレートリテラル式に template literal types を導入したら、破壊的変更が大きすぎるとわかったので #42588 で取り消された。
> https://github.com/microsoft/TypeScript/pull/43376 より

TS 4.3 では破壊的変更を抑えつつテンプレートリテラルをうまく扱うため、**テンプレートリテラルが文脈によって型付けされている (_contextually typed_) ときにのみ template literal type として推論される** ことになりました。contextually typed というのは、たとえば変数宣言での型注釈、関数の引数の型、関数の返り値の型が template literal types になっているという状態です。

```ts:contextually typed とはなにか？
declare const dead: string;
// TS 4.2: Type 'string' is not assignable to type '`un${string}`'. ts(2322)
const foo: `un${string}` = `un${dead}`; //

// TS 4.2: Argument of type 'string' is not assignable to parameter of type '`un${string}`'. ts(2345)
fn(`un${dead}`);

function fn(luck: `un${string}`): `un${string}` {
  // TS 4.2: Type 'string' is not assignable to type '`un${string}`'. ts(2322)
  return `un${luck}`;
}
```

逆に言えば、**文脈によって型付けされていないときは今まで通り `string` として扱われます**。これによって、型推論によって `string` を返していた関数は今まで通り `string` を返すようになっています。

```ts
// const hello: (n: string) => string
const hello = (n: string) => {
  return `hello ${n}`;
};
```

関数の引数が `extends string` な型引数になっている場合も「文脈」として扱われます。わざわざ型引数を取るということはリテラル型か template literal types を受け取りたいということなので妥当ですね。

```ts
declare const s: string;
declare function f<T extends string>(t: T): T;

f(`foobar${s}`);
```

## Template Literal Types どうしでの部分型関係

https://github.com/microsoft/TypeScript/pull/43361

Template literal types 同士の間での部分型関係が追加されました。

いままで、template literal types と string literal types の間では部分型関係がありました。

```ts
declare let s1: `${number}-${number}`;
s1 = `19-25`;
```

しかし、template literal types どうしの間では部分型関係がなかったため、以下のような代入は不可能でした。

```ts
declare let s1: `${number}-${number}`;

declare let s2: `${number}-123`;

// Type '`${number}-123`' is not assignable to type '`${number}-${number}`'.(2322)
s1 = s2;
```

TS 4.3 ではこれができるようになります。

---

これらの新機能を使ってこのような推論をさせることもできるようになりました。

```ts
declare function f<V extends string>(arg: `*${V}*`): V;

function test<T extends string>(s: string, n: number, b: boolean, t: T) {
  const h = f("*hello*"); // "hello"
  const hh = f("**hello**"); // "*hello*"
  const str = f(`*${s}*`); // string
  const num = f(`*${n}*`); // `${number}`
  const bool = f(`*${b}*`); // "false" | "true"
  const tee = f(`*${t}*`); // `${T}`

  const strstr = f(`**${s}**`); // `*${string}*`
}
```

# ECMAScript の `#private` なメソッド、setter、getter のサポート

https://github.com/microsoft/TypeScript/pull/42458

[tc39/proposal-private-methods](https://github.com/tc39/proposal-private-methods) への対応です。[TypeScript 3.8 で `#private` なプロパティが実装されていました](https://qiita.com/vvakame/items/72da760526ec7cc25c2d#ecmascript-private-fields%E3%81%AE%E3%82%B5%E3%83%9D%E3%83%BC%E3%83%88) が、4.3 では `#private` なメソッド、setter、getter が使えるようになりました。

```ts
class Klass {
  #privateMethod() {}
  get #privateGetter() {
    return 1000;
  }
  set #privateSetter(v: number) {
    this.#privateMethod();
    this.#privateGetter;
  }
}

const klass = new Klass();

// Property '#privateMethod' is not accessible outside class 'Klass' because it has a private identifier. ts(18013)
klass.#privateMethod();

// Property '#privateGetter' is not accessible outside class 'Klass' because it has a private identifier. ts(18013)
klass.#privateGetter;

// Property '#privateSetter' is not accessible outside class 'Klass' because it has a private identifier. ts(18013)
klass.#privateSetter = 200;
```

ちなみに、`#private` 指定されたプロパティは子クラスからも完全に隠蔽されるのでオーバーライドはできません。`override` を付けるとエラーになります。

# 条件式での Promise のチェック

https://github.com/microsoft/TypeScript/pull/39175

`Promise` を `if` とかの条件式に突っ込むとエラーが出るようになりました。`await` 忘れに効果的です。

```ts
declare function asynchronouslyGetCondition(): Promise<boolean>;

(async () => {
  const cond = asynchronouslyGetCondition();

  // This condition will always return true since this 'Promise<boolean>' appears to always be defined. ts(2801)
  // Did you forget to use 'await'?
  if (cond) {
    console.log("true!");
  }
})();
```

ちなみに `--strictNullChecks` が無効の場合はこのチェックは行われません (`Promise` 型に falsy な `null` や `undefined` が混入するので)。

# `static` インデックスシグネチャ

https://github.com/microsoft/TypeScript/pull/37797

4.2 の iteration plan に入ってたのが延期されたものです。インデックスシグネチャがクラスの `static` で定義できるようになりました。

```ts
class Animal {
  static cnt: number = 0;
  static [prop: string]: unknown;
}

Animal.foobarIndexSignature; // unknown
```

# import 文の補完

JavaScript の import で最大のつらいポイントは import する物体がモジュール名の前に来てしまうことです。これのおかげで

```ts
import { useState } from "react";
```

のようなコードを素手でぺちぺち打っていくと `import {use}` らへんまで打ったところでは補完が効きません。スニペットで `"react"` を先に打っている人も多いでしょう。

TypeScript 4.3 では `import use` ぐらいまで打つと自動インポートの補完が働きはじめます。そして `useState` のような候補を確定すると、残りの `{ useState } from "react";` まで自動で打ってくれるのです。[実際に動いてる様子はリリースノートの GIF をご参照ください](https://devblogs.microsoft.com/typescript/announcing-typescript-4-3-beta/#import-statement-completions)。

ただしこの機能を使うにはエディタ側の対応が必要らしく、現時点で使えるのは VS Code Insiders の最新版のみのようです。青いほうで使えるのはちょっと先になりそうです。そういうことなので Insiders をインストールして試してみましたが動きませんでした。[VS Code 側で Pull Request はマージされている](https://github.com/microsoft/vscode/pull/119009) ので動くはずなんですがね。まあそのうち動くでしょう。

# `@link` のエディタサポート

エディタで JSDoc 中の `@link` をクリックすると、それの定義に飛べるようになりました。現状 (2021-04-09) では VS Code のリリース版では対応していないので、Insiders 版で動作確認しました。

```ts:dom.ts
export const bar = () => { };
```

```ts:main.ts
import {bar} from "./dom";

/**
 * same as {@link bar} except ...
 */
const foo = () => {};
```

![](https://storage.googleapis.com/zenn-user-upload/yzwa71tldmvcnu22igls8omqoopz)
![](https://storage.googleapis.com/zenn-user-upload/9j4zgy8sqlbq0p5fdz0wiger2qhq)

# 破壊的変更

## 条件式での Promise のチェック

前記参照。

## `lib.d.ts` の変更

https://github.com/microsoft/TypeScript-DOM-lib-generator/issues/991

`lib.d.ts` からブラウザによる実装のない API が除去されました。対象となるのは `Account`, `AssertionOptions`, `RTCStatsEventInit`, `MSGestureEvent`, `DeviceLightEvent`, `MSPointerEvent`, `ServiceWorkerMessageEvent`, `WebAuthentication` です。これらの名前は今後は型名として自由に使うことができるでしょう。特に助かるのは `Account` ですね。

```ts
// type では、すでに存在する型名を定義することはできない
// 4.2以下: Duplicate identifier 'Account'. ts(2300)
type Account = {};

// interface や class では、型名がかぶった場合定義がマージされる
// 4.2 以下: エラーにはならないが、lib.dom.d.ts の定義と declaration merging して勝手にプロパティが生えてくる
class Account {}
```

なお `WebAuthentication` が消されてますが、使っている人が少なすぎて消されたのではなく `WebAuthentication` というインターフェースが消されただけで Web Authentication API は消えてないです。というか `WebAuthentication` という名前のインターフェースが MDN を検索しても見つからないんですよね。

## Union Enum を範囲外の数値と比較できなくなる

https://github.com/microsoft/TypeScript/pull/42472

Union Enum の値の範囲に入っていない数値と比較できなくなったみたいです。

```ts
enum E {
  A = 0,
  B = 1,
}

function f(e: E) {
  // This condition will always return 'false' since the types 'E' and '3' have no overlap. ts(2367)
  if (e === 3) {
  }
}
```

無効化するには `+` をつけるそうです。

```ts
enum E {
  A = +0,
  B = 1,
}
```

# 今後の予定

TypeScript 4.3.1 (RC) は 2021-05-11 に、TypeScript 4.3.2 (Final) はその 2 週間後の 2021-05-25 に公開される予定です。

4.3 で今後予定されている機能の **一部** を記しておきます (先送りになる可能性もあります、特に investigate になってるやつはどういう実装がいいか考えてる段階のものも多いっぽいので)。

- インデックスシグネチャのキーの型に `symbol` やリテラル型を許容 ([Generalized index signatures](https://github.com/microsoft/TypeScript/pull/26797))
  - 4.2 から引き継がれました。
- Well-known symbols の概念を削除して unique symbol として扱うように変更 ([Improve support for well-known symbols](https://github.com/microsoft/TypeScript/pull/42543))
- パッケージインポート/エクスポートのカスタマイズ ([Package export maps](https://github.com/microsoft/TypeScript/issues/33079))
  - Node.js の実験的機能に対するサポートのようです
  - https://github.com/jkrems/proposal-pkg-exports/
- プロジェクトを開始するときのわかりやすさについて再評価する ([Review the project setup experience](https://github.com/microsoft/TypeScript/issues/41580))
  - `tsc --init` で生成される tsconfig.json が巨大で物々しいので量を削って docs へのリンクを貼るようにしようぜ、という感じ
  - https://github.com/microsoft/TypeScript/issues/41580
- `catch(e)` で `e: unknown` をデフォルトにするフラグを導入する提案 ([Investigate strictness flag for `unknown` in `catch`](https://github.com/microsoft/TypeScript/issues/41016))

# さいごに

関東地方でプログラミング、とくに関数型言語や型システムにつよいオタクがたくさんいる大学を探してるので、コメント欄か Twitter ([@aumy_f](https://twitter.com/aumy_f)) かどこか適当なところで教えていただけると助かります。
