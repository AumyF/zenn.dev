---
title: TypeScript 4.3 Beta 変更点
topics: ["TypeScript"]
type: tech
emoji: 👉
---

TypeScript 4.3 が公開されました。

# Separate Write Types on Properties

# `override` キーワードと `--noImplicitOverride` フラグの追加

`override` によって、そのメソッドが基底クラスのメソッドをオーバーライドしていることを明示できるようになりました。`override` によるオーバーライドを強制するオプション `--noImplicitOverride` も追加されています。

新しいキーワードとして `override` が導入されました。C# や Kotlin などにもあるようなものです。

# Template literal types の改善

TypeScript 4.2 Beta で入って RC で撤回されたやつです。

# ECMAScript の private なメソッド、setter、getter のサポート

# Promise に対する恒真チェック

JavaScript のすべてのオブジェクトは真偽値に変換すると `true` になることから、TypeScript では `if` などの条件式に `object` 等の型が来た場合には型エラーが出るようになっています。また `string` に `Promise<string>` を割り当てようとしたときなどに「`await` 忘れてない？」というサジェストを出してくれます。4.3 では `Promise` を条件式に突っ込んだ際にもサジェストが出るようになりました。

# `static` インデックスシグネチャ

4.2 の iteration plan に入ってたのが延期されたものです。インデックスシグネチャがクラスの `static` で定義できるようになりました。

# import 文の補完

JavaScript の import/export で最大のつらいポイントは import する物体がモジュール名の前に来てしまうことです。これのおかげで

```ts
import { useState } from "react";
```

のようなコードを素手でぺちぺち打っていくと `import {use}` らへんまで打ったところでは補完が効きません。スニペットで `"react"` を先に打っている人も多いでしょう。

TypeScript 4.3 では `import use` ぐらいまで打つと自動インポートの補完が働きはじめます。そして `useState` のような候補を確定すると、残りの `{ useState } from "react";` まで自動で打ってくれるのです。

ただしこの機能を使うにはエディタ側の対応が必要らしく、現時点で使えるのは VSCode Insiders の最新版のみのようです。ちょうどこの間 VSCode は最新リリースが出たところなので、青いほうで使えるのはちょっと先になりそうです。

# `@link` のエディタサポート
