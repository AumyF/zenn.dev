---
title: "TypeScript: extendsの意味"
type: tech
topics: [TypeScript, JavaScript]
emoji: 🥅
published: false
---

# はじめに

JavaScript には `extends` というキーワードがあります。TypeScript では `extends` はいろいろな場面で使われるので少々混乱を招いていますが、その核となる意味は一貫しているのでそれを捉えれば迷うことはありません。

# 部分型

TypeScript において `extends` が登場する場面は以下の 4 つです。

- クラスの継承 `class C extends K {}`
- 型引数に与える制約 `<T extends U>`
- conditional types の条件部 `T extends U ? X : Y`
- conditional types の `infer` 制約 `T extends infer U extends V ? X : Y`

これらのどの使い方においても共通していることは **`T extends U` では型 `T` は型 `U` の部分型である** ということです。

「型 `T` のすべての値が型 `U` の値でもある」とき、「型 `T` が型 `U` の部分型である」といいます。たとえば `{ name: string; age: number }` という型は `{ name: string }` という型の部分型です。

```ts
type U = { name: string };
const f = (u: U) => {
  console.log(u.name);
};

type T = { name: string; age: number };
const t: T = {
  name: "Alice",
  age: 17,
};

// T型の値tを、U型の値を引数にとる関数に渡すことができる
f(t);
```

`{ name: string }` という型は「`string` 型の値が入った `name` というプロパティを持つ値」と読むことができます。`{ name: string; age: number }` も `name` プロパティがあり、その型は `string` なので `{ name: string }` 型として扱うことができます。

もう一つの例としてユニオン型を挙げます。たとえば `"foo" | "bar"` 型は `"foo" | "bar" | "baz"` 型の部分型です。

```ts
type U = "foo" | "bar" | "baz";
const f = (u: U) => {
  console.log(u);
};

type T = "foo" | "bar";
const t: T = "bar";

// T型の値tを、U型の値を引数にとる関数に渡すことができる
f(t);
```

これは集合として捉えるとわかりやすいでしょう。foo, bar, baz の 3 つの要素をもつ集合 U と、foo, bar の 2 つの要素をもつ集合 T があった場合、ある値が集合 T に属するならばかならず集合 U にも属しているといえます。

部分型関係について理解したら、`extends` のそれぞれの使用例を見ていき、実際に部分型が使われていることを確認しましょう。

# クラスの継承

JavaScript において `extends` は **クラスの継承** で登場します。クラスの定義時に `extends A` という節を付け加えることによって、クラス `B` はクラス `A` のコンストラクタやメソッドを受け継ぎます。

```js
class A {
  hello() {
    console.log("Hello!");
  }
}

class B extends A {}

const b = new B();
b.hello(); // Hello!
```

このコード例において `B` のインスタンスである `b` は `A` で定義されたメソッドである `hello` を呼び出すことができます。つまり、`b` は `A` 型の値としても扱えるということです。この `b` に限らず `B` のあらゆるインスタンスは同じように `hello` を使えますから、`B` は `A` の部分型であるといえます。

# 型引数の制約

# Conditional Types の条件分岐
