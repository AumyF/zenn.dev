---
title: TypeScript v4.3.0-beta 変更点
topics: ["TypeScript"]
type: tech
emoji: 🌄
---

TypeScript 4.3 Beta が公開されました。

- [Announcing TypeScript 4.3 Beta](https://devblogs.microsoft.com/typescript/announcing-typescript-4-3-beta)
- [TypeScript Roadmap: January - June 2021](https://github.com/microsoft/TypeScript/issues/42673)
- [TypeScript 4.3 Iteration Plan](https://github.com/microsoft/TypeScript/issues/42762)

`npm i typescript@beta` で導入できます。バージョンは `4.3.0-beta` です。

# Beta での変更点まとめ

- getter と setter で別々の型を書けるように (Separate Write Types on Properties)
- `override` と `--noImplicitOverride` の追加 (`override` and the `--noImplicitOverride` Flag)
- Tempalate string type の推論の改善 (Template String Type Improvements)
- ECMAScript の `#private` なメソッド/getter/setter のサポート (ECMAScript `#private` Class Elements)
- 条件式での `Promise` チェック (Always-Truthy Promise Checks)
- `static` インデックスシグネチャ (`static` Index Signatures)
- import 文での補完の改善 (Import Statement Completions)
- `@link` タグのエディタサポート (Editor Support for `@link` Tags)

# 破壊的変更

## `lib.d.ts` の変更

`lib.d.ts` からブラウザによる実装のない API が除去されました。対象となるのは `Account`, `AssertionOptions`, `RTCStatsEventInit`, `MSGestureEvent`, `DeviceLightEvent`, `MSPointerEvent`, `ServiceWorkerMessageEvent`, `WebAuthentication` です。これらの名前は今後は型名として自由に使うことができるでしょう。特に重要なのは **`Account`** ですね。

```ts
// type では、すでに存在する型名を定義することはできない
// 4.2以下: Duplicate identifier 'Account'. ts(2300)
type Account = {};

// interface や class では、型名がかぶった場合定義がマージされる
// 4.2 以下でもエラーにはならないが、lib.dom.d.ts の定義と declaration merging して勝手にプロパティが生えてくる
class Account {}
```

あと `WebAuthentication` が消されてて一瞬焦った。WebAuthn 使ってみたいなとぼんやり思っていたのに使っている人が少なすぎてついに消されたかと思った。`WebAuthentication` というインターフェースが消されただけで Web Authentication API は消えてないです。

## Union Enum を範囲外の数値と比較できなくなる / Union Enums Cannot Be Compared to Arbitrary Numbers

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

# getter と setter で別々の型を書けるように

これ知らなかったんですが、getter の返り値と setter の引数は異なる型にできなかったみたいです。

```ts
// ↓型が通る
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

TS4.3 ではこの制限が撤廃されるので、後者のコードも合法になります。言うまでもないことですが、クラス定義だけでなくオブジェクトリテラルやインターフェース、オブジェクト型でも同様です。

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

ただ、VSCode で見た限り `foo.size` をパッと確認しただけでは setter が `unknown` であることが見えませんでした (definition まで飛ばないとわからない)。

これ setter と getter を逆にして `foo.size: unknown` だけど `number` しか代入できない、というようにしたらすごく面倒になりそうと思って試したら、

```ts
class Foo {
  // The return type of a 'get' accessor must be assignable to its 'set' accessor type. ts(2380)
  get size(): number {
    return 1925;
  }
  set size(value: 1925) {}
}
```

エラーになりました。getter の返り値の型は setter の引数の型の部分型でなければならないみたいです。型引数で `get value(): T` `set value(v: U)` とするなら `T extends U` という制約が必要となります。これは一貫性を保つための意図的な制限とされています。事情がある場合は getter の上に `// @ts-expect-error` か `// @ts-ignore` を書けばよさそうです。

# `override` キーワードと `--noImplicitOverride` フラグの追加

`override` によって、そのメソッド/プロパティが基底クラスのメソッド/プロパティをオーバーライドしていることを明示できるようになりました。`override` によるオーバーライドを強制するオプション `--noImplicitOverride` も追加されています。これらの変更は TC39 や ECMAScript とは特に関係ありません。

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

新しいコンパイラオプション `--noImplicitOverride` も追加されました。その名の通り暗黙のオーバーライドを禁止し、オーバーライドするときは `override` を付けることを強制するオプションです。

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

オーバーライドするつもりはなかったのにうっかり名前がかぶってオーバーライドになってしまっていた、というミスを防止できます。新規プロジェクトでは積極的に有効化していくべきでしょう。

# Template string types の改善

TypeScript 4.2 Beta で入って RC で撤回されたやつです。

## テンプレートリテラルに対する推論

関数でテンプレートリテラルを返す場合、返り値の型が `string` 型の値として扱われて `` Type 'string' is not assignable to type '`hello ${string}`'. ts(2322) `` しまうことから `as const` をつける必要がありました。

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

のように書いても型が通るようになりました。この変更で注目に値する点は **テンプレートリテラルが文脈によって型付けされている (_contextually typed_) ときにのみ template string type として推論される** という点です。逆に言えば、**文脈によって型付けされていないときは今まで通り `string` として扱われます**。

```ts
// const hello: (n: string) => string
const hello = (n: string) => {
  return `hello ${n}`;
};
```

もともと TS4.2 がなぜこのような挙動になっているのかはちゃんと追っていませんが、4.2 Beta でこの変更が導入されたものの、なんか (十中八九互換性の問題と思われます) がうまくいかなかったようで 4.2 RC では撤回された、という経緯があります。すべてのテンプレートリテラルを template string types として扱うようにすると、テンプレートリテラルを返している既存の関数の返り値がすべて書き換わってしまうからでしょうか。

関数の引数が `extends string` な型引数になっている場合も「文脈」として扱われます。わざわざ型引数を取るということはリテラル型かテンプレートリテラル型を受け取りたいということなので妥当ですね。

```ts
declare const s: string;
declare function f<T extends string>(t: T): T;

f(`foobar${s}`);
```

## Template String Types どうしでの部分型関係

Template string types 同士の間での部分型関係が追加されました。

いままで、template string types と string literal types の間では部分型関係がありました。

```ts
declare let s1: `${number}-${number}`;
s1 = `19-24`;
```

しかし、template string types どうしの間では部分型関係がなかったため、以下のような代入は不可能でした。

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

ちなみに、`#private` 指定された物体は子クラスからも隠蔽されるので `override` とはとくに縁がありません。

# 条件式での Promise のチェック

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

TypeScript 4.3 では `import use` ぐらいまで打つと自動インポートの補完が働きはじめます。そして `useState` のような候補を確定すると、残りの `{ useState } from "react";` まで自動で打ってくれるのです。[リリースノート](https://devblogs.microsoft.com/typescript/announcing-typescript-4-3-beta/#import-statement-completions) に GIF があります。

ただしこの機能を使うにはエディタ側の対応が必要らしく、現時点で使えるのは VSCode Insiders の最新版のみのようです。ちょうどこの間 VSCode は最新リリースが出たところなので、青いほうで使えるのはちょっと先になりそうです。そういうことなので Insiders をインストールして試してみましたが動きませんでした。[VS Code 側で Pull Request はマージされている](https://github.com/microsoft/vscode/pull/119009) ので動くはずなんですがね。まあそのうち動くでしょう。

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

# 今後

TypeScript 4.3.1 (RC) は 2021-05-11 に、TypeScript 4.3.2 (Final) は 2 週間後の 2021-05-25 に公開される予定です。

4.3 で今後予定されている機能の一部を記しておきます (先送りになる可能性もあります、特に investigate になってるやつはどういう実装がいいか考えてる段階のものも多いっぽいので)。

- インデックスシグネチャのキーの型に `symbol` やリテラル型を許容 ([Generalized index signatures](https://github.com/microsoft/TypeScript/pull/26797))
  - 4.2 から先送りされました
- Well-known symbols の概念を削除して unique symbol として扱うように変更 ([Improve support for well-known symbols](https://github.com/microsoft/TypeScript/pull/42543))
- パッケージインポート/エクスポートのカスタマイズ ([Package export maps](https://github.com/microsoft/TypeScript/issues/33079))
  - Node.js の実験的機能に対するサポートのようです
  - https://github.com/jkrems/proposal-pkg-exports/
- プロジェクトを開始するときのわかりやすさについて再評価する ([Review the project setup experience](https://github.com/microsoft/TypeScript/issues/41580))
  - `tsc --init` で生成される tsconfig.json が巨大で物々しいので量を削って docs へのリンクを貼るようにしようぜ、という感じ
  - https://github.com/microsoft/TypeScript/issues/41580
- `catch(e)` で `e: unknown` をデフォルトにするフラグを導入する提案 ([Investigate strictness flag for `unknown` in `catch`](https://github.com/microsoft/TypeScript/issues/41016))

そういえば [Improve narrowing of generic types in control flow analysis](https://github.com/microsoft/TypeScript/pull/43183) は Iteration plan に載ってないんですけどマージされてるし導入されるってことでいいんですかね。

# 宣伝

関東地方で関数型言語や型システムやプログラミングにつよいオタクがたくさんいる大学を探してます。コメント欄か Twitter ([@aumy_f](https://twitter.com/aumy_f)) で教えて下さい。
