---
title: "JavaScript: forEach、mapでもコールバック関数の第2引数から添字は取れるのでforにする必要はない"
type: tech
topics: [JavaScript]
emoji: 🌀
---

**for-of / forEach / map でも添字は取れます**。

https://qiita.com/tetsuya-zama/items/11e19b9da4892eb365c4

この記事のブコメで「for-of では添字を取れないので添字が欲しかったら for を使う」と解釈できるものを複数発見しました。これは勘違いです。for-of / forEach / map でも添字は取れるので、**添字がほしいだけなら素の for を使う必要はありません**。

# `forEach` `map` の第 2 引数は添字

`forEach` `map` の場合は非常に簡単です。実はこれらのメソッドが受け取るコールバック関数は、第 1 引数が要素、第 2 引数が添字、第 3 引数がもとの配列、という構成になっているので、普通に第 2 引数を取れば OK です。

```js
const arr = [1, 2, 3, 4, 5];

arr.forEach((value, index) => {
  console.log(`${index}: ${value}`);
});
```

前の要素と等しいか判定し出力してみましょう。

```js
const arr = [1, 2, 3, 3, 4, 5];

arr.forEach((value, index) => {
  console.log(value === arr[index - 1]);
});
```

https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach
https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/map

# `entries` を使えば `for-of` でも添字が取得できる

`for-of` の場合は `forEach` よりちょっと難しいです。`of arr` を `of arr.entries()` に置き換え、変数を分割代入にします。`forEach` の引数と順番が逆なので注意してください。

```js
const arr = [1, 2, 3, 4, 5];

for (const [index, value] of arr.entries()) {
  console.log(`${index}: ${value}`);
}
```

https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/entries

`array.entries()` は `[添字, 要素]` という値を生成するイテレータオブジェクトを返す関数です。イテレータは配列みたいに連続した値が入っていて、配列みたいに `for of` の `of` の右側に置くことで各要素に繰り返し処理を行えます。

:::message
ちなみによく似た [`Object.entries()`](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Object/entries) という関数もあり、`for (const [value, index] of Object.entries(arr))` という使い方もできるのですが、これだと `[index]` が数値でなく文字列になってしまっているので扱いづらいです。これは、配列の添字 `0, 1, ...` が実は数値でなく文字列 `'0', '1', ...` で保持されているからです。`arr[0]` という添字アクセスも型変換で `arr['0']` に置き換えられています。お手元の開発者ツールとかでぜひお試しください。
:::

---

これで `for-of` と `forEach` `map` でも添字を使えるので、素の `for` を使う必要はないことがわかりました。

行いたい処理が複雑になるとどうしても `for (let i = 0; ...)` という素朴な for 文を書かなければいけない場面は存在します。それは仕方ないことです。しかしその場面は今ではありません。みなさんも同居人が「ガスコンロじゃ暖をとれないから囲炉裏導入しようぜ」とか言い出したら抵抗するはずです。ガスストーブを導入しましょう。なければ作りましょう。ないものを自力で作れるのがプログラミングの面白さです。
