---
title: "「CSSのクラス名自動生成は最悪である」"
emoji: "🙄"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["css", "javascript", "cssmodules", "styledcomponents"]
published: false
---

最近の Web フロントエンド開発においては CSS を適用するためのクラス名を自動生成するようなツールがいくつか存在する。たとえば styled-components や Emotion といった CSS in JS ライブラリ、そして CSS modules が挙げられる。**これらは、ある視点から見れば最悪の技術である**。

# Userstyles

**Userstyles** とは、ウェブサイトの利用者がウェブサイトの見た目を改造するために挿入するスタイルシートのことである。UserCSS、カスタム CSS などとも呼ばれる。代表的なものとしては、ダークモードに対応していないウェブサイトをダークモード対応にするものなどが挙げられる。

Userstyles を利用するユーザーからすれば、クラス名の自動生成技術は最悪のものである。その理由は、単純に **スタイルを当てることが困難になるから** である。

例として、以下のような素朴な Web サイトを考えよう:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Document</title>
    <style>
      .section > p {
        font-family: sans-serif;
      }
    </style>
  </head>
  <body>
    <div>
      <div class="section">
        <h1>This section's paragraph is sans serif</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Illo vero
          excepturi quos nemo earum qui atque dolores. Placeat ipsum
          perspiciatis doloribus sunt ab repellendus libero hic distinctio
          officiis. Quaerat, atque!
        </p>
      </div>
    </div>
  </body>
</html>
```

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Document</title>
    <style>
      .section > p {
        font-family: sans-serif;
      }
    </style>
  </head>
  <body>
    <div>
      <div class="section">
        <h1>This section's paragraph is sans serif</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Illo vero
          excepturi quos nemo earum qui atque dolores. Placeat ipsum
          perspiciatis doloribus sunt ab repellendus libero hic distinctio
          officiis. Quaerat, atque!
        </p>
      </div>
    </div>
    <style>
      .section > p {
        font-family: monospace;
      }
    </style>
  </body>
</html>
```

# クラス名自動生成の罪
